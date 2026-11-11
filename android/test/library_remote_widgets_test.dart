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
    await tester.tap(find.byIcon(Icons.menu_book_outlined).first);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'adds SQL catalog book using existing library flow and reload restores progress',
    (tester) async {
      await tester.pumpWidget(shell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir libro').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SQL book 901').last);
      await tester.pumpAndSettle();
      await openLibrary(tester);
      var library = tester.widget<LibraryScreen>(find.byType(LibraryScreen));
      expect(library.statuses.keys, [901]);
      expect(library.statuses.containsKey(1), false);
      await library.onStatusChanged(901, BookStatus.leyendo);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('SQL book 901').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SQL book 901').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Registrar lectura').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar lectura').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('current-page')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('current-page')), '73');
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ebook').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar').last);
      await tester.pumpAndSettle();
      expect(repository.store[901]!.currentPage, 73);
      expect(repository.store[901]!.readingFormat, 'EBOOK');
      await tester.pumpWidget(const SizedBox());
      final fresh = MemoryLibraryRepository(auth, memory);
      await tester.pumpWidget(shell(source: fresh));
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      await openLibrary(tester);
      final library = tester.widget<LibraryScreen>(find.byType(LibraryScreen));
      await library.onStatusChanged(901, BookStatus.leyendo);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('SQL book 901').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SQL book 901').first);
      await tester.pumpAndSettle();
      expect(find.byType(LibraryBookDetailScreen), findsOneWidget);
      repository.mutationFailure = ApiFailure.forStatus(503);
      await tester
          .widget<ReadingStatusField>(find.byType(ReadingStatusField))
          .onChanged(BookStatus.leido);
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      await openLibrary(tester);
      expect(
        tester.widget<LibraryScreen>(find.byType(LibraryScreen)).dataAvailable,
        false,
      );
      expect(find.byType(LibraryEmptyState), findsNothing);
      repository.listFailure = null;
      await tester.tap(find.text('Reintentar').first);
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir libro').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar libro').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Manually registered book',
      );
      await tester.tap(find.text('Guardar y añadir'));
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      LibraryScreen currentLibrary() => tester.widget<LibraryScreen>(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      expect(currentLibrary().statuses.keys, [901]);
      auth.emit(const AuthIdentity(uid: 'second-user', emailVerified: true));
      await tester.pumpAndSettle();
      expect(currentLibrary().statuses, isEmpty);
      expect(currentLibrary().progresses, isEmpty);
      auth.emit(fixtureIdentity);
      await tester.pumpAndSettle();
      expect(currentLibrary().statuses.keys, [901]);
      expect(currentLibrary().progresses[901], 15);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('guest never invokes injected private repository', (
    tester,
  ) async {
    await tester.pumpWidget(shell(guest: true));
    await tester.pumpAndSettle();
    await openLibrary(tester);
    expect(repository.calls, isEmpty);
    expect(find.text('Añadir libro'), findsNothing);
    expect(
      tester.widget<LibraryScreen>(find.byType(LibraryScreen)).statuses,
      isEmpty,
    );
  });
}
