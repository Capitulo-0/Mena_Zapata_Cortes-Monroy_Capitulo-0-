import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/gutendex/data/gutendex_repository.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';
import 'package:android/features/gutendex/presentation/screens/gutendex_detail_screen.dart';

import 'support/gutendex_fakes.dart';

void main() {
  late FakeGutendexRepository repo;
  setUp(() => repo = FakeGutendexRepository());

  Future<void> mount(WidgetTester tester, {GutendexBook? initial, int id = 1}) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: GutendexDetailScreen(repository: repo, bookId: id, initialBook: initial)));
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pump();
  }

  testWidgets('catalog metadata stays visible during delay and updates successfully', (tester) async {
    await mount(tester, initial: fixtureBook(1));
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(find.text('Autor Uno · Autor Dos'), findsOneWidget);
    expect(find.text('Sinopsis fixture.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repo.details.single.id, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(find.text('Sinopsis fixture.'), findsOneWidget);
    expect(repo.details.length, 1);
    await tester.scrollUntilVisible(find.textContaining('EPUB ·'), 250, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    expect(find.textContaining('EPUB ·'), findsOneWidget);
    repo.details.single.result.complete(GutendexBook.fromJson({
      ...bookJson(1), 'title': 'Título actualizado', 'summaries': ['Sinopsis actualizada.'],
    }));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.text('Título actualizado'), findsOneWidget);
    expect(find.text('Sinopsis actualizada.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('failed refresh preserves metadata and retry cannot duplicate requests', (tester) async {
    await mount(tester, initial: fixtureBook(1));
    repo.details.single.result.completeError(const GutendexFailure('HTTP 522'));
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(find.text('HTTP 522'), findsOneWidget);
    await press(tester, 'Reintentar ficha');
    expect(repo.details.length, 2);
    await tester.scrollUntilVisible(find.text('Actualizar ficha'), 300, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Actualizar ficha')).onPressed, isNull);
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Actualizar ficha'));
    await tester.pump();
    await tester.tap(find.text('Actualizar ficha'));
    await tester.pump();
    expect(repo.details.length, 2);
    repo.details.last.result.complete(fixtureBook(1));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('HTTP 522'), findsNothing);
    expect(find.text('Obra fixture 1'), findsOneWidget);
  });

  testWidgets('direct ID loads without seed and supports retry', (tester) async {
    await mount(tester, id: 7);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repo.details.single.id, 7);
    repo.details.single.result.completeError(const GutendexFailure('Sin conexión'));
    await tester.pumpAndSettle();
    await press(tester, 'Reintentar ficha');
    repo.details.last.result.complete(fixtureBook(7));
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 7'), findsOneWidget);
  });

  testWidgets('wrong seed and wrong response ID never display another book', (tester) async {
    await mount(tester, initial: fixtureBook(2));
    expect(find.text('Obra fixture 2'), findsNothing);
    repo.details.single.result.complete(fixtureBook(2));
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 2'), findsNothing);
    expect(find.text('Gutendex devolvió una ficha no válida.'), findsOneWidget);
  });

  for (final lateError in [false, true]) {
    testWidgets('changed ID discards stale response error=$lateError', (tester) async {
      await mount(tester, initial: fixtureBook(1));
      await mount(tester, id: 2, initial: fixtureBook(2));
      expect(repo.details.map((request) => request.id), [1, 2]);
      if (lateError) {
        repo.details.first.result.completeError(const GutendexFailure('Error antiguo'));
      } else {
        repo.details.first.result.complete(fixtureBook(1));
      }
      await tester.pump();
      expect(find.text('Obra fixture 2'), findsOneWidget);
      expect(find.text('Obra fixture 1'), findsNothing);
      expect(find.text('Error antiguo'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      repo.details.last.result.complete(fixtureBook(2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('incomplete refresh keeps known fields and original synopsis language', (tester) async {
    final initial = GutendexBook.fromJson({
      ...bookJson(1), 'summaries': ['An English synopsis supplied by the provider.'],
    });
    await mount(tester, initial: initial);
    repo.details.single.result.complete(const GutendexBook(id: 1, downloadCount: 0, copyright: true));
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(find.text('An English synopsis supplied by the provider.'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('EPUB ·'), 250, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    expect(find.textContaining('EPUB ·'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Descargas informadas: 0'), 250, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    expect(find.text('Copyright informado por el proveedor: sí.'), findsOneWidget);
  });

  testWidgets('rebuilding same book cannot start a duplicate refresh', (tester) async {
    await mount(tester, initial: fixtureBook(1));
    await mount(tester, initial: fixtureBook(1));
    expect(repo.details.length, 1);
    repo.details.single.result.complete(fixtureBook(1));
    await tester.pumpAndSettle();
    await mount(tester, initial: fixtureBook(1));
    expect(repo.details.length, 1);
    expect(find.text('Obra fixture 1'), findsOneWidget);
  });

  testWidgets('late failure after dispose is handled', (tester) async {
    await mount(tester, initial: fixtureBook(1));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    repo.details.single.result.completeError(const GutendexFailure('Error tardío'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
