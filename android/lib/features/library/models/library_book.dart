class LibraryBook {
  const LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.year,
    required this.genre,
    required this.isbn,
    required this.cover,
    required this.synopsis,
    this.authorHandle,
    this.isFree = true,
    this.isBackendBook = false,
    this.publisher = '',
    this.totalPages = 0,
    this.googleVolumeId,
    this.googleBooks,
  });

  final String? googleVolumeId;
  final Map<String,dynamic>? googleBooks;
  final int id;
  final String title;
  final String author;
  final String? authorHandle;
  final int year;
  final String genre;
  final String isbn;
  final String cover;
  final String synopsis;
  final bool isFree;
  final bool isBackendBook;
  final String publisher;
  final int totalPages;
}
