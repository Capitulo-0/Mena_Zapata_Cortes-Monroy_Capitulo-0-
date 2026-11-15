class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.username,
    required this.isPrivate,
    required this.canViewContent,
    this.displayName,
    this.biography,
    this.avatarUrl,
    this.createdAt,
    this.followersCount,
    this.followingCount,
    this.booksCount,
  });

  final int id;
  final String username;
  final String? displayName;
  final String? biography;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool isPrivate;
  final bool canViewContent;
  final int? followersCount;
  final int? followingCount;
  final int? booksCount;

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    return PublicProfile(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      biography: json['biography'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      isPrivate: json['isPrivate'] == true,
      canViewContent: json['canViewContent'] == true,
      followersCount: (json['followersCount'] as num?)?.toInt(),
      followingCount: (json['followingCount'] as num?)?.toInt(),
      booksCount: (json['booksCount'] as num?)?.toInt(),
    );
  }
}
