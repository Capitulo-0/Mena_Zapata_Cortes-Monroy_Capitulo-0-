import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/gutendex/presentation/screens/gutendex_detail_screen.dart';
import 'package:android/features/reader/presentation/screens/text_reader_screen.dart';

import '../library_regression_test.dart' show installLocalTestAssets;
import '../reader/support/local_txt_fakes.dart';
import 'support/gutendex_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  late FakeGutendexRepository repository;
  late FakeLocalTxtPicker picker;
  setUp(() {
    repository = FakeGutendexRepository();
    picker = FakeLocalTxtPicker();
  });

  Future<void> mount(WidgetTester tester, {Size size = const Size(360, 640), bool dark = false}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light,
      home: GutendexDetailScreen(repository: repository, bookId: 1,
        initialBook: fixtureBook(1), txtPicker: picker)));
    repository.details.single.result.complete(fixtureBook(1));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('gutendex-read-txt'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  for (final dark in [false, true]) {
    for (final size in [const Size(360, 640), const Size(800, 1000)]) {
      testWidgets('local TXT reader and back preserve detail dark=$dark size=$size', (tester) async {
        await mount(tester, size: size, dark: dark);
        await choose(tester);
        final bytes = utf8.encode('Aviso de licencia sintético.\n${'Texto de prueba ñ y áéíóú. ' * 120}FIN LOCAL.');
        final file = FakeLocalTxtFile(bytes, name: 'Archivo distinto del catálogo.txt');
        picker.pending.single.complete(file.file);
        await tester.pumpAndSettle();
        expect(find.byType(TextReaderScreen), findsOneWidget);
        final reader = tester.widget<TextReaderScreen>(find.byType(TextReaderScreen));
        expect(reader.source.title, 'Archivo local · Archivo distinto del catálogo.txt');
        expect(reader.source.author, isNull);
        expect((await reader.source.prepare()).blocks.map((block) => block.text).join(), utf8.decode(bytes));
        expect(find.text('Obra fixture 1'), findsNothing);
        expect(find.text('Autor Uno · Autor Dos'), findsNothing);
        await tester.tap(find.byTooltip('Aumentar letra'));
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(find.byKey(const ValueKey('text-reader-font-size'))).data, '20');
        await tester.drag(find.byKey(const ValueKey('text-reader-scroll')), const Offset(0, -350));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(GutendexDetailScreen), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, 2000));
        await tester.pumpAndSettle();
        expect(find.text('Obra fixture 1'), findsOneWidget);
        expect(find.text('Sinopsis fixture.'), findsOneWidget);
        expect(repository.details.length, 1);
        expect(file.reads, 1);
        expect(file.releases, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('button prevents duplicate picks and cancellation preserves detail', (tester) async {
    await mount(tester);
    await choose(tester);
    expect(tester.widget<OutlinedButton>(find.byKey(const ValueKey('gutendex-read-txt'))).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('gutendex-read-txt')));
    await tester.pump();
    expect(picker.calls, 1);
    picker.pending.single.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(TextReaderScreen), findsNothing);
    expect(find.byKey(const ValueKey('gutendex-txt-error')), findsNothing);
    expect(find.byType(GutendexDetailScreen), findsOneWidget);
    await choose(tester);
    expect(picker.calls, 2);
    picker.pending.last.complete(null);
    await tester.pumpAndSettle();
  });

  for (final failure in [
    (name: 'vacío.txt', bytes: <int>[]),
    (name: 'inválido.txt', bytes: <int>[0xff]),
    (name: 'incompatible.epub', bytes: utf8.encode('Texto sintético.')),
  ]) {
    testWidgets('invalid selection stays on detail: ${failure.name}', (tester) async {
      await mount(tester);
      await choose(tester);
      final file = FakeLocalTxtFile(failure.bytes, name: failure.name);
      picker.pending.single.complete(file.file);
      await tester.pumpAndSettle();
      expect(find.byType(TextReaderScreen), findsNothing);
      expect(find.byKey(const ValueKey('gutendex-txt-error')), findsOneWidget);
      expect(file.releases, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('picker errors are understandable and do not expose a private path', (tester) async {
    await mount(tester);
    await choose(tester);
    picker.pending.single.completeError(StateError('/privado/libro.txt'));
    await tester.pumpAndSettle();
    final error = tester.widget<Text>(find.byKey(const ValueKey('gutendex-txt-error'))).data!;
    expect(error, isNot(contains('/privado')));
    expect(find.byType(TextReaderScreen), findsNothing);
  });

  testWidgets('oversized selection stays on detail without opening the stream', (tester) async {
    await mount(tester);
    await choose(tester);
    final file = FakeLocalTxtFile([], reportedSize: 8388609);
    picker.pending.single.complete(file.file);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gutendex-txt-error')), findsOneWidget);
    expect(find.byType(TextReaderScreen), findsNothing);
    expect(file.reads, 0);
    expect(file.releases, 1);
  });

  testWidgets('changing book discards an obsolete file selection', (tester) async {
    await mount(tester);
    await choose(tester);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: GutendexDetailScreen(repository: repository, bookId: 2,
        initialBook: fixtureBook(2), txtPicker: picker)));
    repository.details.last.result.complete(fixtureBook(2));
    final file = FakeLocalTxtFile(utf8.encode('Texto sintético anterior.'));
    picker.pending.single.complete(file.file);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 2'), findsOneWidget);
    expect(find.byType(TextReaderScreen), findsNothing);
    expect(file.reads, 0);
    expect(file.releases, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dispose ignores a late selection and releases it without reading', (tester) async {
    await mount(tester);
    await choose(tester);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final file = FakeLocalTxtFile(utf8.encode('Texto sintético.'));
    picker.pending.single.complete(file.file);
    await tester.pumpAndSettle();
    expect(file.reads, 0);
    expect(file.releases, 1);
    expect(find.byType(TextReaderScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
