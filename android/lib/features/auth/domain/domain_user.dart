class DomainUser {
  const DomainUser({required this.id, required this.email, this.displayName});
  final int id;
  final String email;
  final String? displayName;
  factory DomainUser.fromJson(Map<String, dynamic> data) {
    if (data['id'] is! int ||
        data['email'] is! String ||
        (data['displayName'] != null && data['displayName'] is! String)) {
      throw const FormatException('Invalid user response');
    }
    return DomainUser(
      id: data['id'] as int,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
    );
  }
}
