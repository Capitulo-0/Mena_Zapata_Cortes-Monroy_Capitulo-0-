import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/catalog/data/catalog_repository.dart';
import 'package:android/features/home/data/home_recommendation_repository.dart';
import 'package:android/features/home/data/local_recommendation_fallback.dart';
import 'package:android/features/home/presentation/home_recommendation_controller.dart';
import 'package:android/features/home/presentation/screens/home_screen.dart';
import 'package:android/features/gutendex/models/free_work.dart';
import 'package:android/features/gutendex/presentation/screens/free_library_screen.dart';

import 'library_regression_test.dart' show installLocalTestAssets;
import 'home_recommendations_test.dart' show RecommendationsFake;
import 'support/auth_fakes.dart';
import 'catalog_test.dart' show metadata;

class ImmediateRecommendations implements HomeRecommendationRepository {
  ImmediateRecommendations(this.response, {this.failure});
  HomeRecommendations response;
  Object? failure;
  @override
  String get accountScope => 'fixture';
  @override
  bool get supportsGemini => true;
  @override
  Future<HomeRecommendations> load() async {
    if (failure != null) {
      throw failure!;
    }
    return response;
  }

  @override
  Future<HomeRecommendations> enrich(String _) async => response;
}

Map<String, dynamic> realCandidate(int i) => {
  'googleVolumeId': 'remote$i',
  'title': 'Lectura de prueba $i',
  'author': 'Autora $i',
  'language': 'es',
  'genre': 'Cuentos',
  'cover': '',
};
final saved = [
  {
    'id': 1,
    'title': 'Lectura guardada de prueba',
    'author': 'Gustavo Adolfo Bécquer',
    'genre': 'Short Stories',
  },
];
HomeRecommendations remote(int count) => HomeRecommendations(
  candidateSetId: 'set',
  personalized: true,
  geminiAvailable: true,
  items: List.generate(count, realCandidate),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  test('two remote works complete five only with related reviewed local works and explicit IDs', () async {
    final result = await LocalRecommendationFallbackRepository(
      ImmediateRecommendations(remote(2)),
      saved,
    ).load();
    expect(result.items.length, 5);
    expect(
      result.items.take(2).every((b) => b['googleVolumeId'] != null),
      isTrue,
    );
    final local = result.items.where(
      (b) => b['recommendationSource'] == 'LOCAL_FREE',
    );
    expect(local.length, 3);
    for (final book in local) {
      expect(book.containsKey('googleVolumeId'), isFalse);
      final work = freeWorks.singleWhere((w) => w.id == book['freeWorkId']);
      expect(work.available, isTrue);
      expect(book['title'], work.title);
      expect(book['author'], work.author);
      expect(book['language'], 'es');
      expect(book['cover'], '');
      expect(
        book['recommendationReason'],
        contains('Biblioteca gratuita local'),
      );
    }
  });
  test('saved local IDs and normalized titles are excluded, with duplicate and English removal', () async {
    final owned = freeWorks.firstWhere(
      (w) => w.available && w.genre == 'Cuentos',
    );
    final data = remote(2);
    final source = HomeRecommendations(
      items: [
        ...data.items,
        data.items.first,
        {...realCandidate(9), 'language': 'en'},
      ],
    );
    final result = await LocalRecommendationFallbackRepository(
      ImmediateRecommendations(source),
      [
        ...saved,
        {
          'title': owned.title.toUpperCase(),
          'freeWorkId': owned.id,
          'author': owned.author,
          'genre': 'Cuentos',
        },
      ],
    ).load();
    expect(result.items.length, 5);
    expect(
      result.items.where((b) => b['googleVolumeId'] == 'remote0').length,
      1,
    );
    expect(result.items.every((b) => b['language'] == 'es'), isTrue);
    expect(result.items.any((b) => b['freeWorkId'] == owned.id), isFalse);
  });
  test('larger libraries without relevant local signals do not receive local padding', () async {
    final result = await LocalRecommendationFallbackRepository(
      ImmediateRecommendations(remote(2)),
      [
        {
          'title': 'Lectura ajena 2',
          'author': 'Otro',
          'genre': 'Cocina especializada',
        },
        {
          'title': 'Lectura ajena 3',
          'author': 'Otro',
          'genre': 'Cocina especializada',
        },
        {
          'title': 'Otra lectura',
          'author': 'Autor sin coincidencias',
          'genre': 'Cocina especializada',
        },
      ],
    ).load();
    expect(result.items.length, 2);
    expect(result.items.any((b) => b['freeWorkId'] != null), isFalse);
  });
  test(
    'five remote books remain preferred and no local substitutes are inserted',
    () async {
      final result = await LocalRecommendationFallbackRepository(
        ImmediateRecommendations(remote(5)),
        saved,
      ).load();
      expect(result.items.length, 5);
      expect(result.items.every((b) => b['googleVolumeId'] != null), isTrue);
    },
  );
  test('provider unavailable permits relevant offline works but authentication failure never does', () async {
    final source = ImmediateRecommendations(
      remote(0),
      failure: StateError('provider unavailable fixture'),
    );
    final result = await LocalRecommendationFallbackRepository(
      source,
      saved,
    ).load();
    expect(result.items.length, 5);
    expect(result.geminiAvailable, isFalse);
    source.failure = const ApiFailure(401, 'Session changed');
    await expectLater(
      LocalRecommendationFallbackRepository(source, saved).load(),
      throwsA(isA<ApiFailure>()),
    );
  });
  test(
    'Gemini subset of two cannot shrink five verified recommendations',
    () async {
      final source = RecommendationsFake('a');
      final controller = HomeRecommendationController(source);
      addTearDown(controller.dispose);
      final loading = controller.load();
      source.loads.single.complete(remote(5));
      await loading;
      final enriching = controller.enrich();
      source.enrichments.single.complete(
        HomeRecommendations(
          candidateSetId: 'set',
          personalized: true,
          geminiAvailable: true,
          aiStatus: 'ENRICHED',
          items: [realCandidate(1), realCandidate(0)],
        ),
      );
      await enriching;
      expect(controller.data!.items.length, 5);
      expect(controller.data!.items.first['googleVolumeId'], 'remote1');
    },
  );
  test('controller caps five and deduplicates IDs plus normalized titles without accepting English', () async {
    final source = ImmediateRecommendations(
      HomeRecommendations(
        items: [
          ...remote(6).items,
          realCandidate(0),
          {
            ...realCandidate(8),
            'title': 'The unavailable title',
            'language': 'en',
          },
        ],
      ),
    );
    final controller = HomeRecommendationController(source);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.data!.items.length, 5);
    expect(
      controller.data!.items.map((b) => b['googleVolumeId']).toSet().length,
      5,
    );
  });
  test('late account response including local fallback cannot overwrite a new controller', () async {
    final a = RecommendationsFake('a');
    final b = RecommendationsFake('b');
    final old = HomeRecommendationController(
      LocalRecommendationFallbackRepository(a, saved),
    );
    final pending = old.load();
    old.dispose();
    final current = HomeRecommendationController(
      LocalRecommendationFallbackRepository(b, []),
    );
    addTearDown(current.dispose);
    final load = current.load();
    b.loads.single.complete(remote(5));
    await load;
    a.loads.single.complete(remote(2));
    await pending;
    expect(old.data, isNull);
    expect(current.data!.items.length, 5);
    expect(
      current.data!.items.every((b) => b['googleVolumeId'] != null),
      isTrue,
    );
  });
  testWidgets(
    'real Home API flow exposes local origin and opens the existing free work detail',
    (t) async {
      final auth = FakeAuth()..identity = fixtureIdentity;
      addTearDown(auth.close);
      final client = MockClient(
        (r) async => http.Response(
          jsonEncode({
            'candidateSetId': 'set',
            'personalized': true,
            'items': [
              for (final id in ['one', 'two'])
                {'book': metadata(id), 'reason': 'Preferencia verificada'},
            ],
          }),
          200,
        ),
      );
      addTearDown(client.close);
      final catalog = ApiCatalogRepository(
        ApiClient(auth: auth, baseUrl: 'http://fixture.test', client: client),
      );
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HomeScreen(
              catalogRepository: catalog,
              catalogBooks: saved,
              isGuest: false,
              currentName: 'Lector',
              currentUsername: 'fixture',
              onGuestRestrictedAction: () {},
              onOpenLibrary: () {},
              onOpenWriter: () {},
              onOpenPoints: () {},
              onOpenProfile: () {},
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
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Gratis · local'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await t.scrollUntilVisible(
        find.text('Español · 5 obras'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Español · 5 obras'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Gratis · local'),
        -120,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text('Gratis · local').first);
      await t.pumpAndSettle();
      expect(find.byType(FreeWorkDetailScreen), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
