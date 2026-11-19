import 'dart:async';

import 'package:android/core/network/api_client.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/home/presentation/screens/main_shell_screen.dart';
import 'package:android/features/writer/models/writer_chapter.dart';
import 'package:android/features/writer/presentation/screens/chapter_editor_screen.dart';
import 'package:android/features/writer/presentation/screens/create_story_screen.dart';
import 'package:android/features/writer/presentation/widgets/literary_chat_screen.dart';
import 'package:android/features/writer/services/literary_chat.dart';
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
      await tester.pumpAndSettle();
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

  testWidgets('Writer revisa, descarta y confirma sin guardar', (tester) async {
    final repo = ChatFixture();
    addTearDown(repo.account.close);
    final story = fixture();
    await tester.pumpWidget(
      app(CreateStoryScreen(story: story, repository: repo)),
    );
    final button = find.text('Asistente IA');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await send(tester, 'Propón un título');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('La llave del silencio'), findsNothing);
    await send(tester, 'Propón otro título');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar título'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    final title = tester.widget<TextField>(
      find.byKey(const ValueKey('writer-story-title')),
    );
    expect(title.controller!.text, 'La llave del silencio');
    expect(repo.documents, isEmpty);
  });

  testWidgets('Editor conserva texto y puede deshacer una inserción', (
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
    await tester.tap(find.text('Asistente IA'));
    await tester.pumpAndSettle();
    await send(tester, 'Continúa mi escena');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insertar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    String content() => tester
        .widget<TextField>(find.byKey(const ValueKey('writer-chapter-content')))
        .controller!
        .text;
    expect(content(), 'Original\n\nLa llave del silencio');
    await tester.tap(find.text('Deshacer inserción IA'));
    await tester.pumpAndSettle();
    expect(content(), 'Original');
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
    await tester.tap(find.text('Libro del catálogo'));
    expect(opened, 'volume');
    await tester.tap(find.byTooltip('Nueva conversación'));
    await tester.pumpAndSettle();
    expect(find.text('Libro del catálogo'), findsNothing);
  });

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

  testWidgets('Cerrar el chat descarta la respuesta en curso', (tester) async {
    final repo = ChatFixture()..pending = Completer<ChatReply>();
    addTearDown(repo.account.close);
    await tester.pumpWidget(
      app(CreateStoryScreen(story: fixture(), repository: repo)),
    );
    final button = find.text('Asistente IA');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await send(tester, 'Dame un título');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    repo.pending!.complete((
      sections: [(heading: '', text: 'Resultado tardío', action: 'TITLE')],
      books: <Map<String, dynamic>>[],
    ));
    await tester.pumpAndSettle();
    expect(find.text('Resultado tardío'), findsNothing);
    expect(repo.documents, isEmpty);
  });
}
