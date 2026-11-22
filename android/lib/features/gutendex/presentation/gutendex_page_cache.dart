import '../models/gutendex_models.dart';

typedef GutendexPageKey = ({String query, GutendexLanguage language, Uri? page});

/// Public metadata only. Owned by one catalog controller, never persisted.
class GutendexPageCache {
  GutendexPageCache({
    this.ttl = const Duration(minutes: 3),
    this.maxPages = 8,
    this.maxBooks = 256,
    this.maxTextUnits = 500000,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration ttl;
  final int maxPages;
  final int maxBooks;
  final int maxTextUnits;
  final DateTime Function() _now;
  final _entries = <GutendexPageKey,
    ({GutendexPage page, DateTime saved, int books, int units})>{};

  int get length => _entries.length;
  int get bookCount => _entries.values.fold(0, (sum, entry) => sum + entry.books);
  int get textUnits => _entries.values.fold(0, (sum, entry) => sum + entry.units);

  void _expire() {
    final now = _now();
    _entries.removeWhere((_, entry) => now.difference(entry.saved) >= ttl);
  }

  GutendexPage? read(GutendexPageKey key) {
    _expire();
    final entry = _entries.remove(key);
    if (entry == null) return null;
    _entries[key] = entry; // Least recently used eviction, without extending TTL.
    return entry.page;
  }

  void put(GutendexPageKey key, GutendexPage page) {
    _expire();
    _entries.remove(key);
    if (maxPages <= 0 || ttl <= Duration.zero || page.results.length > maxBooks) return;
    var units = key.query.length + (key.page?.toString().length ?? 0);
    for (final book in page.results) {
      units += (book.title?.length ?? 0);
      for (final text in [...book.summaries, ...book.subjects, ...book.languages]) {
        units += text.length;
      }
      for (final person in [...book.authors, ...book.translators]) {
        units += person.name.length;
      }
      for (final format in book.formats.entries) {
        units += format.key.length + format.value.length;
      }
      if (units > maxTextUnits) return;
    }
    units += (page.next?.toString().length ?? 0) + (page.previous?.toString().length ?? 0);
    if (units > maxTextUnits) return;
    final snapshot = GutendexPage(results: List.unmodifiable(page.results),
      count: page.count, next: page.next, previous: page.previous);
    _entries[key] = (page: snapshot, saved: _now(), books: snapshot.results.length, units: units);
    while (_entries.length > maxPages || bookCount > maxBooks || textUnits > maxTextUnits) {
      _entries.remove(_entries.keys.first);
    }
  }

  void invalidate(String query, GutendexLanguage language) =>
    _entries.removeWhere((key, _) => key.query == query && key.language == language);

  void clear() => _entries.clear();
}
