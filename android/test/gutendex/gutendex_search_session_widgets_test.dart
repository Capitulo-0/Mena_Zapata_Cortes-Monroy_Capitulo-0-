import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/gutendex/data/gutendex_repository.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';
import 'package:android/features/gutendex/presentation/screens/gutendex_catalog_screen.dart';
import 'package:android/features/gutendex/presentation/screens/gutendex_detail_screen.dart';

import 'support/gutendex_fakes.dart';
import '../library_regression_test.dart' show installLocalTestAssets;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  late FakeGutendexRepository repo;
  setUp(() => repo = FakeGutendexRepository());

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: GutendexCatalogScreen(repository: repo)));
    await tester.pump();
  }

  Future<void> language(WidgetTester tester, String label) async {
    final field = find.byKey(const ValueKey('gutendex-language'));
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pump();
  }

  testWidgets('same-query refresh preserves cards and error cannot become an empty success', (tester) async {
    await mount(tester);
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)]));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pump();
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pump();
    expect(repo.calls.length, 2);
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(find.textContaining('Actualizando esta búsqueda'), findsOneWidget);
    repo.calls.last.result.completeError(const GutendexFailure('Gutendex tardó demasiado. Inténtalo nuevamente.'));
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(find.textContaining('tardó demasiado'), findsOneWidget);
    expect(find.textContaining('No encontramos'), findsNothing);
    expect(find.text('Reintentar catálogo'), findsOneWidget);
  });

  testWidgets('cached Spanish and English results never mix and require no extra network on return', (tester) async {
    await mount(tester);
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)]));
    await tester.pumpAndSettle();
    await language(tester, 'Inglés');
    expect(find.text('Obra fixture 1'), findsNothing);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2, language: 'en')]));
    await tester.pumpAndSettle();
    await language(tester, 'Español');
    await tester.pumpAndSettle();
    expect(repo.calls.length, 2);
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(find.text('Obra fixture 2'), findsNothing);
    expect(find.textContaining('Resultados recientes de esta sesión'), findsOneWidget);
    expect(find.text('Idioma de la obra'), findsOneWidget);
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pump();
    expect(repo.calls.length, 3);
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(3)]));
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 3'), findsOneWidget);
  });

  testWidgets('failed refresh of a previously empty query does not claim no results', (tester) async {
    await mount(tester);
    repo.calls.single.result.complete(const GutendexPage(results: [], count: 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('No encontramos'), findsOneWidget);
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pump();
    repo.calls.last.result.completeError(const GutendexFailure('Gutendex no está disponible (HTTP 522).'));
    await tester.pumpAndSettle();
    expect(find.textContaining('HTTP 522'), findsOneWidget);
    expect(find.textContaining('No encontramos'), findsNothing);
  });

  testWidgets('Spanish work displays English synopsis unchanged and a discreet provider notice', (tester) async {
    final book = GutendexBook.fromJson({
      ...bookJson(1), 'summaries': ['This synopsis remains in its original language.'],
    });
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: GutendexDetailScreen(repository: repo, bookId: 1, initialBook: book)));
    repo.details.single.result.complete(book);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('gutendex-summary-language-note')), 150,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    expect(find.text('This synopsis remains in its original language.'), findsOneWidget);
    expect(find.text('Sinopsis original del proveedor; puede estar en otro idioma.'), findsOneWidget);
    expect(find.text('Leer archivo TXT'), findsOneWidget);
  });
}
