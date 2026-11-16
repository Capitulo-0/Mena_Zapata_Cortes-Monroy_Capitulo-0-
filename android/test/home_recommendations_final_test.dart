import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/home/data/home_recommendation_repository.dart';
import 'package:android/features/home/data/recommendation_titles.dart';
import 'package:android/features/home/presentation/home_recommendation_controller.dart';
import 'package:android/features/home/presentation/dialogs/home_gemini_selection_dialog.dart';
import 'package:android/features/home/presentation/screens/home_screen.dart';
import 'package:android/features/home/presentation/widgets/main_header.dart';

import 'home_recommendations_test.dart'
    show RecommendationsFake, result, candidate, home;
import 'catalog_test.dart' show metadata;
import 'support/auth_fakes.dart';
import 'library_regression_test.dart' show installLocalTestAssets;

Widget entry(HomeRecommendationController controller, {bool dark = false}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: MainHeader(
              compact: false,
              isGuest: false,
              onScannerTap: () {},
              onGeminiTap: () => showDialog<void>(
                context: context,
                builder: (_) => HomeGeminiSelectionDialog(
                  controller: controller,
                  isCurrent: () => true,
                ),
              ),
            ),
          ),
          body: const SizedBox(),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);

  test('recommendation title normalization handles accents punctuation whitespace and editorial suffixes', () {
    final keys = [
      'Café de otoño!',
      'Café de otoño (Edición ilustrada) [Spanish Edition]',
      'CAFE   DE OTOÑO (Edición ilustrada)',
      'Cafe\u0301 de otoño: Una novela',
      '  Café-de-otoño [Spanish Edition] ',
    ].map(RecommendationTitles.key).toSet();
    expect(keys, {'cafe de otono'});
    expect(
      RecommendationTitles.key('Obra: Tomo 1'),
      isNot(RecommendationTitles.key('Obra: Tomo 2')),
    );
  });
  test('richer real edition wins without merging or inventing metadata', () {
    final first = {...candidate('a'), 'title': 'Café', 'author': 'Autora A'};
    final best = {
      ...candidate('b'),
      'title': 'CAFE (Edition)',
      'author': 'Autora B',
      'cover': 'https://covers.example.test/book.jpg',
      'isbn': '9780306406157',
    };
    final unique = RecommendationTitles.unique([
      first,
      best,
      candidate('other'),
    ]);
    expect(unique, hasLength(2));
    expect(identical(unique.first, best), true);
    expect(first['title'], 'Café');
    expect(unique.first['author'], 'Autora B');
  });
  test(
    'normal and Gemini final states have one visible normalized title',
    () async {
      final repo = RecommendationsFake('a');
      final controller = HomeRecommendationController(repo);
      addTearDown(controller.dispose);
      final load = controller.load();
      repo.loads.single.complete(
        HomeRecommendations(
          candidateSetId: 'set',
          personalized: true,
          geminiAvailable: true,
          items: [
            {...candidate('a'), 'title': 'Café'},
            {...candidate('b'), 'title': 'CAFE (Edition)'},
            candidate('other'),
          ],
        ),
      );
      await load;
      expect(controller.data!.items, hasLength(2));
      final ai = controller.enrich();
      repo.enrichments.single.complete(
        HomeRecommendations(
          candidateSetId: 'set',
          personalized: true,
          geminiAvailable: true,
          aiStatus: 'ENRICHED',
          items: [controller.data!.items.first, controller.data!.items.first],
        ),
      );
      await ai;
      expect(controller.data!.items, hasLength(1));
      expect(controller.data!.items.single['title'], 'Café');
    },
  );

  for (final size in [const Size(360, 640), const Size(390, 844)]) {
    for (final dark in [false, true]) {
      for (final available in [false, true]) {
        testWidgets('header dialog $size dark=$dark available=$available', (
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
          repo.loads.single.complete(result('real', available: available));
          await load;
          await tester.pumpWidget(entry(controller, dark: dark));
          await tester.pumpAndSettle();
          expect(
            find.byTooltip('Selección inteligente con Gemini'),
            findsOneWidget,
          );
          await tester.tap(find.byTooltip('Selección inteligente con Gemini'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('gemini-selection-dialog')),
            findsOneWidget,
          );
          expect(find.byType(TextField), findsNothing);
          expect(
            find.byKey(const ValueKey('gemini-request')),
            available ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const ValueKey('gemini-unavailable')),
            available ? findsNothing : findsOneWidget,
          );
          expect(repo.enrichments, isEmpty);
          expect(
            find.byKey(const ValueKey('recommendations-gemini')),
            findsNothing,
          );
          await tester.tap(find.byKey(const ValueKey('gemini-close')));
          await tester.pumpAndSettle();
          expect(repo.enrichments, isEmpty);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  for (final status in ['QUOTA', 'TIMEOUT', 'HTTP_ERROR']) {
    testWidgets(
      'Gemini $status stays in the dialog and retains normal recommendations',
      (tester) async {
        final repo = RecommendationsFake('a');
        final controller = HomeRecommendationController(repo);
        addTearDown(controller.dispose);
        final load = controller.load();
        repo.loads.single.complete(result('real'));
        await load;
        await tester.pumpWidget(entry(controller));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Selección inteligente con Gemini'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('gemini-request')));
        await tester.pump();
        expect(repo.enrichments, hasLength(1));
        repo.enrichments.single.complete(
          result('real', status: status, available: status != 'HTTP_ERROR'),
        );
        await tester.pumpAndSettle();
        expect(controller.data!.aiStatus, 'NORMAL');
        expect(controller.data!.items.single['googleVolumeId'], 'real');
        expect(
          find.byKey(const ValueKey('gemini-selection-dialog')),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsNothing);
        await tester.tap(find.byKey(const ValueKey('gemini-close')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'available header selection uses the real authenticated backend contract with a fake server',
    (tester) async {
      final auth = FakeAuth()..identity = fixtureIdentity;
      addTearDown(auth.close);
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'candidateSetId': 'set',
            'personalized': true,
            'geminiAvailable': true,
            'aiStatus': request.method == 'POST' ? 'ENRICHED' : 'NORMAL',
            'items': [
              {
                'book': metadata('real'),
                'reason': 'Comparte autor con tu Biblioteca: Author One',
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      final controller = HomeRecommendationController(
        ApiHomeRecommendationRepository(
          ApiClient(
            auth: auth,
            baseUrl: 'https://api.example.test',
            client: client,
          ),
          fixtureIdentity.uid,
        ),
      );
      addTearDown(controller.dispose);
      await controller.load();
      await tester.pumpWidget(entry(controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Selección inteligente con Gemini'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(find.byKey(const ValueKey('gemini-consent')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('gemini-request')));
      await tester.pumpAndSettle();
      expect(requests, hasLength(2));
      expect(requests.last.url.path, '/api/me/recommendations/gemini');
      expect(requests.last.headers['Authorization'], 'Bearer fixture-token');
      expect(jsonDecode(requests.last.body), {'candidateSetId': 'set'});
      expect(requests.every((r) => r.url.host == 'api.example.test'), true);
      expect(
        find.text('La selección está aplicada a tus recomendaciones.'),
        findsOneWidget,
      );
      expect(controller.data!.items.single['googleVolumeId'], 'real');
    },
  );
  testWidgets(
    'only one Home dialog opens and changing accounts closes it and discards pending selection',
    (tester) async {
      final a = RecommendationsFake('a');
      final b = RecommendationsFake('b');
      final key = GlobalKey<HomeScreenState>();
      await tester.pumpWidget(home(a, homeKey: key));
      a.loads.single.complete(result('a'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Selección inteligente con Gemini'));
      key.currentState!.showGeminiAssistant();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('gemini-selection-dialog')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('gemini-request')));
      await tester.pump();
      expect(a.enrichments, hasLength(1));
      await tester.pumpWidget(home(b, homeKey: key));
      b.loads.single.complete(result('b', available: false));
      a.enrichments.single.complete(result('a', status: 'ENRICHED'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('gemini-selection-dialog')),
        findsNothing,
      );
      expect(find.text('Real fixture a'), findsNothing);
      expect(b.enrichments, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
