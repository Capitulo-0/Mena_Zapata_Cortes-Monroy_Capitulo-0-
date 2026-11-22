import '../../../core/network/api_client.dart';
import '../domain/user_search_result.dart';

abstract interface class UserSearchRepository {
  Future<List<UserSearchResult>> searchUsers(String query);
}

class ApiUserSearchRepository implements UserSearchRepository {
  ApiUserSearchRepository(this.api);

  final ApiClient api;

  @override
  Future<List<UserSearchResult>> searchUsers(String query) async {
    final normalized = query.trim();

    if (normalized.isEmpty) {
      return [];
    }

    final response = await api.requestJson(
      'GET',
      '/api/users/search',
      queryParameters: {'q': normalized},
    );

    if (response is! List<dynamic>) {
      throw const ApiFailure(
        502,
        'No pudimos interpretar los resultados de usuarios.',
      );
    }

    try {
      return response
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid search response');
            }

            return UserSearchResult.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException {
      throw const ApiFailure(
        502,
        'No pudimos interpretar los resultados de usuarios.',
      );
    }
  }
}
