import 'dart:convert';
import 'dart:async';

import 'writer_flow_test.dart' show TestWriterRepository;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/writer/models/writer_story.dart';
import 'package:android/features/writer/services/writer_api_repository.dart';
import 'package:android/features/writer/services/writer_cover_picker.dart';
import 'package:android/features/writer/presentation/widgets/writer_cover.dart';
import 'package:android/features/writer/presentation/screens/writer_screen.dart';
import 'package:android/features/writer/presentation/screens/writer_community_screen.dart';
import 'package:android/features/writer/presentation/screens/manage_story_screen.dart';
import 'package:android/features/writer/presentation/screens/published_story_screen.dart';
import 'package:android/features/writer/presentation/screens/create_story_screen.dart';
import 'package:android/features/profile/presentation/screens/profile_screen.dart';

import '../library_regression_test.dart' show installLocalTestAssets;
import '../support/auth_fakes.dart';
import 'writer_closure_test.dart' show fixture;

class SelectedImagePicker extends WriterCoverPicker {
  SelectedImagePicker(this.selection);
  final WriterCoverSelection selection;
  var _picked = false;
  @override
  Future<WriterCoverSelection?> pick() async {
    if (_picked) return null;
    _picked = true;
    return selection;
  }
}

class DelayedCoverRepository extends TestWriterRepository {
  DelayedCoverRepository(this.latest) : super({});
  final WriterStory latest;
  final older = Completer<List<WriterStory>>();
  @override
  Future<List<WriterStory>> getStories() =>
      ++loads == 1 ? older.future : Future.value([latest]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  Map<String, dynamic> document(String cover) =>
      fixture(published: true)
          .copyWith(title: 'El secreto de la biblioteca', coverPath: cover)
          .toJson();
  ApiWriterRepository repository(
    Map<String, dynamic> doc, {
    String uid = 'fixture-user',
    void Function(http.Request)? onRequest,
  }) {
    final auth = FakeAuth()..identity = fixtureIdentity;
    return ApiWriterRepository(
      ApiClient(
        baseUrl: 'http://fixture.test',
        auth: auth,
        client: MockClient((request) async {
          onRequest?.call(request);
          Object body = doc;
          if (request.url.path == '/api/me/writer/stories') {
            body = [doc];
          }
          if (request.url.path == '/api/writer/stories') {
            body = [
              {
                ...doc,
                'authorName': 'Autora',
                'authorUsername': 'autora',
                'chapterCount': 1,
              },
            ];
          }
          if (request.method == 'POST') {
            doc.addAll(jsonDecode(request.body) as Map<String, dynamic>);
            body = doc;
          }
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      ownerUid: uid,
    );
  }

  Widget app(Widget screen) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: screen),
  );
  void expectBlue(WidgetTester t) {
    final covers = t.widgetList<WriterCover>(find.byType(WriterCover));
    expect(covers, isNotEmpty);
    for (final cover in covers) {
      expect(WriterCover.canonical(cover.coverPath), 'preset:night');
    }
    // Assert rendered pixels' source decoration, not merely that a widget exists.
    final paints = t
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.key == const ValueKey('writer-preset-preset:night'));
    expect(paints, isNotEmpty);
    for (final paint in paints) {
      expect(
        ((paint.decoration as BoxDecoration).gradient as LinearGradient).colors,
        const [Color(0xFF34354A), Color(0xFF171821)],
      );
    }
    expect(
      find.byKey(const ValueKey('writer-cover-unavailable')),
      findsNothing,
    );
    expect(t.takeException(), isNull);
  }

  Widget profile(WriterStory story) => ProfileScreen(
    onOpenSettings: () {},
    name: 'Autora',
    username: 'autora',
    biography: '',
    readingFormat: 'Mixto',
    annualGoal: 12,
    clubs: const [],
    joinedClubIds: const {},
    onToggleClub: (_) {},
    books: const [],
    statuses: const {},
    progresses: const {},
    reviews: const {},
    favorites: const {},
    favoriteCommunityStories: const [],
    onToggleCommunityStoryFavorite: (_) {},
    onStatusChanged: (_, _) {},
    onProgressChanged: (_, _) {},
    onReviewSaved: (_, _) {},
    onToggleFavorite: (_) {},
    publishedStories: [story],
  );

  for (final cover in ['preset:night', ' preset:night ', 'preset:blue']) {
    testWidgets(
      'API persisted $cover renders blue in Writer, profile, manage, community and reader',
      (t) async {
        final repo = repository(document(cover));
        final story = (await repo.getStories()).single;
        expect(story.coverPath, cover);
        await t.pumpWidget(
          app(
            WriterScreen(
              repository: repo,
              currentName: 'Autora',
              currentUsername: 'autora',
            ),
          ),
        );
        await t.pumpAndSettle();
        expectBlue(t);
        await t.pumpWidget(app(profile(story)));
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text('Mis obras (1)'),
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await t.tap(find.text('Mis obras (1)'));
        await t.pumpAndSettle();
        expectBlue(t);
        await t.pumpWidget(
          app(
            ManageStoryScreen(
              story: story,
              repository: repo,
              currentUsername: 'autora',
            ),
          ),
        );
        await t.pumpAndSettle();
        expectBlue(t);
        await t.pumpWidget(
          app(
            WriterCommunityScreen(repository: repo, currentUsername: 'segunda'),
          ),
        );
        await t.pumpAndSettle();
        expectBlue(t);
        await t.pumpWidget(
          app(
            PublishedStoryScreen(
              story: await repo.readPublication(story.id),
              currentUsername: 'segunda',
            ),
          ),
        );
        await t.pumpAndSettle();
        expectBlue(t);
      },
    );
  }
  testWidgets(
    'late old API snapshot cannot replace blue cover after refresh or notify Perfil',
    (t) async {
      final latest = WriterStory.fromJson(document('preset:night'));
      final repo = DelayedCoverRepository(latest);
      final notifications = <List<WriterStory>>[];
      await t.pumpWidget(
        app(
          WriterScreen(
            repository: repo,
            currentName: 'Autora',
            currentUsername: 'autora',
            onStoriesChanged: notifications.add,
          ),
        ),
      );
      await t.pump();
      // El menú de tres puntos se eliminó: la recarga disponible es pull-to-refresh.
      expect(find.byKey(const ValueKey('writer-options')), findsNothing);
      await t.drag(find.byType(CustomScrollView), const Offset(0, 350));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expectBlue(t);
      repo.older.complete([latest.copyWith(removeCover: true)]);
      await t.pumpAndSettle();
      expectBlue(t);
      expect(notifications.last.single.coverPath, 'preset:night');
    },
  );

  testWidgets(
    'editing cover in the real form saves blue and a new list reload renders blue',
    (t) async {
      final doc = document('preset:gold');
      final repo = repository(doc);
      await t.pumpWidget(
        app(
          CreateStoryScreen(story: WriterStory.fromJson(doc), repository: repo),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Cambiar portada'));
      await t.tap(find.text('Cambiar portada'));
      await t.pumpAndSettle();
      await t.tap(find.text('Noche · azul'));
      await t.pumpAndSettle();
      await t.ensureVisible(
        find.byKey(const ValueKey('writer-save-story-draft')),
      );
      await t.tap(find.byKey(const ValueKey('writer-save-story-draft')));
      await t.pumpAndSettle();
      expect(doc['coverPath'], 'preset:night');
      await t.pumpWidget(
        app(
          WriterScreen(
            repository: repository(doc),
            currentName: 'Autora',
            currentUsername: 'autora',
          ),
        ),
      );
      await t.pumpAndSettle();
      expectBlue(t);
    },
  );
  test(
    'different authenticated account cannot submit private Writer requests',
    () async {
      var sent = false;
      final repo = repository(
        document('preset:night'),
        uid: 'another-account',
        onRequest: (_) {
          sent = true;
        },
      );
      await expectLater(repo.getStories(), throwsA(isA<ApiFailure>()));
      expect(sent, isFalse);
    },
  );

  test('editing persists selected cover through a new API repository, no memory dependency', () async {
    final doc = document('preset:gold');
    final repo = repository(doc);
    final story = (await repo.getStories()).single;
    await repo.save(story.copyWith(coverPath: 'preset:night'));
    final fresh = repository(doc);
    expect((await fresh.getStories()).single.coverPath, 'preset:night');
    expect((await fresh.readPublication(story.id)).coverPath, 'preset:night');
  });
  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('Writer encabezado personal y crear obra a $width', (t) async {
      t.view.physicalSize = Size(width, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final repo = repository(document('preset:night'));
      await t.pumpWidget(
        app(
          WriterScreen(
            repository: repo,
            currentName: 'Autora',
            currentUsername: 'autora',
          ),
        ),
      );
      await t.pumpAndSettle();
      expectBlue(t);
      expect(find.text('MIS HISTORIAS'), findsOneWidget);
      expect(
        find.textContaining('Escribe, guarda y comparte tus historias, Autora'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('writer-options')), findsNothing);
      expect(find.byKey(const ValueKey('writer-my-works')), findsNothing);
      expect(find.byKey(const ValueKey('writer-community')), findsNothing);
      expect(find.byKey(const ValueKey('writer-create-story')), findsOneWidget);
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Publicadas'), findsWidgets);
      expect(find.text('Borradores'), findsWidgets);
      await t.tap(find.byKey(const ValueKey('writer-create-story')));
      await t.pumpAndSettle();
      expect(find.byType(CreateStoryScreen), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
  test(
    'image validation rejects fake formats, oversize and corrupt header',
    () async {
      await expectLater(
        WriterCoverPicker.validate(Uint8List.fromList(utf8.encode('<svg/>'))),
        throwsFormatException,
      );
      await expectLater(
        WriterCoverPicker.validate(Uint8List(WriterCoverPicker.maxBytes + 1)),
        throwsFormatException,
      );
      await expectLater(
        WriterCoverPicker.validate(
          Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        ),
        throwsFormatException,
      );
    },
  );
  Future<WriterCoverSelection> image() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.blue, BlendMode.src);
    final picture = recorder.endRecording();
    final decoded = await picture.toImage(4, 6);
    final bytes = await decoded.toByteData(format: ui.ImageByteFormat.png);
    decoded.dispose();
    picture.dispose();
    return WriterCoverPicker.validate(bytes!.buffer.asUint8List());
  }

  testWidgets(
    'own image preview is explicitly local, blocks save and preserves server cover',
    (t) async {
      var writes = 0;
      final doc = document('preset:night');
      final repo = repository(
        doc,
        onRequest: (r) {
          if (r.method == 'POST') {
            writes++;
          }
        },
      );
      final selection = await t.runAsync(image);
      await t.pumpWidget(
        app(
          CreateStoryScreen(
            story: WriterStory.fromJson(doc),
            repository: repo,
            coverPicker: SelectedImagePicker(selection!),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('writer-upload-cover')));
      await t.tap(find.byKey(const ValueKey('writer-upload-cover')));
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('writer-cover-preview-notice')),
        findsOneWidget,
      );
      expect(find.byType(Image), findsWidgets);
      await t.tap(find.byKey(const ValueKey('writer-upload-cover')));
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('writer-cover-preview-notice')),
        findsOneWidget,
      );
      await t.ensureVisible(
        find.byKey(const ValueKey('writer-save-story-draft')),
      );
      await t.tap(find.byKey(const ValueKey('writer-save-story-draft')));
      await t.pumpAndSettle();
      expect(writes, 0);
      expect(doc['coverPath'], 'preset:night');
      expect(
        find.textContaining('Falta configurar almacenamiento privado'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );
}
