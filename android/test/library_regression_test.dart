import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Interfaz ya instalada por google_maps_flutter; doble local, sin nuevas dependencias.
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:android/core/theme/app_theme.dart';

import 'fixtures/home_test_books.dart';

import 'package:android/features/home/presentation/screens/main_shell_screen.dart';
import 'package:android/features/home/presentation/screens/home_screen.dart';
import 'package:android/features/home/presentation/widgets/continue_reading_section.dart';
import 'package:android/features/home/presentation/widgets/home_search_section.dart';
import 'package:android/features/library/presentation/widgets/reading_status_field.dart';
import 'package:android/features/home/presentation/screens/home_book_detail_screen.dart';
import 'package:android/features/library/presentation/screens/library_screen.dart';
import 'package:android/features/library/presentation/screens/simulated_reader_screen.dart';
import 'package:android/features/profile/presentation/screens/profile_screen.dart';

// Fuentes locales del SDK solo para probar widgets existentes sin descargar fuentes.
Future<void> installLocalTestAssets() async {
  var directory = File(Platform.resolvedExecutable).parent;
  File? font;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${directory.path}/artifacts/material_fonts/roboto-regular.ttf',
    );
    if (candidate.existsSync()) {
      font = candidate;
      break;
    }
    directory = directory.parent;
  }
  if (font == null) {
    throw StateError('No se encontró la fuente local del SDK Flutter.');
  }
  final fontData = ByteData.sublistView(await font.readAsBytes());
  final manifest = <String, Object>{};
  final assets = <String, ByteData>{};
  for (final family in ['Inter', 'Merriweather', 'Cinzel']) {
    for (final variant in [
      'Thin',
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
      'Black',
      'Italic',
    ]) {
      final name = 'test_fonts/$family-$variant.ttf';
      manifest[name] = [
        {'asset': name},
      ];
      assets[name] = fontData;
    }
  }
  for (final name in [
    'assets/images/logo_capitulo0.png',
    'assets/images/splash_capitulo0.png',
  ]) {
    assets[name] = ByteData.sublistView(await File(name).readAsBytes());
    manifest[name] = [
      {'asset': name},
    ];
  }
  final binaryManifest = const StandardMessageCodec().encodeMessage(manifest);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final name = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        if (name == 'AssetManifest.bin') return binaryManifest;
        if (name == 'AssetManifest.json') {
          return ByteData.sublistView(Uint8List.fromList(utf8.encode('{}')));
        }
        return assets[name];
      });
  GoogleFonts.config.allowRuntimeFetching = false;
}

// El mapa queda fuera del alcance: no crear vistas nativas durante estas pruebas.
class _StaticMapsPlatform extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox.expand();
}

Widget shell({bool guest = false}) => MaterialApp(
  theme: AppTheme.light,
  home: MainShellScreen(
    isGuest: guest,
    onLogout: () {},
    onGuestLoginRequested: () {},
    onGuestRegisterRequested: () {},
    isDarkMode: false,
    onDarkModeChanged: (_) {},
  ),
);

