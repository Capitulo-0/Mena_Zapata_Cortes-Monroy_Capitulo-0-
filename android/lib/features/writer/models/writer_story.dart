import 'writer_chapter.dart';

enum WriterStoryStatus { draft, published }

class WriterStory {
  const WriterStory({
    required this.id,
    required this.title,
    required this.synopsis,
    required this.genre,
    required this.status,
    required this.chapters,
    required this.createdAt,
    required this.updatedAt,
    this.coverPath,
    this.followers = 0,
    this.rating = 0,
  });

  final String id;
  final String title;
  final String synopsis;
  final String genre;
  final String? coverPath;
  final WriterStoryStatus status;
  final List<WriterChapter> chapters;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int followers;
  final double rating;

  bool get isPublished => status == WriterStoryStatus.published;
  bool get isDraft => status == WriterStoryStatus.draft;
  int get chapterCount => chapters.length;

  int get publishedChapterCount =>
      chapters.where((chapter) => chapter.isPublished).length;

  int get draftChapterCount =>
      chapters.where((chapter) => !chapter.isPublished).length;

  int get totalWordCount {
    return chapters.fold(0, (total, chapter) => total + chapter.wordCount);
  }

  double get publicationProgress {
    if (chapters.isEmpty) {
      return 0;
    }

    return publishedChapterCount / chapters.length;
  }

  WriterStory copyWith({
    String? id,
    String? title,
    String? synopsis,
    String? genre,
    String? coverPath,
    bool removeCover = false,
    WriterStoryStatus? status,
    List<WriterChapter>? chapters,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? followers,
    double? rating,
  }) {
    return WriterStory(
      id: id ?? this.id,
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      genre: genre ?? this.genre,
      coverPath: removeCover ? null : coverPath ?? this.coverPath,
      status: status ?? this.status,
      chapters: chapters ?? this.chapters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      followers: followers ?? this.followers,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'synopsis': synopsis,
      'genre': genre,
      'coverPath': coverPath,
      'status': status.name,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'followers': followers,
      'rating': rating,
    };
  }

  factory WriterStory.fromJson(Map<String, dynamic> json) {
    final chaptersJson = json['chapters'];

    final chapters = chaptersJson is List
        ? chaptersJson
              .whereType<Map>()
              .map(
                (chapter) =>
                    WriterChapter.fromJson(Map<String, dynamic>.from(chapter)),
              )
              .toList()
        : <WriterChapter>[];

    final statusValue = json['status'] as String?;

    return WriterStory(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      synopsis: json['synopsis'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      coverPath: json['coverPath'] as String?,
      status: statusValue == WriterStoryStatus.published.name
          ? WriterStoryStatus.published
          : WriterStoryStatus.draft,
      chapters: chapters,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      followers: json['followers'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}
