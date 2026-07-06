class AuditLogRecord {
  final String id;
  final String? userId;
  final String? actorId;
  final String actionType;
  final String description;
  final String? role;
  final String? targetId;
  final DateTime createdAt;
  final String? userEmail;
  final String? userRole;

  const AuditLogRecord({
    required this.id,
    this.userId,
    this.actorId,
    required this.actionType,
    required this.description,
    this.role,
    this.targetId,
    required this.createdAt,
    this.userEmail,
    this.userRole,
  });

  factory AuditLogRecord.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return AuditLogRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      actorId: json['actor_id'] as String?,
      actionType: (json['action'] ?? json['action_type'] ?? 'ACTION') as String,
      description: (json['description'] ?? json['action'] ?? '') as String,
      role: json['role'] as String?,
      targetId: json['target_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userEmail: profile?['email'] as String?,
      userRole: profile?['role'] as String? ?? json['role'] as String?,
    );
  }
}
