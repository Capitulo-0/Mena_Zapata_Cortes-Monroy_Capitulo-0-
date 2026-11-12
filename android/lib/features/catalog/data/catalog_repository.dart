import '../../../core/network/api_client.dart';

class CatalogPage {
  const CatalogPage(this.items, this.nextStartIndex);
  final List<Map<String, dynamic>> items;
  final int? nextStartIndex;
}

abstract interface class CatalogRepository {
  Future<CatalogPage> search(
    String query, {
    String mode = 'all',
    int start = 0,
  });
  Future<Map<String, dynamic>> detail(String volumeId);
  Future<Map<String, dynamic>> importBook(String volumeId);
}

class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this.api);
  final ApiClient api;
  static Map<String, dynamic> presentation(Map<String, dynamic> book) {
    final authors = List<String>.from(book['authors'] as List? ?? []);
    final categories = List<String>.from(book['categories'] as List? ?? []);
    final ids = Map<String, dynamic>.from(book['identifiers'] as Map? ?? {});
    return {
      'googleVolumeId': book['volumeId'],
      'googleBooks': book,
      'title': book['title'] ?? '',
      'subtitle': book['subtitle'],
      'authorReal': authors.join(', '),
      'author': authors.join(', '),
      'year':
          int.tryParse(
            (book['publishedDate'] as String? ?? '').split('-').first,
          ) ??
          0,
      'genre': categories.join(', '),
      'isbn': ids['ISBN_13'] ?? ids['ISBN_10'] ?? '',
      'cover': book['coverUrl'] ?? '',
      'synopsis': book['description'] ?? '',
      'publisher': book['publisher'] ?? '',
      'totalPages': book['pageCount'] ?? 0,
      'availability': 'REGISTRO',
      'rating': 0.0,
      'isExternalBook': true,
    };
  }

  @override
  Future<CatalogPage> search(
    String query, {
    String mode = 'all',
    int start = 0,
  }) async {
    final result = await api.requestJson(
      'GET',
      '/api/catalog/search',
      publicRead: true,
      queryParameters: {
        'q': query,
        'mode': mode,
        'startIndex': '$start',
        'maxResults': '20',
      },
    );
    try {
      final data = result as Map<String, dynamic>;
      return CatalogPage(
        (data['items'] as List)
            .map((v) => presentation(Map<String, dynamic>.from(v as Map)))
            .toList(),
        data['nextStartIndex'] as int?,
      );
    } catch (_) {
      throw const ApiFailure(502, 'El catálogo devolvió datos no válidos.');
    }
  }

  @override
  Future<Map<String, dynamic>> detail(String volumeId) async {
    final data = await api.requestJson(
      'GET',
      '/api/catalog/google-books/${Uri.encodeComponent(volumeId)}',
      publicRead: true,
    );
    return presentation(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<Map<String, dynamic>> importBook(String volumeId) => api.request(
    'POST',
    '/api/books/import/google-books',
    body: {'volumeId': volumeId},
  );
}
