import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/gutendex/data/gutendex_saved_catalog.dart';
import 'package:android/features/gutendex/data/gutendex_repository.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';
import 'package:android/features/gutendex/presentation/gutendex_controller.dart';
import 'package:android/features/gutendex/presentation/screens/gutendex_catalog_screen.dart';
import 'package:android/features/gutendex/presentation/screens/gutendex_detail_screen.dart';
import 'package:android/features/gutendex/presentation/widgets/gutendex_cover.dart';

import '../library_regression_test.dart' show installLocalTestAssets;
import 'support/gutendex_fakes.dart';

class SlowSavedCatalog extends GutendexSavedCatalog {
  final pending = Completer<GutendexPage?>();
  @override
  Future<GutendexPage?> read(String query, GutendexLanguage language) =>
      pending.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const es = GutendexLanguage.spanish;
  const en = GutendexLanguage.english;
  test(
    'public metadata round trip keeps identity authors formats and exact keys',
    () async {
      final store = GutendexSavedCatalog();
      await store.save(
        'Cervantes',
        es,
        GutendexPage(
          results: [fixtureBook(1)],
          count: 9,
          next: Uri.parse(
            'https://gutendex.com/books/?search=Cervantes&languages=es&page=2',
          ),
        ),
      );
      final restored = await GutendexSavedCatalog().read('Cervantes', es);
      expect(
        restored!.results.single.displayAuthors,
        fixtureBook(1).displayAuthors,
      );
      expect(
        restored.results.single.readingFormats.length,
        fixtureBook(1).readingFormats.length,
      );
      expect(restored.results.single.languages, ['es']);
      expect(restored.next!.queryParameters['page'], '2');
      expect(await store.read('Cervantes', en), isNull);
      expect(await store.read('cervantes', es), isNull);
      expect(await store.read('Otro', es), isNull);
    },
  );
  test('expiry and future dates rejected without renewing on read', () async {
    var now = DateTime.utc(2026, 11, 16);
    final store = GutendexSavedCatalog(now: () => now);
    await store.save('', es, GutendexPage(results: [fixtureBook(1)]));
    now = now.add(const Duration(hours: 23));
    expect(await store.read('', es), isNotNull);
    now = now.add(const Duration(hours: 1));
    expect(await store.read('', es), isNull);
    now = DateTime.utc(2026, 11, 15);
    expect(await store.read('', es), isNull);
  });
  test(
    'limits total sixty books four queries and serialized metadata',
    () async {
      final store = GutendexSavedCatalog();
      for (var i = 0; i < 5; i++) {
        await store.save(
          '$i',
          es,
          GutendexPage(results: List.generate(30, (n) => fixtureBook(n + 1))),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(GutendexSavedCatalog.storageKey)!;
      final entries = (jsonDecode(raw) as Map)['entries'] as List;
      expect(entries.length, lessThanOrEqualTo(4));
      expect(
        entries.fold<int>(0, (n, e) => n + (e['books'] as List).length),
        lessThanOrEqualTo(60),
      );
      expect(raw.length, lessThanOrEqualTo(GutendexSavedCatalog.maxUnits));
      expect(await store.read('0', es), isNull);
      await store.save(
        'huge',
        es,
        GutendexPage(results: [GutendexBook(id: 999, title: 'x' * 260000)]),
      );
      expect(await store.read('huge', es), isNull);
      expect(await store.read('4', es), isNotNull);
    },
  );
  for (final bad in [
    'not json',
    '{"version":2,"entries":[]}',
    jsonEncode({
      'version': 1,
      'entries': [
        {
          'query': '',
          'language': 'es',
          'saved': DateTime.now().toIso8601String(),
          'count': 1,
          'next': 'https://evil.test/books/?page=2',
          'books': [bookJson(1)],
        },
      ],
    }),
    jsonEncode({
      'version': 1,
      'entries': [
        {
          'query': '',
          'language': 'es',
          'saved': DateTime.now().toIso8601String(),
          'books': [
            {'id': -1},
          ],
        },
      ],
    }),
    'x' * 250001,
  ]) {
    test(
      'invalid or incompatible stored data ignored case ${bad.length} ${bad.substring(0, 8)}',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(GutendexSavedCatalog.storageKey, bad);
        expect(await GutendexSavedCatalog().read('', es), isNull);
      },
    );
  }
  test('reopen uses saved real response without network; manual timeout retains it then recovers', () async {
    final store = GutendexSavedCatalog();
    await store.save('', es, GutendexPage(results: [fixtureBook(1)]));
    final repo = FakeGutendexRepository();
    final c = GutendexController(repo, savedCatalog: store);
    addTearDown(c.dispose);
    await c.search();
    expect(repo.calls, isEmpty);
    expect(c.fromSavedCatalog, isTrue);
    final refresh = c.search(refresh: true);
    expect(c.items.single.id, 1);
    expect(identical(refresh, c.search(refresh: true)), isTrue);
    repo.calls.single.result.completeError(
      const GutendexFailure('Gutendex tardó demasiado. Inténtalo nuevamente.'),
    );
    await refresh;
    expect(c.items.single.id, 1);
    expect(c.fromSavedCatalog, isTrue);
    expect(c.error, contains('tardó demasiado'));
    final retry = c.search(refresh: true);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2)]));
    await retry;
    expect(c.fromSavedCatalog, isFalse);
    expect(c.error, isNull);
    expect(c.items.single.id, 2);
  });
  test('cold timeout does not masquerade as an empty success', () async {
    final repo = FakeGutendexRepository();
    final c = GutendexController(repo, savedCatalog: GutendexSavedCatalog());
    addTearDown(c.dispose);
    final task = c.search();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    repo.calls.single.result.completeError(
      const GutendexFailure('Gutendex tardó demasiado.'),
    );
    await task;
    expect(c.hasSearched, isFalse);
    expect(c.items, isEmpty);
    expect(c.error, isNotNull);
    expect(repo.calls, hasLength(1));
  });
  test(
    'persistent lookup cannot apply a previous language after immediate change',
    () async {
      final store = GutendexSavedCatalog();
      await store.save('', es, GutendexPage(results: [fixtureBook(1)]));
      await store.save(
        '',
        en,
        GutendexPage(results: [fixtureBook(2, language: 'en')]),
      );
      final repo = FakeGutendexRepository();
      final c = GutendexController(repo, savedCatalog: store);
      addTearDown(c.dispose);
      await Future.wait([c.search(), c.search(language: en)]);
      expect(c.items.single.id, 2);
      expect(c.language, en);
      expect(repo.calls, isEmpty);
      final next = c.search(query: 'different');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.items, isEmpty);
      expect(c.fromSavedCatalog, isFalse);
      repo.calls.single.result.complete(
        GutendexPage(results: [fixtureBook(3)]),
      );
      await next;
      expect(c.items.single.id, 3);
    },
  );
  test('successful network page is saved automatically and survives controller disposal', () async {
    final store = GutendexSavedCatalog();
    final repo = FakeGutendexRepository();
    final controller = GutendexController(repo, savedCatalog: store);
    final task = controller.search(query: 'Real');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(7)]));
    await task;
    // Wait behind the queued best-effort write without depending on wall-clock I/O.
    await store.save('Other', es, const GutendexPage(results: []));
    controller.dispose();
    final reopened = GutendexController(
      repo,
      savedCatalog: GutendexSavedCatalog(),
    );
    addTearDown(reopened.dispose);
    await reopened.search(query: 'Real');
    expect(reopened.items.single.id, 7);
    expect(reopened.fromSavedCatalog, isTrue);
    expect(repo.calls, hasLength(1));
  });
  test('parallel saves preserve both query keys and never alter unrelated preferences', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unrelated', 'keep');
    final store = GutendexSavedCatalog();
    await Future.wait([
      store.save('A', es, GutendexPage(results: [fixtureBook(1)])),
      store.save(
        'B',
        en,
        GutendexPage(results: [fixtureBook(2, language: 'en')]),
      ),
    ]);
    expect(await store.read('A', es), isNotNull);
    expect(await store.read('B', en), isNotNull);
    expect(prefs.getString('unrelated'), 'keep');
  });
  testWidgets(
    'slow local storage cannot block network or overwrite newer results',
    (tester) async {
      final store = SlowSavedCatalog();
      final repo = FakeGutendexRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: GutendexCatalogScreen(repository: repo, savedCatalog: store),
        ),
      );
      expect(repo.calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 501));
      expect(repo.calls, hasLength(1));
      repo.calls.single.result.complete(
        GutendexPage(results: [fixtureBook(2)]),
      );
      await tester.pumpAndSettle();
      store.pending.complete(GutendexPage(results: [fixtureBook(1)]));
      await tester.pumpAndSettle();
      expect(find.text('Obra fixture 2'), findsOneWidget);
      expect(find.text('Obra fixture 1'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'saved catalog navigation retry and fallback size=$size dark=$dark',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final store = GutendexSavedCatalog();
          await store.save(
            '',
            es,
            GutendexPage(
              results: [
                GutendexBook.fromJson({
                  ...bookJson(1),
                  'title': 'Título real extenso áéíóú ñ para comprobar el catálogo y su navegación',
                  'formats': {
                    'text/plain; charset=utf-8':
                        'https://www.gutenberg.org/files/1/1.txt',
                  },
                }),
              ],
            ),
          );
          final repo = FakeGutendexRepository();
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: GutendexCatalogScreen(
                repository: repo,
                savedCatalog: store,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.textContaining(
              'Resultados guardados de una consulta anterior',
            ),
            findsOneWidget,
          );
          expect(repo.calls, isEmpty);
          final card = find.byKey(const ValueKey('gutendex-book-1'));
          await tester.ensureVisible(card);
          await tester.pumpAndSettle();
          await tester.tap(card);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byType(GutendexDetailScreen), findsOneWidget);
          repo.details.single.result.completeError(
            const GutendexFailure('HTTP 503'),
          );
          await tester.pumpAndSettle();
          expect(find.textContaining('Título real extenso'), findsOneWidget);
          final txt = find.byKey(const ValueKey('gutendex-read-txt'));
          await tester.scrollUntilVisible(
            txt,
            150,
            scrollable: find
                .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          expect(txt, findsOneWidget);
          await tester.pageBack();
          await tester.pumpAndSettle();
          final search = find.byTooltip('Buscar');
          await tester.ensureVisible(search);
          await tester.pumpAndSettle();
          await tester.tap(search);
          await tester.pump();
          repo.calls.single.result.completeError(
            const GutendexFailure('Gutendex tardó demasiado.'),
          );
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Se muestran resultados guardados'),
            findsOneWidget,
          );
          expect(find.text('Reintentar catálogo'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('failed cover remains fallback on rebuild and new URL can load', (
    tester,
  ) async {
    Widget image(Uri? url) => MaterialApp(
      home: Scaffold(
        body: GutendexCover(
          url: url,
          title: 'Título real',
          width: 130,
          height: 190,
        ),
      ),
    );
    final url = Uri.parse('https://www.gutenberg.org/a.jpg');
    await tester.pumpWidget(image(url));
    final network = tester.widget<Image>(find.byType(Image));
    network.errorBuilder!(
      tester.element(find.byType(Image)),
      Exception('503'),
      StackTrace.empty,
    );
    await tester.pumpWidget(image(url));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(
      find.byKey(const ValueKey('gutendex-cover-placeholder')),
      findsOneWidget,
    );
    expect(find.text('Título real'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      image(Uri.parse('https://www.gutenberg.org/b.jpg')),
    );
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
