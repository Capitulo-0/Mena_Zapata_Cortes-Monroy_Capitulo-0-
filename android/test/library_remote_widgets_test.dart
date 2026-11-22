import 'dart:async';

import 'package:android/features/library/presentation/widgets/library_sync_bar.dart';
import 'package:android/features/library/presentation/controllers/library_controller.dart';
import 'package:android/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Existing transitive plugin interface: no new dependency.
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/app.dart';
import 'package:android/features/auth/domain/auth_repository.dart';
import 'package:android/features/auth/presentation/controllers/session_controller.dart';
import 'package:android/features/library/models/library_entry.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/home/presentation/screens/main_shell_screen.dart';
import 'package:android/features/library/presentation/screens/library_screen.dart';
import 'package:android/features/library/presentation/screens/library_book_detail_screen.dart';
import 'package:android/features/library/presentation/widgets/library_feedback_widgets.dart';
import 'package:android/features/library/presentation/widgets/reading_status_field.dart';

import 'support/auth_fakes.dart';
import 'support/library_fakes.dart';
import 'library_regression_test.dart' show installLocalTestAssets;
import 'epub/epub_import_widgets_test.dart' show MemoryStore;

import 'package:android/features/library/presentation/widgets/library_header.dart';

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

class _DelayedLibrary extends MemoryLibraryRepository {
  _DelayedLibrary(super.auth, super.memory);
  Completer<List<LibraryEntry>>? pendingList;
  @override
  Future<List<LibraryEntry>> list() => pendingList?.future ?? super.list();
}

