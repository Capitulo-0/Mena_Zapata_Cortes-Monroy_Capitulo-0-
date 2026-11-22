import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/gutendex/data/asset_reader_source.dart';
import 'package:android/features/gutendex/models/free_work.dart';
import 'package:android/features/gutendex/presentation/screens/free_library_screen.dart';
import 'package:android/features/reader/models/reader_document.dart';
import 'package:android/features/reader/presentation/screens/text_reader_screen.dart';

import '../library_regression_test.dart' show installLocalTestAssets;

class CollectionBundle extends CachingAssetBundle {
  final loads = <String>[];
  @override
  Future<ByteData> load(String key) async {
    loads.add(key);
    return ByteData.sublistView(File(key).readAsBytesSync());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  test(
    'exactly fifty distinct complete books have readable local assets',
    () async {
      expect(freeWorks, hasLength(50));
      expect(
        freeWorks.map((w) => w.title.trim().toLowerCase()).toSet(),
        hasLength(50),
      );
      expect(freeWorks.map((w) => w.id).toSet(), hasLength(50));
      expect(freeWorks.map((w) => w.assetPath).toSet(), hasLength(50));
      final texts = <String>{};
      final bundle = CollectionBundle();
      for (final work in freeWorks) {
        expect(work.available, isTrue);
        final source = await AssetReaderSource(bundle: bundle).load(work);
        final document = await source.prepare();
        final text = document.blocks.map((b) => b.text).join();
        expect(text, await File(work.assetPath!).readAsString());
        expect(texts.add(text), isTrue);
        expect(document.length, lessThanOrEqualTo(ReaderSource.maxCodeUnits));
        final manifest = jsonDecode(
          await File(work.assetPath!.replaceAll('.txt', '.source.json'))
              .readAsString(),
        ) as Map<String, dynamic>;
        expect(document.length, manifest['utf16_units']);
        expect(await File(work.assetPath!).length(), manifest['bytes']);
      }
      expect(bundle.loads, hasLength(50));
    },
  );
  test('all SHA256 and ordered source sections pass offline audit', () async {
    final result = await Process.run('python', ['tool/verify_collection.py']);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout.toString(), contains('50 complete works'));
  });
  testWidgets('an asset without a complete review cannot promise reading', (
    tester,
  ) async {
    final incomplete = FreeWork(
      id: 'incomplete',
      title: 'Incompleta',
      author: 'Autor',
      language: 'es',
      source: '',
      edition: '',
      conditions: '',
      assetPath: freeWorks.first.assetPath,
    );
    expect(incomplete.available, isFalse);
    final bundle = CollectionBundle();
    await expectLater(
      AssetReaderSource(bundle: bundle).load(incomplete),
      throwsA(isA<ReaderFailure>()),
    );
    expect(bundle.loads, isEmpty);
    await tester.pumpWidget(
      MaterialApp(home: FreeWorkDetailScreen(work: incomplete)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Leer ahora'), findsNothing);
    expect(
      find.text('Esta obra no tiene texto local disponible.'),
      findsOneWidget,
    );
  });
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('local title author genre and two actual readings $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bundle = CollectionBundle();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: FreeLibraryScreen(
            onlineBuilder: (_) =>
                throw StateError('Unexpected external catalogue'),
            source: AssetReaderSource(bundle: bundle),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        bundle.loads,
        isEmpty,
        reason: 'Listing metadata must not load any book',
      );
      final search = find.byKey(const ValueKey('free-library-search'));
      await tester.enterText(search, 'alarcon');
      await tester.pumpAndSettle();
      expect(find.text('1 obras · 50 con lectura disponible'), findsOneWidget);
      await tester.enterText(search, 'titulo inexistente');
      await tester.pumpAndSettle();
      expect(find.text('No hay obras que coincidan.'), findsOneWidget);
      await tester.enterText(search, '');
      await tester.pumpAndSettle();
      final genre = find.byKey(const ValueKey('free-library-genre'));
      await tester.ensureVisible(genre);
      await tester.tap(genre);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Poesía').last);
      await tester.pumpAndSettle();
      expect(find.text('36 obras · 50 con lectura disponible'), findsOneWidget);
      await tester.tap(genre);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos los géneros').last);
      await tester.pumpAndSettle();
      final readTexts = <String>[];
      for (final slug in ['monte_animas', 'rimas_1885']) {
        final work = freeWorks.singleWhere(
          (w) => w.id == 'wikisource-es-$slug',
        );
        await tester.scrollUntilVisible(
          search,
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(search, work.title);
        await tester.pumpAndSettle();
        final card = find.byKey(ValueKey('free-work-${work.id}'));
        await tester.scrollUntilVisible(
          card,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(card);
        await tester.pumpAndSettle();
        final read = find.byKey(const ValueKey('free-work-read'));
        await tester.scrollUntilVisible(
          read,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(read);
        await tester.pumpAndSettle();
        await tester.tap(read);
        for (
          var i = 0;
          i < 150 && find.byType(TextReaderScreen).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        await tester.pumpAndSettle();
        final reader = tester.widget<TextReaderScreen>(
          find.byType(TextReaderScreen),
        );
        expect(reader.source.title, work.title);
        readTexts.add(
          (await reader.source.prepare()).blocks.map((b) => b.text).join(),
        );
        await tester.drag(
          find.byKey(const ValueKey('text-reader-scroll')),
          const Offset(0, -350),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          search,
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.widget<TextField>(search).controller!.text, work.title);
      }
      expect(readTexts[0], isNot(readTexts[1]));
      expect(bundle.loads, hasLength(2));
      expect(bundle.loads.toSet(), hasLength(2));
      expect(tester.takeException(), isNull);
    });
  }
}
