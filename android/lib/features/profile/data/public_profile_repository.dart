import '../../../core/network/api_client.dart';
import '../domain/public_profile.dart';
import '../domain/public_profile_activity.dart';
import '../domain/reading_mood.dart';

abstract interface class PublicProfileRepository {
  Future<PublicProfile> getProfile(String username);
}

/// Funciones optativas para no romper los dobles de prueba existentes de perfiles.
abstract interface class ProfileActivitySource {
  Future<PublicProfileActivity> getActivity(String username);
  Future<Set<int>> getMyFavoriteBooks();
  Future<void> setMyFavoriteBook(int bookId, {required bool favorite});
}

/// Contrato separado para que los repositorios falsos existentes sigan funcionando.
abstract interface class ReadingMoodSource {
  Future<ReadingMood?> getMyReadingMood();
  Future<ReadingMood?> saveMyReadingMood(ReadingMood? mood);
}

class ApiPublicProfileRepository
    implements
        PublicProfileRepository,
        ProfileActivitySource,
        ReadingMoodSource {
  ApiPublicProfileRepository(this.api);

  final ApiClient api;

  @override
  Future<PublicProfile> getProfile(String username) async {
    final normalized = username.trim().replaceFirst(RegExp(r'^@'), '');

    if (normalized.isEmpty) {
      throw const ApiFailure(400, 'Debes indicar un nombre de usuario.');
    }

    final encodedUsername = Uri.encodeComponent(normalized);

    final response = await api.requestJson(
      'GET',
      '/api/users/$encodedUsername',
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiFailure(
        502,
        'No pudimos interpretar el perfil del usuario.',
      );
    }

    try {
      return PublicProfile.fromJson(response);
    } on FormatException catch (_) {
      throw const ApiFailure(
        502,
        'No pudimos interpretar el perfil del usuario.',
      );
    } on TypeError catch (_) {
      throw const ApiFailure(
        502,
        'El servidor devolvió datos de perfil inválidos.',
      );
    }
  }

  @override
  Future<PublicProfileActivity> getActivity(String username) async {
    final normalized = username.trim().replaceFirst(RegExp(r'^@'), '');
    if (normalized.isEmpty) {
      throw const ApiFailure(400, 'Debes indicar un nombre de usuario.');
    }
    final response = await api.requestJson(
      'GET',
      '/api/users/${Uri.encodeComponent(normalized)}/activity',
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiFailure(502, 'La actividad del perfil no es válida.');
    }
    try {
      return PublicProfileActivity.fromJson(response);
    } catch (_) {
      throw const ApiFailure(
        502,
        'No pudimos interpretar la actividad del perfil.',
      );
    }
  }

  @override
  Future<ReadingMood?> getMyReadingMood() async {
    final response = await api.requestJson('GET', '/api/me/reading-mood');
    if (response == null) return null;
    if (response is! Map<String, dynamic>) {
      throw const ApiFailure(502, 'El estado lector recibido no es válido.');
    }
    return ReadingMood.fromJson(response);
  }

  @override
  Future<ReadingMood?> saveMyReadingMood(ReadingMood? mood) async {
    final response = await api.requestJson(
      'PUT',
      '/api/me/reading-mood',
      body: mood?.toJson() ?? {'emoji': null, 'label': null, 'detail': null},
    );
    if (response == null) return null;
    if (response is! Map<String, dynamic>) {
      throw const ApiFailure(502, 'No pudimos interpretar el estado guardado.');
    }
    return ReadingMood.fromJson(response);
  }

  @override
  Future<Set<int>> getMyFavoriteBooks() async {
    final response = await api.requestJson('GET', '/api/me/favorite-books');
    if (response is! List) {
      throw const ApiFailure(502, 'No pudimos interpretar tus favoritos.');
    }
    try {
      return response.map((id) => (id as num).toInt()).toSet();
    } catch (_) {
      throw const ApiFailure(502, 'No pudimos interpretar tus favoritos.');
    }
  }

  @override
  Future<void> setMyFavoriteBook(int bookId, {required bool favorite}) async {
    await api.requestJson(
      favorite ? 'POST' : 'DELETE',
      '/api/me/favorite-books/$bookId',
    );
  }
}
