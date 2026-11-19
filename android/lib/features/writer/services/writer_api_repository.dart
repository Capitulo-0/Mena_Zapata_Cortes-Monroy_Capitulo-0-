import '../../../core/network/api_client.dart';
import '../models/writer_story.dart';
import '../models/writer_publication.dart';
import 'writer_repository.dart';
import 'writer_assistant.dart';
import 'literary_chat.dart';

class ApiWriterRepository
    implements
        WriterRepository,
        CommunityWriterRepository,
        WriterAssistantRepository,
        LiteraryChatRepository {
  ApiWriterRepository(this.api, {required this.ownerUid});
  final ApiClient api;
  final String ownerUid;

  @override
  bool get chatAccountIsCurrent => api.auth.currentUser?.uid == ownerUid;

  @override
  Stream<bool> get chatAccountActive => api.auth
      .authStateChanges()
      .map((identity) => identity?.uid == ownerUid)
      .distinct();

  @override
  Future<List<ChatChoice>> chatStories({String? storyId}) async {
    if (storyId != null) _path(storyId);
    final data = await api.requestJson(
      'GET',
      storyId == null
          ? '/api/me/assistant/stories'
          : '/api/me/assistant/stories/$storyId/chapters',
      expectedUid: ownerUid,
    );
    if (data is! List) {
      throw const ApiFailure(502, 'No pudimos cargar la lista.');
    }
    return [
      for (final item in data)
        (id: item['id'] as String, title: item['title'] as String),
    ];
  }

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
    try {
      final data = await api.request(
        'POST',
        '/api/me/assistant',
        expectedUid: ownerUid,
        responseTimeout: const Duration(seconds: 50),
        body: {
          'message': message,
          'history': [
            for (final turn in history) {'role': turn.role, 'text': turn.text},
          ],
          'storyId': ?storyId,
          'chapterId': ?chapterId,
          'shareStory': storyId != null,
          'useLibrary': useLibrary,
          'editorExcerpt': excerpt,
          'genre': genre,
        },
      );
      return (
        sections: [
          for (final part in data['sections'] as List)
            (
              heading: part['heading'] as String,
              text: part['text'] as String,
              action: part['action'] as String,
            ),
        ],
        books: [
          for (final book in data['books'] as List)
            Map<String, dynamic>.from(book as Map),
        ],
      );
    } on ApiFailure catch (error) {
      throw _assistantError(error);
    }
  }

  @override
  Future<List<String>> suggest({
    required WriterAssistantTask task,
    required String genre,
    required String context,
    required String direction,
    required String tone,
  }) async {
    try {
      final data = await api.request(
        'POST',
        '/api/me/writer/assistant',
        responseTimeout: const Duration(seconds: 50),
        expectedUid: ownerUid,
        body: {
          'task': task.wireName,
          'genre': genre,
          'context': context,
          'direction': direction,
          'tone': tone,
        },
      );
      final values = data['suggestions'];
      if (values is! List ||
          values.isEmpty ||
          values.any((value) => value is! String || value.trim().isEmpty)) {
        throw const ApiFailure(
          502,
          'Gemini devolvió una respuesta vacía o inválida.',
        );
      }
      return List<String>.unmodifiable(values);
    } on ApiFailure catch (e) {
      throw _assistantError(e);
    }
  }

  ApiFailure _assistantError(ApiFailure e) {
    final message = switch (e.code) {
      'WRITER_AI_NOT_CONFIGURED' => 'El asistente todavía no está configurado.',
      'WRITER_AI_QUOTA' =>
        'Se alcanzó el límite de solicitudes. Intenta más tarde.',
      'WRITER_AI_TIMEOUT' =>
        'Gemini tardó demasiado. Puedes volver a intentarlo.',
      'WRITER_AI_EMPTY' => 'Gemini devolvió una respuesta vacía.',
      'WRITER_AI_INVALID' =>
        'Gemini devolvió una sugerencia con formato inválido.',
      'WRITER_AI_UNAVAILABLE' =>
        'No pudimos conectar con Gemini. Intenta más tarde.',
      'WRITER_AI_INPUT_TOO_LARGE' => 'Acorta el texto antes de enviarlo.',
      _ => e.message,
    };
    return ApiFailure(e.statusCode, message, code: e.code);
  }

  String _path(String id) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id)) {
      throw const ApiFailure(400, 'Identificador Writer no valido.');
    }
    return '/api/me/writer/stories/$id';
  }

  WriterStory _decode(Object? value) {
    if (value is! Map) {
      throw const ApiFailure(502, 'Respuesta Writer no valida.');
    }
    if (value['chapters'] is! List ||
        value['revision'] is! num ||
        DateTime.tryParse(value['createdAt']?.toString() ?? '') == null ||
        DateTime.tryParse(value['updatedAt']?.toString() ?? '') == null) {
      throw const ApiFailure(
        502,
        'Respuesta Writer incompleta; no se reemplazo el contenido.',
      );
    }
    final ids = <String>{};
    final orders = <int>{};
    for (final chapter in value['chapters'] as List) {
      if (chapter is! Map ||
          chapter['id'] is! String ||
          (chapter['id'] as String).isEmpty ||
          !ids.add(chapter['id'] as String) ||
          chapter['title'] is! String ||
          chapter['content'] is! String ||
          chapter['order'] is! int ||
          (chapter['order'] as int) < 1 ||
          !orders.add(chapter['order'] as int) ||
          chapter['isPublished'] is! bool) {
        throw const ApiFailure(
          502,
          'Capítulos Writer incompletos; se conservó tu texto.',
        );
      }
    }
    if (value['status'] != 'draft' && value['status'] != 'published') {
      throw const ApiFailure(502, 'Estado Writer no válido.');
    }
    final story = WriterStory.fromJson(Map<String, dynamic>.from(value));
    if (story.id.isEmpty || story.title.trim().isEmpty) {
      throw const ApiFailure(502, 'Respuesta Writer incompleta.');
    }
    return story;
  }

  @override
  Future<List<WriterPublication>> getPublications() async {
    final data = await api.requestJson(
      'GET',
      '/api/writer/stories',
      expectedUid: ownerUid,
    );
    if (data is! List) {
      throw const ApiFailure(502, 'Catalogo Writer no valido.');
    }
    return data
        .map(
          (item) => WriterPublication.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<WriterStory> readPublication(String id) async {
    _path(
      id,
    ); // Reuse identifier validation before constructing the community path.
    return _decode(
      await api.requestJson(
        'GET',
        '/api/writer/stories/$id',
        expectedUid: ownerUid,
      ),
    );
  }

  @override
  Future<List<WriterStory>> getStories() async {
    final data = await api.requestJson(
      'GET',
      '/api/me/writer/stories',
      expectedUid: ownerUid,
    );
    if (data is! List) throw const ApiFailure(502, 'Lista Writer no valida.');
    return data.map(_decode).toList();
  }

  @override
  Future<WriterStory?> getStoryById(String id) async =>
      _decode(await api.requestJson('GET', _path(id), expectedUid: ownerUid));
  Map<String, dynamic> _body(WriterStory story) => {
    ...story.toJson(),
    'createdAt': story.createdAt.toUtc().toIso8601String(),
    'updatedAt': story.updatedAt.toUtc().toIso8601String(),
    'chapters': story.chapters
        .map(
          (chapter) => {
            ...chapter.toJson(),
            'createdAt': chapter.createdAt.toUtc().toIso8601String(),
            'updatedAt': chapter.updatedAt.toUtc().toIso8601String(),
          },
        )
        .toList(),
  };

  @override
  Future<WriterStory> save(WriterStory story) async => _decode(
    await api.requestJson(
      'POST',
      _path(story.id),
      expectedUid: ownerUid,
      body: _body(story),
    ),
  );
  @override
  Future<WriterStory> setPublished(WriterStory story, bool published) async =>
      _decode(
        await api.requestJson(
          'POST',
          '${_path(story.id)}/publication',
          expectedUid: ownerUid,
          body: {'revision': story.revision, 'published': published},
        ),
      );
  @override
  Future<void> remove(WriterStory story) async {
    await api.requestJson(
      'DELETE',
      _path(story.id),
      expectedUid: ownerUid,
      queryParameters: {'revision': '${story.revision}'},
    );
  }
}
