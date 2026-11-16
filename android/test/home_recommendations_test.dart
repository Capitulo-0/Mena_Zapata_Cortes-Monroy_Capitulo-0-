import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/auth/domain/auth_repository.dart';
import 'package:android/features/catalog/data/catalog_repository.dart';
import 'package:android/features/home/data/home_recommendation_repository.dart';
import 'package:android/features/home/presentation/home_recommendation_controller.dart';
import 'package:android/features/home/presentation/screens/home_screen.dart';
import 'package:android/features/home/presentation/screens/home_book_detail_screen.dart';
import 'package:android/features/home/presentation/widgets/library_recommendations_section.dart';
import 'package:android/features/home/presentation/widgets/main_header.dart';
import 'package:android/features/library/presentation/screens/library_screen.dart';

import 'support/auth_fakes.dart';
import 'catalog_test.dart' show CatalogFake, metadata;
import 'library_regression_test.dart' show installLocalTestAssets;

Map<String, dynamic> candidate(String id) => {
  ...ApiCatalogRepository.presentation(metadata(id)),
  'recommendationReason': 'Comparte autor con tu Biblioteca: Author One',
};
HomeRecommendations result(
  String id, {
  String status = 'NORMAL',
  bool personal = true,
  bool available = true,
}) => HomeRecommendations(
  candidateSetId: 'set-$id',
  personalized: personal,
  geminiAvailable: available,
  aiStatus: status,
  items: [candidate(id)],
  notice: personal ? 'Basadas en tu Biblioteca.' : 'Exploración general.',
);

class RecommendationsFake implements HomeRecommendationRepository {
  RecommendationsFake(this.accountScope);
  @override
  final String accountScope;
  @override
  bool get supportsGemini => true;
  final loads = <Completer<HomeRecommendations>>[];
  final enrichments = <Completer<HomeRecommendations>>[];
  @override
  Future<HomeRecommendations> load() {
    final c = Completer<HomeRecommendations>();
    loads.add(c);
    return c.future;
  }

  @override
  Future<HomeRecommendations> enrich(String candidateSetId) {
    final c = Completer<HomeRecommendations>();
    enrichments.add(c);
    return c.future;
  }
}

