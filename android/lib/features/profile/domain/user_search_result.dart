class UserSearchResult {
  const UserSearchResult({
    required this.displayName,
    required this.username,
    this.avatarUrl,
  });

  final String? displayName;
  final String username;
  final String? avatarUrl;

  factory UserSearchResult.fromJson(Map<String, dynamic> data) {
    if (data['username'] is! String ||
        (data['displayName'] != null && data['displayName'] is! String) ||
        (data['avatarUrl'] != null && data['avatarUrl'] is! String)) {
      throw const FormatException('Invalid user search result');
    }

    final username = (data['username'] as String).trim();

    if (username.isEmpty) {
      throw const FormatException('Invalid username');
    }

    return UserSearchResult(
      displayName: data['displayName'] as String?,
      username: username,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }
}
