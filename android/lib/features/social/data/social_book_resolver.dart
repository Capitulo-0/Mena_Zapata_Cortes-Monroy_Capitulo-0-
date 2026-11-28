import '../../../core/network/api_client.dart';
import '../../library/models/library_book.dart';
import 'social_api_repository.dart';

/// Resolves catalogue identity without adding anything to the user's library.
class SocialBookResolver {
  SocialBookResolver(this.api, {required this.expectedUid}) {
    if (expectedUid.isEmpty) {
      throw ArgumentError('Se requiere una sesión.');
    }
  }

  final ApiClient api;
  final String expectedUid;

  Future<SocialTarget> fromHome(Map<String, dynamic> book) => _resolve(
    backendId: book['isBackendBook'] == true ? book['id'] : null,
    volumeId: book['googleVolumeId'],
  );

  Future<SocialTarget> fromLibrary(LibraryBook book) => _resolve(
    backendId: book.isBackendBook ? book.id : null,
    volumeId: book.googleVolumeId,
  );

  Future<SocialTarget> _resolve({
    required Object? backendId,
    required Object? volumeId,
  }) async {
    _requireSession();
    if (backendId is int && backendId > 0) {
      return SocialTarget.book(backendId);
    }
    if (volumeId is! String || volumeId.trim().isEmpty) {
      throw const ApiFailure(
        400,
        'Este libro no tiene un identificador de catálogo válido.',
      );
    }
    final result = await api.request(
      'POST',
      '/api/books/import/google-books',
      body: {'volumeId': volumeId.trim()},
      expectedUid: expectedUid,
    );
    _requireSession();
    final id = result['id'];
    if (id is! int || id <= 0 ||
        result['googleVolumeId'] != volumeId.trim()) {
      throw const ApiFailure(502, 'El catálogo devolvió un libro no válido.');
    }
    return SocialTarget.book(id);
  }

  void _requireSession() {
    if (api.auth.currentUser?.uid != expectedUid) {
      throw ApiFailure.forStatus(401);
    }
  }
}
