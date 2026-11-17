import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/gutendex_models.dart';

/// Bounded public first-page metadata, never reader content or account data.
class GutendexSavedCatalog {
  GutendexSavedCatalog({DateTime Function()? now}) : _now = now ?? DateTime.now;
  static const storageKey = 'gutendex.public_catalog.v1';
  static const maxUnits = 250000;
  Future<void> _writes = Future.value();
  final DateTime Function() _now;

  Future<List<Map<String, dynamic>>> _entries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.length > maxUnits) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['entries'] is! List) {
        return [];
      }
      final entries = (decoded['entries'] as List).cast<Map<String, dynamic>>();
      if (entries.length > 4) {
        return [];
      }
      var books = 0;
      final valid = <Map<String, dynamic>>[];
      for (final entry in entries) {
        final saved = DateTime.tryParse(entry['saved'] as String);
        final query = entry['query'];
        final language = entry['language'];
        final rows = entry['books'] as List;
        books += rows.length;
        if (books > 60 ||
            query is! String ||
            query.length > 1000 ||
            !GutendexLanguage.values.any((l) => l.code == language)) {
          return [];
        }
        if (saved == null ||
            saved.isAfter(_now()) ||
            _now().difference(saved) >= const Duration(hours: 24)) {
          continue;
        }
        final count = entry['count'];
        if (count != null && (count is! int || count < 0)) {
          return [];
        }
        _next(entry['next'], query, language as String);
        for (final row in rows) {
          GutendexBook.fromJson(Map<String, dynamic>.from(row as Map));
        }
        valid.add(entry);
      }
      return valid;
    } catch (_) {
      return [];
    }
  }

  Uri? _next(Object? value, String query, String language) {
    if (value == null) {
      return null;
    }
    final uri = Uri.parse(value as String);
    final p = uri.queryParametersAll;
    if (uri.scheme != 'https' ||
        uri.host != 'gutendex.com' ||
        uri.port != 443 ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        !['/books/', '/books'].contains(uri.path) ||
        p.keys.any((k) => !['search', 'languages', 'page'].contains(k)) ||
        p.values.any((v) => v.length != 1) ||
        (uri.queryParameters['search'] ?? '') != query ||
        (uri.queryParameters['languages'] ?? '') != language ||
        (int.tryParse(uri.queryParameters['page'] ?? '') ?? 0) < 1) {
      throw const FormatException();
    }
    return uri;
  }

  Future<GutendexPage?> read(String query, GutendexLanguage language) async {
    try {
      for (final entry in await _entries()) {
        if (entry['query'] != query || entry['language'] != language.code) {
          continue;
        }
        return GutendexPage(
          results: List.unmodifiable(
            (entry['books'] as List).map(
              (row) =>
                  GutendexBook.fromJson(Map<String, dynamic>.from(row as Map)),
            ),
          ),
          count: entry['count'] as int?,
          next: _next(entry['next'], query, language.code),
        );
      }
    } catch (_) {
      /* Storage unavailable: network/session remain usable. */
    }
    return null;
  }

  Future<void> save(
    String query,
    GutendexLanguage language,
    GutendexPage page,
  ) {
    _writes = _writes.then((_) async {
      try {
        if (query.length > 1000 || page.results.length > 60) {
          return;
        }
        var units = query.length;
        for (final book in page.results) {
          units += (book.title?.length ?? 0);
          for (final text in [
            ...book.languages,
            ...book.subjects,
            ...book.summaries,
          ]) {
            units += text.length;
          }
          for (final person in [...book.authors, ...book.translators]) {
            units += person.name.length;
          }
          for (final entry in book.formats.entries) {
            units += entry.key.length + entry.value.length;
          }
          if (units > maxUnits) {
            return;
          }
        }
        final entries = await _entries();
        entries.removeWhere(
          (e) => e['query'] == query && e['language'] == language.code,
        );
        entries.add({
          'query': query,
          'language': language.code,
          'saved': _now().toUtc().toIso8601String(),
          'count': page.count,
          'next': page.next?.toString(),
          'books': page.results.map(_book).toList(),
        });
        String encoded() => jsonEncode({'version': 1, 'entries': entries});
        while (entries.length > 4 ||
            entries.fold<int>(0, (n, e) => n + (e['books'] as List).length) >
                60 ||
            encoded().length > maxUnits) {
          entries.removeAt(0);
          if (entries.isEmpty) {
            return;
          }
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(storageKey, encoded());
      } catch (_) {
        /* Best effort; never turn a successful response into an error. */
      }
    });
    return _writes;
  }

  Map<String, Object?> _book(GutendexBook b) => {
    'id': b.id,
    'title': b.title,
    'languages': b.languages,
    'subjects': b.subjects,
    'summaries': b.summaries,
    'formats': b.formats,
    'copyright': b.copyright,
    'download_count': b.downloadCount,
    'authors': b.authors.map(_person).toList(),
    'translators': b.translators.map(_person).toList(),
  };
  Map<String, Object?> _person(GutendexPerson p) => {
    'name': p.name,
    'birth_year': p.birthYear,
    'death_year': p.deathYear,
  };
}
