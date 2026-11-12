import 'package:android/features/home/presentation/widgets/nearby_reading_point_section.dart';
import 'package:android/features/home/presentation/widgets/community_stories_section.dart';
import 'package:android/features/home/presentation/widgets/reading_clubs_section.dart';
import 'package:android/features/home/presentation/widgets/recommended_books_section.dart';
import 'package:android/features/home/presentation/widgets/continue_reading_section.dart';
import 'package:android/features/home/presentation/widgets/home_quote_section.dart';
import 'package:android/features/home/presentation/widgets/home_welcome_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Existing platform interface used by the maps fixture.
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/catalog/data/catalog_repository.dart';
import 'package:android/features/home/presentation/screens/main_shell_screen.dart';
import 'package:android/features/home/presentation/screens/home_book_detail_screen.dart';
import 'package:android/features/home/presentation/widgets/home_search_section.dart';
import 'package:android/features/library/presentation/screens/library_screen.dart';
import 'package:android/features/library/models/library_entry.dart';

import 'support/auth_fakes.dart';
import 'support/library_fakes.dart';
import 'catalog_test.dart' show CatalogFake, metadata;
import 'library_regression_test.dart' show installLocalTestAssets;

class _Maps extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox.expand();
}

class _Catalog extends CatalogFake {
  late LibraryMemory memory;
  bool failImport = false;
  @override
  Future<Map<String, dynamic>> importBook(String id) async {
    if (failImport) throw StateError('fixture failure');
    final data = {
      ...bookJson(id: 902),
      'googleVolumeId': id,
      'googleBooks': metadata(id),
    };
    memory.catalog[902] = LibraryEntry.parseBook(data);
    return data;
  }
}

