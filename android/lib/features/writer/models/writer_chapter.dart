class WriterChapter {
  const WriterChapter({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final int order;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get wordCount {
    final cleanText = content.trim();

    if (cleanText.isEmpty) {
      return 0;
    }

    return cleanText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  WriterChapter copyWith({
    String? id,
    String? title,
    String? content,
    int? order,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WriterChapter(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'order': order,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WriterChapter.fromJson(Map<String, dynamic> json) {
    return WriterChapter(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      isPublished: json['isPublished'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