// MainShell contiene actualizaciones periódicas (p. ej., mapas):
// pumpAndSettle nunca termina si siempre hay un nuevo frame programado.
// Avanzamos el reloj de prueba para que las rutas, diálogos y animaciones
// completen sus transiciones sin depender de la inactividad global del shell.
Future<void> pumpShellUi(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

// Los favoritos ya no se precargan como datos simulados en MainShell.
// Cada escenario declara explícitamente los libros que considera favoritos.
Future<void> seedTestFavorites(WidgetTester tester, List<int> ids) async {
  final home = tester.widget<HomeScreen>(
    find.byType(HomeScreen, skipOffstage: false),
  );
  for (final id in ids) {
    home.onToggleFavoriteBook(id);
  }
  await pumpShellUi(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleMapsFlutterPlatform.instance = _StaticMapsPlatform();
  });

  testWidgets(
    'detalle reconoce pertenencia y ofrece abrir un libro leído como acción secundaria',
    (tester) async {
      var additions = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: HomeBookDetailScreen(
            book: HomeTestBooks.books.first,
            currentUsername: '@demo',
            initialReview: null,
            onReviewSaved: (_, _) {},
            initiallyFavorite: true,
            onToggleFavorite: () {},
            onOpenOwnProfile: () {},
            onAddToLibrary: () => additions++,
            isGuest: false,
            onGuestRestrictedAction: () {},
            initialProgress: 100,
            readStatus: () => BookStatus.leido,
            onRead: () async => 100,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Añadir a mi biblioteca'), findsNothing);
      expect(find.text('Ya está en tu biblioteca'), findsOneWidget);
      expect(find.text('Continuar leyendo'), findsNothing);
      expect(
        find.widgetWithText(OutlinedButton, 'Abrir libro'),
        findsOneWidget,
      );
      expect(find.text('Leído'), findsOneWidget);
      expect(additions, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'MainShell conserva reseñas y favoritos al eliminar y evita duplicados al reincorporar',
    (tester) async {
      await tester.pumpWidget(shell());
      // Avanzar los frames sin esperar a que termine toda la actividad del shell.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await seedTestFavorites(tester, [1, 2]);
      var library = tester.widget<LibraryScreen>(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      final context = tester.element(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      final review = library.reviews[1];
      expect(library.favorites.contains(1), isTrue);
      final open = library.onReadBook!(context, 1);
      await pumpShellUi(tester);
      expect(find.byType(SimulatedReaderScreen), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('reader-scroll')),
        const Offset(0, -2000),
      );
      await pumpShellUi(tester);
      await tester.pageBack();
      await pumpShellUi(tester);
      await open;
      expect(library.statuses[1], BookStatus.leido);
      expect(library.progresses[1], 100);
      final cancelled = library.onRemoveBook!(context, 1);
      await pumpShellUi(tester);
      await tester.tap(find.text('Cancelar'));
      await pumpShellUi(tester);
      expect(await cancelled, isFalse);
      expect(library.progresses[1], 100);
      final remove = library.onRemoveBook!(context, 1);
      await pumpShellUi(tester);
      await tester.tap(find.text('Eliminar'));
      await pumpShellUi(tester);
      expect(await remove, isTrue);
      library = tester.widget<LibraryScreen>(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      expect(library.statuses.containsKey(1), isFalse);
      expect(library.progresses.containsKey(1), isFalse);
      expect(library.books.any((b) => b.id == 1), isTrue);
      expect(library.reviews[1], same(review));
      expect(library.favorites.contains(1), isTrue);
      expect(library.statuses[2], BookStatus.leido);
      final profile = tester.widget<ProfileScreen>(
        find.byType(ProfileScreen, skipOffstage: false),
      );
      expect(profile.reviews[1], same(review));
      expect(profile.favorites.contains(1), isTrue);
      expect(profile.statuses.containsKey(1), isFalse);
      final home = tester.widget<HomeScreen>(
        find.byType(HomeScreen, skipOffstage: false),
      );
      home.onAddBook!(Map<String, dynamic>.from(HomeTestBooks.books.first));
      home.onAddBook!(Map<String, dynamic>.from(HomeTestBooks.books.first));
      await pumpShellUi(tester);
      expect(library.books.where((b) => b.id == 1).length, 1);
      expect(library.statuses[1], BookStatus.porLeer);
      expect(library.progresses[1], 0);
      expect(library.reviews[1], same(review));
      expect(library.favorites.contains(1), isTrue);
      // Ejercitar la opción visible de eliminar y comprobar que se borra el seguimiento.
      home.onOpenLibrary();
      // Recorrer la transición: decoración y opacidad deben permanecer en rango.
      await tester.pump();
      for (var frame = 0; frame < 24; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      }
      await pumpShellUi(tester);
      await tester.tap(find.byKey(const ValueKey('book-options-5')));
      await pumpShellUi(tester);
      await tester.tap(find.text('Eliminar de Mi Biblioteca'));
      await pumpShellUi(tester);
      await tester.tap(find.text('Eliminar'));
      await pumpShellUi(tester);
      expect(library.statuses.containsKey(5), isFalse);
      expect(library.progresses.containsKey(5), isFalse);
      final external = library.books.firstWhere((b) => b.id == 5);
      home.onAddBook!({
        'id': external.id,
        'title': external.title,
        'authorReal': external.author,
        'year': external.year,
        'genre': external.genre,
        'isbn': external.isbn,
        'cover': external.cover,
        'synopsis': external.synopsis,
        'availability': 'EXTERNA',
      });
      await pumpShellUi(tester);
      final externalRead = library.onReadBook!(context, 5);
      await pumpShellUi(tester);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('current-page')))
            .controller!
            .text,
        '0',
      );
      await tester.tap(find.text('Cancelar'));
      await pumpShellUi(tester);
      await externalRead;
      // Las acciones existentes de reseñas y favoritos siguen conectadas con Perfil.
      home.onToggleFavoriteBook(2);
      await pumpShellUi(tester);
      expect(library.favorites.contains(2), isFalse);
      home.onToggleFavoriteBook(2);
      const savedReview = BookReview(
        rating: 4,
        text: 'Reseña de regresión',
        isPublic: false,
      );
      home.onReviewSaved(2, savedReview);
      await pumpShellUi(tester);
      expect(library.favorites.contains(2), isTrue);
      expect(profile.reviews[2], same(savedReview));
      expect(library.reviews[1], same(review));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('invitado no abre lector ni confirma eliminación', (
    tester,
  ) async {
    await tester.pumpWidget(shell(guest: true));
    // Avanzar los frames sin esperar a que termine toda la actividad del shell.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    final library = tester.widget<LibraryScreen>(
      find.byType(LibraryScreen, skipOffstage: false),
    );
    final context = tester.element(
      find.byType(LibraryScreen, skipOffstage: false),
    );
    expect(await library.onReadBook!(context, 1), isNull);
    await pumpShellUi(tester);
    expect(find.byType(SimulatedReaderScreen), findsNothing);
    Navigator.of(context).pop();
    await pumpShellUi(tester);
    expect(await library.onRemoveBook!(context, 1), isFalse);
    await pumpShellUi(tester);
    expect(find.text('¿Eliminar de Mi Biblioteca?'), findsNothing);
    expect(library.statuses, isEmpty);
    expect(library.progresses, isEmpty);
    Navigator.of(context).pop();
    await pumpShellUi(tester);
    final profile = tester.widget<ProfileScreen>(
      find.byType(ProfileScreen, skipOffstage: false),
    );
    expect(profile.statuses, isEmpty);
    expect(profile.progresses, isEmpty);
    final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(home.statuses, isEmpty);
    expect(home.progresses, isEmpty);
    expect(home.continueReadingProgress, 0);
    library.onStatusChanged(1, BookStatus.porLeer);
    await pumpShellUi(tester);
    Navigator.of(context).pop();
    await pumpShellUi(tester);
    // Cambiar solo el modo de acceso conserva el mismo estado del shell.
    await tester.pumpWidget(shell());
    // Avanzar los frames sin esperar a que termine toda la actividad del shell.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    final authenticated = tester.widget<LibraryScreen>(
      find.byType(LibraryScreen, skipOffstage: false),
    );
    expect(authenticated.statuses[1], BookStatus.leido);
    expect(authenticated.progresses[1], 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Finalizar en Home reemplaza solo por Leyendo y finalmente muestra vacío',
    (tester) async {
      await tester.pumpWidget(shell());
      // Avanzar los frames sin esperar a que termine toda la actividad del shell.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      HomeScreen home() => tester.widget<HomeScreen>(
        find.byType(HomeScreen, skipOffstage: false),
      );
      LibraryScreen library() => tester.widget<LibraryScreen>(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      ContinueReadingSection section() => tester.widget<ContinueReadingSection>(
        find.byType(ContinueReadingSection),
      );
      expect(home().continueReadingBook?.id, 7);
      const review = BookReview(rating: 5, text: 'Se conserva al finalizar');
      home().onReviewSaved(7, review);
      home().onToggleFavoriteBook(7);
      await pumpShellUi(tester);
      section().onFinish();
      await tester.pump();
      expect(library().statuses[7], BookStatus.leido);
      expect(library().progresses[7], 100);
      expect(library().books.any((book) => book.id == 7), isTrue);
      expect(library().reviews[7], same(review));
      expect(library().favorites.contains(7), isTrue);
      expect(home().continueReadingBook?.id, 5);
      expect(section().finishedReadingTitle, isNotNull);
      // Algunos flujos existentes notifican estado y progreso por separado.
      library().onStatusChanged(7, BookStatus.leido);
      library().onProgressChanged(7, 100);
      await tester.pump();
      expect(section().finishedReadingTitle, isNotNull);
      await tester.pump(const Duration(seconds: 2));
      expect(section().finishedReadingTitle, isNotNull);
      await tester.pump(const Duration(seconds: 1));
      await pumpShellUi(tester);
      expect(section().finishedReadingTitle, isNull);
      expect(section().book?.id, 5);
      expect(library().statuses[section().book!.id], BookStatus.leyendo);
      section().onFinish();
      await tester.pump();
      expect(library().statuses[5], BookStatus.leido);
      expect(library().progresses[5], 100);
      expect(home().continueReadingBook, isNull);
      await tester.pump(const Duration(seconds: 3));
      await pumpShellUi(tester);
      expect(section().finishedReadingTitle, isNull);
      expect(find.text('Comienza una nueva lectura'), findsOneWidget);
      expect(library().statuses.containsKey(7), isTrue);
      expect(library().reviews[7], same(review));
      expect(library().favorites.contains(7), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'estado manual sincroniza páginas y reanuda sin perder formato ni editorial',
    (tester) async {
      await tester.pumpWidget(shell());
      // Avanzar los frames sin esperar a que termine toda la actividad del shell.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await seedTestFavorites(tester, [1]);
      final library = tester.widget<LibraryScreen>(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      final profile = tester.widget<ProfileScreen>(
        find.byType(ProfileScreen, skipOffstage: false),
      );
      final context = tester.element(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      profile.onStatusChanged(5, BookStatus.leido);
      await tester.pump();
      expect(library.progresses[5], 100);
      profile.onStatusChanged(5, BookStatus.leyendo);
      await pumpShellUi(tester);
      expect(library.progresses[5], 30);
      final registration = library.onReadBook!(context, 5);
      await pumpShellUi(tester);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('current-page')))
            .controller!
            .text,
        '60',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('total-pages')))
            .controller!
            .text,
        '200',
      );
      expect(find.text('Físico'), findsOneWidget);
      expect(find.text('Editorial demo'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await pumpShellUi(tester);
      await registration;
      library.onStatusChanged(5, BookStatus.porLeer);
      await pumpShellUi(tester);
      expect(library.progresses[5], 0);
      expect(
        tester
            .widget<HomeScreen>(find.byType(HomeScreen))
            .continueReadingBook
            ?.id,
        7,
      );
      final pending = library.onReadBook!(context, 5);
      await pumpShellUi(tester);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('current-page')))
            .controller!
            .text,
        '0',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('total-pages')))
            .controller!
            .text,
        '200',
      );
      await tester.tap(find.text('Cancelar'));
      await pumpShellUi(tester);
      await pending;
      library.onStatusChanged(7, BookStatus.leido);
      await tester.pump();
      library.onStatusChanged(7, BookStatus.leyendo);
      await pumpShellUi(tester);
      expect(library.progresses[7], 65);
      expect(profile.statuses[7], BookStatus.leyendo);
      expect(library.reviews[1], isNotNull);
      expect(library.favorites.contains(1), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selector del detalle actualiza los textos Comenzar, Continuar y Abrir',
    (tester) async {
      await tester.pumpWidget(shell());
      // Avanzar los frames sin esperar a que termine toda la actividad del shell.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await seedTestFavorites(tester, [1]);
      final library = tester.widget<LibraryScreen>(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      final review = library.reviews[1];
      library.onStatusChanged(1, BookStatus.porLeer);
      await pumpShellUi(tester);
      tester
          .widget<HomeSearchSection>(find.byType(HomeSearchSection))
          .onBookTap(HomeTestBooks.books.first);
      await pumpShellUi(tester);
      expect(
        find.descendant(
          of: find.byType(HomeBookDetailScreen),
          matching: find.text('Comenzar a leer'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(HomeBookDetailScreen),
          matching: find.text('Continuar leyendo'),
        ),
        findsNothing,
      );
      final selector = find.descendant(
        of: find.byType(ReadingStatusField),
        matching: find.byType(DropdownButtonFormField<BookStatus>),
      );
      await Scrollable.ensureVisible(tester.element(selector), alignment: .5);
      await pumpShellUi(tester);
      await tester.tap(selector);
      await pumpShellUi(tester);
      await tester.tap(find.text('Leyendo').last);
      await pumpShellUi(tester);
      expect(library.statuses[1], BookStatus.leyendo);
      expect(
        find.descendant(
          of: find.byType(HomeBookDetailScreen),
          matching: find.text('Continuar leyendo'),
        ),
        findsOneWidget,
      );
      await Scrollable.ensureVisible(tester.element(selector), alignment: .5);
      await pumpShellUi(tester);
      await tester.tap(selector);
      await pumpShellUi(tester);
      await tester.tap(find.text('Leído').last);
      await pumpShellUi(tester);
      expect(library.statuses[1], BookStatus.leido);
      expect(library.progresses[1], 100);
      expect(
        find.descendant(
          of: find.byType(HomeBookDetailScreen),
          matching: find.text('Continuar leyendo'),
        ),
        findsNothing,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Abrir libro'),
        findsOneWidget,
      );
      expect(library.reviews[1], same(review));
      expect(library.favorites.contains(1), isTrue);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).hitTestable());
      await tester.pump(const Duration(seconds: 3));
      await pumpShellUi(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Comenzar inicia Leyendo sin scroll y abrir no reinicia lecturas existentes',
    (tester) async {
      await tester.pumpWidget(shell());
      // Avanzar los frames sin esperar a que termine toda la actividad del shell.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await seedTestFavorites(tester, [1]);
      LibraryScreen library() => tester.widget<LibraryScreen>(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      final context = tester.element(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      final review = library().reviews[1];
      library().onStatusChanged(1, BookStatus.porLeer);
      await pumpShellUi(tester);
      final start = library().onReadBook!(context, 1);
      expect(library().statuses[1], BookStatus.leyendo);
      expect(library().progresses[1], 0);
      await pumpShellUi(tester);
      expect(
        tester
            .widget<SimulatedReaderScreen>(find.byType(SimulatedReaderScreen))
            .initialStatus,
        BookStatus.leyendo,
      );
      expect(
        tester
            .widget<HomeScreen>(find.byType(HomeScreen, skipOffstage: false))
            .continueReadingBook
            ?.id,
        1,
      );
      await tester.pageBack();
      await pumpShellUi(tester);
      await start;
      expect(library().statuses[1], BookStatus.leyendo);
      expect(library().progresses[1], 0);
      final reading = library().onReadBook!(context, 7);
      await pumpShellUi(tester);
      await tester.pageBack();
      await pumpShellUi(tester);
      await reading;
      expect(library().statuses[7], BookStatus.leyendo);
      expect(library().progresses[7], 65);
      library().onStatusChanged(1, BookStatus.leido);
      await tester.pump();
      final completed = library().onReadBook!(context, 1);
      await pumpShellUi(tester);
      await tester.pageBack();
      await pumpShellUi(tester);
      await completed;
      expect(library().statuses[1], BookStatus.leido);
      expect(library().progresses[1], 100);
      expect(library().reviews[1], same(review));
      expect(library().favorites.contains(1), isTrue);
      await tester.pump(const Duration(seconds: 3));
      await pumpShellUi(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'el invitado ve el catálogo sin porcentajes ni controles personales',
    (tester) async {
      await tester.pumpWidget(shell(guest: true));
      // Avanzar los frames sin esperar a que termine toda la actividad del shell.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(home.progresses, isEmpty);
      expect(home.statuses, isEmpty);
      expect(home.continueReadingBook, isNull);
      expect(home.continueReadingProgress, 0);
      tester
          .widget<HomeSearchSection>(find.byType(HomeSearchSection))
          .onBookTap(HomeTestBooks.books.first);
      await pumpShellUi(tester);
      final detail = find.byType(HomeBookDetailScreen);
      expect(
        find.text(HomeTestBooks.books.first['title'] as String),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: detail, matching: find.byType(ReadingStatusField)),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data?.startsWith('Progreso:') ?? false),
        ),
        findsNothing,
      );
      final action = find.widgetWithText(FilledButton, 'Comenzar a leer');
      await Scrollable.ensureVisible(tester.element(action), alignment: .5);
      await pumpShellUi(tester);
      await tester.tap(action);
      await pumpShellUi(tester);
      expect(find.byType(SimulatedReaderScreen), findsNothing);
      Navigator.of(tester.element(detail)).pop();
      await pumpShellUi(tester);
      Navigator.of(tester.element(detail)).pop();
      await pumpShellUi(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'MainShell deriva porcentaje y estado de páginas y recupera el avance exacto',
    (tester) async {
      await tester.pumpWidget(shell());
      // Avanzar los frames sin esperar a que termine toda la actividad del shell.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await seedTestFavorites(tester, [1]);
      final library = tester.widget<LibraryScreen>(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      final context = tester.element(
        find.byType(LibraryScreen, skipOffstage: false),
      );
      final registration = library.onReadBook!(context, 5);
      await pumpShellUi(tester);
      await tester.enterText(find.byKey(const ValueKey('total-pages')), '3');
      await tester.enterText(find.byKey(const ValueKey('current-page')), '1');
      await tester.tap(find.text('Guardar'));
      await pumpShellUi(tester);
      await registration;
      expect(library.progresses[5], 33);
      library.onProgressChanged(5, 50);
      await pumpShellUi(tester);
      expect(library.progresses[5], 66);
      expect(library.statuses[5], BookStatus.leyendo);
      library.onProgressChanged(5, 99);
      await tester.pump();
      expect(library.progresses[5], 100);
      expect(library.statuses[5], BookStatus.leido);
      library.onStatusChanged(5, BookStatus.leyendo);
      await pumpShellUi(tester);
      expect(library.progresses[5], 66);
      final resumed = library.onReadBook!(context, 5);
      await pumpShellUi(tester);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('current-page')))
            .controller!
            .text,
        '2',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('total-pages')))
            .controller!
            .text,
        '3',
      );
      expect(find.text('Físico'), findsOneWidget);
      expect(find.text('Editorial demo'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await pumpShellUi(tester);
      await resumed;
      expect(library.reviews[1], isNotNull);
      expect(library.favorites.contains(1), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
