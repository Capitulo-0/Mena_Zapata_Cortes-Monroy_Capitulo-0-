import 'dart:typed_data';

class EpubFailure implements Exception {
  const EpubFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class EpubTocItem {
  const EpubTocItem(this.title, this.href);
  final String title, href;
  Map<String, dynamic> toJson() => {'title': title, 'href': href};
  factory EpubTocItem.fromJson(Map<String, dynamic> value) =>
      EpubTocItem(value['title'] as String, value['href'] as String);
}

/// A local edition, never a Google Books volume or a server LibraryEntry.
class ImportedEpub {
  const ImportedEpub({
    required this.id,
    required this.title,
    required this.author,
    required this.fileName,
    required this.size,
    required this.chapters,
    required this.createdAt,
    this.cfi = '',
    this.progress = 0,
    this.fontSize = 18,
    this.fileAvailable = true,
  });
  final String id, title, author, fileName, createdAt, cfi;
  final int size, fontSize;
  final double progress;
  final List<EpubTocItem> chapters;
  final bool fileAvailable;
  String get status => cfi.isEmpty
      ? 'Por leer'
      : progress >= .99
      ? 'Leído'
      : 'Leyendo';
  ImportedEpub position({
    String? cfi,
    double? progress,
    int? fontSize,
    bool? fileAvailable,
    List<EpubTocItem>? chapters,
  }) => ImportedEpub(
    id: id,
    title: title,
    author: author,
    fileName: fileName,
    size: size,
    chapters: chapters ?? this.chapters,
    createdAt: createdAt,
    cfi: cfi ?? this.cfi,
    progress: progress ?? this.progress,
    fontSize: fontSize ?? this.fontSize,
    fileAvailable: fileAvailable ?? this.fileAvailable,
  );
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'title': title,
    'author': author,
    'fileName': fileName,
    'size': size,
    'createdAt': createdAt,
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'cfi': cfi,
    'progress': progress,
    'fontSize': fontSize,
  };
  factory ImportedEpub.fromJson(Map<String, dynamic> value) {
    final id = value['id'] as String;
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(id) || value['version'] != 1) {
      throw const FormatException('Invalid EPUB record');
    }
    final progress = (value['progress'] as num).toDouble();
    final fontSize = value['fontSize'] as int;
    if (!progress.isFinite ||
        progress < 0 ||
        progress > 1 ||
        fontSize < 12 ||
        fontSize > 32) {
      throw const FormatException('Invalid EPUB position');
    }
    return ImportedEpub(
      id: id,
      title: value['title'] as String,
      author: value['author'] as String,
      fileName: value['fileName'] as String,
      size: value['size'] as int,
      createdAt: value['createdAt'] as String,
      cfi: value['cfi'] as String,
      progress: progress,
      fontSize: fontSize,
      chapters: (value['chapters'] as List)
          .map((c) => EpubTocItem.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList(),
    );
  }
}

class ValidatedEpub {
  const ValidatedEpub(this.book, this.bytes);
  final ImportedEpub book;
  final Uint8List bytes;
}
