import 'reading_mood.dart';

class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.username,
    required this.isPrivate,
    required this.canViewContent,
    this.verifiedOrganizer = false,
    this.displayName,
    this.biography,
    this.avatarUrl,
    this.createdAt,
    this.followersCount,
    this.followingCount,
    this.booksCount,
    this.readingMood,
  });

  final int id;
  final String username;
  final String? displayName;
  final String? biography;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool isPrivate;
  final bool canViewContent;
  final bool verifiedOrganizer;
  final int? followersCount;
  final int? followingCount;
  final int? booksCount;
  final ReadingMood? readingMood;

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
      verifiedOrganizer: json['verifiedOrganizer'] == true,
      followersCount: (json['followersCount'] as num?)?.toInt(),
      followingCount: (json['followingCount'] as num?)?.toInt(),
      booksCount: (json['booksCount'] as num?)?.toInt(),
      readingMood:
          json['canViewContent'] == true &&
              json['readingMood'] is Map<String, dynamic>
          ? ReadingMood.fromJson(json['readingMood'] as Map<String, dynamic>)
          : null,
    );
  }
}
