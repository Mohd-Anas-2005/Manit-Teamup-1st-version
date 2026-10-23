import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/features/notifications/domain/notification_item.dart';
import 'package:manit_teamup/features/notifications/presentation/notifications_screen.dart';
import 'package:manit_teamup/features/notifications/services/notification_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationItem Serialization & Model Tests', () {
    test('Correctly parses from Supabase database columns (read_at, created_at, related_team_id)', () {
      final dbJson = {
        'id': 'notif-101',
        'recipient_id': 'user-alice-uuid',
        'type': 'joinRequest',
        'title': 'New Join Request 📩',
        'body': 'Bob requested to join "Robotics Club".',
        'related_team_id': 'team-robotics-uuid',
        'read_at': null,
        'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      };

      final item = NotificationItem.fromJson(dbJson);

      expect(item.id, 'notif-101');
      expect(item.recipientId, 'user-alice-uuid');
      expect(item.type, NotificationType.joinRequest);
      expect(item.title, 'New Join Request 📩');
      expect(item.body, 'Bob requested to join "Robotics Club".');
      expect(item.referenceId, 'team-robotics-uuid');
      expect(item.isRead, false);
      expect(item.timeAgo, contains('5m ago'));
    });

    test('Correctly parses read notification with read_at timestamp', () {
      final dbJson = {
        'id': 'notif-102',
        'recipient_id': 'user-alice-uuid',
        'type': 'requestAccepted',
        'title': 'Request Accepted! 🎉',
        'body': 'Your application was accepted.',
        'related_team_id': 'team-ai-uuid',
        'read_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      };

      final item = NotificationItem.fromJson(dbJson);

      expect(item.isRead, true);
      expect(item.timeAgo, contains('2h ago'));
    });

    test('copyWith properly creates new instance with updated read state', () {
      final original = NotificationItem(
        id: 'notif-1',
        recipientId: 'user-1',
        type: NotificationType.teamAnnouncement,
        title: 'Meeting Tomorrow',
        body: 'Sync at 4 PM in cafeteria',
        isRead: false,
        timestamp: DateTime.now(),
      );

      final updated = original.copyWith(isRead: true);

      expect(original.isRead, false);
      expect(updated.isRead, true);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
    });

    test('toJson generates matching database keys', () {
      final item = NotificationItem(
        id: 'notif-json',
        recipientId: 'recipient-123',
        type: NotificationType.requestWithdrawn,
        title: 'Application Withdrawn',
        body: 'Requester canceled pitch',
        referenceId: 'team-456',
        isRead: true,
        timestamp: DateTime.parse('2026-10-21T12:00:00Z'),
      );

      final json = item.toJson();

      expect(json['id'], 'notif-json');
      expect(json['recipient_id'], 'recipient-123');
      expect(json['type'], 'requestWithdrawn');
      expect(json['related_team_id'], 'team-456');
      expect(json['read_at'], isNotNull);
      expect(json['is_read'], true);
    });
  });

  group('NotificationRepository Security & Unread Count Tests', () {
    test('NotificationRepository handles uninitialized backend without throwing or leaking', () async {
      final repo = NotificationRepository.instance;
      final notifications = await repo.fetchNotifications();
      expect(notifications, isEmpty);

      final unread = await repo.refreshUnreadCount();
      expect(unread, 0);
    });

    test('UnreadCountNotifier correctly triggers updates on value changes', () {
      final repo = NotificationRepository.instance;
      int notifiedCount = -1;

      void listener() {
        notifiedCount = repo.unreadCountNotifier.value;
      }

      repo.unreadCountNotifier.addListener(listener);

      repo.unreadCountNotifier.value = 5;
      expect(notifiedCount, 5);

      repo.unreadCountNotifier.value = 0;
      expect(notifiedCount, 0);

      repo.unreadCountNotifier.removeListener(listener);
    });
  });

  group('NotificationsScreen UI & Interaction Tests', () {
    testWidgets('Renders empty state when user has no notifications', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationsScreen(
            initialNotifications: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('All Caught Up'), findsOneWidget);
      expect(
        find.textContaining('You have no pending notifications'),
        findsOneWidget,
      );
    });

    testWidgets('Renders notifications list with unread badge and mark all read button', (tester) async {
      final items = [
        NotificationItem(
          id: 'n1',
          recipientId: 'alice',
          type: NotificationType.joinRequest,
          title: 'New Join Request 📩',
          body: 'Charlie applied to Robotics Club',
          referenceId: 'team-1',
          teamTitle: 'Robotics Club',
          isRead: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        NotificationItem(
          id: 'n2',
          recipientId: 'alice',
          type: NotificationType.requestAccepted,
          title: 'Request Accepted! 🎉',
          body: 'You are now a member of SIH Elite',
          referenceId: 'team-2',
          teamTitle: 'SIH Elite',
          isRead: true,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            initialNotifications: items,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header unread count pill
      expect(find.text('1 unread'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);

      // Check items rendered
      expect(find.text('New Join Request 📩'), findsOneWidget);
      expect(find.text('Charlie applied to Robotics Club'), findsOneWidget);
      expect(find.text('Request Accepted! 🎉'), findsOneWidget);
      expect(find.text('Team: Robotics Club'), findsOneWidget);

      // Tap "Mark all read"
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      // After marking all read, the "1 unread" pill and "Mark all read" button disappear
      expect(find.text('1 unread'), findsNothing);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('Tapping notification triggers read update and navigation callback', (tester) async {
      bool tapped = false;

      final items = [
        NotificationItem(
          id: 'n3',
          recipientId: 'alice',
          type: NotificationType.joinRequest,
          title: 'Join Request',
          body: 'Tap to review',
          isRead: false,
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            initialNotifications: items,
            onNotificationTapped: () {
              tapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 unread'), findsOneWidget);

      // Tap the notification
      await tester.tap(find.text('Join Request'));
      await tester.pumpAndSettle();

      expect(tapped, true);
      // Item marked as read optimistically
      expect(find.text('1 unread'), findsNothing);
    });
  });
}
