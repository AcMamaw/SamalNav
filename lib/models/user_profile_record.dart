class UserProfileRecord {
  final String id;
  final String? email;
  final String? displayName;
  final String role;

  const UserProfileRecord({
    required this.id,
    this.email,
    this.displayName,
    required this.role,
  });

  factory UserProfileRecord.fromJson(Map<String, dynamic> json) {
    return UserProfileRecord(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      role: json['role'] as String? ?? 'tourist',
    );
  }
}
