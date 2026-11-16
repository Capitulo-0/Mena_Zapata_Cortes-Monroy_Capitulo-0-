import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/gutendex/data/gutendex_repository.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';
import 'package:android/features/gutendex/presentation/gutendex_controller.dart';
import 'package:android/features/gutendex/presentation/gutendex_page_cache.dart';

import 'support/gutendex_fakes.dart';

void main() {
  late FakeGutendexRepository repo;
  late GutendexController controller;
  setUp(() {
    repo = FakeGutendexRepository();
    controller = GutendexController(repo);
  });
  tearDown(() => controller.dispose());

  test('identical pending searches share one task, including keyboard/manual refresh', () async {
    final first = controller.search(query: 'Don Quijote');
    final duplicate = controller.search(query: ' Don Quijote ', refresh: true);
    expect(identical(first, duplicate), isTrue);
    expect(repo.calls.length, 1);
    controller.prepare(query: ' Don Quijote ');
    expect(controller.loading, isTrue);
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)]));
    await first;
    expect(controller.items.single.id, 1);
    await controller.search(query: 'Don Quijote');
    expect(repo.calls.length, 1);
  });

  test('refresh preserves only the same query and a failure is never cached as empty', () async {
    var task = controller.search(query: 'Cervantes');
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)], count: 20));
    await task;
    task = controller.search(refresh: true);
    expect(controller.loading, isTrue);
    expect(controller.items.single.id, 1);
    expect(controller.count, 20);
    repo.calls.last.result.completeError(const GutendexFailure('Gutendex tardó demasiado. Inténtalo nuevamente.'));
    await task;
    expect(controller.error, contains('tardó demasiado'));
    expect(controller.items.single.id, 1);
    expect(controller.hasSearched, isTrue);
    task = controller.search(refresh: true);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2)], count: 1));
    await task;
    expect(controller.error, isNull);
    expect(controller.items.single.id, 2);
    expect(repo.calls.length, 3);
    controller.prepare(query: 'Otro');
    expect(controller.items, isEmpty);
    expect(controller.count, isNull);
  });

  test('Spanish English round trip and additional page are restored from distinct cache keys', () async {
    final next = Uri.https('gutendex.com', '/books/', {'languages': 'es', 'page': '2'});
    var task = controller.search();
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(1)], next: next));
    await task;
    task = controller.more();
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2)]));
    await task;
    task = controller.search(language: GutendexLanguage.english);
    expect(controller.items, isEmpty);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(3, language: 'en')]));
    await task;
    await controller.search(language: GutendexLanguage.spanish);
    expect(controller.fromSessionCache, isTrue);
    expect(controller.items.map((book) => book.id), [1]);
    await controller.more();
    expect(controller.items.map((book) => book.id), [1, 2]);
    expect(repo.calls.length, 3);
    await controller.search(language: GutendexLanguage.english);
    expect(controller.items.single.languages, ['en']);
    expect(repo.calls.length, 3);
  });

  test('A B A pending searches reuse the correct request and ignore B response', () async {
    final first = controller.search(query: 'A');
    final other = controller.search(query: 'B');
    final back = controller.search(query: 'A');
    expect(repo.calls.length, 2);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2)]));
    await other;
    expect(controller.items, isEmpty);
    repo.calls.first.result.complete(GutendexPage(results: [fixtureBook(1)]));
    await Future.wait([first, back]);
    expect(controller.items.single.id, 1);
    expect(controller.query, 'A');
  });

  test('new first page invalidates cached and pending additional pages', () async {
    final next = Uri.https('gutendex.com', '/books/', {'languages': 'es', 'page': '2'});
    var task = controller.search();
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(1)], next: next));
    await task;
    final oldMore = controller.more();
    task = controller.search(refresh: true);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(10)], next: next));
    await task;
    repo.calls[1].result.complete(GutendexPage(results: [fixtureBook(2)]));
    await oldMore;
    expect(controller.items.map((book) => book.id), [10]);
    task = controller.more();
    expect(repo.calls.length, 4);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(11)]));
    await task;
    expect(controller.items.map((book) => book.id), [10, 11]);
  });

  test('expired cache requires network and cannot restore a foreign language', () async {
    var now = DateTime.utc(2026);
    final isolated = GutendexController(repo, cache: GutendexPageCache(now: () => now));
    addTearDown(isolated.dispose);
    var task = isolated.search(query: 'Título');
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(1)]));
    await task;
    task = isolated.search(query: 'Título', language: GutendexLanguage.english);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2, language: 'en')]));
    await task;
    now = now.add(const Duration(minutes: 4));
    task = isolated.search(query: 'Título', language: GutendexLanguage.spanish);
    expect(repo.calls.length, 3);
    expect(isolated.items, isEmpty);
    expect(isolated.fromSessionCache, isFalse);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(3)]));
    await task;
    expect(isolated.items.single.id, 3);
  });

  test('failed responses are not cached and retries remain manual', () async {
    var task = controller.search();
    repo.calls.last.result.completeError(const GutendexFailure('HTTP 522'));
    await task;
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls.length, 1);
    expect(controller.hasSearched, isFalse);
    task = controller.search();
    expect(repo.calls.length, 2);
    repo.calls.last.result.complete(const GutendexPage(results: [], count: 0));
    await task;
    expect(controller.hasSearched, isTrue);
    expect(controller.error, isNull);
    await controller.search();
    expect(repo.calls.length, 2);
  });

  test('late responses after query change cannot populate the visible cache', () async {
    final old = controller.search(query: 'A');
    final active = controller.search(query: 'B');
    repo.calls.first.result.complete(GutendexPage(results: [fixtureBook(1)]));
    await old;
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2)]));
    await active;
    final again = controller.search(query: 'A');
    expect(repo.calls.length, 3);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(3)]));
    await again;
    expect(controller.items.single.id, 3);
  });

  test('disposing a session drops cache and cannot store late results', () async {
    final cache = GutendexPageCache();
    final isolated = GutendexController(repo, cache: cache);
    final task = isolated.search();
    isolated.dispose();
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(1)]));
    await task;
    expect(cache.length, 0);
  });
}
