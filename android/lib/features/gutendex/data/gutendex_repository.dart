import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/gutendex_models.dart';

class GutendexFailure implements Exception {
  const GutendexFailure(this.message);
  final String message;
}

abstract interface class GutendexRepository {
  Future<GutendexPage> list({
    required String query,
    required GutendexLanguage language,
    Uri? next,
  });
  Future<GutendexBook> detail(int id);
}

/// Public metadata only. No Firebase token, app API client, or database access.
class HttpGutendexRepository implements GutendexRepository {
  HttpGutendexRepository({http.Client? client,
    this.timeout = const Duration(seconds: 15)}) : _client = client ?? http.Client();
  final http.Client _client;
  final Duration timeout;

  Uri _listUri(String query, GutendexLanguage language) =>
      Uri.https('gutendex.com', '/books/', {
        if (query.trim().isNotEmpty) 'search': query.trim(),
        if (language.code.isNotEmpty) 'languages': language.code,
      });

  Uri _validatePage(Uri uri, String query, GutendexLanguage language) {
    final params = uri.queryParametersAll;
    if (uri.scheme != 'https' || uri.host != 'gutendex.com' ||
        uri.port != 443 || uri.userInfo.isNotEmpty || uri.hasFragment ||
        !['/books', '/books/'].contains(uri.path) ||
        params.keys.any((k) => !['search', 'languages', 'page'].contains(k)) ||
        params.values.any((v) => v.length != 1) ||
        (uri.queryParameters['search'] ?? '') != query.trim() ||
        (uri.queryParameters['languages'] ?? '') != language.code ||
        (int.tryParse(uri.queryParameters['page'] ?? '1') ?? 0) <= 0) {
      throw const GutendexFailure('Gutendex devolvió una paginación no válida.');
    }
    return uri;
  }

  Uri? _pageLink(Object? value, String query, GutendexLanguage language) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw const FormatException('Invalid page link');
    }
    final uri = Uri.tryParse(value);
    if (uri == null) throw const FormatException('Invalid page URL');
    return _validatePage(uri, query, language);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['Accept'] = 'application/json';
      final response = await _client.send(request)
          .then(http.Response.fromStream).timeout(timeout);
      if (response.statusCode != 200) {
        throw GutendexFailure(response.statusCode == 404
          ? 'No se encontró esta obra en Gutendex.'
          : 'Gutendex no está disponible (HTTP ${response.statusCode}).');
      }
      final value = jsonDecode(utf8.decode(response.bodyBytes));
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object');
      }
      return value;
    } on TimeoutException {
      throw const GutendexFailure('Gutendex tardó demasiado. Inténtalo nuevamente.');
    } on http.ClientException {
      throw const GutendexFailure('No pudimos conectar con Gutendex.');
    } on FormatException {
      throw const GutendexFailure('Gutendex devolvió datos no válidos.');
    }
  }

  @override
  Future<GutendexPage> list({
    required String query,
    required GutendexLanguage language,
    Uri? next,
  }) async {
    final uri = next == null ? _listUri(query, language)
        : _validatePage(next, query, language);
    final json = await _get(uri);
    try {
      final results = json['results'];
      if (results is! List) throw const FormatException('Missing results');
      final count = json['count'];
      if (count != null && (count is! int || count < 0)) {
        throw const FormatException('Invalid count');
      }
      return GutendexPage(
        results: List.unmodifiable(results.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid book');
          }
          return GutendexBook.fromJson(item);
        })),
        count: count as int?,
        next: _pageLink(json['next'], query, language),
        previous: _pageLink(json['previous'], query, language),
      );
    } on FormatException {
      throw const GutendexFailure('Gutendex devolvió un catálogo incompleto o no válido.');
    }
  }

  @override
  Future<GutendexBook> detail(int id) async {
    if (id <= 0) throw const GutendexFailure('Identificador de obra no válido.');
    final json = await _get(Uri.https('gutendex.com', '/books/$id/'));
    try {
      final book = GutendexBook.fromJson(json);
      if (book.id != id) throw const FormatException('Unexpected book');
      return book;
    } on FormatException {
      throw const GutendexFailure('Gutendex devolvió una ficha no válida.');
    }
  }

  void close() => _client.close();
}
