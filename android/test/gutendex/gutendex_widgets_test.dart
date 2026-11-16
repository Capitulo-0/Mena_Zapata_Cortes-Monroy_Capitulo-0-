import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/gutendex/data/gutendex_repository.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';
import 'package:android/features/gutendex/presentation/screens/gutendex_catalog_screen.dart';
import 'package:android/features/gutendex/presentation/screens/gutendex_detail_screen.dart';

import 'support/gutendex_fakes.dart';

void main() {
  late FakeGutendexRepository repo;
  setUp(() => repo = FakeGutendexRepository());

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
      home: GutendexCatalogScreen(repository: repo)));
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets('catalog and page retry preserve loaded cards', (tester) async {
    await mount(tester);
    repo.calls.single.result.completeError(const GutendexFailure('Fallo inicial'));
    await tester.pumpAndSettle();
    expect(find.text('Fallo inicial'), findsOneWidget);
    expect(find.textContaining('No encontramos'), findsNothing);
    await tap(tester, find.text('Reintentar catálogo'));
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(1)],
      next: Uri.parse('https://gutendex.com/books/?languages=es&page=2')));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Más obras'));
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    repo.calls.last.result.completeError(const GutendexFailure('Fallo página'));
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 1'), findsOneWidget);
    await tap(tester, find.text('Reintentar página'));
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2)]));
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(find.text('Obra fixture 2'), findsOneWidget);
    expect(find.text('Fin de resultados.'), findsOneWidget);
  });

  testWidgets('detail retry, absent synopsis and safe format presentation', (tester) async {
    await tester.pumpWidget(MaterialApp(home: GutendexDetailScreen(repository: repo, bookId: 3)));
    repo.details.single.result.completeError(const GutendexFailure('Ficha no disponible'));
    await tester.pumpAndSettle();
    expect(find.text('Ficha no disponible'), findsOneWidget);
    await tap(tester, find.text('Reintentar ficha'));
    repo.details.last.result.complete(GutendexBook.fromJson({
      'id': 3, 'languages': ['fr'], 'formats': {
        'text/html': 'javascript:alert(1)',
        'application/octet-stream': 'https://evil.test/a',
        'text/plain': 'https://www.gutenberg.org/files/3/3.txt',
      },
    }));
    await tester.pumpAndSettle();
    expect(find.text('Este libro no tiene una sinopsis disponible.'), findsOneWidget);
    expect(find.text('Título no disponible'), findsOneWidget);
    expect(find.text('Idioma: fr'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Texto plano ·'), 300);
    expect(find.text('javascript:alert(1)'), findsNothing);
    expect(find.text('https://evil.test/a'), findsNothing);
    expect(find.byType(SelectableText), findsWidgets);
    expect(find.text('https://www.gutenberg.org/files/3/3.txt'), findsOneWidget);
  });

  testWidgets('small dark screen remains usable without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark,
      home: GutendexCatalogScreen(repository: repo)));
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tap(tester, find.text('Obra fixture 1'));
    repo.details.single.result.complete(GutendexBook.fromJson({'id': 1}));
    await tester.pumpAndSettle();
    expect(find.text('Sinopsis fixture.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog, missing cover, ID detail and back preserve results', (tester) async {
    await mount(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('No encontramos'), findsNothing);
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)], count: 1));
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(find.textContaining('Autor Uno · Autor Dos'), findsOneWidget);
    expect(find.byKey(const ValueKey('gutendex-cover-placeholder')), findsOneWidget);
    await tap(tester, find.text('Obra fixture 1'));
    expect(repo.details.single.id, 1);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Sinopsis fixture.'), findsOneWidget);
    repo.details.single.result.complete(fixtureBook(1));
    await tester.pumpAndSettle();
    expect(find.byType(GutendexDetailScreen), findsOneWidget);
    expect(find.text('Sinopsis fixture.'), findsOneWidget);
    expect(find.text('Traductores: Traductor fixture'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Obra fixture 1'), findsOneWidget);
    expect(repo.calls.length, 1);
  });

  testWidgets('debounced search and language reset', (tester) async {
    await mount(tester);
    repo.calls.single.result.complete(GutendexPage(results: [fixtureBook(1)],
      next: Uri.parse('https://gutendex.com/books/?languages=es&page=2')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('gutendex-search')), 'Cervantes');
    await tester.pump();
    expect(find.text('Obra fixture 1'), findsNothing);
    await tester.pump(const Duration(milliseconds: 399));
    expect(repo.calls.length, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(repo.calls.last.query, 'Cervantes');
    repo.calls.last.result.complete(GutendexPage(results: [fixtureBook(2)]));
    await tester.pumpAndSettle();
    for (final language in [GutendexLanguage.english, GutendexLanguage.all,
      GutendexLanguage.spanish]) {
      await tap(tester, find.byKey(const ValueKey('gutendex-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(language.label).last);
      await tester.pump();
      expect(repo.calls.last.language, language);
      expect(repo.calls.last.query, 'Cervantes');
      expect(repo.calls.last.next, isNull);
      expect(find.text('Obra fixture 2'), findsNothing);
      repo.calls.last.result.complete(const GutendexPage(results: [], count: 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('No encontramos obras'), findsOneWidget);
    }
  });
}
