import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/gutendex/data/gutendex_repository.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';
import 'package:android/features/gutendex/presentation/gutendex_controller.dart';

import 'support/gutendex_fakes.dart';

void main() {
  late FakeGutendexRepository repo;
  late GutendexController controller;
  setUp(() {
    repo = FakeGutendexRepository();
    controller = GutendexController(repo);
  });
  tearDown(() => controller.dispose());

  test('initial Spanish, loading, error retry and successful empty', () async {
    var task = controller.search();
    expect(controller.loading, true);
    expect(repo.calls.single.language, GutendexLanguage.spanish);
    repo.calls.single.result.completeError(const GutendexFailure('Offline'));
    await task;
    expect(controller.loading, false);
    expect(controller.error, 'Offline');
    expect(controller.hasSearched, false);
    task = controller.search();
    repo.calls.last.result.complete(const GutendexPage(results: [], count: 0));
    await task;
    expect(controller.error, isNull);
    expect(controller.hasSearched, true);
    expect(controller.items, isEmpty);
  });

  test('page failure preserves books, exact cursor retry and deduplication', () async {
    final next = Uri.parse('https://gutendex.com/books/?languages=es&page=2');
    var task = controller.search();
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)], next: next));
    await task;
    task = controller.more();
    expect(controller.loadingMore, true);
    expect(controller.loading, false);
    expect(controller.items.single.id, 1);
    await controller.more();
    expect(repo.calls.length, 2);
    repo.calls.last.result.completeError(const GutendexFailure('Page failed'));
    await task;
    expect(controller.items.single.id, 1);
    expect(controller.error, isNull);
    expect(controller.moreError, 'Page failed');
    task = controller.more();
    expect(repo.calls.last.next, next);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(1), fixtureBook(2)]));
    await task;
    expect(controller.items.map((b) => b.id), [1, 2]);
    expect(controller.moreError, isNull);
    await controller.more();
    expect(repo.calls.length, 3);
  });

  test('language change clears cursor and rejects obsolete error', () async {
    final old = controller.search(query: 'old');
    final current = controller.search(query: 'new', language: GutendexLanguage.english);
    expect(controller.items, isEmpty);
    expect(controller.next, isNull);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2, language: 'en')]));
    await current;
    repo.calls.first.result.completeError(const GutendexFailure('Old error'));
    await old;
    expect(controller.items.single.id, 2);
    expect(controller.language, GutendexLanguage.english);
    expect(controller.error, isNull);
  });

  test('typing invalidates response before debounce expires', () async {
    final task = controller.search(query: 'old');
    controller.prepare(query: 'new');
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)]));
    await task;
    expect(controller.items, isEmpty);
    expect(controller.hasSearched, false);
  });

  test('old page cannot contaminate new query', () async {
    var task = controller.search();
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)],
      next: Uri.parse('https://gutendex.com/books/?languages=es&page=2')));
    await task;
    final oldPage = controller.more();
    task = controller.search(query: 'new');
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(3)]));
    await task;
    repo.calls[1].result.complete(GutendexPage(results: [fixtureBook(2)]));
    await oldPage;
    expect(controller.items.single.id, 3);
  });

  test('repeated next link stops without automatic requests', () async {
    final next = Uri.parse('https://gutendex.com/books/?languages=es&page=2');
    var task = controller.search();
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)], next: next));
    await task;
    task = controller.more();
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2)], next: next));
    await task;
    expect(controller.next, isNull);
    expect(controller.moreError, isNotNull);
    await controller.more();
    expect(repo.calls.length, 2);
  });

  test('dispose ignores pending requests', () async {
    final isolated = GutendexController(repo);
    final task = isolated.search();
    isolated.dispose();
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)]));
    await task;
    expect(isolated.items, isEmpty);
  });
}
