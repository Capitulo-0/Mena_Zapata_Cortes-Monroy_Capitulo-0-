import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/home/data/home_recommendation_repository.dart';
import 'package:android/features/home/presentation/home_recommendation_controller.dart';
import 'package:android/features/home/presentation/widgets/library_recommendations_section.dart';
import 'package:android/features/home/presentation/widgets/home_network_cover.dart';
import 'package:android/features/home/presentation/widgets/main_header.dart';

import 'home_recommendations_test.dart' show RecommendationsFake, result;
import 'library_regression_test.dart' show installLocalTestAssets;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  for (final size in [const Size(360, 640), const Size(390, 844)]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('compact recommendations $size dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = RecommendationsFake('a');
          final controller = HomeRecommendationController(repo);
          addTearDown(controller.dispose);
          final load = controller.load();
          repo.loads.single.complete(result('real', available: false));
          await load;
          int opened = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: SingleChildScrollView(
                    child: LibraryRecommendationsSection(
                      key: const ValueKey('compact-section'),
                      controller: controller,
                      onBookTap: (_) => opened++,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Recomendado para ti'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('recommendations-gemini')),
            findsNothing,
          );
          expect(
            find.textContaining('configurado en el servidor'),
            findsNothing,
          );
          expect(find.text('Real fixture real'), findsOneWidget);
          final reason =
              controller.data!.items.single['recommendationReason'] as String;
          expect(find.text(reason), findsNothing);
          final height = tester
              .getSize(find.byKey(const ValueKey('compact-section')))
              .height;
          // A single result now retains one third of the grid, instead of stretching.
          // Allow its real wrapped content; still bound the section and check layout errors below.
          final card = find
              .ancestor(
                of: find.byType(HomeNetworkCover),
                matching: find.byType(InkWell),
              )
              .first;
          expect(
            tester.getSize(card).width,
            closeTo((size.width - 32 - 14) / 3, .1),
          );
          expect(height, lessThan(scale == 1 ? 410 : 470));
          final info = find.byTooltip(reason);
          await tester.tap(info);
          await tester.pump();
          expect(find.text(reason), findsOneWidget);
          expect(opened, 0);
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Real fixture real'));
          expect(opened, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  for (final available in [false, true]) {
    testWidgets(
      'header always exposes the unique Gemini entry account=$available',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: MainHeader(
                compact: false,
                isGuest: !available,

                onScannerTap: () {},
                onGeminiTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byTooltip('Selección inteligente con Gemini'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'configured Gemini stays optional and absent legacy flag is safe',
    (tester) async {
      final repo = RecommendationsFake('a');
      final controller = HomeRecommendationController(repo);
      addTearDown(controller.dispose);
      final load = controller.load();
      repo.loads.single.complete(result('real'));
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
      expect(
        find.byKey(const ValueKey('recommendations-gemini')),
        findsNothing,
      );
      expect(repo.enrichments, isEmpty);
      expect(const HomeRecommendations().geminiAvailable, isFalse);
    },
  );
}
