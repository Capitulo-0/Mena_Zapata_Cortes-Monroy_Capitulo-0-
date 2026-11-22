import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/catalog/data/catalog_repository.dart';
import 'package:android/features/home/presentation/screens/home_screen.dart';
import 'package:android/features/home/presentation/widgets/home_search_section.dart';
import 'package:android/features/gutendex/presentation/screens/gutendex_catalog_screen.dart';
import 'package:android/features/gutendex/presentation/screens/free_library_screen.dart';
import 'package:android/features/gutendex/models/free_work.dart';

import 'catalog_test.dart' show CatalogFake;
import 'library_regression_test.dart' show installLocalTestAssets;
import 'gutendex/support/gutendex_fakes.dart' show bookJson, pageJson;

// Home puede mantener frames programados (mapa/animaciones periódicas).
// Avanzamos el tiempo suficiente para las transiciones de navegación sin
// exigir que toda la pantalla quede completamente inactiva.
Future<void> pumpNavigationUi(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);

  Widget home(CatalogFake catalog, {required bool guest}) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: HomeScreen(
        catalogRepository: catalog,
        isGuest: guest,
        onGuestRestrictedAction: () {},
        onOpenLibrary: () {},
        onOpenWriter: () {},
        onOpenPoints: () {},
        onOpenProfile: () {},
        currentName: 'Lector fixture',
        currentUsername: '@fixture',
        reviews: const {},
        onReviewSaved: (_, _) {},
        favoriteBookIds: const {},
        onToggleFavoriteBook: (_) {},
        favoriteCommunityStoryIds: const {},
        onToggleCommunityStoryFavorite: (_) {},
        clubs: const [],
        joinedClubIds: const {},
        onToggleClub: (_) {},
        continueReadingBook: null,
        continueReadingProgress: 0,
        onContinueReadingProgressChanged: (_, _) {},
      ),
    ),
  );

  for (final guest in [false, true]) {
    for (final size in [const Size(800, 1000), const Size(360, 640)]) {
      testWidgets('Home -> Gutendex -> Home guest=$guest size=$size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final requests = <Uri>[];
        final client = MockClient((request) async {
          requests.add(request.url);
          expect(request.url.host, 'gutendex.com');
          expect(request.headers.containsKey('Authorization'), false);
          return http.Response(
            jsonEncode(
              request.url.path == '/books/1/' ? bookJson(1) : pageJson(),
            ),
            200,
          );
        });
        addTearDown(client.close);
        await http.runWithClient(() async {
          final catalog = CatalogFake();
          await tester.pumpWidget(home(catalog, guest: guest));
          catalog.pending['subject:fiction']!.complete(
            const CatalogPage([], null),
          );
          await pumpNavigationUi(tester);
          final entry = find.byKey(const ValueKey('home-gutendex-entry'));
          expect(find.text('Libros gratis'), findsOneWidget);
          expect(entry, findsOneWidget);
          expect(find.byType(HomeSearchSection), findsOneWidget);
          await tester.ensureVisible(entry);
          await tester.tap(entry);
          await pumpNavigationUi(tester);
          expect(find.byType(GutendexCatalogScreen), findsOneWidget);
          expect(
            requests,
            isEmpty,
            reason: 'Local library must not query Gutendex on first opening',
          );
          expect(find.text('Obras completas para leer aquí'), findsOneWidget);
          expect(find.text('Consultar catálogo en línea'), findsNothing);
          final first = find.byKey(ValueKey('free-work-${freeWorks.first.id}'));
          await tester.ensureVisible(first);
          await tester.tap(first);
          await pumpNavigationUi(tester);
          expect(find.byType(FreeWorkDetailScreen), findsOneWidget);
          expect(requests, isEmpty);
          // Volver desde la ruta activa, sin depender de tooltips "Back"
          // que pueden coexistir durante la transición.
          Navigator.of(tester.element(find.byType(FreeWorkDetailScreen))).pop();
          await pumpNavigationUi(tester);
          expect(find.byType(GutendexCatalogScreen), findsOneWidget);
          // Salir del catálogo hasta la ruta raíz (Home), evitando que
          // una ruta anterior todavía en transición retenga el catálogo.
          Navigator.of(tester.element(find.byType(GutendexCatalogScreen)))
              .popUntil((route) => route.isFirst);
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(GutendexCatalogScreen), findsNothing);
          expect(find.byType(HomeScreen), findsOneWidget);
          final scrollable = find
              .descendant(
                of: find.byType(HomeScreen),
                matching: find.byType(Scrollable),
              )
              .first;
          tester.state<ScrollableState>(scrollable).position.jumpTo(0);
          await pumpNavigationUi(tester);
          expect(find.byType(HomeSearchSection), findsOneWidget);
          expect(entry, findsOneWidget);
          expect(tester.takeException(), isNull);
          final homeField = find.descendant(
            of: find.byType(HomeSearchSection),
            matching: find.byType(TextField),
          );
          await tester.enterText(homeField, 'consulta');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump();
          expect(catalog.requests.last, 'all:consulta:0');
          catalog.pending['consulta']!.complete(const CatalogPage([], null));
          await pumpNavigationUi(tester);
          expect(find.byType(HomeSearchSection), findsOneWidget);
          expect(entry, findsNothing);
          await tester.ensureVisible(find.text('Volver'));
          await tester.tap(find.text('Volver'));
          await pumpNavigationUi(tester);
          expect(entry, findsOneWidget);
          expect(requests, isEmpty);
        }, () => client);
      });
    }
  }
}
