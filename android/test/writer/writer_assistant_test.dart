import 'dart:async';

import 'package:android/core/network/api_client.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/home/presentation/screens/main_shell_screen.dart';
import 'package:android/features/writer/models/writer_chapter.dart';
import 'package:android/features/writer/presentation/screens/chapter_editor_screen.dart';
import 'package:android/features/writer/presentation/screens/create_story_screen.dart';
import 'package:android/features/writer/presentation/widgets/literary_chat_screen.dart';
import 'package:android/features/writer/services/literary_chat.dart';
import 'package:android/features/writer/services/chat_dictation.dart';
import 'package:android/features/writer/services/writer_api_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/auth_fakes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../library_regression_test.dart' show installLocalTestAssets;
import 'writer_closure_test.dart' show fixture;
import 'writer_flow_test.dart' show TestWriterRepository;

class ChatFixture extends TestWriterRepository
    implements LiteraryChatRepository {
  ChatFixture() : super({});
  final account = StreamController<bool>.broadcast();
  final messages = <String>[];
  List<ChatTurn> lastHistory = [];
  String? lastStory;
  String? lastChapter;
  Completer<ChatReply>? pending;
  ApiFailure? failure;
  String action = 'TITLE';
  List<Map<String, dynamic>> books = [];
  @override
  bool chatAccountIsCurrent = true;
  @override
  Stream<bool> get chatAccountActive => account.stream;
  @override
  Future<List<ChatChoice>> chatStories({String? storyId}) async =>
      storyId == null
      ? [(id: 'own', title: 'Historia propia')]
      : [(id: 'chapter', title: 'Primer capítulo')];
  @override
  Future<ChatReply> chat({
    required String message,
    required List<ChatTurn> history,
    String? storyId,
    String? chapterId,
    required bool useLibrary,
    required String excerpt,
    required String genre,
  }) async {
    messages.add(message);
    lastHistory = history;
    lastStory = storyId;
    lastChapter = chapterId;
    if (failure case final error?) throw error;
    if (pending case final request?) return request.future;
    return (
      sections: [
        (
          heading: 'Primera idea',
          text: 'La llave del silencio',
          action: action,
        ),
      ],
      books: books,
    );
  }
}

class FakeChatDictation implements ChatDictation {
  ValueChanged<String>? text;
  ValueChanged<String>? error;
  VoidCallback? done;
  int starts = 0;
  int cancels = 0;
  int stops = 0;
  @override
  Future<void> start({
    required ValueChanged<String> onText,
    required ValueChanged<String> onError,
    required VoidCallback onDone,
  }) async {
    starts++;
    text = onText;
    error = onError;
    done = onDone;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Widget app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

  Future<void> send(WidgetTester tester, String message) async {
    await tester.enterText(
      find.byKey(const ValueKey('literary-chat-input')),
      message,
    );
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pump();
  }

  testWidgets(
    'conserva la premisa y la selección numerada al avanzar la conversación',
    (tester) async {
      final repo = ChatFixture();
      addTearDown(repo.account.close);
      await tester.pumpWidget(app(LiteraryChatScreen(repository: repo)));
      for (final message in [
        'Hola',
        'Una princesa enamorada de un villano',
        'Hazla más oscura',
        'Que tenga un secreto',
        'Dame tres títulos',
      ]) {
        await send(tester, message);
        await tester.pumpAndSettle();
      }
      repo.books = [
        {
          'volumeId': 'first',
          'title': 'Primera novela',
          'authors': ['Autora A'],
        },
        {
          'volumeId': 'second',
          'title': 'Segunda novela',
          'authors': ['Autora B'],
        },
        {
          'volumeId': 'third',
          'title': 'Tercera novela',
          'authors': ['Autora C'],
        },
      ];
      await send(tester, 'Recomiéndame libros');
      await tester.pumpAndSettle();
      await send(tester, 'El tercero me interesa');
      await tester.pumpAndSettle();
      expect(repo.lastHistory, hasLength(7));
      expect(
        repo.lastHistory.first.text,
        'Una princesa enamorada de un villano',
      );
      expect(
        repo.lastHistory.any((turn) => turn.text.contains('3. Tercera novela')),
        isTrue,
      );
    },
  );

  testWidgets(
    'dictado requiere permiso, permite editar y nunca envía por sí solo',
    (tester) async {
      final repo = ChatFixture();
      final mic = FakeChatDictation();
      addTearDown(repo.account.close);
      await tester.pumpWidget(
        app(LiteraryChatScreen(repository: repo, dictation: mic)),
      );
      final input = find.byKey(const ValueKey('literary-chat-input'));
      await tester.enterText(input, 'Quiero');
      await tester.tap(find.byTooltip('Dictar en español'));
      await tester.pumpAndSettle();
      expect(mic.starts, 0);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(mic.starts, 0);
      await tester.tap(find.byTooltip('Dictar en español'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Permitir dictado'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Detener dictado'));
      await tester.pumpAndSettle();
      expect(mic.stops, 1);
      mic.text!('un misterio corto');
      mic.done!();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(input).controller!.text,
        'Quiero un misterio corto',
      );
      expect(repo.messages, isEmpty);
      await send(tester, 'Quiero un misterio en español');
      await tester.pumpAndSettle();
      expect(repo.messages, ['Quiero un misterio en español']);
    },
  );

