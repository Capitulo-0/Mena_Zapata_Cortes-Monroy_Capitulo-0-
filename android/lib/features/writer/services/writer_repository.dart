import '../models/writer_story.dart';
import '../models/writer_publication.dart';
import '../../../core/network/api_client.dart';

abstract class WriterRepository {
  Future<List<WriterStory>> getStories();
  Future<WriterStory?> getStoryById(String id);
  Future<WriterStory> save(WriterStory story);
  Future<WriterStory> setPublished(WriterStory story, bool published);
  Future<void> remove(WriterStory story);
}

abstract class CommunityWriterRepository {
  Future<List<WriterPublication>> getPublications();
  Future<WriterStory> readPublication(String id);
  // Implementaciones por defecto para dobles de prueba antiguos.
  // El repositorio HTTP real sobrescribe estos métodos.
  Future<List<WriterPublication>> getSavedPublications() async =>
      throw UnsupportedError('La consulta de historias guardadas no está implementada.');
  Future<void> savePublication(String id) async =>
      throw UnsupportedError('El guardado de historias no está implementado.');
  Future<void> removeSavedPublication(String id) async =>
      throw UnsupportedError('La eliminación de historias guardadas no está implementada.');
}

class UnavailableWriterRepository implements WriterRepository {
  const UnavailableWriterRepository();
  Never _missing() => throw const ApiFailure(
    503,
    'Writer necesita una cuenta autenticada y el backend configurado.',
  );
  @override
  Future<List<WriterStory>> getStories() async => _missing();
  @override
  Future<WriterStory?> getStoryById(String id) async => _missing();
  @override
  Future<WriterStory> save(WriterStory story) async => _missing();
  @override
  Future<WriterStory> setPublished(WriterStory story, bool published) async =>
      _missing();
  @override
  Future<void> remove(WriterStory story) async => _missing();
}

String writerError(Object error) => error is ApiFailure
    ? error.code == 'WRITER_CONFLICT' || error.statusCode == 409
          ? 'La historia cambio en otra sesion. Tu texto sigue en el editor. Copialo antes de recargar para resolver el conflicto.'
          : '${error.message} Tu texto no se ha descartado; puedes reintentar.'
    : 'No se pudo guardar o recuperar la historia. Conserva tu texto y reintenta.';
