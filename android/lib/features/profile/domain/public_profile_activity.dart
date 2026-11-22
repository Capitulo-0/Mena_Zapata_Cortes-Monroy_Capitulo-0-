import '../../clubs/models/reading_club.dart';
import '../../library/models/book_status.dart';
import '../../library/models/library_book.dart';
import '../../library/models/library_entry.dart';
import '../../writer/models/writer_story.dart';

/// Actividad del propietario: nunca contiene datos de la sesión visitante.
class PublicProfileActivity {
  const PublicProfileActivity({
    required this.annualGoal,
    required this.clubs,
    required this.books,
    required this.statuses,
    required this.progresses,
    required this.favorites,
    required this.publishedStories,
  });

  final int annualGoal;
  final List<ReadingClub> clubs;
  final List<LibraryBook> books;
  final Map<int, BookStatus> statuses;
  final Map<int, int> progresses;
  final Set<int> favorites;
  final List<WriterStory> publishedStories;

  factory PublicProfileActivity.fromJson(Map<String, dynamic> json) {
    final entries = (json['library'] as List)
        .map(
          (item) =>
              LibraryEntry.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    final favoriteBooks = (json['favoriteBooks'] as List)
        .map(
          (item) =>
              LibraryEntry.parseBook(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    final bookMap = <int, LibraryBook>{
      for (final entry in entries) entry.book.id: entry.book,
      for (final book in favoriteBooks) book.id: book,
    };

    return PublicProfileActivity(
      annualGoal: (json['annualGoal'] as num).toInt(),
      clubs: (json['clubs'] as List)
          .map(
            (item) =>
                ReadingClub.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      books: bookMap.values.toList(),
      statuses: {for (final entry in entries) entry.book.id: entry.status},
      progresses: {
        for (final entry in entries)
          entry.book.id: entry.progressPercentage.floor(),
      },
      favorites: favoriteBooks.map((book) => book.id).toSet(),
      publishedStories: (json['publishedStories'] as List)
          .map(
            (item) =>
                WriterStory.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .where((story) => story.isPublished)
          .toList(),
    );
  }
}
