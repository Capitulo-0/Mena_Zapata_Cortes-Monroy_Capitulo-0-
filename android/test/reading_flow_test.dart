import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/library/models/book_status.dart';
import 'package:android/features/library/models/library_book.dart';
import 'package:android/features/library/models/reading_record.dart';
import 'package:android/features/library/presentation/screens/simulated_reader_screen.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/core/theme/app_colors.dart';
import 'package:android/features/library/presentation/dialogs/reading_record_dialog.dart';

const book = LibraryBook(
  id: 99,
  title: 'Libro demo',
  author: 'Autor',
  year: 2026,
  genre: 'Demo',
  isbn: '',
  cover: '',
  synopsis: 'Sinopsis demo',
  publisher: 'Editorial demo',
  totalPages: 200,
);

Widget host(VoidCallback Function(BuildContext) action) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) =>
          TextButton(onPressed: action(context), child: const Text('Abrir')),
    ),
  ),
);

void main() {
  testWidgets('lector completo restaura progreso y solo guarda al avanzar', (
    tester,
  ) async {
    final changes = <ReadingRecord>[];
    await tester.pumpWidget(
      host(
        (context) => () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SimulatedReaderScreen(
                book: book,
                initialProgress: 65,
                initialStatus: BookStatus.leyendo,
                onChanged: changes.add,
              ),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('65%'), findsOneWidget);
    expect(changes, isEmpty);
    final scroll = tester
        .widget<SingleChildScrollView>(
          find.byKey(const ValueKey('reader-scroll')),
        )
        .controller!;
    expect(scroll.offset / scroll.position.maxScrollExtent, closeTo(.65, .01));
    await tester.drag(
      find.byKey(const ValueKey('reader-scroll')),
      const Offset(0, -4000),
    );
    await tester.pumpAndSettle();
    expect(changes.last.progress, 100);
    expect(changes.last.status, BookStatus.leido);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abrir y recorrer un libro leído no cambia sus datos', (
    tester,
  ) async {
    final changes = <ReadingRecord>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SimulatedReaderScreen(
          book: book,
          initialProgress: 100,
          initialStatus: BookStatus.leido,
          onChanged: changes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Leído · 100%'), findsOneWidget);
    expect(find.text('Muestra de demostración'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.darkBackground,
    );
    await tester.drag(
      find.byKey(const ValueKey('reader-scroll')),
      const Offset(0, -4000),
    );
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(find.text('Leído · 100%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registro valida páginas y conserva formato y editorial', (
    tester,
  ) async {
    ReadingRecord? result;
    await tester.pumpWidget(
      host(
        (context) => () async {
          result = await showReadingRecordDialog(
            context: context,
            book: book,
            initial: null,
            status: BookStatus.leyendo,
            progress: 0,
          );
        },
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '201');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa una página entre 0 y el total.'), findsOneWidget);
    expect(result, isNull);
    await tester.enterText(fields.at(1), '50');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(result?.progress, 25);
    expect(result?.currentPage, 50);
    expect(result?.totalPages, 200);
    expect(result?.format, 'Físico');
    expect(result?.publisher, 'Editorial demo');
    expect(result?.status, BookStatus.leyendo);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'registro en pantalla pequeña conserva valores y cancelar no guarda',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const existing = ReadingRecord(
        format: 'Ebook',
        currentPage: 75,
        totalPages: 300,
        publisher: 'Editorial guardada',
        status: BookStatus.leyendo,
      );
      ReadingRecord? result;
      await tester.pumpWidget(
        host(
          (context) => () async {
            result = await showReadingRecordDialog(
              context: context,
              book: book,
              initial: existing,
              status: BookStatus.leyendo,
              progress: 25,
            );
          },
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Ebook'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('current-page')))
            .controller!
            .text,
        '75',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('total-pages')))
            .controller!
            .text,
        '300',
      );
      await tester.enterText(find.byKey(const ValueKey('current-page')), '80');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(existing.currentPage, 75);
      expect(existing.publisher, 'Editorial guardada');
      expect(tester.takeException(), isNull);
    },
  );

  test('el porcentaje no termina antes de la última página', () {
    const record = ReadingRecord(
      format: 'Ebook',
      currentPage: 199,
      totalPages: 200,
      publisher: '',
      status: BookStatus.leyendo,
    );
    expect(record.progress, 99);
    expect(record.withProgress(99, BookStatus.leyendo).currentPage, 199);
    expect(record.withProgress(100, BookStatus.leido).currentPage, 200);
    expect(record.withProgress(0, BookStatus.porLeer).currentPage, 0);
  });

  test('cambios manuales conservan páginas y metadatos al reanudar', () {
    const reading = ReadingRecord(
      format: 'Ebook',
      currentPage: 199,
      totalPages: 200,
      publisher: 'Editorial conservada',
      status: BookStatus.leyendo,
    );
    final completed = reading.withStatus(BookStatus.leido);
    expect(completed.progress, 100);
    expect(completed.currentPage, 200);
    final resumed = completed.withStatus(BookStatus.leyendo, resume: reading);
    expect(resumed.currentPage, 199);
    expect(resumed.progress, 99);
    expect(resumed.publisher, reading.publisher);
    expect(resumed.format, reading.format);
    expect(resumed.totalPages, reading.totalPages);
    expect(completed.withStatus(BookStatus.leyendo).currentPage, 199);
    final pending = resumed.withStatus(BookStatus.porLeer);
    expect(pending.currentPage, 0);
    expect(pending.progress, 0);
    expect(pending.totalPages, 200);
    expect(pending.withStatus(BookStatus.leyendo).progress, 0);
  });

  test('reanudar una muestra conserva el porcentaje preciso del scroll', () {
    const reading = ReadingRecord(
      format: 'Lector simulado',
      currentPage: 3,
      totalPages: 4,
      publisher: '',
      status: BookStatus.leyendo,
      readerProgress: 65,
    );
    final completed = reading.withStatus(BookStatus.leido);
    expect(completed.progress, 100);
    expect(
      completed.withStatus(BookStatus.leyendo, resume: reading).progress,
      65,
    );
    expect(completed.withStatus(BookStatus.porLeer).progress, 0);
  });

  test(
    'porcentajes externos se convierten sin truncar el avance solicitado',
    () {
      for (final total in [3, 7, 200, 317]) {
        final initial = ReadingRecord(
          format: 'Ebook',
          currentPage: 0,
          totalPages: total,
          publisher: 'Editorial conservada',
          status: BookStatus.leyendo,
        );
        for (var percent = 0; percent <= 100; percent++) {
          final updated = initial.withProgress(
            percent,
            percent == 100 ? BookStatus.leido : BookStatus.leyendo,
          );
          expect(
            updated.progress,
            greaterThanOrEqualTo(percent),
            reason: '$percent% de $total páginas',
          );
          expect(updated.progress, updated.currentPage * 100 ~/ total);
          expect(updated.currentPage, inInclusiveRange(0, total));
          expect(
            updated.status,
            updated.progress == 100 ? BookStatus.leido : BookStatus.leyendo,
          );
          expect(updated.format, initial.format);
          expect(updated.publisher, initial.publisher);
          expect(updated.totalPages, total);
          expect(
            updated.withProgress(updated.progress, updated.status).currentPage,
            updated.currentPage,
          );
        }
      }
    },
  );

  test('tres páginas representan 33% sin perder la primera página', () {
    const initial = ReadingRecord(
      format: 'Físico',
      currentPage: 0,
      totalPages: 3,
      publisher: '',
      status: BookStatus.leyendo,
    );
    final third = initial.withProgress(33, BookStatus.leyendo);
    expect(third.currentPage, 1);
    expect(third.progress, 33);
    final half = third.withProgress(50, BookStatus.leyendo);
    expect(half.currentPage, 2);
    expect(half.progress, 66);
    expect(half.status, BookStatus.leyendo);
    final nearEnd = half.withProgress(99, BookStatus.leyendo);
    expect(nearEnd.currentPage, 3);
    expect(nearEnd.progress, 100);
    expect(nearEnd.status, BookStatus.leido);
  });

  test('el callback simulado conserva el porcentaje de scroll exacto', () {
    const initial = ReadingRecord(
      format: 'Lector simulado',
      currentPage: 0,
      totalPages: 4,
      publisher: '',
      status: BookStatus.leyendo,
      readerProgress: 0,
    );
    final updated = initial.withProgress(65, BookStatus.leyendo);
    expect(updated.progress, 65);
    expect(updated.currentPage, 3);
    expect(updated.status, BookStatus.leyendo);
    final completed = updated.withStatus(BookStatus.leido);
    expect(
      completed.withStatus(BookStatus.leyendo, resume: updated).progress,
      65,
    );
  });
}
