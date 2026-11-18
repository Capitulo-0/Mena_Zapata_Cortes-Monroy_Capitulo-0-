import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/widgets/literary_cover.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/features/auth/domain/auth_repository.dart';
import 'package:android/features/catalog/data/catalog_repository.dart';
import 'package:android/features/library/models/library_entry.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';
import 'package:android/features/home/data/spanish_recommendations.dart';
import 'package:android/features/home/data/home_recommendation_repository.dart';
import 'package:android/features/home/presentation/home_recommendation_controller.dart';
import 'package:android/features/writer/presentation/widgets/writer_cover.dart';
import 'package:android/features/writer/models/writer_story.dart';

import 'support/auth_fakes.dart';
import 'support/library_fakes.dart' show bookJson;
import 'home_recommendations_test.dart' show RecommendationsFake;
import 'library_regression_test.dart' show installLocalTestAssets;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  setUp(LiteraryCover.resetFailures);
  test(
    'Google image identity never changes to another volume or stock image',
    () {
      expect(
        BookCoverReference.resolve(
          'http://books.google.com/books/content?id=one&img=1',
          googleVolumeId: 'one',
        ),
        'https://books.google.com/books/content?id=one&img=1',
      );
      for (final url in [
        'https://books.google.com/books/content?id=two&img=1',
        'https://books.google.com/books/content?id=one&id=two',
        'https://images.unsplash.com/photo-example',
      ]) {
        expect(BookCoverReference.resolve(url, googleVolumeId: 'one'), '');
      }
    },
  );
  test('persisted library metadata of another volume cannot supply author or cover', () {
    final book = LibraryEntry.parseBook({
      ...bookJson(),
      'googleVolumeId': 'one',
      'author': 'Autor guardado',
      'coverUrl': 'https://books.google.com/books/content?id=two&img=1',
      'googleBooks': {
        'volumeId': 'two',
        'authors': ['Autor ajeno'],
      },
    });
    expect(book.cover, '');
    expect(book.author, 'Autor guardado');
    expect(book.googleBooks, isNull);
  });
  test('Gutendex uses advertised compatible images only for the same ID', () {
    final book = GutendexBook.fromJson({
      'id': 2000,
      'title': 'Don Quijote',
      'formats': {
        'image/jpeg; charset=binary':
            'https://www.gutenberg.org/cache/epub/2000/pg2000.cover.medium.jpg',
      },
    });
    expect(book.cover?.path, '/cache/epub/2000/pg2000.cover.medium.jpg');
    final wrong = GutendexBook.fromJson({
      'id': 2000,
      'formats': {
        'image/jpeg':
            'https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg',
      },
    });
    expect(wrong.cover, isNull);
    expect(GutendexBook.fromJson({'id': 2000, 'formats': {}}).cover, isNull);
  });
  for (final language in ['en', 'fr', '', 'und']) {
    test(
      'recommendations reject non Spanish or unknown language $language',
      () {
        expect(
          SpanishRecommendations.accepts({
            'language': language,
            'title': 'Un libro',
          }),
          isFalse,
        );
      },
    );
  }
  test(
    'Spanish metadata with clear English title or description is not enough',
    () {
      expect(
        SpanishRecommendations.accepts({
          'language': 'es',
          'title': 'The Secret Library',
        }),
        isFalse,
      );
      expect(
        SpanishRecommendations.accepts({
          'language': 'es',
          'title': 'Una lectura',
          'synopsis': 'The book and the story with the characters and their world was written for you.',
        }),
        isFalse,
      );
      expect(
        SpanishRecommendations.accepts({
          'language': 'es',
          'title': 'Don Quijote de la Mancha',
          'synopsis':
              'Una novela sobre el caballero y sus aventuras por los caminos.',
        }),
        isTrue,
      );
    },
  );
  test(
    'controller does not pad an incomplete Spanish selection with English',
    () async {
      final repo = RecommendationsFake('account');
      final controller = HomeRecommendationController(repo);
      addTearDown(controller.dispose);
      final pending = controller.load();
      repo.loads.single.complete(
        const HomeRecommendations(
          items: [
            {
              'googleVolumeId': 'es',
              'title': 'Don Quijote de la Mancha',
              'language': 'es',
            },
            {
              'googleVolumeId': 'en',
              'title': 'The Secret Library',
              'language': 'en',
            },
          ],
        ),
      );
      await pending;
      expect(controller.data!.items.map((b) => b['googleVolumeId']), ['es']);
      expect(controller.data!.notice, contains('español'));
    },
  );
  test(
    'late recommendation response cannot cross Firebase account scope',
    () async {
      final auth = FakeAuth()..identity = fixtureIdentity;
      addTearDown(auth.close);
      final response = Completer<http.Response>();
      final api = ApiClient(
        auth: auth,
        baseUrl: 'http://127.0.0.1:8086',
        client: MockClient((_) => response.future),
      );
      addTearDown(api.close);
      final repo = ApiHomeRecommendationRepository(api, fixtureIdentity.uid);
      final pending = repo.load();
      final assertion = expectLater(pending, throwsA(isA<ApiFailure>()));
      await Future<void>.delayed(Duration.zero);
      auth.identity = const AuthIdentity(
        uid: 'other-account',
        emailVerified: true,
      );
      response.complete(http.Response(jsonEncode({'items': []}), 200));
      await assertion;
    },
  );
  test(
    'exploration sends language es and filters unexpected English response',
    () async {
      final auth = FakeAuth();
      addTearDown(auth.close);
      final api = ApiClient(
        auth: auth,
        baseUrl: 'http://127.0.0.1:8086',
        client: MockClient((request) async {
          expect(request.url.queryParameters['language'], 'es');
          return http.Response(
            jsonEncode({
              'items': [
                {'volumeId': 'es', 'title': 'Don Quijote', 'language': 'es'},
                {
                  'volumeId': 'en',
                  'title': 'The English Book',
                  'language': 'en',
                },
              ],
              'nextStartIndex': null,
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final result = await ExplorationRecommendationRepository(
        ApiCatalogRepository(api),
        'guest',
      ).load();
      expect(result.items.map((b) => b['googleVolumeId']), ['es']);
    },
  );
  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets(
      'persisted Writer presets and own-metadata fallback fit width $width',
      (t) async {
        t.view.physicalSize = Size(width, 640);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final now = DateTime.utc(2026, 11, 17);
        var story = WriterStory(
          id: 'own',
          title: 'El secreto de la biblioteca',
          synopsis: '',
          genre: 'Misterio',
          status: WriterStoryStatus.draft,
          chapters: [],
          createdAt: now,
          updatedAt: now,
          coverPath: 'preset:forest',
        );
        story = WriterStory.fromJson(
          jsonDecode(jsonEncode(story.toJson())) as Map<String, dynamic>,
        );
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Wrap(
                children: [
                  WriterCover(
                    storyId: story.id,
                    title: story.title,
                    coverPath: story.coverPath,
                    width: 78,
                    height: 108,
                  ),
                  const LiteraryCover(
                    identity: '2000',
                    title: 'Don Quijote de la Mancha',
                    author: 'Miguel de Cervantes',
                    width: 130,
                    height: 190,
                  ),
                ],
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final decorated = t
            .widgetList<Container>(find.byType(Container))
            .where(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration as BoxDecoration).gradient != null,
            );
        expect(
          decorated.any(
            (c) =>
                ((c.decoration as BoxDecoration).gradient as LinearGradient)
                    .colors
                    .first ==
                WriterCover.colors('preset:forest').first,
          ),
          isTrue,
        );
        expect(find.text('MIGUEL DE CERVANTES'), findsNothing);
        expect(find.text('Miguel de Cervantes'), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WriterCover(
                storyId: story.id,
                title: story.title,
                coverPath: 'preset:gold',
                width: 78,
                height: 108,
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(
          t
              .widgetList<Container>(find.byType(Container))
              .any(
                (c) =>
                    c.decoration is BoxDecoration &&
                    (c.decoration as BoxDecoration).gradient
                        is LinearGradient &&
                    ((c.decoration as BoxDecoration).gradient as LinearGradient)
                            .colors
                            .first ==
                        WriterCover.colors('preset:gold').first,
              ),
          isTrue,
        );
      },
    );
  }
}
