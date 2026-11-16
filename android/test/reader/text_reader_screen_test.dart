import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_colors.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/reader/models/reader_document.dart';
import 'package:android/features/reader/presentation/screens/text_reader_screen.dart';

import '../library_regression_test.dart' show installLocalTestAssets;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  const short = 'Texto sintético creado para pruebas. España, ñ, áéíóú y 📖.\nSegunda línea.';

  Future<void> mount(WidgetTester tester, ReaderSource source, {
    bool dark = false, Size size = const Size(360, 640), double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light,
      home: MediaQuery(data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: TextReaderScreen(source: source))));
    await tester.pumpAndSettle();
  }

  int position(WidgetTester tester) {
    final text = tester.widget<Text>(find.byKey(const ValueKey('text-reader-position'))).data!;
    return int.parse(RegExp(r'Posición: (\d+)').firstMatch(text)!.group(1)!);
  }

  ScrollController controller(WidgetTester tester) =>
    tester.widget<ListView>(find.byKey(const ValueKey('text-reader-scroll'))).controller!;

  testWidgets('displays the supplied text with title and author', (tester) async {
    await mount(tester, const ReaderSource.text(short, title: 'Título de prueba', author: 'Autora de prueba'));
    expect(find.text(short), findsOneWidget);
    expect(find.text('Título de prueba'), findsOneWidget);
    expect(find.text('Autora de prueba'), findsOneWidget);
    expect(position(tester), 1);
    expect(find.textContaining('Leído'), findsNothing);
  });

  testWidgets('strict UTF-8 input is rendered with Spanish characters', (tester) async {
    await mount(tester, ReaderSource.utf8(utf8.encode(short)));
    expect(find.text(short), findsOneWidget);
    expect(find.text('Lectura'), findsOneWidget);
  });

  for (final source in [const ReaderSource.text(''), ReaderSource.utf8([0xff])]) {
    testWidgets('empty or invalid content has a visible error and retry', (tester) async {
      await mount(tester, source);
      expect(find.byKey(const ValueKey('text-reader-error')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('text-reader-error')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('long content is lazy, scrolls to its real ending and keeps position on reflow', (tester) async {
    final paragraphs = List.generate(300, (i) => 'Párrafo sintético $i. ${'Texto de ensayo con ñ y tildes. ' * 10}\n\n').join();
    final text = '${paragraphs}MARCADOR FINAL EXCLUSIVO DEL TEST.';
    final source = ReaderSource.text(text);
    await mount(tester, source, size: const Size(800, 1000));
    expect(find.byType(Text).evaluate().length, lessThan(35));
    expect(find.textContaining('MARCADOR FINAL EXCLUSIVO'), findsNothing);
    final scroll = controller(tester);
    scroll.jumpTo(scroll.position.maxScrollExtent * .4);
    await tester.pumpAndSettle();
    final anchor = position(tester);
    expect(anchor, greaterThan(1));
    await tester.tap(find.byTooltip('Aumentar letra'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const ValueKey('text-reader-font-size'))).data, '20');
    expect((position(tester) - anchor).abs(), lessThan(100));
    expect(controller(tester).offset, greaterThan(0));
    controller(tester).jumpTo(controller(tester).position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.textContaining('MARCADOR FINAL EXCLUSIVO'), findsOneWidget);
    expect(position(tester), greaterThan(anchor));
    expect(tester.takeException(), isNull);
  });

  testWidgets('font size is bounded and can decrease', (tester) async {
    await mount(tester, const ReaderSource.text(short));
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.byTooltip('Aumentar letra'));
      await tester.pumpAndSettle();
    }
    expect(tester.widget<Text>(find.byKey(const ValueKey('text-reader-font-size'))).data, '30');
    expect(tester.widget<IconButton>(find.byWidgetPredicate((widget) => widget is IconButton && widget.tooltip == 'Aumentar letra')).onPressed, isNull);
    for (var i = 0; i < 9; i++) {
      await tester.tap(find.byTooltip('Reducir letra'));
      await tester.pumpAndSettle();
    }
    expect(tester.widget<Text>(find.byKey(const ValueKey('text-reader-font-size'))).data, '14');
    expect(tester.widget<IconButton>(find.byWidgetPredicate((widget) => widget is IconButton && widget.tooltip == 'Reducir letra')).onPressed, isNull);
  });

  for (final dark in [false, true]) {
    for (final size in [const Size(360, 640), const Size(800, 1000)]) {
      testWidgets('responsive reader dark=$dark size=$size and accessibility text scaling', (tester) async {
        await mount(tester, ReaderSource.text('Texto sintético extenso. ' * 100,
          title: 'Título de prueba muy largo ' * 8, author: 'Autor extenso ' * 8),
          dark: dark, size: size, scale: 2);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, dark ? AppColors.darkBackground : AppColors.background);
        await tester.drag(find.byKey(const ValueKey('text-reader-scroll')), const Offset(0, -350));
        await tester.pumpAndSettle();
        expect(position(tester), greaterThan(1));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('new document resets position and discarded work cannot reveal previous content', (tester) async {
    final long = ReaderSource.text('Primer texto sintético. ' * 2000);
    await mount(tester, long);
    controller(tester).jumpTo(800);
    await tester.pumpAndSettle();
    expect(position(tester), greaterThan(1));
    await mount(tester, const ReaderSource.text('Segundo texto independiente.'));
    expect(position(tester), 1);
    expect(find.text('Segundo texto independiente.'), findsOneWidget);
    expect(find.textContaining('Primer texto'), findsNothing);
    await tester.pumpWidget(MaterialApp(home: TextReaderScreen(source: long)));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('route keeps temporary position while covered; closing and reopening starts fresh', (tester) async {
    final source = ReaderSource.text('Texto sintético para navegación. ' * 300);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: Builder(builder: (context) => Scaffold(body: TextButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => TextReaderScreen(source: source))),
        child: const Text('Abrir lector'))))));
    await tester.tap(find.text('Abrir lector'));
    await tester.pumpAndSettle();
    controller(tester).jumpTo(600);
    await tester.pumpAndSettle();
    final anchor = position(tester);
    final context = tester.element(find.byType(TextReaderScreen));
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(appBar: AppBar(), body: const Text('Otra pantalla'))));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(position(tester), anchor);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Abrir lector'), findsOneWidget);
    await tester.tap(find.text('Abrir lector'));
    await tester.pumpAndSettle();
    expect(position(tester), 1);
  });
}
