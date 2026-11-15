import '../../../core/network/api_client.dart';
import '../domain/public_profile.dart';

abstract interface class PublicProfileRepository {
  Future<PublicProfile> getProfile(String username);
}

class ApiPublicProfileRepository implements PublicProfileRepository {
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
}
