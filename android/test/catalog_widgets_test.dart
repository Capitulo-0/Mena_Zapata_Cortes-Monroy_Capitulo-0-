import 'dart:async';
import 'package:android/features/profile/data/user_search_repository.dart';
import 'package:android/features/profile/domain/user_search_result.dart';
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


class _SearchCatalog extends CatalogFake {
  final calls = <({String query, String mode, int start,
    Completer<CatalogPage> response})>[];

  @override
  Future<CatalogPage> search(String query, {String mode = 'all', int start = 0}) {
    final response = Completer<CatalogPage>();
    calls.add((query: query, mode: mode, start: start, response: response));
    return response.future;
  }
}

class _SearchUsers implements UserSearchRepository {
  final calls = <({String query, Completer<List<UserSearchResult>> response})>[];

  @override
  Future<List<UserSearchResult>> searchUsers(String query) {
    final response = Completer<List<UserSearchResult>>();
    calls.add((query: query, response: response));
    return response.future;
  }
}

const _reader = UserSearchResult(displayName: 'Lector fixture', username: 'lector');

CatalogPage _page(String id, {int? next}) => CatalogPage([
  {...ApiCatalogRepository.presentation(metadata(id)), 'cover': ''},
], next);


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
  group('independent book and user searches', () {
    late _SearchCatalog books;
    late _SearchUsers users;
    late List<String> opened;
    late List<bool> searchModes;

    Future<void> mount(WidgetTester tester, {bool local = false}) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      books = _SearchCatalog();
      users = _SearchUsers();
      opened = [];
      searchModes = [];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: HomeSearchSection(
          books: local ? _page('local').items : const [],
          catalogRepository: local ? null : books,
          userSearchRepository: users,
          onBookTap: (book) => opened.add('book:${book['googleVolumeId']}'),
          onUserTap: (username) => opened.add('user:$username'),
          onSearchModeChanged: searchModes.add,
        ))),
      ));
    }

    Future<void> submit(WidgetTester tester, [String query = 'consulta']) async {
      await tester.enterText(find.byType(TextField), query);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    Future<void> tap(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }

    for (final usersFirst in [true, false]) {
      testWidgets('both categories render independently usersFirst=$usersFirst',
          (tester) async {
        await mount(tester);
        await submit(tester);
        expect(books.calls.single.query, 'consulta');
        expect(users.calls.single.query, 'consulta');
        expect(find.text('0 usuarios encontrados'), findsNothing);
        expect(find.text('No encontramos resultados'), findsNothing);
        if (usersFirst) {
          users.calls.single.response.complete([_reader]);
        } else {
          books.calls.single.response.complete(_page('found'));
        }
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(usersFirst ? 'Lector fixture' : 'Real fixture found'),
          findsOneWidget);
        expect(find.text('No encontramos resultados'), findsNothing);
        if (usersFirst) {
          books.calls.single.response.complete(_page('found'));
        } else {
          users.calls.single.response.complete([_reader]);
        }
        await tester.pumpAndSettle();
        expect(find.text('Real fixture found'), findsOneWidget);
        expect(find.text('Lector fixture'), findsOneWidget);
        expect(find.text('Volver'), findsOneWidget);
        await tap(tester, find.text('Real fixture found'));
        await tap(tester, find.text('Lector fixture'));
        expect(opened, ['book:found', 'user:lector']);
        await tap(tester, find.text('Volver'));
        await tester.pumpAndSettle();
        expect(searchModes.last, false);
        expect(find.text('Real fixture found'), findsNothing);
        expect(find.text('Lector fixture'), findsNothing);
      });
    }

    for (final failUsers in [true, false]) {
      testWidgets('failure and retry isolated failUsers=$failUsers', (tester) async {
        await mount(tester);
        await submit(tester);
        if (failUsers) {
          users.calls.single.response.completeError(StateError('users failed'));
          books.calls.single.response.complete(_page('valid'));
        } else {
          books.calls.single.response.completeError(StateError('books failed'));
          users.calls.single.response.complete([_reader]);
        }
        await tester.pumpAndSettle();
        final valid = find.text(failUsers ? 'Real fixture valid' : 'Lector fixture');
        expect(valid, findsOneWidget);
        expect(find.text('No encontramos resultados'), findsNothing);
        await tap(tester, find.byKey(ValueKey(failUsers ? 'retry-users' : 'retry-books')));
        expect(valid, findsOneWidget);
        expect(failUsers ? books.calls.length : users.calls.length, 1);
        if (failUsers) {
          users.calls.last.response.complete([_reader]);
        } else {
          books.calls.last.response.complete(_page('recovered'));
        }
        await tester.pumpAndSettle();
        expect(find.text('Lector fixture'), findsOneWidget);
        expect(find.text(failUsers ? 'Real fixture valid' : 'Real fixture recovered'),
          findsOneWidget);
      });
    }

    for (final userState in ['visible', 'loading', 'failed']) {
      testWidgets('pagination and page retry with users $userState', (tester) async {
        await mount(tester);
        await submit(tester);
        books.calls.single.response.complete(_page('first', next: 20));
        if (userState == 'visible') {
          users.calls.single.response.complete([_reader]);
        } else if (userState == 'failed') {
          users.calls.single.response.completeError(StateError('users failed'));
        }
        await tester.pump(const Duration(milliseconds: 600));
        await tap(tester, find.text('Más resultados'));
        expect(books.calls.last.start, 20);
        books.calls.last.response.completeError(StateError('page failed'));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Real fixture first'), findsOneWidget);
        await tap(tester, find.byKey(const ValueKey('retry-books')));
        expect(books.calls.last.start, 20);
        books.calls.last.response.complete(CatalogPage([
          ..._page('first').items, ..._page('second').items,
        ], null));
        if (userState == 'loading') {
          users.calls.single.response.complete([_reader]);
        }
        await tester.pumpAndSettle();
        expect(find.text('Real fixture first'), findsOneWidget);
        expect(find.text('Real fixture second'), findsOneWidget);
        expect(users.calls, hasLength(1));
        expect(find.text('Más resultados'), findsNothing);
      });
    }

    testWidgets('simultaneous suggestions keep debounce and navigation', (tester) async {
      await mount(tester);
      await tester.enterText(find.byType(TextField), 'con');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'consulta');
      await tester.pump(const Duration(milliseconds: 399));
      expect(books.calls, isEmpty);
      expect(users.calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(books.calls.single.query, 'consulta');
      expect(users.calls.single.query, 'consulta');
      books.calls.single.response.complete(_page('suggestion'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Real fixture suggestion'), findsOneWidget);
      expect(find.text('No se encontraron usuarios.'), findsNothing);
      users.calls.single.response.complete([_reader]);
      await tester.pumpAndSettle();
      expect(find.text('SUGERENCIA'), findsOneWidget);
      await tap(tester, find.text('Real fixture suggestion'));
      await tap(tester, find.text('Lector fixture'));
      expect(opened, ['book:suggestion', 'user:lector']);
    });

    for (final failUsers in [true, false]) {
      testWidgets('suggestion retry isolated failUsers=$failUsers', (tester) async {
        await mount(tester);
        await tester.enterText(find.byType(TextField), 'consulta');
        await tester.pump(const Duration(milliseconds: 400));
        if (failUsers) {
          users.calls.single.response.completeError(StateError('users'));
          books.calls.single.response.complete(_page('suggestion'));
        } else {
          books.calls.single.response.completeError(StateError('books'));
          users.calls.single.response.complete([_reader]);
        }
        await tester.pumpAndSettle();
        expect(find.text(failUsers ? 'Real fixture suggestion' : 'Lector fixture'),
          findsOneWidget);
        await tap(tester, failUsers
          ? find.byKey(const ValueKey('retry-user-preview'))
          : find.text('No se pudieron cargar sugerencias. Reintentar'));
        expect(failUsers ? books.calls.length : users.calls.length, 1);
        if (failUsers) {
          users.calls.last.response.complete([_reader]);
        } else {
          books.calls.last.response.complete(_page('recovered'));
        }
        await tester.pumpAndSettle();
        expect(find.text('Lector fixture'), findsOneWidget);
        expect(find.text(failUsers ? 'Real fixture suggestion' : 'Real fixture recovered'),
          findsOneWidget);
      });
    }

    for (final lateError in [true, false]) {
      testWidgets('old results and previews discarded lateError=$lateError', (tester) async {
        await mount(tester);
        await submit(tester, 'old submitted');
        await tester.enterText(find.byType(TextField), 'old preview');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.enterText(find.byType(TextField), 'new');
        await tester.pump(const Duration(milliseconds: 400));
        books.calls.last.response.complete(_page('new'));
        users.calls.last.response.complete([_reader]);
        await tester.pumpAndSettle();
        for (final call in books.calls.take(2)) {
          if (lateError) {
            call.response.completeError(StateError('obsolete'));
          } else {
            call.response.complete(_page('obsolete'));
          }
        }
        for (final call in users.calls.take(2)) {
          if (lateError) {
            call.response.completeError(StateError('obsolete'));
          } else {
            call.response.complete([
              const UserSearchResult(displayName: 'Obsoleto', username: 'obsolete'),
            ]);
          }
        }
        await tester.pumpAndSettle();
        expect(find.text('Real fixture new'), findsOneWidget);
        expect(find.text('Lector fixture'), findsOneWidget);
        expect(find.text('Real fixture obsolete'), findsNothing);
        expect(find.text('Obsoleto'), findsNothing);
        expect(find.textContaining('Reintentar'), findsNothing);
      });
    }

    testWidgets('old page cannot enter a new submitted query', (tester) async {
      await mount(tester);
      await submit(tester, 'old');
      books.calls.single.response.complete(_page('old', next: 20));
      users.calls.single.response.complete([]);
      await tester.pumpAndSettle();
      await tap(tester, find.text('Más resultados'));
      final oldPage = books.calls.last.response;
      await submit(tester, 'new');
      books.calls.last.response.complete(_page('new'));
      users.calls.last.response.complete([_reader]);
      await tester.pumpAndSettle();
      oldPage.complete(_page('obsolete'));
      await tester.pumpAndSettle();
      expect(find.text('Real fixture new'), findsOneWidget);
      expect(find.text('Real fixture obsolete'), findsNothing);
    });

    for (final entry in {'Título': 'title', 'Autor': 'author', 'ISBN': 'isbn',
      'Gótico': 'all', 'Más recientes': 'all'}.entries) {
      testWidgets('literary mode/filter excludes users: ${entry.key}', (tester) async {
        await mount(tester);
        await tap(tester, find.text('Filtrar'));
        await tester.pumpAndSettle();
        if (entry.key == 'Gótico') {
          await tap(tester, find.text('Géneros'));
          await tester.pumpAndSettle();
          await tap(tester, find.text('Gótico'));
          await tester.pumpAndSettle();
          await tap(tester, find.byIcon(Icons.arrow_back_rounded).last);
        } else {
          await tap(tester, find.text(
            entry.key == 'Más recientes' ? 'Orden' : entry.key,
          ).last);
        }
        await tester.pumpAndSettle();
        await tap(tester, find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();
        await submit(tester);
        expect(users.calls, isEmpty);
        expect(books.calls.single.mode, entry.value);
        final items = [
          {..._page('older').items.single, 'genre': 'Gótico', 'year': 2000},
          {..._page('newer').items.single, 'genre': 'Gótico', 'year': 2026},
          {..._page('other').items.single, 'genre': 'Romance', 'year': 2025},
        ];
        books.calls.single.response.complete(CatalogPage(items, null));
        await tester.pumpAndSettle();
        expect(find.text('Real fixture newer'), findsOneWidget);
        if (entry.key == 'Gótico') {
          expect(find.text('Real fixture other'), findsNothing);
        }
        if (entry.key == 'Más recientes') {
          expect(tester.getTopLeft(find.text('Real fixture newer')).dy,
            lessThan(tester.getTopLeft(find.text('Real fixture older')).dy));
        }
      });
    }

    testWidgets('empty categories appear only after each valid response', (tester) async {
      await mount(tester);
      await submit(tester);
      users.calls.single.response.complete([]);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('0 usuarios encontrados'), findsOneWidget);
      expect(find.text('No encontramos resultados'), findsNothing);
      books.calls.single.response.complete(const CatalogPage([], null));
      await tester.pumpAndSettle();
      expect(find.text('No encontramos resultados'), findsOneWidget);
      expect(find.text('0 usuarios encontrados'), findsOneWidget);
    });

    testWidgets('Volver invalidates both pending categories', (tester) async {
      await mount(tester);
      await submit(tester);
      await tap(tester, find.text('Volver'));
      books.calls.single.response.complete(_page('obsolete'));
      users.calls.single.response.complete([_reader]);
      await tester.pumpAndSettle();
      expect(find.text('Real fixture obsolete'), findsNothing);
      expect(find.text('Lector fixture'), findsNothing);
      expect(searchModes.last, false);
    });

    testWidgets('local fallback coexists with user suggestions and results', (tester) async {
      await mount(tester, local: true);
      await tester.enterText(find.byType(TextField), 'local');
      await tester.pump(const Duration(milliseconds: 400));
      users.calls.single.response.complete([_reader]);
      await tester.pumpAndSettle();
      expect(find.text('Real fixture local'), findsOneWidget);
      expect(find.text('Lector fixture'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      users.calls.last.response.complete([_reader]);
      await tester.pumpAndSettle();
      expect(books.calls, isEmpty);
      expect(find.text('Real fixture local'), findsOneWidget);
      expect(find.text('Lector fixture'), findsOneWidget);
    });
  });

}
