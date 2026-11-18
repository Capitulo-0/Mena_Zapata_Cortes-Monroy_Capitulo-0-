import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/home/data/recommendation_titles.dart';
import 'package:android/features/home/data/home_recommendation_repository.dart';
import 'package:android/features/home/data/local_recommendation_fallback.dart';
import 'package:android/features/home/presentation/home_recommendation_controller.dart';
import 'package:android/features/home/presentation/widgets/library_recommendations_section.dart';
import 'package:android/features/home/presentation/widgets/recommended_books_section.dart';
import 'package:android/features/gutendex/models/free_work.dart';
import 'package:android/features/gutendex/presentation/widgets/free_work_cover.dart';
import 'package:android/features/gutendex/presentation/screens/free_library_screen.dart';

import 'home_recommendations_five_test.dart'
    show ImmediateRecommendations, realCandidate;
import 'library_regression_test.dart' show installLocalTestAssets;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  test('valid ISBN10 and ISBN13 identities and transitive editions collapse before final count', () {
    expect(RecommendationTitles.isbn('0-306-40615-2'), '9780306406157');
    expect(RecommendationTitles.isbn('9780000000001'), isNull);
    final a = {
      ...realCandidate(1),
      'title': 'La misma obra',
      'isbn': '0306406152',
    };
    final b = {
      ...realCandidate(2),
      'title': 'La misma obra (Edición ilustrada)',
      'isbn': '9780140328721',
    };
    final c = {
      ...realCandidate(3),
      'title': 'Otro título',
      'isbn': '9780140328721',
    };
    expect(RecommendationTitles.unique([a, b, c]), hasLength(1));
    expect(
      RecommendationTitles.unique([
        realCandidate(1),
        {...realCandidate(1), 'title': 'Otro nombre'},
        realCandidate(2),
      ]),
      hasLength(2),
    );
  });
  test('Google Gemini and local aliases are deduplicated together, without merged metadata', () {
    final local = freeWorks.first;
    final maps = [
      {...realCandidate(0), 'title': local.title, 'author': local.author},
      {
        'freeWorkId': local.id,
        'title': local.title,
        'author': local.author,
        'recommendationSource': 'LOCAL_FREE',
      },
      {...realCandidate(0), 'title': local.title.toUpperCase()},
      realCandidate(2),
    ];
    final unique = RecommendationTitles.unique(maps);
    expect(unique, hasLength(2));
    expect(
      unique.every((b) => maps.any((source) => identical(source, b))),
      isTrue,
    );
  });
  test('small-library local classics are real distinct Spanish works and stable within the session', () async {
    for (final count in [0, 1, 2]) {
      final source = ImmediateRecommendations(const HomeRecommendations());
      final repo = LocalRecommendationFallbackRepository(
        source,
        List.generate(
          count,
          (i) => {
            'title': 'Guardado $i',
            'author': 'Otro',
            'genre': 'Sin metadatos',
          },
        ),
      );
      final a = await repo.load(), b = await repo.load();
      expect(a.items, hasLength(5));
      if (count==0) { expect(a.personalized,isFalse); }
      expect(
        a.items.map((m) => m['freeWorkId']).toList(),
        b.items.map((m) => m['freeWorkId']).toList(),
      );
      expect(a.items.map((m) => m['title']).toSet(), hasLength(5));
      for (final item in a.items) {
        expect(
          freeWorks.any(
            (w) => w.id == item['freeWorkId'] && w.title == item['title'],
          ),
          isTrue,
        );
        expect(item['language'], 'es');
      }
    }
  });
  testWidgets(
    'finite pages show five distinct stable-key cards exactly once going forward',
    (t) async {
      final data = HomeRecommendations(items: List.generate(5, realCandidate));
      final controller = HomeRecommendationController(
        ImmediateRecommendations(data),
      );
      addTearDown(controller.dispose);
      await controller.load();
      await t.pumpWidget(
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
      await t.pumpAndSettle();
      List<String> shown() => t
          .widget<RecommendedBooksSection>(find.byType(RecommendedBooksSection))
          .books
          .where(
            (b) => find
                .byKey(
                  ValueKey(
                    'recommendation-${RecommendationTitles.identity(b)}',
                  ),
                )
                .evaluate()
                .isNotEmpty,
          )
          .map((b) => b['googleVolumeId'] as String)
          .toList();
      final first = shown();
      expect(first, hasLength(3));
      await t.tap(find.byIcon(Icons.chevron_right_rounded));
      await t.pumpAndSettle();
      final second = shown();
      expect(second, hasLength(2));
      expect(first.toSet().intersection(second.toSet()), isEmpty);
      expect({...first, ...second}, hasLength(5));
      await t.tap(find.byIcon(Icons.chevron_right_rounded));
      await t.pumpAndSettle();
      expect(shown(), second);
      await t.tap(find.byIcon(Icons.chevron_left_rounded));
      await t.pumpAndSettle();
      expect(shown(), first);
      expect(find.text('Español · 5 obras'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'fifty ID-bound offline cover compositions produce fifty different rendered images',
    (t) async {
      expect(freeWorks, hasLength(50));
      expect(freeWorks.map(FreeWorkCover.signature).toSet(), hasLength(50));
      final hashes = <String>{};
      final key = GlobalKey();
      for (final work in freeWorks) {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: 120,
                    height: 174,
                    child: FreeWorkCover(work: work),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.byKey(ValueKey('free-cover-${work.id}')), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        final digest = await t.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return sha256.convert(bytes!.buffer.asUint8List()).toString();
        });
        hashes.add(digest!);
        expect(t.takeException(), isNull);
      }
      expect(hashes, hasLength(50));
    },
  );
  testWidgets(
    'local search and edition show the same ID-bound cover and no external invitation',
    (t) async {
      final work = freeWorks.first;
      await t.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const FreeLibraryScreen()),
      );
      await t.pumpAndSettle();
      expect(find.text('Consultar catálogo en línea'), findsNothing);
      expect(find.textContaining('requiere internet'), findsNothing);
      await t.enterText(
        find.byKey(const ValueKey('free-library-search')),
        work.title,
      );
      await t.pumpAndSettle();
      expect(find.byKey(ValueKey('free-cover-${work.id}')), findsOneWidget);
      await t.tap(find.byKey(ValueKey('free-work-${work.id}')));
      await t.pumpAndSettle();
      expect(find.byType(FreeWorkDetailScreen), findsOneWidget);
      expect(find.byKey(ValueKey('free-cover-${work.id}')), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Fuente y condiciones'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Fuente y condiciones'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  test('a mismatched local ID/title cannot borrow another work cover', () {
    expect(
      FreeWorkCover.fromBook({
        'freeWorkId': freeWorks.first.id,
        'title': 'Otro libro',
        'author': freeWorks.first.author,
      }),
      isNull,
    );
  });
}
