import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../joining_requests/presentation/joining_requests_screen.dart';
import '../../teams/domain/team.dart';
import '../../teams/presentation/team_detail_screen.dart';
import '../domain/notification_item.dart';
import '../services/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  final List<NotificationItem>? initialNotifications;
  final VoidCallback? onNotificationTapped;

  const NotificationsScreen({
    super.key,
    this.initialNotifications,
    this.onNotificationTapped,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialNotifications != null) {
      _notifications.addAll(widget.initialNotifications!);
    } else {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await NotificationRepository.instance.fetchNotifications();
      if (mounted) {
        setState(() {
          _notifications
            ..clear()
            ..addAll(items);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(NotificationItem item, int index) async {
    if (item.isRead) return;

    HapticFeedback.lightImpact();

    // Optimistically update UI
    setState(() {
      _notifications[index] = item.copyWith(isRead: true);
    });

    await NotificationRepository.instance.markAsRead(item.id);
  }

  Future<void> _markAllAsRead() async {
    HapticFeedback.mediumImpact();

    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });

    final success = await NotificationRepository.instance.markAllAsRead();
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onItemTapped(NotificationItem item, int index) async {
    await _markAsRead(item, index);

    if (!mounted) return;

    if (widget.onNotificationTapped != null) {
      widget.onNotificationTapped!();
      return;
    }

    // Route based on notification type and related entity
    if (item.type == NotificationType.joinRequest) {
      // Team owner received application -> navigate to Joining Requests (Incoming)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const JoiningRequestsScreen(),
        ),
      );
      return;
    }

    // If related to a team, fetch team details and navigate
    if (item.referenceId != null && item.referenceId!.isNotEmpty) {
      await _navigateToTeam(item.referenceId!);
      return;
    }

    // Default fallback: open Joining Requests
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const JoiningRequestsScreen(),
      ),
    );
  }

  Future<void> _navigateToTeam(String teamId) async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) {
      // In uninitialized/test mode, open JoiningRequestsScreen gracefully
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const JoiningRequestsScreen(),
        ),
      );
      return;
    }

    try {
      final res = await supabase.client!
          .from('teams')
          .select()
          .eq('id', teamId)
          .maybeSingle();

      if (!mounted) return;

      if (res != null) {
        final team = Team.fromJson(res);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TeamDetailScreen(team: team),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const JoiningRequestsScreen(),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const JoiningRequestsScreen(),
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(NotificationItem item, int index) async {
    HapticFeedback.lightImpact();

    final removed = _notifications.removeAt(index);
    setState(() {});

    final success = await NotificationRepository.instance.deleteNotification(item.id);

    if (mounted && !success) {
      // Revert if delete failed
      setState(() {
        _notifications.insert(index, removed);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete notification')),
      );
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Screen Header Bar
            _buildHeader(),

            // Notifications List / States
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      color: AppColors.charcoalSurface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Inbox',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.electricVioletSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.electricVioletLight, width: 1),
                  ),
                  child: Text(
                    '$_unreadCount unread',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.electricVioletGlow,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.cyanLight),
              label: Text(
                'Mark all read',
                style: AppTypography.labelMedium.copyWith(color: AppColors.cyanLight),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          CardSkeleton(height: 96),
          CardSkeleton(height: 96),
          CardSkeleton(height: 96),
        ],
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _loadNotifications,
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.electricVioletLight,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const EmptyStateView(
              icon: Icons.notifications_none_rounded,
              title: 'All Caught Up',
              message:
                  'You have no pending notifications. When someone requests to join your team or responds to your pitch, you will be notified here.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.electricVioletLight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return StaggeredEntrance(
            index: index,
            child: Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.coralAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.coralAccent),
              ),
              onDismissed: (_) => _deleteNotification(item, index),
              child: GestureDetector(
                onTap: () => _onItemTapped(item, index),
                child: GradientCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeIcon(item.type),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                                      color: item.isRead
                                          ? AppColors.textPrimary
                                          : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.timeAgo,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: AppTypography.bodyMedium.copyWith(
                                color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.teamTitle != null && item.teamTitle!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.charcoalSurfaceVariant,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Team: ${item.teamTitle}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.cyanLight,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!item.isRead) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.cyanAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x9906B6D4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeIcon(NotificationType type) {
    IconData icon;
    Color color;
    Color bg;

    switch (type) {
      case NotificationType.joinRequest:
        icon = Icons.person_add_alt_1_rounded;
        color = AppColors.cyanLight;
        bg = AppColors.cyanSubtle;
        break;
      case NotificationType.requestAccepted:
        icon = Icons.check_circle_rounded;
        color = AppColors.statusSuccess;
        bg = AppColors.statusSuccessSubtle;
        break;
      case NotificationType.requestRejected:
      case NotificationType.requestWithdrawn:
        icon = Icons.cancel_outlined;
        color = AppColors.coralAccent;
        bg = AppColors.coralSubtle;
        break;
      case NotificationType.teamAnnouncement:
      case NotificationType.directMessage:
        icon = Icons.campaign_rounded;
        color = AppColors.electricVioletGlow;
        bg = AppColors.electricVioletSubtle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
