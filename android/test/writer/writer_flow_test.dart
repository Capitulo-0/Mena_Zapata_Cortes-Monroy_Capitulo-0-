import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/writer/models/writer_story.dart';
import 'package:android/features/writer/models/writer_chapter.dart';
import 'package:android/features/writer/presentation/screens/chapter_editor_screen.dart';
import 'package:android/features/writer/services/writer_repository.dart';
import 'package:android/features/writer/services/writer_api_repository.dart';
import 'package:android/features/writer/presentation/screens/writer_screen.dart';
import 'package:android/features/writer/presentation/screens/create_story_screen.dart';
import 'package:android/features/writer/presentation/screens/manage_story_screen.dart';

import '../support/auth_fakes.dart';

import 'package:android/features/auth/domain/auth_repository.dart';

import '../library_regression_test.dart' show installLocalTestAssets;

class TestWriterRepository implements WriterRepository {
  TestWriterRepository(this.documents);
  final Map<String, Map<String, dynamic>> documents;
  bool fail = false;
  int loads = 0;
  void check() {
    if (fail) throw const ApiFailure(503, 'Fallo de red de prueba.');
  }

  WriterStory copy(WriterStory s) => WriterStory.fromJson(
    jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
  );
  @override
  Future<List<WriterStory>> getStories() async {
    loads++;
    check();
    return documents.values.map(WriterStory.fromJson).toList();
  }

  @override
  Future<WriterStory?> getStoryById(String id) async {
    check();
    return WriterStory.fromJson(documents[id]!);
  }

  @override
  Future<WriterStory> save(WriterStory s) async {
    check();
    final old = documents[s.id];
    if (old != null && old['revision'] != s.revision) {
      throw const ApiFailure(409, 'Version obsoleta.', code: 'WRITER_CONFLICT');
    }
    final saved = copy(s.copyWith(revision: old == null ? 0 : s.revision + 1));
    documents[s.id] = saved.toJson();
    return saved;
  }

  @override
  Future<WriterStory> setPublished(WriterStory s, bool value) async => save(
    s.copyWith(
      status: value ? WriterStoryStatus.published : WriterStoryStatus.draft,
      chapters: value
          ? s.chapters.map((c) => c.copyWith(isPublished: true)).toList()
          : s.chapters,
    ),
  );
  @override
  Future<void> remove(WriterStory s) async {
    check();
    documents.remove(s.id);
  }
}

