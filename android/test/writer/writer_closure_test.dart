import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/core/session/local_account_scope.dart';
import 'package:android/features/writer/presentation/screens/manage_story_screen.dart';
import 'package:android/features/writer/models/writer_chapter.dart';
import 'package:android/features/writer/models/writer_story.dart';
import 'package:android/features/writer/models/writer_publication.dart';
import 'package:android/features/writer/services/writer_repository.dart';
import 'package:android/features/writer/services/writer_api_repository.dart';
import 'package:android/features/writer/services/writer_draft_store.dart';
import 'package:android/features/writer/presentation/screens/chapter_editor_screen.dart';
import 'package:android/features/writer/presentation/screens/published_story_screen.dart';
import 'package:android/features/writer/presentation/screens/writer_screen.dart';
import 'package:android/features/writer/presentation/screens/writer_community_screen.dart';

import '../library_regression_test.dart' show installLocalTestAssets;
import '../support/auth_fakes.dart';
import 'writer_flow_test.dart' show TestWriterRepository;

WriterStory fixture({int revision = 0, bool published = false}) {
  final now = DateTime.utc(2026, 11, 17);
  return WriterStory(
    id: 'original',
    title: 'La casa del viento',
    synopsis: 'Una obra de otra autora.',
    genre: 'Cuento',
    status: published ? WriterStoryStatus.published : WriterStoryStatus.draft,
    revision: revision,
    createdAt: now,
    updatedAt: now,
    chapters: [
      WriterChapter(
        id: 'c1',
        title: 'La puerta',
        content: 'Texto guardado en el servidor.',
        order: 1,
        isPublished: published,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

class CommunityFixture extends TestWriterRepository
    implements CommunityWriterRepository {
  CommunityFixture() : super({});
  bool visible = true;
  int reads = 0;
  @override
  Future<List<WriterPublication>> getPublications() async => visible
      ? [
          const WriterPublication(
            id: 'original',
            title: 'La casa del viento',
            synopsis: 'Una obra de otra autora.',
            genre: 'Cuento',
            coverPath: null,
            authorName: 'Autora real',
            authorUsername: 'autora',
            chapterCount: 1,
          ),
        ]
      : [];
  @override
  Future<WriterStory> readPublication(String id) async {
    reads++;
    if (!visible) throw const ApiFailure(404, 'Historia retirada.');
    return fixture(published: true);
  }
  // Simulación de las historias guardadas en la biblioteca.
  @override
  Future<List<WriterPublication>> getSavedPublications() async {
    return [];
  }

  @override
  Future<void> savePublication(String id) async {}

  @override
  Future<void> removeSavedPublication(String id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  WriterDraftStore store({String owner = 'a'}) =>
      WriterDraftStore(ownerUid: owner, storyId: 'original', chapterId: 'c1');
  Map<String, dynamic> snapshot({int revision = 0}) => {
    'title': 'Título local',
    'content': 'Mi texto recuperable',
    'revision': revision,
    'chapterId': 'c1',
    'order': 1,
  };
  Future<void> press(WidgetTester t, Finder f) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Widget editor(WriterStory story, TestWriterRepository repo) => MaterialApp(
    theme: AppTheme.light,
    home: ChapterEditorScreen(
      story: story,
      chapter: story.chapters.first,
      repository: repo,
      draftStore: store(),
    ),
  );

  test('recovery writes are ordered, isolated by account and never uploaded by storage', () async {
    final a = store();
    final first = a.save(snapshot());
    final second = a.save({...snapshot(), 'content': 'Última edición'});
    await Future.wait([first, second]);
    expect((await store().load())!['content'], 'Última edición');
    expect(await store(owner: 'b').load(), isNull);
    await a.clear();
    expect(await store().load(), isNull);
  });
  testWidgets(
    'editor recovers after disposal and clears copy only after confirmed server save',
    (t) async {
      final story = fixture();
      final repo = TestWriterRepository({story.id: story.toJson()});
      await t.pumpWidget(editor(story, repo));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('writer-chapter-content')),
        'Mi texto recuperable',
      );
      await t.pumpAndSettle();
      expect((await store().load())!['content'], 'Mi texto recuperable');
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await t.pumpWidget(editor(story, repo));
      await t.pumpAndSettle();
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('writer-restore-draft')),
        findsOneWidget,
      );
      await press(t, find.byKey(const ValueKey('writer-restore-draft')));
      expect(find.byKey(const ValueKey('writer-draft-notice')), findsOneWidget);
      expect(
        (await repo.getStoryById(story.id))!.chapters.first.content,
        'Texto guardado en el servidor.',
      );
      repo.fail = true;
      await press(t, find.byKey(const ValueKey('writer-save-chapter-draft')));
      expect((await store().load())!['content'], 'Mi texto recuperable');
      repo.fail = false;
      await press(t, find.byKey(const ValueKey('writer-save-chapter-draft')));
      expect(
        (await repo.getStoryById(story.id))!.chapters.first.content,
        'Mi texto recuperable',
      );
      expect(await store().load(), isNull);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'old recovered revision blocks overwriting newer server and copy survives',
    (t) async {
      await store().save(snapshot());
      final story = fixture(revision: 7);
      final repo = TestWriterRepository({story.id: story.toJson()});
      await t.pumpWidget(editor(story, repo));
      await t.pumpAndSettle();
      await press(t, find.byKey(const ValueKey('writer-restore-draft')));
      expect(find.textContaining('guardado está bloqueado'), findsOneWidget);
      expect(
        t
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('writer-save-chapter-draft')),
            )
            .onPressed,
        isNull,
      );
      expect((await repo.getStoryById(story.id))!.revision, 7);
      expect((await store().load())!['revision'], 0);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'choosing server version explicitly discards only this pending copy',
    (t) async {
      await store().save(snapshot());
      await store(owner: 'b').save(snapshot());
      final story = fixture();
      final repo = TestWriterRepository({story.id: story.toJson()});
      await t.pumpWidget(editor(story, repo));
      await t.pumpAndSettle();
      await press(t, find.text('Usar versión guardada'));
      expect(await store().load(), isNull);
      expect(await store(owner: 'b').load(), isNotNull);
      expect(
        t
            .widget<TextField>(
              find.byKey(const ValueKey('writer-chapter-content')),
            )
            .controller!
            .text,
        'Texto guardado en el servidor.',
      );
    },
  );
  testWidgets(
    'community navigation reads server text, author, hides social mocks and refreshes withdrawal',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final repo = CommunityFixture();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: WriterCommunityScreen(
            repository: repo,
            currentUsername: '@lector',
          ),
        ),
      );
      await t.pumpAndSettle();
      await press(t, find.byKey(const ValueKey('writer-read-original')));
      expect(repo.reads, 1);
      expect(find.byType(PublishedStoryScreen), findsOneWidget);
      expect(find.text('Texto guardado en el servidor.'), findsOneWidget);
      expect(find.text('@autora'), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsNothing);
      expect(find.text('0 seguidores'), findsNothing);
      repo.visible = false;
      await press(t, find.text('Volver atrás'));
      expect(find.byKey(const ValueKey('writer-read-original')), findsNothing);
      expect(
        find.text('Aún no hay obras de otros autores publicadas.'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'withdrawn work in stale catalogue fails instead of opening cached reader',
    (t) async {
      final repo = CommunityFixture();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: WriterCommunityScreen(
            repository: repo,
            currentUsername: '@lector',
          ),
        ),
      );
      await t.pumpAndSettle();
      repo.visible = false;
      await press(t, find.byKey(const ValueKey('writer-read-original')));
      expect(find.byType(PublishedStoryScreen), findsNothing);
      expect(find.byKey(const ValueKey('writer-read-original')), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Writer personal no muestra Comunidad ni menú anterior', (
    t,
  ) async {
    final repo = CommunityFixture();
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: WriterScreen(
          repository: repo,
          currentName: 'Autora',
          currentUsername: 'autora',
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('writer-community')), findsNothing);
    expect(find.byKey(const ValueKey('writer-my-works')), findsNothing);
    expect(find.byKey(const ValueKey('writer-options')), findsNothing);
    expect(find.byKey(const ValueKey('writer-create-story')), findsOneWidget);
    expect(
      find.textContaining('Escribe, guarda y comparte tus historias, Autora'),
      findsOneWidget,
    );
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Publicadas'), findsWidgets);
    expect(find.text('Borradores'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  test('API community catalogue and reading carry Firebase token and matching owner UID', () async {
    final auth = FakeAuth()..identity = fixtureIdentity;
    addTearDown(auth.close);
    final calls = <http.Request>[];
    final api = ApiClient(
      auth: auth,
      baseUrl: 'http://127.0.0.1:1234',
      client: MockClient((request) async {
        calls.add(request);
        expect(request.headers['authorization'], startsWith('Bearer '));
        return http.Response(
          jsonEncode(
            request.url.path.endsWith('/original')
                ? fixture(published: true).toJson()
                : [
                    {
                      'id': 'original',
                      'title': 'La casa del viento',
                      'authorName': 'Autora',
                      'chapterCount': 1,
                    },
                  ],
          ),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final repo = ApiWriterRepository(api, ownerUid: fixtureIdentity.uid);
    expect(await repo.getPublications(), hasLength(1));
    expect(
      (await repo.readPublication('original')).chapters.first.content,
      'Texto guardado en el servidor.',
    );
    expect(calls.map((c) => c.url.path), [
      '/api/writer/stories',
      '/api/writer/stories/original',
    ]);
  });

  testWidgets('account scope reaches editor across Writer navigator routes', (
    t,
  ) async {
    final story = fixture();
    final repo = TestWriterRepository({story.id: story.toJson()});
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LocalAccountScope(
          uid: 'a',
          child: WriterScreen(
            repository: repo,
            currentName: 'Autora',
            currentUsername: '@autora',
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await press(t, find.byKey(const ValueKey('writer-manage-original')));
    await press(t, find.byKey(const ValueKey('writer-edit-chapter-c1')));
    await t.enterText(
      find.byKey(const ValueKey('writer-chapter-content')),
      'Pendiente en ruta real',
    );
    await t.pumpAndSettle();
    expect((await store().load())!['content'], 'Pendiente en ruta real');
    expect(await store(owner: 'b').load(), isNull);
    expect(t.takeException(), isNull);
  });
  testWidgets('server publication failure never shows a success confirmation', (
    t,
  ) async {
    final story = fixture();
    final repo = TestWriterRepository({story.id: story.toJson()});
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ManageStoryScreen(
          story: story,
          repository: repo,
          currentUsername: '@autora',
        ),
      ),
    );
    await t.pumpAndSettle();
    await press(t, find.text('Publicar historia').first);
    repo.fail = true;
    await press(t, find.byKey(const ValueKey('writer-confirm-publication')));
    expect(find.text('Historia publicada en tu cuenta'), findsNothing);
    expect(repo.documents[story.id]!['status'], 'draft');
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'further edits of a recovered conflict retain the original revision locally',
    (t) async {
      await store().save(snapshot());
      final story = fixture(revision: 9);
      final repo = TestWriterRepository({story.id: story.toJson()});
      await t.pumpWidget(editor(story, repo));
      await t.pumpAndSettle();
      await press(t, find.byKey(const ValueKey('writer-restore-draft')));
      await t.enterText(
        find.byKey(const ValueKey('writer-chapter-content')),
        'Continuación local segura',
      );
      await t.pumpAndSettle();
      expect((await store().load())!['revision'], 0);
      expect((await store().load())!['content'], 'Continuación local segura');
      expect(
        t
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('writer-save-chapter-draft')),
            )
            .onPressed,
        isNull,
      );
      expect(
        (await repo.getStoryById(story.id))!.chapters.first.content,
        'Texto guardado en el servidor.',
      );
    },
  );
  test(
    'API rejects a partially malformed chapter list without dropping entries',
    () async {
      final auth = FakeAuth()..identity = fixtureIdentity;
      addTearDown(auth.close);
      final body = fixture().toJson();
      body['chapters'] = <Object?>[
        ...body['chapters'] as List,
        'broken-chapter',
      ];
      final api = ApiClient(
        auth: auth,
        baseUrl: 'http://127.0.0.1:1234',
        client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
      );
      addTearDown(api.close);
      await expectLater(
        ApiWriterRepository(
          api,
          ownerUid: fixtureIdentity.uid,
        ).getStoryById('original'),
        throwsA(isA<ApiFailure>()),
      );
    },
  );
}
