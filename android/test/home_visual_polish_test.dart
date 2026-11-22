import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_colors.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/home/data/home_recommendation_repository.dart';
import 'package:android/features/home/presentation/home_recommendation_controller.dart';
import 'package:android/features/home/presentation/screens/home_book_detail_screen.dart';
import 'package:android/features/home/presentation/widgets/library_recommendations_section.dart';
import 'package:android/features/home/presentation/widgets/reading_clubs_section.dart';
import 'package:android/features/home/presentation/widgets/recommendation_explanation.dart';

import 'home_recommendations_test.dart'
    show RecommendationsFake, candidate, home;
import 'catalog_test.dart' show CatalogFake;
import 'library_regression_test.dart' show installLocalTestAssets;

const reason = 'Comparte autor con tu Biblioteca: Author One.';
const notice = 'Basadas en autores y categorías reales de tu Biblioteca.';
HomeRecommendations data({String status = 'NORMAL'}) => HomeRecommendations(
  candidateSetId: 'set',
  personalized: true,
  aiStatus: status,
  notice: notice,
  items: [
    {
      ...candidate('one'),
      'title': 'Las cadenas del rey',
      'recommendationReason': reason,
    },
    {
      ...candidate('two'),
      'title': 'SUAVE ES LA NOCHE',
      'recommendationReason': 'Relacionado con una categoría: Fiction.',
    },
    {
      ...candidate('three'),
      'title': 'El corazón del rey (Saga Rey I)',
      'recommendationReason': 'Comparte un autor de tus lecturas.',
    },
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('Home visual polish $size dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = RecommendationsFake('reader');
          final base = home(repo, catalog: CatalogFake()) as MaterialApp;
          final scaffold = base.home! as Scaffold;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: scaffold.body,
                extendBody: true,
                bottomNavigationBar: SafeArea(
                  minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: SizedBox(
                    key: const ValueKey('floating-nav'),
                    height: 76,
                    child: Material(
                      color: AppColors.deep,
                      child: Center(
                        child: Text(
                          'Inicio · Biblioteca · Perfil',
                          style: TextStyle(
                            color: AppColors.background,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          repo.loads.single.complete(data());
          await tester.pumpAndSettle();
          final entry = find.byKey(const ValueKey('home-gutendex-entry'));
          expect(entry, findsOneWidget);
          final button = tester.widget<OutlinedButton>(entry);
          expect(
            button.style!.backgroundColor!.resolve({}),
            dark ? AppColors.darkDeep : AppColors.deep,
          );
          expect(
            button.style!.foregroundColor!.resolve({}),
            AppColors.background,
          );
          expect(find.text('Catálogo Project Gutenberg'), findsOneWidget);
          expect(button.onPressed, isNotNull);
          final info = find.byTooltip(reason);
          await tester.scrollUntilVisible(
            info,
            120,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(info);
          await tester.pumpAndSettle();
          await tester.tap(info);
          await tester.pumpAndSettle();
          final panel = find.byType(RecommendationExplanation);
          expect(panel, findsOneWidget);
          expect(find.text(reason), findsOneWidget);
          expect(find.byType(SnackBar), findsNothing);
          expect(find.byType(HomeBookDetailScreen), findsNothing);
          final decoration =
              tester
                      .widget<Container>(
                        find
                            .descendant(
                              of: panel,
                              matching: find.byType(Container),
                            )
                            .first,
                      )
                      .decoration!
                  as BoxDecoration;
          expect(decoration.color, AppColors.background);
          expect(
            tester.widget<Text>(find.text(reason)).style!.color,
            AppColors.deep,
          );
          expect(tester.getSize(panel).height, lessThanOrEqualTo(112));
          expect(
            tester
                .getRect(panel)
                .overlaps(
                  tester.getRect(find.byKey(const ValueKey('floating-nav'))),
                ),
            false,
          );
          final clubs = find.byType(ReadingClubsSection);
          expect(clubs, findsOneWidget);
          expect(tester.getRect(panel).overlaps(tester.getRect(clubs)), false);
          expect(find.text('Google Books'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('recommendations-refresh')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('recommendations-gemini')),
            findsNothing,
          );
          expect(repo.loads, hasLength(1));
          expect(repo.enrichments, isEmpty);
          await tester.tap(find.byTooltip('Cerrar explicación'));
          await tester.pumpAndSettle();
          expect(panel, findsNothing);
          final sourceInfo = find.byTooltip(notice);
          await tester.ensureVisible(sourceInfo);
          await tester.pumpAndSettle();
          await tester.tap(sourceInfo);
          await tester.pumpAndSettle();
          expect(panel, findsOneWidget);
          expect(find.text(notice), findsOneWidget);
          expect(find.text(reason), findsNothing);
          await tester.tap(find.byTooltip('Cerrar explicación'));
          await tester.pumpAndSettle();
          expect(panel, findsNothing);
          expect(repo.loads, hasLength(1));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets(
    'explanation announces real content and can be closed with the keyboard',
    (tester) async {
      final repo = RecommendationsFake('reader');
      final controller = HomeRecommendationController(repo);
      addTearDown(controller.dispose);
      final load = controller.load();
      repo.loads.single.complete(data());
      await load;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: LibraryRecommendationsSection(
                controller: controller,
                onBookTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(reason));
      await tester.pumpAndSettle();
      final panel = find.byType(RecommendationExplanation);
      final semantics = tester.widget<Semantics>(
        find.descendant(of: panel, matching: find.byType(Semantics)).first,
      );
      expect(semantics.properties.liveRegion, true);
      expect(find.text(reason), findsOneWidget);
      final close = find.descendant(
        of: panel,
        matching: find.byIcon(Icons.close),
      );
      Focus.of(tester.element(close)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Google Books attribution remains visible for AI-selected candidates',
    (tester) async {
      final repo = RecommendationsFake('reader');
      final controller = HomeRecommendationController(repo);
      addTearDown(controller.dispose);
      final load = controller.load();
      repo.loads.single.complete(data(status: 'ENRICHED'));
      await load;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: LibraryRecommendationsSection(
                controller: controller,
                onBookTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Google Books'), findsOneWidget);
      expect(find.text('Selección con Gemini'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recommendations-refresh')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recommendations-gemini')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
