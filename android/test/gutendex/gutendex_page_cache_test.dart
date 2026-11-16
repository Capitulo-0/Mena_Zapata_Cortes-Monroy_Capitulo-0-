import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';
import 'package:android/features/gutendex/presentation/gutendex_page_cache.dart';

import 'support/gutendex_fakes.dart';

GutendexPageKey key(String query, {GutendexLanguage language = GutendexLanguage.spanish, int? page}) =>
  (query: query, language: language, page: page == null ? null :
    Uri.https('gutendex.com', '/books/', {'search': query, 'languages': language.code, 'page': '$page'}));

void main() {
  test('cache isolates exact query, language and page', () {
    final cache = GutendexPageCache();
    cache.put(key('Quijote'), GutendexPage(results: [fixtureBook(1)]));
    cache.put(key('Quijote', language: GutendexLanguage.english),
      GutendexPage(results: [fixtureBook(2, language: 'en')]));
    cache.put(key('Quijote', page: 2), GutendexPage(results: [fixtureBook(3)]));
    expect(cache.read(key('Quijote'))!.results.single.id, 1);
    expect(cache.read(key('Quijote', language: GutendexLanguage.english))!.results.single.id, 2);
    expect(cache.read(key('Quijote', page: 2))!.results.single.id, 3);
    expect(cache.read(key('quijote')), isNull);
    expect(cache.read(key('Otro')), isNull);
    expect(cache.read(key('Quijote', language: GutendexLanguage.all)), isNull);
  });

  test('TTL expires without extending freshness on reads', () {
    var now = DateTime.utc(2026);
    final cache = GutendexPageCache(now: () => now);
    cache.put(key('a'), GutendexPage(results: [fixtureBook(1)]));
    now = now.add(const Duration(minutes: 2));
    expect(cache.read(key('a')), isNotNull);
    now = now.add(const Duration(minutes: 1));
    expect(cache.read(key('a')), isNull);
    expect(cache.length, 0);
  });

  test('least recently used pages are evicted', () {
    final cache = GutendexPageCache(maxPages: 2);
    for (final query in ['a', 'b']) {
      cache.put(key(query), GutendexPage(results: [fixtureBook(1)]));
    }
    cache.read(key('a'));
    cache.put(key('c'), GutendexPage(results: [fixtureBook(3)]));
    expect(cache.length, 2);
    expect(cache.read(key('b')), isNull);
    expect(cache.read(key('a')), isNotNull);
  });

  test('cache bounds both book count and text metadata', () {
    final cache = GutendexPageCache(maxBooks: 2, maxTextUnits: 100);
    cache.put(key('a'), const GutendexPage(results: [GutendexBook(id: 1, title: 'a')]));
    cache.put(key('b'), const GutendexPage(results: [GutendexBook(id: 2, title: 'b')]));
    cache.put(key('c'), const GutendexPage(results: [GutendexBook(id: 3, title: 'c')]));
    expect(cache.bookCount, 2);
    expect(cache.read(key('a')), isNull);
    cache.put(key('large'), GutendexPage(results: [
      GutendexBook(id: 4, summaries: ['x' * 101]),
    ]));
    expect(cache.read(key('large')), isNull);
    expect(cache.textUnits, lessThanOrEqualTo(100));
    cache.put(key('many'), const GutendexPage(results: [
      GutendexBook(id: 5), GutendexBook(id: 6), GutendexBook(id: 7),
    ]));
    expect(cache.read(key('many')), isNull);
  });

  test('cache bounds keys and owns an immutable snapshot of result lists', () {
    final cache = GutendexPageCache(maxTextUnits: 100);
    final mutable = [const GutendexBook(id: 1)];
    cache.put(key('a'), GutendexPage(results: mutable));
    mutable.add(const GutendexBook(id: 2));
    final stored = cache.read(key('a'))!;
    expect(stored.results.single.id, 1);
    expect(() => stored.results.add(const GutendexBook(id: 3)), throwsUnsupportedError);
    cache.put(key('x' * 101), const GutendexPage(results: []));
    expect(cache.read(key('x' * 101)), isNull);
  });

  test('invalidating one query cannot remove another query or language', () {
    final cache = GutendexPageCache();
    for (final entry in [key('a'), key('a', page: 2), key('b'),
      key('a', language: GutendexLanguage.english)]) {
      cache.put(entry, const GutendexPage(results: []));
    }
    cache.invalidate('a', GutendexLanguage.spanish);
    expect(cache.read(key('a')), isNull);
    expect(cache.read(key('a', page: 2)), isNull);
    expect(cache.length, 2);
    cache.clear();
    expect(cache.length, 0);
  });
}
