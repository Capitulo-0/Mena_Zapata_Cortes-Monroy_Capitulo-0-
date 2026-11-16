import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/library/models/book_status.dart';
import 'package:android/features/library/models/library_book.dart';
import 'package:android/features/library/models/reading_record.dart';
import 'package:android/features/library/presentation/dialogs/reading_record_dialog.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    ValueChanged<ReadingRecord?> saved, {
    BookStatus status = BookStatus.leyendo,
    int total = 350,
    int page = 70,
    bool allowUnknownTotal = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final book = LibraryBook(
      id: 99, title: 'Fixture', author: 'Autor', year: 2026,
      genre: '', isbn: '', cover: '', synopsis: '', publisher: 'Editorial',
      totalPages: total,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(
        child: const Text('Abrir'),
        onPressed: () async => saved(await showReadingRecordDialog(
          context: context, book: book,
          initial: ReadingRecord(format: 'Ebook', currentPage: page,
            totalPages: total, publisher: 'Editorial', status: status),
          status: status, progress: 0, allowUnknownTotal: allowUnknownTotal,
        )),
      ),
    ))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  String pageText(WidgetTester tester) => tester.widget<TextFormField>(
    find.byKey(const ValueKey('current-page')),
  ).controller!.text;

  Future<void> select(WidgetTester tester, BookStatus status) async {
    final field = find.byType(DropdownButtonFormField<BookStatus>);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(status.label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Leido completa 350 paginas y guarda 100% sin escribir la pagina',
      (tester) async {
    ReadingRecord? result;
    await open(tester, (value) => result = value);
    await select(tester, BookStatus.leido);
    expect(pageText(tester), '350');
    expect(find.text('Progreso: 100%'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator)).value, 1);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(result?.currentPage, 350);
    expect(result?.totalPages, 350);
    expect(result?.status, BookStatus.leido);
    expect(result?.progress, 100);
    expect(result?.format, 'Ebook');
    expect(result?.publisher, 'Editorial');
  });

  testWidgets('Por leer reinicia pagina despues de Leido', (tester) async {
    ReadingRecord? result;
    await open(tester, (value) => result = value);
    await select(tester, BookStatus.leido);
    await select(tester, BookStatus.porLeer);
    expect(pageText(tester), '0');
    expect(find.text('Progreso: 0%'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(result?.currentPage, 0);
    expect(result?.status, BookStatus.porLeer);
  });

  testWidgets('Leyendo conserva pagina parcial al editar total', (tester) async {
    ReadingRecord? result;
    await open(tester, (value) => result = value);
    await tester.enterText(find.byKey(const ValueKey('total-pages')), '400');
    expect(pageText(tester), '70');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(result?.currentPage, 70);
    expect(result?.totalPages, 400);
    expect(result?.status, BookStatus.leyendo);
  });

  testWidgets('Leido sincroniza total editado y al abrir registro completo',
      (tester) async {
    ReadingRecord? result;
    await open(tester, (value) => result = value,
      status: BookStatus.leido, page: 350);
    await tester.enterText(find.byKey(const ValueKey('total-pages')), '420');
    expect(pageText(tester), '420');
    expect(find.text('Progreso: 100%'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(result?.currentPage, 420);
    expect(result?.totalPages, 420);
  });

  testWidgets('Leido a Leyendo exige progreso parcial explicito', (tester) async {
    ReadingRecord? result;
    await open(tester, (value) => result = value);
    await select(tester, BookStatus.leido);
    await select(tester, BookStatus.leyendo);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('current-page')));
    await tester.enterText(find.byKey(const ValueKey('current-page')), '80');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(result?.currentPage, 80);
    expect(result?.status, BookStatus.leyendo);
    expect(result!.progress, lessThan(100));
  });

  testWidgets('Reducir total en Leyendo no sobrescribe pagina y valida limites',
      (tester) async {
    ReadingRecord? result;
    await open(tester, (value) => result = value);
    await tester.enterText(find.byKey(const ValueKey('total-pages')), '50');
    expect(pageText(tester), '70');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.byType(Dialog), findsOneWidget);
  });

  for (final allow in [true, false]) {
    testWidgets('Sin total no inventa paginas (allowUnknownTotal=$allow)',
        (tester) async {
      ReadingRecord? result;
      await open(tester, (value) => result = value,
        total: 0, page: 0, allowUnknownTotal: allow);
      await select(tester, BookStatus.leido);
      expect(pageText(tester), '0');
      expect(tester.widget<TextFormField>(
        find.byKey(const ValueKey('total-pages'))).controller!.text, '');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      if (allow) {
        expect(result?.totalPages, 0);
        expect(result?.currentPage, 0);
        expect(result?.status, BookStatus.leido);
      } else {
        expect(result, isNull);
        expect(find.byType(Dialog), findsOneWidget);
      }
    });
  }
}
