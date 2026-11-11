import 'book_status.dart';
import 'library_book.dart';
import 'reading_record.dart';

class LibraryEntry {
  const LibraryEntry({
    required this.book,
    required this.status,
    required this.readingFormat,
    required this.currentPage,
    required this.totalPages,
    required this.publisher,
    required this.progressPercentage,
    required this.updatedAt,
  });
  final LibraryBook book;
  final BookStatus status;
  final String readingFormat;
  final int currentPage;
  final int? totalPages;
  final String publisher;
  final double progressPercentage;
  final DateTime updatedAt;

  static LibraryBook parseBook(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int || id <= 0 || json['title'] is! String) {
      throw const FormatException('Invalid book response');
    }
    return LibraryBook(
      id: id,
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      year: json['publicationYear'] as int? ?? 0,
      genre: '',
      isbn: json['isbn'] as String? ?? '',
      cover: json['coverUrl'] as String? ?? '',
      synopsis: json['synopsis'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      totalPages: json['totalPages'] as int? ?? 0,
      isFree: false,
      isBackendBook: true,
    );
  }

  factory LibraryEntry.fromJson(Map<String, dynamic> json) {
    final book = parseBook(Map<String, dynamic>.from(json['book'] as Map));
    final status = switch (json['status']) {
      'POR_LEER' => BookStatus.porLeer,
      'LEYENDO' => BookStatus.leyendo,
      'LEIDO' => BookStatus.leido,
      _ => throw const FormatException('Invalid status'),
    };
    final format = json['readingFormat'];
    if (!['FISICO', 'EBOOK', 'OTRA_PLATAFORMA'].contains(format)) {
      throw const FormatException('Invalid reading format');
    }
    final page = json['currentPage'] as int;
    final total = json['totalPages'] as int?;
    final progress = (json['progressPercentage'] as num).toDouble();
    if (page < 0 ||
        (total != null && (total <= 0 || page > total)) ||
        !progress.isFinite ||
        progress < 0 ||
        progress > 100) {
      throw const FormatException('Invalid reading progress');
    }
    return LibraryEntry(
      book: book,
      status: status,
      readingFormat: format as String,
      currentPage: page,
      totalPages: total,
      publisher: json['publisherOverride'] as String? ?? book.publisher,
      progressPercentage: progress,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  ReadingRecord get record => ReadingRecord(
    format: switch (readingFormat) {
      'FISICO' => 'Físico',
      'EBOOK' => 'Ebook',
      _ => 'Otra plataforma',
    },
    currentPage: currentPage,
    totalPages: totalPages ?? 0,
    publisher: publisher,
    status: status,
  );
  static String statusValue(BookStatus status) => switch (status) {
    BookStatus.porLeer => 'POR_LEER',
    BookStatus.leyendo => 'LEYENDO',
    BookStatus.leido => 'LEIDO',
  };
  static String formatValue(String format) => switch (format) {
    'Físico' => 'FISICO',
    'Ebook' => 'EBOOK',
    'Otra plataforma' => 'OTRA_PLATAFORMA',
    _ => throw const FormatException('Invalid reading format'),
  };
  static Map<String, dynamic> homeData(LibraryBook book) => {
    'id': book.id,
    'title': book.title,
    'authorReal': book.author,
    'author': book.author,
    'year': book.year,
    'genre': book.genre,
    'isbn': book.isbn,
    'cover': book.cover,
    'synopsis': book.synopsis,
    'publisher': book.publisher,
    'totalPages': book.totalPages,
    'availability': 'REGISTRO',
    'rating': 0.0,
    'isBackendBook': true,
  };
}
