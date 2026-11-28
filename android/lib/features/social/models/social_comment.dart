class SocialComment {
  const SocialComment({
    required this.id,
    required this.anonymous,
    required this.ownComment,
    required this.deleted,
    required this.likeCount,
    required this.likedByMe,
    required this.replyCount,
    required this.createdAt,
    required this.updatedAt,
    this.bookId,
    this.storyKey,
    this.chapterId,
    this.parentId,
    this.content,
    this.username,
    this.avatarUrl,
    this.hidden = false,
    this.canModerate = false,
  });

  final int id;
  final int? bookId;
  final String? storyKey;
  final String? chapterId;
  final int? parentId;
  final String? content;
  final String? username;
  final String? avatarUrl;
  final bool anonymous;
  final bool ownComment;
  final bool deleted;
  final bool hidden;
  final bool canModerate;
  final int likeCount;
  final bool likedByMe;
  final int replyCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    final anonymous = json['anonymous'] as bool;
    final deleted = json['deleted'] as bool;
    final hidden = json['hidden'] as bool? ?? false;
    final concealed = deleted || hidden;
    return SocialComment(
      id: json['id'] as int,
      bookId: json['bookId'] as int?,
      storyKey: json['storyKey'] as String?,
      chapterId: json['chapterId'] as String?,
      parentId: json['parentId'] as int?,
      content: concealed ? null : json['content'] as String?,
      username: concealed ? null : (anonymous ? '@anonimo' : json['username'] as String?),
      avatarUrl: concealed || anonymous ? null : json['avatarUrl'] as String?,
      anonymous: anonymous,
      ownComment: !concealed && (json['ownComment'] as bool),
      deleted: deleted,
      hidden: hidden,
      canModerate: json['canModerate'] as bool? ?? false,
      likeCount: concealed ? 0 : json['likeCount'] as int,
      likedByMe: !concealed && (json['likedByMe'] as bool),
      replyCount: json['replyCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