class PendingWriterRepository extends TestWriterRepository {
  PendingWriterRepository() : super({});
  final pending = Completer<WriterStory>();
  WriterStory? submitted;
  int saves = 0;
  @override
  Future<WriterStory> save(WriterStory story) {
    submitted = story;
    saves++;
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  Future<void> tap(WidgetTester t, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  Future<void> top(WidgetTester t) async {
    final scroll = t.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(0);
    await t.pumpAndSettle();
  }

  Widget app(WriterRepository repository) => MaterialApp(
    theme: AppTheme.light,
    home: WriterScreen(
      repository: repository,
      currentName: 'Autora de prueba',
      currentUsername: '@autora',
    ),
  );
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Writer create chapters restore edit publish delete $size', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final docs = <String, Map<String, dynamic>>{};
      final repository = TestWriterRepository(docs);
      await t.pumpWidget(app(repository));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const ValueKey('writer-create-story')));
      await t.enterText(
        find.byKey(const ValueKey('writer-story-title')),
        'La ventana de la noche',
      );
      await t.enterText(
        find.byKey(const ValueKey('writer-story-synopsis')),
        'Una historia original para probar el guardado.',
      );
      await tap(t, find.byKey(const ValueKey('writer-save-story-draft')));
      expect(docs, hasLength(1));
      final id = docs.keys.single;
      // Save twice while the editor remains open: one stable ID, new revision.
      await tap(t, find.byKey(const ValueKey('writer-save-story-draft')));
      expect(docs, hasLength(1));
      await top(t);
      await tap(t, find.text('Volver').first);
      expect(find.byType(CreateStoryScreen), findsNothing);
      await tap(t, find.byKey(ValueKey('writer-manage-$id')));
      await tap(t, find.text('Nuevo capítulo'));
      await t.enterText(
        find.byKey(const ValueKey('writer-chapter-title')),
        'La primera llave',
      );
      await t.enterText(
        find.byKey(const ValueKey('writer-chapter-content')),
        'Texto original del primer capitulo.',
      );
      repository.fail = true;
      await tap(t, find.byKey(const ValueKey('writer-save-chapter-draft')));
      expect(
        t
            .widget<TextField>(
              find.byKey(const ValueKey('writer-chapter-content')),
            )
            .controller!
            .text,
        'Texto original del primer capitulo.',
      );
      expect((docs[id]!['chapters'] as List), isEmpty);
      repository.fail = false;
      await tap(t, find.byKey(const ValueKey('writer-save-chapter-draft')));
      expect((docs[id]!['chapters'] as List), hasLength(1));
      await tap(t, find.text('Nuevo capítulo'));
      await t.enterText(
        find.byKey(const ValueKey('writer-chapter-title')),
        'La segunda llave',
      );
      await t.enterText(
        find.byKey(const ValueKey('writer-chapter-content')),
        'Texto original del segundo capitulo.',
      );
      await tap(t, find.byKey(const ValueKey('writer-save-chapter-draft')));
      expect((docs[id]!['chapters'] as List), hasLength(2));
      // Dispose the entire UI/repository and recover from the independent test store.
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      final restarted = TestWriterRepository(docs);
      await t.pumpWidget(app(restarted));
      await t.pumpAndSettle();
      await tap(t, find.byKey(ValueKey('writer-manage-$id')));
      expect(
        (await restarted.getStoryById(id))!.chapters.map((c) => c.content),
        [
          'Texto original del primer capitulo.',
          'Texto original del segundo capitulo.',
        ],
      );
      final chapterId = (docs[id]!['chapters'] as List).first['id'];
      await tap(t, find.byKey(ValueKey('writer-edit-chapter-$chapterId')));
      await t.enterText(
        find.byKey(const ValueKey('writer-chapter-content')),
        'Primer capitulo corregido.',
      );
      await tap(t, find.byKey(const ValueKey('writer-save-chapter-draft')));
      expect((docs[id]!['chapters'] as List), hasLength(2));
      expect((docs[id]!['chapters'] as List).first['id'], chapterId);
      expect(
        (docs[id]!['chapters'] as List).first['content'],
        'Primer capitulo corregido.',
      );
      expect(
        (docs[id]!['chapters'] as List).last['content'],
        'Texto original del segundo capitulo.',
      );
      await top(t);
      await tap(t, find.text('Editar historia'));
      await t.enterText(
        find.byKey(const ValueKey('writer-story-title')),
        'La ventana corregida',
      );
      await tap(t, find.byKey(const ValueKey('writer-save-story-draft')));
      await top(t);
      await tap(t, find.text('Volver').first);
      expect(docs[id]!['title'], 'La ventana corregida');
      expect((docs[id]!['chapters'] as List), hasLength(2));
      await tap(t, find.text('Publicar historia').first);
      expect(
        find.byKey(const ValueKey('writer-confirm-publication')),
        findsOneWidget,
      );
      await tap(t, find.text('Cancelar'));
      expect(docs[id]!['status'], 'draft');
      await tap(t, find.text('Publicar historia').first);
      await tap(t, find.byKey(const ValueKey('writer-confirm-publication')));
      expect(docs[id]!['status'], 'published');
      expect((await restarted.getStoryById(id))!.publishedChapterCount, 2);
      await tap(t, find.text('Eliminar historia'));
      await tap(t, find.text('Cancelar'));
      expect(docs, hasLength(1));
      await tap(t, find.text('Eliminar historia'));
      await tap(t, find.text('Eliminar').last);
      expect(docs, isEmpty);
      expect(find.byType(ManageStoryScreen), findsNothing);
      expect(t.takeException(), isNull);
    });
  }
  test('API repository binds owner, carries full chapters/revision and rejects account switch', () async {
    final auth = FakeAuth()..identity = fixtureIdentity;
    addTearDown(auth.close);
    final now = DateTime(2026, 11, 17);
    final story = WriterStory(
      id: 'fixture-story',
      title: 'Original',
      synopsis: 'Texto propio',
      genre: 'Cuento',
      status: WriterStoryStatus.draft,
      chapters: [
        WriterChapter(
          id: 'wire-c1',
          title: 'Capitulo',
          content: 'Texto real',
          order: 1,
          isPublished: false,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    final calls = <http.Request>[];
    final client = ApiClient(
      auth: auth,
      baseUrl: 'http://127.0.0.1:1234',
      client: MockClient((r) async {
        calls.add(r);
        expect(r.headers['authorization'], startsWith('Bearer '));
        if (r.method == 'GET') {
          return http.Response(jsonEncode([story.toJson()]), 200);
        }
        return http.Response(
          jsonEncode(story.copyWith(revision: 2).toJson()),
          200,
        );
      }),
    );
    addTearDown(client.close);
    final repo = ApiWriterRepository(client, ownerUid: fixtureIdentity.uid);
    expect(await repo.getStories(), hasLength(1));
    expect((await repo.save(story)).revision, 2);
    expect(calls.last.method, 'POST');
    final payload = jsonDecode(calls.last.body) as Map;
    expect(payload['chapters'], hasLength(1));
    expect(payload['createdAt'], endsWith('Z'));
    expect((payload['chapters'] as List).single['updatedAt'], endsWith('Z'));
    expect(payload['revision'], 0);
    expect(payload.containsKey('ownerId'), isFalse);
    auth.identity = const AuthIdentity(uid: 'other', emailVerified: true);
    await expectLater(repo.save(story), throwsA(isA<ApiFailure>()));
    expect(calls, hasLength(2));
  });
  testWidgets('list network error is not shown as empty success and retries', (
    t,
  ) async {
    final repo = TestWriterRepository({})..fail = true;
    await t.pumpWidget(app(repo));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('writer-load-error')), findsOneWidget);
    repo.fail = false;
    await tap(t, find.text('Reintentar'));
    expect(find.byKey(const ValueKey('writer-load-error')), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'pending save disables input and failure preserves the metadata draft',
    (t) async {
      final repo = PendingWriterRepository();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CreateStoryScreen(repository: repo),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('writer-story-title')),
        'Texto que debe conservarse',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      final button = find.byKey(const ValueKey('writer-save-story-draft'));
      await t.ensureVisible(button);
      await t.pumpAndSettle();
      await t.tap(button);
      await t.pump();
      expect(repo.saves, 1);
      expect(t.widget<OutlinedButton>(button).onPressed, isNull);
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('writer-story-title')))
            .enabled,
        isFalse,
      );
      repo.pending.completeError(
        const ApiFailure(503, 'Servidor de prueba no disponible.'),
      );
      await t.pumpAndSettle();
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('writer-story-title')))
            .controller!
            .text,
        'Texto que debe conservarse',
      );
      expect(t.widget<OutlinedButton>(button).onPressed, isNotNull);
      expect(repo.documents, isEmpty);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'stale chapter save keeps editor text and never erases newer chapters',
    (t) async {
      final now = DateTime.utc(2026, 11, 17);
      final chapter = WriterChapter(
        id: 'c1',
        title: 'Original',
        content: 'Original',
        order: 1,
        isPublished: false,
        createdAt: now,
        updatedAt: now,
      );
      final story = WriterStory(
        id: 'stale',
        title: 'Historia',
        synopsis: '',
        genre: '',
        status: WriterStoryStatus.draft,
        chapters: [chapter],
        createdAt: now,
        updatedAt: now,
      );
      final repo = TestWriterRepository({story.id: story.toJson()});
      await repo.save(
        story.copyWith(
          chapters: [chapter.copyWith(content: 'Guardado en otra sesion')],
        ),
      );
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChapterEditorScreen(
            story: story,
            chapter: chapter,
            repository: repo,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('writer-chapter-content')),
        'Mi texto aun no guardado',
      );
      await tap(t, find.byKey(const ValueKey('writer-save-chapter-draft')));
      expect(
        t
            .widget<TextField>(
              find.byKey(const ValueKey('writer-chapter-content')),
            )
            .controller!
            .text,
        'Mi texto aun no guardado',
      );
      expect(
        (await repo.getStoryById(story.id))!.chapters.single.content,
        'Guardado en otra sesion',
      );
      expect(find.textContaining('La historia cambio'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  test(
    'API rejects incomplete response instead of silently dropping chapters',
    () async {
      final auth = FakeAuth()..identity = fixtureIdentity;
      addTearDown(auth.close);
      final api = ApiClient(
        auth: auth,
        baseUrl: 'http://127.0.0.1:1234',
        client: MockClient(
          (_) async => http.Response('{"id":"x","title":"Incomplete"}', 200),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        ApiWriterRepository(
          api,
          ownerUid: fixtureIdentity.uid,
        ).getStoryById('x'),
        throwsA(isA<ApiFailure>()),
      );
    },
  );
  testWidgets(
    'Writer loads only on entry and fetches again after leaving the tab',
    (t) async {
      final repo = TestWriterRepository({});
      Widget view(bool active) => MaterialApp(
        theme: AppTheme.light,
        home: WriterScreen(
          repository: repo,
          active: active,
          currentName: 'Autora',
          currentUsername: '@autora',
        ),
      );
      await t.pumpWidget(view(false));
      await t.pumpAndSettle();
      expect(repo.loads, 0);
      await t.pumpWidget(view(true));
      await t.pumpAndSettle();
      expect(repo.loads, 1);
      await t.pumpWidget(view(false));
      await t.pumpAndSettle();
      final now = DateTime.utc(2026, 11, 17);
      final story = WriterStory(
        id: 'returned',
        title: 'Recuperada al volver',
        synopsis: '',
        genre: '',
        status: WriterStoryStatus.draft,
        chapters: const [],
        createdAt: now,
        updatedAt: now,
      );
      repo.documents[story.id] = story.toJson();
      await t.pumpWidget(view(true));
      await t.pumpAndSettle();
      expect(repo.loads, 2);
      expect(find.text(story.title), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