Widget home(
  RecommendationsFake repo, {
  CatalogRepository? catalog,
  GlobalKey<HomeScreenState>? homeKey,
  List<Map<String, dynamic>> library = const [],
  Map<int, BookStatus> statuses = const {},
}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    appBar: homeKey == null
        ? null
        : PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: MainHeader(
              compact: false,
              isGuest: false,
              onScannerTap: () {},
              onGeminiTap: () => homeKey.currentState?.showGeminiAssistant(),
            ),
          ),
    body: HomeScreen(
      key: homeKey,
      recommendationRepository: repo,
      catalogRepository: catalog,
      catalogBooks: library,
      statuses: statuses,
      isGuest: false,
      currentName: 'Lector',
      currentUsername: repo.accountScope,
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
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);

  test('repository sends only candidateSetId to authenticated backend and deduplicates real metadata', () async {
    final auth = FakeAuth()..identity = fixtureIdentity;
    addTearDown(auth.close);
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'candidateSetId': 'set',
          'personalized': true,
          'aiStatus': 'NORMAL',
          'items': [
            {'book': metadata('real'), 'reason': 'Relación verificada'},
            {'book': metadata('real'), 'reason': 'Duplicado'},
          ],
        }),
        200,
      );
    });
    addTearDown(client.close);
    final api = ApiClient(
      auth: auth,
      baseUrl: 'https://api.example.test',
      client: client,
    );
    final repository = ApiHomeRecommendationRepository(
      api,
      fixtureIdentity.uid,
    );
    final data = await repository.load();
    expect(data.items.single['googleVolumeId'], 'real');
    expect(data.items.single['author'], 'Author One, Author Two');
    expect(data.items.single['recommendationReason'], 'Relación verificada');
    await repository.enrich('set');
    expect(requests.first.url.path, '/api/me/recommendations');
    expect(requests.last.url.path, '/api/me/recommendations/gemini');
    expect(jsonDecode(requests.last.body), {'candidateSetId': 'set'});
    expect(
      requests.every(
        (r) => r.headers['Authorization'] == 'Bearer fixture-token',
      ),
      true,
    );
    expect(requests.every((r) => r.url.host == 'api.example.test'), true);
  });

  test(
    'account switch during HTTP response rejects data from previous account',
    () async {
      final auth = FakeAuth()..identity = fixtureIdentity;
      addTearDown(auth.close);
      final pending = Completer<http.Response>();
      final client = MockClient((_) => pending.future);
      addTearDown(client.close);
      final repo = ApiHomeRecommendationRepository(
        ApiClient(
          auth: auth,
          baseUrl: 'https://api.example.test',
          client: client,
        ),
        fixtureIdentity.uid,
      );
      final future = repo.load();
      final expectation = expectLater(future, throwsA(isA<ApiFailure>()));
      await Future<void>.delayed(Duration.zero);
      auth.emit(
        const AuthIdentity(
          uid: 'other',
          email: 'other@example.test',
          emailVerified: true,
        ),
      );
      pending.complete(http.Response(jsonEncode({'items': []}), 200));
      await expectation;
    },
  );

  test('normal requests are deduplicated and failure preserves same-query valid data', () async {
    final repo = RecommendationsFake('a');
    final controller = HomeRecommendationController(repo);
    addTearDown(controller.dispose);
    final load = controller.load();
    await controller.load();
    expect(repo.loads, hasLength(1));
    repo.loads.single.complete(result('real'));
    await load;
    final retry = controller.load();
    repo.loads.last.completeError(Exception('HTTP'));
    await retry;
    expect(controller.data!.items.single['googleVolumeId'], 'real');
    expect(controller.error, isNotNull);
  });

  test('Gemini is explicit, deduplicated and unavailable provider retains normal data', () async {
    final repo = RecommendationsFake('a');
    final controller = HomeRecommendationController(repo);
    addTearDown(controller.dispose);
    final load = controller.load();
    repo.loads.single.complete(result('real'));
    await load;
    expect(repo.enrichments, isEmpty);
    final ai = controller.enrich();
    await controller.enrich();
    expect(repo.enrichments, hasLength(1));
    repo.enrichments.single.complete(
      result('real', status: 'NOT_CONFIGURED', available: false),
    );
    await ai;
    expect(controller.data!.aiStatus, 'NORMAL');
    expect(controller.aiMessage, contains('no está disponible'));
    expect(controller.data!.geminiAvailable, isFalse);
    final reload = controller.load();
    repo.loads.last.complete(result('real'));
    await reload;
    final retry = controller.enrich();
    repo.enrichments.last.completeError(TimeoutException('slow'));
    await retry;
    expect(controller.data!.items.single['googleVolumeId'], 'real');
  });

  test(
    'invented candidate is rejected and verified Gemini result is accepted',
    () async {
      final repo = RecommendationsFake('a');
      final controller = HomeRecommendationController(repo);
      addTearDown(controller.dispose);
      final load = controller.load();
      repo.loads.single.complete(result('real'));
      await load;
      final bad = controller.enrich();
      repo.enrichments.last.complete(
        const HomeRecommendations(
          candidateSetId: 'set-real',
          personalized: true,
          aiStatus: 'ENRICHED',
          items: [
            {'googleVolumeId': 'invented'},
          ],
        ),
      );
      await bad;
      expect(controller.data!.items.single['googleVolumeId'], 'real');
      expect(controller.aiMessage, contains('no fue válida'));
      final valid = controller.enrich();
      repo.enrichments.last.complete(result('real', status: 'ENRICHED'));
      await valid;
      expect(controller.data!.aiStatus, 'ENRICHED');
    },
  );

  test('empty library/general exploration never calls Gemini', () async {
    final repo = RecommendationsFake('a');
    final controller = HomeRecommendationController(repo);
    addTearDown(controller.dispose);
    final load = controller.load();
    repo.loads.single.complete(result('general', personal: false));
    await load;
    await controller.enrich();
    expect(repo.enrichments, isEmpty);
  });

  test('disposed request cannot update session state or notify', () async {
    final repo = RecommendationsFake('old');
    final controller = HomeRecommendationController(repo);
    final load = controller.load();
    controller.dispose();
    repo.loads.single.complete(result('old'));
    await load;
    expect(controller.data, isNull);
  });

  for (final size in [const Size(360, 640), const Size(800, 1000)]) {
    for (final dark in [false, true]) {
      testWidgets('recommendations responsive size=$size dark=$dark', (
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
        repo.loads.single.complete(result('real'));
        await load;
        Map<String, dynamic>? opened;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: LibraryRecommendationsSection(
                  controller: controller,
                  onBookTap: (book) => opened = book,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Recomendado para ti'), findsOneWidget);
        await tester.tap(find.text('Real fixture real'));
        expect(opened!['googleVolumeId'], 'real');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'library changes including mutable statuses refresh Home and discard stale responses',
    (tester) async {
      final repo = RecommendationsFake('a');
      final library = [
        {'id': 1, 'title': 'Lectura', 'author': 'Autora'},
      ];
      final statuses = <int, BookStatus>{1: BookStatus.porLeer};
      await tester.pumpWidget(home(repo, library: library, statuses: statuses));
      expect(repo.loads, hasLength(1));
      statuses[1] = BookStatus.leido;
      await tester.pumpWidget(home(repo, library: library, statuses: statuses));
      expect(repo.loads, hasLength(2));
      repo.loads.last.complete(result('new'));
      await tester.pumpAndSettle();
      repo.loads.first.complete(result('old'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Real fixture new').first);
      expect(find.text('Real fixture old'), findsNothing);
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
      expect(repo.loads, hasLength(3));
      repo.loads.last.complete(result('refreshed'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'switching accounts clears previous recommendations immediately',
    (tester) async {
      final a = RecommendationsFake('a');
      final b = RecommendationsFake('b');
      await tester.pumpWidget(home(a));
      a.loads.single.complete(result('privateA'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(home(b));
      await tester.pump();
      expect(find.text('Real fixture privateA'), findsNothing);
      b.loads.single.complete(result('privateB'));
      await tester.pumpAndSettle();
      expect(find.text('Real fixture privateA'), findsNothing);
    },
  );

  testWidgets(
    'Gemini consent cancels without provider call then confirms and navigates real details',
    (tester) async {
      final repo = RecommendationsFake('a');
      final catalog = CatalogFake();
      await tester.pumpWidget(
        home(repo, catalog: catalog, homeKey: GlobalKey<HomeScreenState>()),
      );
      repo.loads.single.complete(result('real'));
      await tester.pumpAndSettle();
      final button = find.byTooltip('Selección inteligente con Gemini');
      expect(
        find.byKey(const ValueKey('recommendations-gemini')),
        findsNothing,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No se envían datos de tu cuenta'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(repo.enrichments, isEmpty);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solicitar selección'));
      await tester.pump();
      expect(repo.enrichments, hasLength(1));
      repo.enrichments.single.complete(result('real', status: 'ENRICHED'));
      await tester.pumpAndSettle();
      expect(
        find.text('La selección está aplicada a tus recomendaciones.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      final card = find.text('Real fixture real');
      await tester.scrollUntilVisible(
        card,
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(HomeBookDetailScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(repo.loads, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
