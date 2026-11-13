class DomainUser {
  const DomainUser({
    required this.id,
    required this.email,
    this.displayName,
    this.username,
    this.biography,
    this.avatarUrl,
    this.createdAt,
  });

  final int id;
  final String email;
  final String? displayName;
  final String? username;
  final String? biography;
  final String? avatarUrl;
  final DateTime? createdAt;

  factory DomainUser.fromJson(Map<String, dynamic> data) {
    if (data['id'] is! int ||
        data['email'] is! String ||
        (data['displayName'] != null && data['displayName'] is! String) ||
        (data['username'] != null && data['username'] is! String) ||
        (data['biography'] != null && data['biography'] is! String) ||
        (data['avatarUrl'] != null && data['avatarUrl'] is! String) ||
        (data['createdAt'] != null && data['createdAt'] is! String)) {
      throw const FormatException('Invalid user response');
    }

    final String? createdAtString = data['createdAt'] as String?;

    DateTime? createdAt;
    if (createdAtString != null) {
      createdAt = DateTime.tryParse(createdAtString);

      if (createdAt == null) {
        throw const FormatException('Invalid createdAt');
      }
    }

    return DomainUser(
      id: data['id'] as int,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      username: data['username'] as String?,
      biography: data['biography'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: createdAt,
    );
  }
}
