import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/home/data/home_recommendation_repository.dart';
import 'package:android/features/home/presentation/home_recommendation_controller.dart';
import 'package:android/features/home/presentation/screens/home_book_detail_screen.dart';
import 'package:android/features/home/presentation/widgets/home_network_cover.dart';
import 'package:android/features/home/presentation/widgets/recommended_books_section.dart';
import 'package:android/features/home/presentation/widgets/library_recommendations_section.dart';
import 'package:android/features/home/presentation/widgets/recommendation_explanation.dart';

import 'home_recommendations_test.dart' show RecommendationsFake, home;
import 'home_recommendations_overflow_test.dart' show realisticBooks;
import 'catalog_test.dart' show CatalogFake;
import 'library_regression_test.dart' show installLocalTestAssets;

HomeRecommendations response(int count, int revision) => HomeRecommendations(
  candidateSetId: 'set-$revision',
  personalized: true,
  items: realisticBooks().take(count).toList(),
  notice: 'Basadas en tu Biblioteca.',
);
List<Finder> cards() {
  final covers = find.descendant(
    of: find.byType(RecommendedBooksSection),
    matching: find.byType(HomeNetworkCover),
  );
  return List.generate(
    covers.evaluate().length,
    (index) => find
        .ancestor(of: covers.at(index), matching: find.byType(InkWell))
        .first,
  );
}

