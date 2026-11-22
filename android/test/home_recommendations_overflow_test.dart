import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/home/data/home_recommendation_repository.dart';
import 'package:android/features/home/presentation/home_recommendation_controller.dart';
import 'package:android/features/home/presentation/widgets/home_network_cover.dart';
import 'package:android/features/home/presentation/widgets/library_recommendations_section.dart';
import 'package:android/features/home/presentation/widgets/main_header.dart';

import 'home_recommendations_test.dart' show RecommendationsFake;
import 'library_regression_test.dart' show installLocalTestAssets;

const titles = [
  'Las cadenas del rey',
  'SUAVE ES LA NOCHE',
  'El corazón del rey (Saga Rey I)',
  'Una historia extraordinariamente larga sobre los caminos de la memoria y los secretos del bosque',
  'Lectura con metadatos incompletos',
  'Las últimas páginas de una biblioteca al otro lado del océano y del tiempo',
];
List<Map<String, dynamic>> realisticBooks() => List.generate(
  titles.length,
  (index) => {
    'googleVolumeId': 'realistic-$index',
    'language': 'es',
    'title': titles[index],
    'author': index == 4
        ? null
        : 'María de los Ángeles Fernández de la Cruz y Alejandro de los Ríos',
    'cover': index == 4 ? null : '',
    'availability': index.isEven ? 'REGISTRO' : 'GRATIS',
    'rating': null,
    'recommendationReason': 'Comparte una categoría real de tu Biblioteca.',
  },
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
    for (final scale in [1.0, 1.3, 1.5]) {
      for (final dark in [false, true]) {
        testWidgets(
          'realistic recommendations ${size.width.toInt()}x${size.height.toInt()} scale=$scale dark=$dark',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final repo = RecommendationsFake('reader');
            final controller = HomeRecommendationController(repo);
            addTearDown(controller.dispose);
            final load = controller.load();
            repo.loads.single.complete(
              HomeRecommendations(
                candidateSetId: 'set',
                personalized: true,
                items: realisticBooks(),
                notice: 'Basadas en tu Biblioteca.',
              ),
            );
            await load;
            final selectedTitles = controller.data!.items
                .map((b) => b['title'] as String)
                .toList();
            Map<String, dynamic>? opened;
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  extendBody: true,
                  body: Column(
                    children: [
                      MainHeader(
                        compact: false,
                        isGuest: false,
                        onScannerTap: () {},
                        onGeminiTap: () {},
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 130),
                          children: [
                            LibraryRecommendationsSection(
                              controller: controller,
                              onBookTap: (book) => opened = book,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: SafeArea(
                    minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    child: SizedBox(
                      key: const ValueKey('floating-nav'),
                      height: 76,
                      child: Material(
                        color: Colors.brown,
                        child: Center(
                          child: Text(
                            'Inicio · Biblioteca · Perfil',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'Initial layout must have no Flutter errors',
            );
            expect(
              find.byKey(const ValueKey('recommendations-gemini')),
              findsNothing,
            );
            for (
              var page = 0;
              page < (controller.data!.items.length + 2) ~/ 3;
              page++
            ) {
              final covers = find.byType(HomeNetworkCover);
              final visibleCount = (controller.data!.items.length - page * 3)
                  .clamp(0, 3);
              expect(covers, findsNWidgets(visibleCount));
              final heights = <double>[];
              for (var i = 0; i < visibleCount; i++) {
                final card = find
                    .ancestor(of: covers.at(i), matching: find.byType(InkWell))
                    .first;
                heights.add(tester.getSize(card).height);
              }
              expect(
                heights.every((height) => (height - heights.first).abs() < .1),
                true,
                reason: 'All visible cards must have coherent heights',
              );
              expect(
                tester.takeException(),
                isNull,
                reason: 'Page $page must have no overflow',
              );
              if (page < (controller.data!.items.length + 2) ~/ 3 - 1) {
                final next = find.byIcon(Icons.chevron_right_rounded);
                await tester.ensureVisible(next);
                await tester.pumpAndSettle();
                await tester.tap(next);
                await tester.pumpAndSettle();
              }
            }
            final previous = find.byIcon(Icons.chevron_left_rounded);
            await tester.ensureVisible(previous);
            await tester.pumpAndSettle();
            await tester.tap(previous);
            await tester.pumpAndSettle();
            expect(find.text(selectedTitles.last), findsNothing);
            await tester.tap(find.byIcon(Icons.chevron_right_rounded));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'Previous and next must preserve valid layout',
            );
            expect(find.text(selectedTitles.last), findsOneWidget);
            final lastTitle = find.text(selectedTitles.last);
            await tester.ensureVisible(lastTitle);
            await tester.pumpAndSettle();
            expect(
              tester.getRect(lastTitle).bottom,
              lessThanOrEqualTo(
                tester.getRect(find.byKey(const ValueKey('floating-nav'))).top,
              ),
              reason:
                  'Outer scroll must expose content above floating navigation',
            );
            final lastCard = find
                .ancestor(of: lastTitle, matching: find.byType(InkWell))
                .first;
            expect(
              find.descendant(of: lastCard, matching: find.byType(Scrollable)),
              findsNothing,
              reason: 'Cards must never introduce their own vertical scroll',
            );
            await tester.tap(lastTitle);
            expect(
              opened!['googleVolumeId'],
              controller.data!.items.last['googleVolumeId'],
            );
            final rating = find.text('Sin valorar').last;
            await tester.ensureVisible(rating);
            await tester.pumpAndSettle();
            expect(
              tester.getRect(rating).bottom,
              lessThanOrEqualTo(
                tester.getRect(find.byKey(const ValueKey('floating-nav'))).top,
              ),
              reason:
                  'Lowest metadata must be reachable above floating navigation',
            );
            final reason = find
                .byTooltip('Comparte una categoría real de tu Biblioteca.')
                .first;
            await tester.ensureVisible(reason);
            await tester.pumpAndSettle();
            await tester.tap(reason);
            await tester.pump();
            expect(
              find.text('Comparte una categoría real de tu Biblioteca.'),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
