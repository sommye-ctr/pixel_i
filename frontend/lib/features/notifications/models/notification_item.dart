class NotificationItem {
  final String id;
  final String verb;
  final String actorUsername;
  final String actorId;
  final String targetType;
  final String targetId;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final bool read;

  NotificationItem({
    required this.id,
    required this.verb,
    required this.actorUsername,
    required this.targetType,
    required this.targetId,
    required this.data,
    required this.createdAt,
    required this.read,
    required this.actorId,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    final actor = map['actor'] as Map<String, dynamic>?;
    final tsRaw = map['created_at'] as String?;
    DateTime? ts;
    if (tsRaw != null) {
      ts = DateTime.tryParse(tsRaw);
    }
    return NotificationItem(
      id: (map['id'] ?? '').toString(),
      verb: (map['verb'] ?? '').toString(),
      actorUsername: (actor?['username'] ?? 'Someone').toString(),
      actorId: (actor?['id'] ?? '').toString(),
      targetType: (map['target_type'] ?? '').toString(),
      targetId: (map['target_id'] ?? '').toString(),
      data: (map['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: ts,
      read: (map['read'] as bool?) ?? false,
    );
  }
}