class _Library extends MemoryLibraryRepository {
  _Library(super.auth, super.memory);
  @override
  Future<LibraryEntry> add(int id) async {
    await super.add(id);
    final book = memory.catalog[id]!;
    return store[id] = LibraryEntry.fromJson({
      ...entryJson(id: id, status: 'POR_LEER', page: 0),
      'book': {
        ...bookJson(id: id),
        'googleVolumeId': book.googleVolumeId,
        'googleBooks': book.googleBooks,
      },
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  late FakeAuth auth;
  late LibraryMemory memory;
  late MemoryLibraryRepository library;
  late _Catalog catalog;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleMapsFlutterPlatform.instance = _Maps();
    auth = FakeAuth()..identity = fixtureIdentity;
    memory = LibraryMemory()..catalog.clear();
    library = _Library(auth, memory);
    catalog = _Catalog()..memory = memory;
  });
  tearDown(() => auth.close());
  Widget shell() => MaterialApp(
    theme: AppTheme.light,
    home: MainShellScreen(
      isGuest: false,
      libraryRepository: library,
      catalogRepository: catalog,
      onLogout: () {},
      onGuestLoginRequested: () {},
      onGuestRegisterRequested: () {},
      isDarkMode: false,
      onDarkModeChanged: (_) {},
    ),
  );
  Future<void> recommend(WidgetTester tester) async {
    await tester.pumpWidget(shell());
    await tester.pump();
    catalog.pending['subject:fiction']!.complete(
      CatalogPage([ApiCatalogRepository.presentation(metadata('rec'))], null),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'empty library still discovers and opens original full detail, then imports SQL identity',
    (tester) async {
      await recommend(tester);
      expect(library.store, isEmpty);
      final card = find.text('Real fixture rec').first;
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(HomeBookDetailScreen), findsOneWidget);
      final detail = tester.widget<HomeBookDetailScreen>(
        find.byType(HomeBookDetailScreen),
      );
      expect(detail.book.containsKey('id'), false);
      expect(detail.book['googleVolumeId'], 'rec');
      expect(find.text('INFORMACIÓN DEL LIBRO'), findsOneWidget);
      final add = find.text('Añadir a mi biblioteca');
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(find.byType(HomeBookDetailScreen), findsNothing);
      expect(
        tester.widget<LibraryScreen>(find.byType(LibraryScreen)).statuses.keys,
        [902],
      );
      expect(library.store[902]!.currentPage, 0);
    },
  );
  testWidgets('failed import preserves detail and private library', (
    tester,
  ) async {
    catalog.failImport = true;
    await recommend(tester);
    final card = find.text('Real fixture rec').first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    final add = find.text('Añadir a mi biblioteca');
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byType(HomeBookDetailScreen), findsOneWidget);
    expect(library.store, isEmpty);
    expect(find.text('Ya está en tu biblioteca'), findsNothing);
  });
  testWidgets(
    'search waits for submit and shows actual results with existing cards',
    (tester) async {
      await recommend(tester);
      final field = find
          .descendant(
            of: find.byType(HomeSearchSection),
            matching: find.byType(TextField),
          )
          .first;
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'author query');
      await tester.pump();
      expect(catalog.requests, hasLength(1)); // recommendations only
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(catalog.requests.last, 'all:author query:0');
      catalog.pending['author query']!.complete(
        CatalogPage([
          ApiCatalogRepository.presentation(metadata('search')),
        ], null),
      );
      await tester.pumpAndSettle();
      expect(find.text('Real fixture search'), findsWidgets);
      expect(find.text('Real fixture rec'), findsNothing);
    },
  );
  testWidgets(
    'original filters contain all modes and preserve genres and order',
    (tester) async {
      await recommend(tester);
      expect(find.byType(DropdownButton<String>), findsNothing);
      await tester.tap(find.text('Filtrar'));
      await tester.pumpAndSettle();
      for (final label in [
        'Texto libre',
        'Título',
        'Autor',
        'ISBN',
        'Géneros',
        'Orden',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Autor'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: find.byType(HomeSearchSection),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'Gabriel');
      await tester.pump(const Duration(milliseconds: 399));
      expect(catalog.requests, hasLength(1));
      expect(find.textContaining('No se encontr?'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(catalog.requests.last, 'author:Gabriel:0');
      await tester.enterText(field, 'Gabriel García');
      catalog.pending['Gabriel']!.complete(
        CatalogPage([
          ApiCatalogRepository.presentation(metadata('late')),
        ], null),
      );
      await tester.pump();
      expect(find.text('Real fixture late'), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      catalog.pending['Gabriel García']!.complete(
        CatalogPage([
          ApiCatalogRepository.presentation(metadata('suggestion')),
        ], null),
      );
      await tester.pumpAndSettle();
      expect(find.text('SUGERENCIA'), findsOneWidget);
      await tester.tap(find.text('Real fixture suggestion'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeBookDetailScreen), findsOneWidget);
    },
  );
  for (final mode in {
    'Título': 'title',
    'Autor': 'author',
    'ISBN': 'isbn',
  }.entries) {
    testWidgets('manual search uses ${mode.value}', (tester) async {
      await recommend(tester);
      await tester.tap(find.text('Filtrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(mode.key));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: find.byType(HomeSearchSection),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'consulta');
      await tester.tap(find.text('Buscar'));
      await tester.pump();
      expect(catalog.requests.last, '${mode.value}:consulta:0');
      expect(find.text('No encontramos resultados'), findsNothing);
      catalog.pending['consulta']!.complete(const CatalogPage([], null));
      await tester.pumpAndSettle();
      expect(find.text('No encontramos resultados'), findsOneWidget);
    });
  }
  testWidgets('suggestion error retries and typing is debounced', (
    tester,
  ) async {
    await recommend(tester);
    final field = find.descendant(
      of: find.byType(HomeSearchSection),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'Ga');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(field, 'Gabriel');
    await tester.pump(const Duration(milliseconds: 399));
    expect(catalog.requests, hasLength(1));
    catalog.fail = true;
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudieron cargar sugerencias. Reintentar'),
      findsOneWidget,
    );
    expect(find.textContaining('No se encontr'), findsNothing);
    catalog.fail = false;
    await tester.tap(
      find.text('No se pudieron cargar sugerencias. Reintentar'),
    );
    await tester.pump(const Duration(milliseconds: 400));
    catalog.pending['Gabriel']!.complete(const CatalogPage([], null));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se encontr'), findsOneWidget);
  });
  for (final action in ['edit', 'erase', 'clear', 'back']) {
    testWidgets('submitted search restores original Home sections on $action', (
      tester,
    ) async {
      library.store[901] = LibraryEntry.fromJson(entryJson());
      await recommend(tester);
      final field = find.descendant(
        of: find.byType(HomeSearchSection),
        matching: find.byType(TextField),
      );
      final sectionTypes = <Type>[
        HomeWelcomeSection,
        HomeQuoteSection,
        ContinueReadingSection,
        RecommendedBooksSection,
        ReadingClubsSection,
        CommunityStoriesSection,
        NearbyReadingPointSection,
      ];
      final home = tester.state(find.byType(HomeSearchSection)).context;
      // Inspect the parent's configured children, including those below the viewport.
      List<Widget> homeChildren() {
        final list = home.findAncestorWidgetOfExactType<ListView>()!;
        return (list.childrenDelegate as SliverChildListDelegate).children;
      }

      void expectSections(bool visible) {
        final types = homeChildren()
            .map((widget) => widget.runtimeType)
            .toSet();
        for (final type in sectionTypes) {
          expect(types.contains(type), visible, reason: '$type after $action');
        }
      }

      expectSections(true);
      await tester.ensureVisible(field);
      await tester.enterText(field, 'original query');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      catalog.pending['original query']!.complete(
        CatalogPage([
          ApiCatalogRepository.presentation(metadata('result')),
        ], null),
      );
      await tester.pumpAndSettle();
      expectSections(false);
      if (action == 'back') {
        await tester.tap(find.text('Volver'));
      } else if (action == 'clear') {
        await tester.tap(
          find.descendant(
            of: find.byType(HomeSearchSection),
            matching: find.byIcon(Icons.close_rounded),
          ),
        );
      } else {
        await tester.enterText(field, action == 'edit' ? 'edited query' : '');
      }
      await tester.pump();
      expectSections(true);
      expect(find.text('RESULTADOS'), findsNothing);
      if (action == 'edit') {
        await tester.pump(const Duration(milliseconds: 400));
        expect(catalog.requests.last, 'all:edited query:0');
        catalog.pending['edited query']!.complete(
          CatalogPage([
            ApiCatalogRepository.presentation(metadata('edited')),
          ], null),
        );
        await tester.pumpAndSettle();
        expect(find.text('SUGERENCIA'), findsOneWidget);
      } else {
        await tester.pump(const Duration(milliseconds: 500));
        expect(catalog.requests, [
          'all:subject:fiction:0',
          'all:original query:0',
        ]);
      }
      expect(library.store[901]!.currentPage, 45);
    });
  }
  testWidgets('recommendation failure shows retry instead of demo books', (
    tester,
  ) async {
    catalog.fail = true;
    await tester.pumpWidget(shell());
    await tester.pumpAndSettle();
    expect(
      find.text('Google Books: no disponible. Reintentar'),
      findsOneWidget,
    );
    expect(find.text('Real fixture rec'), findsNothing);
    expect(library.store, isEmpty);
  });
}