// MainShell puede producir frames continuos (mapas y secciones dinámicas).
// Avanzamos transiciones y tareas diferidas sin esperar inactividad global.
Future<void> pumpLibraryUi(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  late FakeAuth auth;
  late LibraryMemory memory;
  late MemoryLibraryRepository repository;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleMapsFlutterPlatform.instance = _Maps();
    auth = FakeAuth()..identity = fixtureIdentity;
    memory = LibraryMemory();
    repository = MemoryLibraryRepository(auth, memory);
  });
  tearDown(() => auth.close());
  Widget shell({bool guest = false, MemoryLibraryRepository? source}) =>
      MaterialApp(
        theme: AppTheme.light,
        home: MainShellScreen(
          isGuest: guest,
          libraryRepository: source ?? repository,
          onLogout: () {},
          onGuestLoginRequested: () {},
          onGuestRegisterRequested: () {},
          isDarkMode: false,
          onDarkModeChanged: (_) {},
        ),
      );
  Future<void> openLibrary(WidgetTester tester) async {
    if (find.byIcon(Icons.menu_book_outlined).evaluate().isEmpty) return;
    await tester.tap(find.byIcon(Icons.menu_book_outlined).first);
    await pumpLibraryUi(tester);
  }

  Future<void> openOptions(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('library-options')));
    await pumpLibraryUi(tester);
    for (final title in [
      'Importar libro .epub',
      'Registra tu libro físico',
      'Crear lista',
      'Exportar mi biblioteca',
      'Exportar mi lista',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    // La recarga manual se eliminó de la interfaz en la fase 1.
    expect(find.byKey(const ValueKey('library-refresh')), findsNothing);
  }

  Future<void> openRegistration(WidgetTester tester) async {
    await openOptions(tester);
    await tester.tap(find.text('Registra tu libro físico'));
    // La acción abre el formulario después de cerrar el bottom sheet.
    await pumpLibraryUi(tester);
  }

  testWidgets(
    'adds SQL catalog book using existing library flow and reload restores progress',
    (tester) async {
      await tester.pumpWidget(shell());
      await pumpLibraryUi(tester);
      await openLibrary(tester);
      await openRegistration(tester);
      await tester.tap(find.text('Ver catálogo'));
      await pumpLibraryUi(tester);
      await tester.tap(find.text('SQL book 901').last);
      await pumpLibraryUi(tester);
      await openLibrary(tester);
      var library = tester.widget<LibraryScreen>(find.byType(LibraryScreen));
      expect(library.statuses.keys, [901]);
      expect(library.statuses.containsKey(1), false);
      await library.onStatusChanged(901, BookStatus.leyendo);
      await pumpLibraryUi(tester);
      await tester.ensureVisible(find.text('SQL book 901').first);
      await pumpLibraryUi(tester);
      await tester.tap(find.text('SQL book 901').first);
      await pumpLibraryUi(tester);
      await tester.ensureVisible(find.text('Registrar lectura').last);
      await pumpLibraryUi(tester);
      await tester.tap(find.text('Registrar lectura').last);
      await pumpLibraryUi(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('current-page')));
      await pumpLibraryUi(tester);
      await tester.enterText(find.byKey(const ValueKey('current-page')), '73');
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await pumpLibraryUi(tester);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await pumpLibraryUi(tester);
      await tester.tap(find.text('Ebook').last);
      await pumpLibraryUi(tester);
      await tester.ensureVisible(find.text('Guardar').last);
      await pumpLibraryUi(tester);
      await tester.tap(find.text('Guardar').last);
      await pumpLibraryUi(tester);
      expect(repository.store[901]!.currentPage, 73);
      expect(repository.store[901]!.readingFormat, 'EBOOK');
      await tester.pumpWidget(const SizedBox());
      final fresh = MemoryLibraryRepository(auth, memory);
      await tester.pumpWidget(shell(source: fresh));
      await pumpLibraryUi(tester);
      await openLibrary(tester);
      library = tester.widget<LibraryScreen>(find.byType(LibraryScreen));
      expect(library.progresses[901], 24);
      expect(library.statuses[901], BookStatus.leyendo);
      expect(fresh.store[901]!.readingFormat, 'EBOOK');
    },
  );
  testWidgets(
    'failed state update preserves confirmed detail and shows no finish success',
    (tester) async {
      await repository.add(901);
      await tester.pumpWidget(shell());
      await pumpLibraryUi(tester);
      await openLibrary(tester);
      final library = tester.widget<LibraryScreen>(find.byType(LibraryScreen));
      await library.onStatusChanged(901, BookStatus.leyendo);
      await pumpLibraryUi(tester);
      await tester.ensureVisible(find.text('SQL book 901').first);
      await pumpLibraryUi(tester);
      await tester.tap(find.text('SQL book 901').first);
      await pumpLibraryUi(tester);
      expect(find.byType(LibraryBookDetailScreen), findsOneWidget);
      repository.mutationFailure = ApiFailure.forStatus(503);
      await tester
          .widget<ReadingStatusField>(find.byType(ReadingStatusField))
          .onChanged(BookStatus.leido);
      await pumpLibraryUi(tester);
      expect(repository.store[901]!.status, BookStatus.leyendo);
      expect(
        tester
            .widget<ReadingStatusField>(find.byType(ReadingStatusField))
            .status,
        BookStatus.leyendo,
      );
      expect(find.byType(LibraryFinishSuccessMessage), findsNothing);
      expect(find.textContaining('no está disponible'), findsWidgets);
    },
  );
  testWidgets(
    'load error is not an empty success and retry restores empty state',
    (tester) async {
      repository.listFailure = ApiFailure.forStatus(503);
      await tester.pumpWidget(shell());
      await pumpLibraryUi(tester);
      await openLibrary(tester);
      expect(
        tester.widget<LibraryScreen>(find.byType(LibraryScreen)).dataAvailable,
        false,
      );
      expect(find.byType(LibraryEmptyState), findsNothing);
      repository.listFailure = null;
      await tester.tap(find.text('Reintentar').first);
      await pumpLibraryUi(tester);
      expect(
        tester.widget<LibraryScreen>(find.byType(LibraryScreen)).dataAvailable,
        true,
      );
      expect(
        find.text('Todavía no tienes libros en tu biblioteca.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'empty SQL catalog permits manual registration without demo ids',
    (tester) async {
      memory.catalog.clear();
      await tester.pumpWidget(shell());
      await pumpLibraryUi(tester);
      await openLibrary(tester);
      await openRegistration(tester);
      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Ver catálogo'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Manually registered book',
      );
      await tester.tap(find.text('Guardar y añadir'));
      await pumpLibraryUi(tester);
      expect(repository.store.keys, [902]);
      expect(repository.calls.where((call) => call == 'create').length, 1);
    },
  );

  testWidgets(
    'App changes accounts without reusing private library and restores first account',
    (tester) async {
      final session = SessionController(auth: auth, accounts: FakeAccounts());
      addTearDown(session.dispose);
      memory.byOwner[fixtureIdentity.uid] = {
        901: LibraryEntry.fromJson(entryJson()),
      };
      await tester.pumpWidget(
        CapituloCeroApp(
          session: session,
          libraryRepositoryFactory: (uid) =>
              MemoryLibraryRepository(auth, memory, ownerUid: uid),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await pumpLibraryUi(tester);
      LibraryScreen currentLibrary() => tester.widget<LibraryScreen>(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      expect(currentLibrary().statuses.keys, [901]);
      auth.emit(const AuthIdentity(uid: 'second-user', emailVerified: true));
      await pumpLibraryUi(tester);
      expect(currentLibrary().statuses, isEmpty);
      expect(currentLibrary().progresses, isEmpty);
      auth.emit(fixtureIdentity);
      await pumpLibraryUi(tester);
      expect(currentLibrary().statuses.keys, [901]);
      expect(currentLibrary().progresses[901], 15);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'no sync strip; actualización de datos alimenta Perfil y reto anual sin recarga manual',
    (tester) async {
      await tester.pumpWidget(shell());
      await pumpLibraryUi(tester);
      expect(repository.calls.where((c) => c == 'list').length, 1);
      expect(find.byType(LibrarySyncBar), findsNothing);
      await openLibrary(tester);
      expect(find.text('Mi biblioteca sincronizada'), findsNothing);
      expect(find.byTooltip('Añadir libro'), findsNothing);
      await openOptions(tester);
      // El menú de opciones sigue disponible, pero la recarga manual no.
      expect(find.byKey(const ValueKey('library-refresh')), findsNothing);
      Navigator.of(tester.element(find.text('Crear lista'))).pop();
      await pumpLibraryUi(tester);
      repository.store[901] = LibraryEntry.fromJson(
        entryJson(status: 'LEIDO', page: 300),
      );
      final controller = tester
          .widget<LibraryScreen>(find.byType(LibraryScreen))
          .syncController!;
      await controller.load();
      await pumpLibraryUi(tester);
      expect(repository.calls.where((c) => c == 'list').length, 2);
      final library = tester.widget<LibraryScreen>(find.byType(LibraryScreen));
      expect(library.statuses[901], BookStatus.leido);
      expect(library.progresses[901], 100);
      await tester.tap(find.byIcon(Icons.person_outline).last);
      await pumpLibraryUi(tester);
      expect(find.byType(LibrarySyncBar), findsNothing);
      final profile = tester.widget<ProfileScreen>(find.byType(ProfileScreen));
      expect(profile.statuses[901], BookStatus.leido);
      expect(profile.progresses[901], 100);
      final challenge = find.text('1 / ${profile.annualGoal} libros');
      await tester.scrollUntilVisible(
        challenge,
        250,
        scrollable: find
            .descendant(
              of: find.byType(ProfileScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await pumpLibraryUi(tester);
      expect(challenge, findsOneWidget);
      expect(repository.calls.where((c) => c == 'list').length, 2);
    },
  );
  testWidgets(
    'reintento tras fallo inicial sigue disponible sin recarga manual',
    (tester) async {
      repository.listFailure = ApiFailure.forStatus(503);
      await tester.pumpWidget(shell());
      await pumpLibraryUi(tester);
      await openLibrary(tester);
      expect(find.byKey(const ValueKey('library-options')), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      repository.listFailure = null;
      await tester.tap(find.text('Reintentar'));
      await pumpLibraryUi(tester);
      expect(
        tester.widget<LibraryScreen>(find.byType(LibraryScreen)).dataAvailable,
        true,
      );
      expect(repository.store, isEmpty);
    },
  );
  testWidgets('manual validation and catalog recovery preserve one creation', (
    tester,
  ) async {
    await tester.pumpWidget(shell());
    await pumpLibraryUi(tester);
    await openLibrary(tester);
    await openRegistration(tester);
    await tester.tap(find.text('Guardar y añadir'));
    await pumpLibraryUi(tester);
    expect(find.text('Ingresa el título.'), findsOneWidget);
    expect(repository.calls.where((c) => c == 'create'), isEmpty);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Preserved manual fixture',
    );
    repository.mutationFailure = ApiFailure.forStatus(503);
    await tester.tap(find.text('Guardar y añadir'));
    await pumpLibraryUi(tester);
    expect(repository.calls.where((c) => c == 'create').length, 1);
    expect(repository.store, isEmpty);
    expect(find.byKey(const ValueKey('add-library-error')), findsOneWidget);
    repository.mutationFailure = null;
    await tester.tap(find.text('Recargar catálogo'));
    await pumpLibraryUi(tester);
    await tester.tap(find.text('Preserved manual fixture').last);
    await pumpLibraryUi(tester);
    expect(repository.calls.where((c) => c == 'create').length, 1);
    expect(repository.store.keys, [902]);
    // Selecting an already added catalog book must remain idempotent.
    await openRegistration(tester);
    await tester.tap(find.text('Ver catálogo'));
    await pumpLibraryUi(tester);
    await tester.tap(find.text(repository.store[902]!.book.title).last);
    await pumpLibraryUi(tester);
    expect(repository.store.keys, [902]);
    expect(
      repository.calls.where((c) => c == 'add').length,
      2,
    ); // failed attempt plus recovery
  });
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets(
      'compact header $size keeps menu, registration permissions and retry',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final source = _DelayedLibrary(auth, memory);
        final controller = LibraryController(source);
        addTearDown(controller.dispose);
        await controller.load();
        var opened = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: AnimatedBuilder(
                animation: controller,
                builder: (_, _) => LibraryScreen(
                  syncController: controller,
                  onAddBook: () => opened++,
                  epubStore: MemoryStore(),
                  dataAvailable: controller.loaded,
                  books: const [],
                  statuses: const {},
                  progresses: const {},
                  reviews: const {},
                  favorites: const {},
                  currentName: 'Lector',
                  currentUsername: '@lector',
                  onOpenProfile: () {},
                  onStatusChanged: (_, _) {},
                  onProgressChanged: (_, _) {},
                  onReviewSaved: (_, _) {},
                  onToggleFavorite: (_) {},
                ),
              ),
            ),
          ),
        );
        await pumpLibraryUi(tester);
        expect(find.byType(LibrarySyncBar), findsNothing);
        expect(find.text('MI BIBLIOTECA'), findsOneWidget);
        expect(find.byKey(const ValueKey('library-add')), findsNothing);
        final menu = find.byKey(const ValueKey('library-options'));
        expect(tester.getRect(menu).height, greaterThanOrEqualTo(48));
        expect(
          tester.getRect(find.text('MI BIBLIOTECA')).right,
          lessThanOrEqualTo(tester.getRect(menu).left),
        );
        await tester.tap(menu);
        await pumpLibraryUi(tester);
        expect(find.text('Registra tu libro físico'), findsOneWidget);
        expect(find.byKey(const ValueKey('library-refresh')), findsNothing);
        await tester.tap(find.text('Registra tu libro físico'));
        await pumpLibraryUi(tester);
        expect(opened, 1);

        source.pendingList = Completer<List<LibraryEntry>>();
        final loading = controller.load();
        await tester.pump();
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        await tester.tap(menu);
        await pumpLibraryUi(tester);
        final registration = find
            .ancestor(
              of: find.text('Registra tu libro físico'),
              matching: find.byType(InkWell),
            )
            .first;
        expect(tester.widget<InkWell>(registration).onTap, isNull);
        expect(find.byKey(const ValueKey('library-refresh')), findsNothing);
        Navigator.of(tester.element(registration)).pop();
        await pumpLibraryUi(tester);
        source.pendingList!.complete([]);
        await loading;
        source.pendingList = null;
        await pumpLibraryUi(tester);

        source.listFailure = ApiFailure.forStatus(503);
        await controller.load();
        await pumpLibraryUi(tester);
        expect(
          find.byKey(const ValueKey('library-sync-error')),
          findsOneWidget,
        );
        expect(find.text('Reintentar'), findsOneWidget);
        source.listFailure = null;
        await tester.tap(find.text('Reintentar'));
        await pumpLibraryUi(tester);
        expect(find.byKey(const ValueKey('library-sync-error')), findsNothing);
        await tester.tap(menu);
        await pumpLibraryUi(tester);
        final recoveredRegistration = find
            .ancestor(
              of: find.text('Registra tu libro físico'),
              matching: find.byType(InkWell),
            )
            .first;
        expect(tester.widget<InkWell>(recoveredRegistration).onTap, isNotNull);
        Navigator.of(tester.element(recoveredRegistration)).pop();
        await pumpLibraryUi(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('title and menu fit $size at text scale 2', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var addCalls = 0, menuCalls = 0;
      Widget header(bool enabled) => MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: LibraryHeader(
                currentName: 'Lector',
                onAddTap: enabled ? () => addCalls++ : null,
                onOptionsTap: () => menuCalls++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(header(true));
      await pumpLibraryUi(tester);
      expect(find.text('MI BIBLIOTECA'), findsOneWidget);
      expect(find.byKey(const ValueKey('library-add')), findsNothing);
      await tester.tap(find.byTooltip('Opciones de biblioteca'));
      expect(
        addCalls,
        0,
      ); // Parámetro conservado por compatibilidad; sin botón.
      expect(menuCalls, 1);
      await tester.pumpWidget(header(false));
      await pumpLibraryUi(tester);
      expect(find.byKey(const ValueKey('library-add')), findsNothing);
      expect(find.byTooltip('Opciones de biblioteca'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('guest never invokes injected private repository', (
    tester,
  ) async {
    await tester.pumpWidget(shell(guest: true));
    await pumpLibraryUi(tester);
    await openLibrary(tester);
    expect(repository.calls, isEmpty);
    expect(find.byKey(const ValueKey('library-add')), findsNothing);
    // El invitado no tiene acceso al menú de acciones privadas.
    expect(find.byKey(const ValueKey('library-options')), findsNothing);
    expect(find.text('Registra tu libro físico'), findsNothing);
    expect(find.byKey(const ValueKey('library-refresh')), findsNothing);
    expect(
      tester
          .widget<LibraryScreen>(
            find.byType(LibraryScreen, skipOffstage: false),
          )
          .statuses,
      isEmpty,
    );
  });
}
