class WriterPublication {
  const WriterPublication({
    required this.id,
    required this.title,
    required this.synopsis,
    required this.genre,
    required this.coverPath,
    required this.authorName,
    required this.authorUsername,
    required this.chapterCount,
  });
  final String id, title, synopsis, genre, authorName;
  final String? coverPath, authorUsername;
  final int chapterCount;
  String get author =>
      authorUsername?.isNotEmpty == true ? '@$authorUsername' : authorName;
  factory WriterPublication.fromJson(Map<String, dynamic> json) =>
      WriterPublication(
        id: json['id'] as String,
        title: json['title'] as String,
        synopsis: json['synopsis'] as String? ?? '',
        genre: json['genre'] as String? ?? '',
        coverPath: json['coverPath'] as String?,
        authorName: json['authorName'] as String,
        authorUsername: json['authorUsername'] as String?,
        chapterCount: (json['chapterCount'] as num).toInt(),
      );
}
