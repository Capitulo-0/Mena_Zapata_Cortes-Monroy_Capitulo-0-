import '../../../core/network/api_client.dart';
import '../models/writer_story.dart';
import '../models/writer_publication.dart';
import 'writer_repository.dart';

class ApiWriterRepository
    implements WriterRepository, CommunityWriterRepository {
  ApiWriterRepository(this.api, {required this.ownerUid});
  final ApiClient api;
  final String ownerUid;
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
