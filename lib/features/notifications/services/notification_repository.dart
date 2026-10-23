import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/notification_item.dart';

class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository _instance = NotificationRepository._();
  static NotificationRepository get instance => _instance;

  /// Global notifier for unread notification count across the app (e.g. Navigation badges)
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// Fetches notifications for the authenticated user.
  /// RLS guarantees only notifications where recipient_id == auth.uid() are returned.
  Future<List<NotificationItem>> fetchNotifications({int limit = 50}) async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) {
      unreadCountNotifier.value = 0;
      return [];
    }

    final user = supabase.currentUser;
    if (user == null) {
      unreadCountNotifier.value = 0;
      return [];
    }

    try {
      final res = await supabase.client!
          .from('notifications')
          .select()
          .eq('recipient_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      final List<NotificationItem> items = (res as List<dynamic>)
          .map((data) => NotificationItem.fromJson(data as Map<String, dynamic>))
          .toList();

      final unread = items.where((item) => !item.isRead).length;
      unreadCountNotifier.value = unread;

      return items;
    } catch (e) {
      debugPrint('[NotificationRepository] fetchNotifications error: $e');
      return [];
    }
  }

  /// Fetches unread notification count via secure RPC or direct query.
  Future<int> refreshUnreadCount() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized || supabase.currentUser == null) {
      unreadCountNotifier.value = 0;
      return 0;
    }

    try {
      // Attempt to invoke the optimized RPC function
      final rpcRes = await supabase.client!.rpc('get_unread_notification_count');
      if (rpcRes is int) {
        unreadCountNotifier.value = rpcRes;
        return rpcRes;
      } else if (rpcRes != null) {
        final parsed = int.tryParse(rpcRes.toString()) ?? 0;
        unreadCountNotifier.value = parsed;
        return parsed;
      }
    } catch (_) {
      // Fallback to table count if RPC is unavailable in current migration context
    }

    try {
      final res = await supabase.client!
          .from('notifications')
          .select('id')
          .eq('recipient_id', supabase.currentUser!.id)
          .isFilter('read_at', null);

      final count = (res as List<dynamic>).length;
      unreadCountNotifier.value = count;
      return count;
    } catch (e) {
      debugPrint('[NotificationRepository] refreshUnreadCount fallback error: $e');
      return unreadCountNotifier.value;
    }
  }

  /// Marks a specific notification as read.
  /// Enforced in PostgreSQL to only allow modifying own notification.
  Future<bool> markAsRead(String notificationId) async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized || supabase.currentUser == null) return false;

    try {
      // Attempt RPC first
      await supabase.client!.rpc(
        'mark_notification_as_read',
        params: {'p_notification_id': notificationId},
      );

      if (unreadCountNotifier.value > 0) {
        unreadCountNotifier.value -= 1;
      }
      return true;
    } catch (_) {
      // Direct update fallback
      try {
        await supabase.client!
            .from('notifications')
            .update({'read_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', notificationId)
            .eq('recipient_id', supabase.currentUser!.id);

        if (unreadCountNotifier.value > 0) {
          unreadCountNotifier.value -= 1;
        }
        return true;
      } catch (e) {
        debugPrint('[NotificationRepository] markAsRead error: $e');
        return false;
      }
    }
  }

  /// Marks all unread notifications as read for current user.
  Future<bool> markAllAsRead() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized || supabase.currentUser == null) return false;

    try {
      await supabase.client!.rpc('mark_all_notifications_as_read');
      unreadCountNotifier.value = 0;
      return true;
    } catch (_) {
      try {
        await supabase.client!
            .from('notifications')
            .update({'read_at': DateTime.now().toUtc().toIso8601String()})
            .eq('recipient_id', supabase.currentUser!.id)
            .isFilter('read_at', null);

        unreadCountNotifier.value = 0;
        return true;
      } catch (e) {
        debugPrint('[NotificationRepository] markAllAsRead error: $e');
        return false;
      }
    }
  }

  /// Deletes a notification belonging to the current user.
  Future<bool> deleteNotification(String notificationId) async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized || supabase.currentUser == null) return false;

    try {
      await supabase.client!
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('recipient_id', supabase.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('[NotificationRepository] deleteNotification error: $e');
      return false;
    }
  }
}
