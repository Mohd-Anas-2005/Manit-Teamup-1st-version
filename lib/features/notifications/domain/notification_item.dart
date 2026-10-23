enum NotificationType {
  joinRequest('Join Request'),
  requestAccepted('Request Accepted'),
  requestRejected('Request Declined'),
  requestWithdrawn('Request Withdrawn'),
  teamAnnouncement('Team Announcement'),
  directMessage('Direct Message');

  final String label;
  const NotificationType(this.label);
}

class NotificationItem {
  final String id;
  final String recipientId;
  final NotificationType type;
  final String title;
  final String body;
  final String? referenceId; // related_team_id or request_id
  final String? teamTitle;
  final String? actorName;
  final bool isRead;
  final DateTime timestamp;

  const NotificationItem({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    this.teamTitle,
    this.actorName,
    this.isRead = false,
    required this.timestamp,
  });

  NotificationItem copyWith({
    String? id,
    String? recipientId,
    NotificationType? type,
    String? title,
    String? body,
    String? referenceId,
    String? teamTitle,
    String? actorName,
    bool? isRead,
    DateTime? timestamp,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      referenceId: referenceId ?? this.referenceId,
      teamTitle: teamTitle ?? this.teamTitle,
      actorName: actorName ?? this.actorName,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'type': type.name,
      'title': title,
      'body': body,
      'related_team_id': referenceId,
      'reference_id': referenceId,
      'team_title': teamTitle,
      'actor_name': actorName,
      'read_at': isRead ? timestamp.toIso8601String() : null,
      'is_read': isRead,
      'created_at': timestamp.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      recipientId: json['recipient_id'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.teamAnnouncement,
      ),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      referenceId: (json['related_team_id'] ?? json['reference_id']) as String?,
      teamTitle: json['team_title'] as String?,
      actorName: json['actor_name'] as String?,
      isRead: json['read_at'] != null || (json['is_read'] as bool? ?? false),
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : DateTime.now()),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '${mins}m ago';
    } else if (difference.inHours < 24) {
      final hrs = difference.inHours;
      return '${hrs}h ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '${days}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
