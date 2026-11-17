import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/gutendex/data/asset_reader_source.dart';
import 'package:android/features/gutendex/data/gutendex_repository.dart';
import 'package:android/features/gutendex/models/free_work.dart';
import 'package:android/features/gutendex/presentation/screens/free_library_screen.dart';
import 'package:android/features/gutendex/presentation/screens/gutendex_catalog_screen.dart';
import 'package:android/features/reader/models/reader_document.dart';
import 'package:android/features/reader/presentation/screens/text_reader_screen.dart';

import '../library_regression_test.dart' show installLocalTestAssets;
import 'support/gutendex_fakes.dart';

class WorkBundle extends CachingAssetBundle {
  WorkBundle(this.bytes);
  final Uint8List bytes;
  int loads = 0;
  @override
  Future<ByteData> load(String key) async {
    loads++;
    return ByteData.sublistView(bytes);
  }
}

const metadataOnly = FreeWork(
  id: 'wikisource-es-vida-sueno',
  title: 'La vida es sueño',
  author: 'Pedro Calderón de la Barca',
  language: 'es',
  edition: 'Información bibliográfica',
  source: 'https://es.wikisource.org/wiki/La_vida_es_sueño',
  conditions: 'Texto no incluido.',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List bytes;
  late Map<String, dynamic> manifest;
  setUpAll(() async {
    await installLocalTestAssets();
    bytes = await File(freeWorks.first.assetPath!).readAsBytes();
    manifest = jsonDecode(
      await File('assets/free_works/lazarillo_1921.source.json').readAsString(),
    ) as Map<String, dynamic>;
  });
  test('verified edition contains all eight literary sections beginning and ending unchanged', () async {
    final bundle = WorkBundle(bytes);
    final source = await AssetReaderSource(bundle: bundle)
        .load(freeWorks.first);
    final document = await source.prepare();
    final text = document.blocks.map((b) => b.text).join();
    expect(text, utf8.decode(bytes));
    expect(bytes.length, 112127);
    expect(bytes.length, manifest['bytes']);
    expect(text.length, manifest['utf16_units']);
    expect(source.title, 'El Lazarillo de Tormes');
    expect(source.author, 'Anónimo');
    expect(text, startsWith('PROLOGO'));
    expect(text, contains('Yo por bien tengo'));
    final sections = manifest['sections'] as List;
    expect(sections, hasLength(8));
    var previous = -1;
    for (final section in sections) {
      final position = text.indexOf(section['beginning'] as String);
      expect(position, greaterThan(previous));
      expect(text, contains(section['ending'] as String));
      previous = position;
    }
    expect(
      text.indexOf('\nFIN'),
      lessThan(text.indexOf('PROCEDENCIA Y CONDICIONES')),
    );
    expect(text, contains('CC BY-SA 4.0'));
    expect(bundle.loads, 1);
  });
  test(
    'absent text and unapproved asset paths cannot promise or open reading',
    () async {
      final loader = AssetReaderSource(bundle: WorkBundle(bytes));
      expect(metadataOnly.available, isFalse);
      await expectLater(
        loader.load(metadataOnly),
        throwsA(isA<ReaderFailure>()),
      );
      final invalid = FreeWork(
        id: 'x',
        title: 'X',
        author: 'X',
        language: 'es',
        source: '',
        edition: '',
        conditions: '',
        assetPath: '../private.txt',
      );
      await expectLater(loader.load(invalid), throwsA(isA<ReaderFailure>()));
    },
  );
  test(
    'asset uses strict UTF8 empty size and cancellation validations',
    () async {
      for (final invalid in [
        Uint8List.fromList([0xff]),
        Uint8List(0),
        Uint8List(ReaderSource.maxBytes + 1),
      ]) {
        await expectLater(
          AssetReaderSource(bundle: WorkBundle(invalid)).load(freeWorks.first),
          throwsA(isA<ReaderFailure>()),
        );
      }
      final bundle = WorkBundle(bytes);
      await expectLater(
        AssetReaderSource(bundle: bundle)
            .load(freeWorks.first, isCancelled: () => true),
        throwsA(isA<ReaderCancelled>()),
      );
      expect(bundle.loads, 0);
    },
  );
  testWidgets(
    'default entry opens offline and optional remote failure cannot erase local selection',
    (tester) async {
      final repo = FakeGutendexRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: GutendexCatalogScreen(repository: repo, showLocalLibrary: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      expect(find.byType(Image), findsNothing);
      expect(
        find.byKey(ValueKey('free-work-${freeWorks.first.id}')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Consultar catálogo en línea'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Consultar catálogo en línea'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.calls, hasLength(1));
      repo.calls.single.result.completeError(
        const GutendexFailure('Gutendex no disponible HTTP 503'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gutendex no disponible HTTP 503'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(FreeLibraryScreen), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('free-library-search')),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(
          '${freeWorks.length} obras · ${freeWorks.length} con lectura disponible',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('metadata-only work has no reading button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: FreeWorkDetailScreen(work: metadataOnly)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Leer ahora'), findsNothing);
    expect(
      find.text('Esta obra no tiene texto local disponible.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  test('second complete work preserves all three jornadas and is distinct from Lazarillo', () async {
    final second = await File(freeWorks[1].assetPath!).readAsBytes();
    final metadata = jsonDecode(
      await File('assets/free_works/vida_sueno.source.json').readAsString(),
    ) as Map<String, dynamic>;
    final source = await AssetReaderSource(bundle: WorkBundle(second))
        .load(freeWorks[1]);
    final text = (await source.prepare()).blocks.map((b) => b.text).join();
    expect(text, utf8.decode(second));
    expect(second.length, 104700);
    expect(second.length, metadata['bytes']);
    expect(source.author, 'Pedro Calderón de la Barca');
    expect(text, startsWith('PERSONAS'));
    expect(text, contains('Hipogrifo violento'));
    expect(
      text,
      contains('Perdón, pues de pechos nobles es tan propio el perdonarlas.'),
    );
    final sections = metadata['sections'] as List;
    expect(sections, hasLength(3));
    var previous = -1;
    for (final entry in sections) {
      final offset = text.indexOf(entry['beginning'] as String);
      expect(offset, greaterThan(previous));
      expect(text, contains(entry['ending'] as String));
      previous = offset;
    }
    expect(metadata['scan_pages'], {'first': 9, 'last': 79, 'count': 71});
    expect(text, isNot(utf8.decode(bytes)));
    expect(text, isNot(contains('Yo por bien tengo')));
  });
  testWidgets(
    'two works open their own real assets without any remote source',
    (tester) async {
      final second = File(freeWorks[1].assetPath!).readAsBytesSync();
      final bundle = WorkBundle(second);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: FreeWorkDetailScreen(
            work: freeWorks[1],
            source: AssetReaderSource(bundle: bundle),
          ),
        ),
      );
      final read = find.byKey(const ValueKey('free-work-read'));
      await tester.scrollUntilVisible(
        read,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(read);
      for (
        var i = 0;
        i < 100 && find.byType(TextReaderScreen).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();
      final reader = tester.widget<TextReaderScreen>(
        find.byType(TextReaderScreen),
      );
      expect(reader.source.title, 'La vida es sueño');
      expect(
        (await reader.source.prepare()).blocks.map((b) => b.text).join(),
        utf8.decode(second),
      );
      expect(bundle.loads, 1);
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('complete bundled book reader and back $size dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bundle = WorkBundle(bytes);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: FreeLibraryScreen(
              onlineBuilder: (_) => const Scaffold(),
              source: AssetReaderSource(bundle: bundle),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = find.byKey(ValueKey('free-work-${freeWorks.first.id}'));
        await tester.scrollUntilVisible(
          card,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(card);
        await tester.pumpAndSettle();
        final read = find.byKey(const ValueKey('free-work-read'));
        await tester.scrollUntilVisible(
          read,
          150,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(read);
        await tester.pump();
        for (
          var i = 0;
          i < 100 && find.byType(TextReaderScreen).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        await tester.pumpAndSettle();
        expect(find.byType(TextReaderScreen), findsOneWidget);
        final reader = tester.widget<TextReaderScreen>(
          find.byType(TextReaderScreen),
        );
        final document = await reader.source.prepare();
        expect(document.blocks.map((b) => b.text).join(), utf8.decode(bytes));
        expect(reader.source.title, freeWorks.first.title);
        expect(bundle.loads, 1);
        await tester.tap(find.byTooltip('Aumentar letra'));
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('text-reader-font-size')))
              .data,
          '20',
        );
        await tester.drag(
          find.byKey(const ValueKey('text-reader-scroll')),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(FreeWorkDetailScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(FreeLibraryScreen), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