Widget frame(
  HomeRecommendationController controller, {
  bool dark = false,
  double scale = 1,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        LibraryRecommendationsSection(
          controller: controller,
          onBookTap: (_) {},
        ),
      ],
    ),
  ),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  testWidgets('refresh regression keeps width across three and two', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = RecommendationsFake('reader');
    final controller = HomeRecommendationController(repo);
    addTearDown(controller.dispose);
    final load = controller.load();
    repo.loads.single.complete(response(3, 0));
    await load;
    await tester.pumpWidget(frame(controller));
    await tester.pumpAndSettle();
    final original = tester.getSize(cards().first).width;
    final refresh = controller.load();
    repo.loads.last.complete(response(2, 1));
    await refresh;
    await tester.pumpAndSettle();
    expect(cards(), hasLength(2));
    expect(
      tester.getSize(cards().first).width,
      closeTo(original, .1),
      reason: 'A valid two-book response must not stretch cards',
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.3, 1.5]) {
        testWidgets('refresh sequences $size dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = RecommendationsFake('reader');
          final controller = HomeRecommendationController(repo);
          addTearDown(controller.dispose);
          final load = controller.load();
          repo.loads.single.complete(response(3, 0));
          await load;
          await tester.pumpWidget(frame(controller, dark: dark, scale: scale));
          await tester.pumpAndSettle();
          final width = tester.getSize(cards().first).width;
          final left = tester.getRect(cards().first).left;
          void verify(int count) {
            final visible = cards();
            expect(visible, hasLength(min(3, count)));
            for (final card in visible) {
              expect(tester.getSize(card).width, closeTo(width, .1));
              expect(
                tester.getSize(card).height,
                closeTo(tester.getSize(visible.first).height, .1),
              );
            }
            if (visible.isNotEmpty) {
              expect(tester.getRect(visible.first).left, closeTo(left, .1));
            }
            expect(controller.data!.items, hasLength(count));
            expect(
              tester.takeException(),
              isNull,
              reason: 'No layout errors at count $count',
            );
          }

          verify(3);
          int previous = 3;
          for (final count in [2, 3, 1, 3, 0, 3, 5, 2, 3]) {
            final button = find.byKey(
              const ValueKey('recommendations-refresh'),
            );
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            final requests = repo.loads.length;
            await tester.tap(button);
            await tester.pump();
            expect(repo.loads, hasLength(requests + 1));
            expect(controller.loading, true);
            verify(previous);
            expect(tester.widget<IconButton>(button).onPressed, isNull);
            await controller.load();
            expect(repo.loads, hasLength(requests + 1));
            repo.loads.last.complete(response(count, requests));
            await tester.pumpAndSettle();
            verify(count);
            if (count == 0) {
              expect(
                find.textContaining('Aún no hay sugerencias relacionadas'),
                findsOneWidget,
              );
            }
            if (count == 5) {
              final next = find.byIcon(Icons.chevron_right_rounded);
              await tester.ensureVisible(next);
              await tester.pumpAndSettle();
              await tester.tap(next);
              await tester.pumpAndSettle();
              await tester.tap(next);
              await tester.pumpAndSettle();
              expect(
                find.text(realisticBooks()[4]['title'] as String),
                findsOneWidget,
              );
              verify(5);
              await tester.tap(find.byIcon(Icons.chevron_left_rounded));
              await tester.pumpAndSettle();
              verify(5);
            }
            previous = count;
          }
          final info = find
              .byTooltip('Comparte una categoría real de tu Biblioteca.')
              .first;
          await tester.ensureVisible(info);
          await tester.pumpAndSettle();
          await tester.tap(info);
          await tester.pumpAndSettle();
          expect(find.byType(RecommendationExplanation), findsOneWidget);
          expect(
            find.text('Comparte una categoría real de tu Biblioteca.'),
            findsOneWidget,
          );
          await tester.tap(find.byTooltip('Cerrar explicación'));
          await tester.pumpAndSettle();
          verify(3);
        });
      }
    }
  }
  testWidgets('Home refresh to two retains width and real detail navigation', (
    tester,
  ) async {
    final repo = RecommendationsFake('reader');
    await tester.pumpWidget(home(repo, catalog: CatalogFake()));
    repo.loads.single.complete(response(3, 0));
    await tester.pumpAndSettle();
    final original = tester.getSize(cards().first).width;
    final refresh = find.byKey(const ValueKey('recommendations-refresh'));
    await tester.scrollUntilVisible(
      refresh,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(refresh);
    await tester.pumpAndSettle();
    await tester.tap(refresh);
    await tester.pump();
    repo.loads.last.complete(response(2, 1));
    await tester.pumpAndSettle();
    // Refresh is below the row; reveal the lazily built group before measuring it.
    await tester.scrollUntilVisible(
      find.text('Las cadenas del rey'),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(cards(), hasLength(2));
    expect(tester.getSize(cards().first).width, closeTo(original, .1));
    final title = find.text('Las cadenas del rey');
    await tester.scrollUntilVisible(
      title,
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(find.byType(HomeBookDetailScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await tester.pumpAndSettle();
    expect(cards(), hasLength(2));
    expect(tester.getSize(cards().first).width, closeTo(original, .1));
    expect(repo.loads, hasLength(2));
    expect(tester.takeException(), isNull);
  });
  test('valid smaller responses and deliberate title dedup are distinguished from state loss', () async {
    final repo = RecommendationsFake('reader');
    final controller = HomeRecommendationController(repo);
    addTearDown(controller.dispose);
    final first = controller.load();
    repo.loads.last.complete(response(3, 0));
    await first;
    final second = controller.load();
    repo.loads.last.complete(response(2, 1));
    await second;
    expect(controller.data!.items.map((b) => b['googleVolumeId']), [
      'realistic-0',
      'realistic-1',
    ]);
    final duplicate = HomeRecommendations(
      candidateSetId: 'duplicate',
      items: [
        ...realisticBooks().take(2),
        {
          ...realisticBooks().first,
          'googleVolumeId': 'other-edition',
          'title': 'LAS CADENAS DEL REY (Edition)',
        },
      ],
    );
    final third = controller.load();
    repo.loads.last.complete(duplicate);
    await third;
    expect(duplicate.items, hasLength(3));
    expect(controller.data!.items, hasLength(2));
  });
  test('failed refresh conserves the previous valid set', () async {
    final repo = RecommendationsFake('reader');
    final controller = HomeRecommendationController(repo);
    addTearDown(controller.dispose);
    final first = controller.load();
    repo.loads.last.complete(response(3, 0));
    await first;
    final previous = controller.data!;
    final refresh = controller.load();
    repo.loads.last.completeError(Exception('network'));
    await refresh;
    expect(controller.data, same(previous));
    expect(controller.error, isNotNull);
  });
}