  testWidgets(
    'dictado maneja errores, cancelación y cierre sin aplicar resultados tardíos',
    (tester) async {
      final repo = ChatFixture();
      final mic = FakeChatDictation();
      addTearDown(repo.account.close);
      await tester.pumpWidget(
        app(LiteraryChatScreen(repository: repo, dictation: mic)),
      );
      Future<void> start() async {
        await tester.tap(find.byTooltip('Dictar en español'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Permitir dictado'));
        await tester.pumpAndSettle();
      }

      await start();
      await tester.tap(find.byTooltip('Cancelar dictado'));
      await tester.pumpAndSettle();
      mic.text!('Resultado tardío');
      expect(find.text('Resultado tardío'), findsNothing);
      expect(mic.cancels, 1);
      await start();
      mic.error!('Permiso bloqueado');
      await tester.pump();
      expect(find.text('Permiso bloqueado'), findsOneWidget);
      await start();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(mic.cancels, 3);
      expect(repo.messages, isEmpty);
    },
  );

  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('Cabecera abre el chat y conserva el contexto a $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = ChatFixture();
      addTearDown(repo.account.close);
      await tester.pumpWidget(
        app(
          MainShellScreen(
            isGuest: false,
            onLogout: () {},
            onGuestLoginRequested: () {},
            onGuestRegisterRequested: () {},
            isDarkMode: false,
            onDarkModeChanged: (_) {},
            writerRepository: repo,
          ),
        ),
      );
      // MainShell contiene un mapa con cargas/animaciones ajenas al chat.
      // No esperar a que todos los widgets del Shell queden globalmente inactivos.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byTooltip('Asistente Capítulo 0'), findsOneWidget);
      await tester.tap(find.byTooltip('Asistente Capítulo 0'));
      await tester.pumpAndSettle();
      expect(find.byType(LiteraryChatScreen), findsOneWidget);
      await send(tester, 'Dame una idea');
      await tester.pumpAndSettle();
      expect(find.text('Primera idea'), findsOneWidget);
      await send(tester, 'Hazla más misteriosa');
      await tester.pumpAndSettle();
      expect(repo.lastHistory.map((turn) => turn.role), ['user', 'assistant']);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(
        tester
            .getBottomLeft(find.byKey(const ValueKey('literary-chat-input')))
            .dy,
        lessThan(640 - 280.0),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Selecciona y autoriza historia y capítulo antes de enviar', (
    tester,
  ) async {
    final repo = ChatFixture();
    addTearDown(repo.account.close);
    await tester.pumpWidget(app(LiteraryChatScreen(repository: repo)));
    await tester.tap(find.text('Mi historia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historia propia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autorizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Capítulo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Primer capítulo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autorizar'));
    await tester.pumpAndSettle();
    await send(tester, 'Continúa mi capítulo');
    await tester.pumpAndSettle();
    expect(repo.lastStory, 'own');
    expect(repo.lastChapter, 'chapter');
  });

  testWidgets('Cuenta nueva borra historial e ignora la respuesta pendiente', (
    tester,
  ) async {
    final repo = ChatFixture()..pending = Completer<ChatReply>();
    addTearDown(repo.account.close);
    await tester.pumpWidget(app(LiteraryChatScreen(repository: repo)));
    await send(tester, 'Fragmento privado');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.bySemanticsLabel('Gemini está escribiendo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 42));
    expect(find.bySemanticsLabel('Gemini está escribiendo'), findsOneWidget);
    repo.chatAccountIsCurrent = false;
    repo.account.add(false);
    await tester.pumpAndSettle();
    repo.pending!.complete((
      sections: [(heading: '', text: 'Resultado tardío', action: 'NONE')],
      books: <Map<String, dynamic>>[],
    ));
    await tester.pumpAndSettle();
    expect(find.text('Fragmento privado'), findsNothing);
    expect(find.text('Resultado tardío'), findsNothing);
    expect(find.byTooltip('Enviar'), findsNothing);
  });

  testWidgets('CreateStory no muestra el acceso de Asistente IA', (
    tester,
  ) async {
    final repo = ChatFixture();
    addTearDown(repo.account.close);
    final story = fixture();
    await tester.pumpWidget(
      app(CreateStoryScreen(story: story, repository: repo)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asistente IA'), findsNothing);
    expect(find.text('Deshacer inserción IA'), findsNothing);
    expect(find.byType(LiteraryChatScreen), findsNothing);
    expect(repo.documents, isEmpty);
  });

  testWidgets('ChapterEditor no muestra controles del Asistente IA', (
    tester,
  ) async {
    final repo = ChatFixture()..action = 'INSERT';
    addTearDown(repo.account.close);
    final story = fixture();
    final chapter = WriterChapter(
      id: 'chapter',
      title: 'Uno',
      content: 'Original',
      order: 1,
      isPublished: false,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      app(
        ChapterEditorScreen(story: story, chapter: chapter, repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asistente IA'), findsNothing);
    expect(find.text('Deshacer inserción IA'), findsNothing);
    final content = tester
        .widget<TextField>(find.byKey(const ValueKey('writer-chapter-content')))
        .controller!
        .text;
    expect(content, 'Original');
    expect(repo.documents, isEmpty);
  });

  testWidgets('Tarjeta bibliográfica abre una ficha por ID y puede reiniciar', (
    tester,
  ) async {
    final repo = ChatFixture()
      ..books = [
        {
          'volumeId': 'volume',
          'title': 'Libro del catálogo',
          'authors': ['Autora'],
        },
      ];
    addTearDown(repo.account.close);
    String? opened;
    await tester.pumpWidget(
      app(
        LiteraryChatScreen(
          repository: repo,
          onBook: (book) async {
            opened = book['googleVolumeId'] as String;
          },
        ),
      ),
    );
    await send(tester, 'Busca un libro');
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Libro del catálogo'));
    expect(opened, 'volume');
    await tester.tap(find.byTooltip('Nueva conversación'));
    await tester.pumpAndSettle();
    expect(find.text('1. Libro del catálogo'), findsNothing);
  });

  test(
    'el repositorio distingue el límite de Gemini y conserva Retry-After',
    () async {
      final client = ApiClient(
        auth: FakeAuth()..identity = fixtureIdentity,
        baseUrl: 'http://localhost:8086',
        client: MockClient(
          (request) async => http.Response(
            '{"code":"WRITER_AI_PROVIDER_QUOTA"}',
            429,
            headers: {'Retry-After': '17'},
          ),
        ),
      );
      final repository = ApiWriterRepository(
        client,
        ownerUid: fixtureIdentity.uid,
      );
      await expectLater(
        repository.chat(
          message: 'Dame otra idea',
          history: [],
          useLibrary: false,
          excerpt: '',
          genre: '',
        ),
        throwsA(
          isA<ApiFailure>()
              .having(
                (error) => error.message,
                'message',
                contains('Google Gemini'),
              )
              .having((error) => error.retryAfterSeconds, 'seconds', 17),
        ),
      );
    },
  );

  testWidgets(
    'respeta la pausa antes del reintento manual y no envía automáticamente',
    (tester) async {
      final repo = ChatFixture()
        ..failure = const ApiFailure(429, 'Límite local', retryAfterSeconds: 3);
      addTearDown(repo.account.close);
      await tester.pumpWidget(app(LiteraryChatScreen(repository: repo)));
      await send(tester, 'Dame una idea');
      await tester.pumpAndSettle();
      expect(find.text('Espera 3 s antes de reintentar.'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Reintentar'), findsOneWidget);
      expect(repo.messages, hasLength(1));
      repo.failure = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(repo.messages, hasLength(2));
    },
  );

  for (final status in [429, 502, 503, 504]) {
    testWidgets('Error $status permite reintento explícito', (tester) async {
      final repo = ChatFixture()..failure = ApiFailure(status, 'Error $status');
      addTearDown(repo.account.close);
      await tester.pumpWidget(app(LiteraryChatScreen(repository: repo)));
      await send(tester, 'Dame una idea');
      await tester.pumpAndSettle();
      expect(find.text('Error $status'), findsOneWidget);
      expect(repo.messages, hasLength(1));
      repo.failure = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(repo.messages, hasLength(2));
      expect(find.text('La llave del silencio'), findsOneWidget);
    });
  }

  testWidgets('CreateStory permanece estable sin acceso al Asistente IA', (
    tester,
  ) async {
    final repo = ChatFixture()..pending = Completer<ChatReply>();
    addTearDown(repo.account.close);
    await tester.pumpWidget(
      app(CreateStoryScreen(story: fixture(), repository: repo)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asistente IA'), findsNothing);
    expect(find.byType(CloseButton), findsNothing);
    repo.pending!.complete((
      sections: [(heading: '', text: 'Resultado tardío', action: 'TITLE')],
      books: <Map<String, dynamic>>[],
    ));
    await tester.pumpAndSettle();
    expect(find.text('Resultado tardío'), findsNothing);
    expect(repo.documents, isEmpty);
  });
}
