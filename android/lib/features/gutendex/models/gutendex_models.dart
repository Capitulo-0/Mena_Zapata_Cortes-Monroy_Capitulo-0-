enum GutendexLanguage {
  all('', 'Todos los idiomas'),
  spanish('es', 'Español'),
  english('en', 'Inglés');

  const GutendexLanguage(this.code, this.label);
  final String code;
  final String label;
}

List<String> _strings(Object? value) => value is List
    ? List.unmodifiable(
        value.whereType<String>().where((s) => s.trim().isNotEmpty),
      )
    : const [];

class GutendexPerson {
  const GutendexPerson(this.name, this.birthYear, this.deathYear);
  final String name;
  final int? birthYear;
  final int? deathYear;

  static List<GutendexPerson> parseList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return List.unmodifiable(
      value
          .whereType<Map>()
          .where(
            (p) =>
                p['name'] is String && (p['name'] as String).trim().isNotEmpty,
          )
          .map(
            (p) => GutendexPerson(
              p['name'] as String,
              p['birth_year'] is int ? p['birth_year'] as int : null,
              p['death_year'] is int ? p['death_year'] as int : null,
            ),
          ),
    );
  }
}

/// Only HTTPS resources on the two exact Project Gutenberg hosts are displayed.
/// Never repairs, follows, or upgrades an untrusted URL.
Uri? gutenbergResource(Object? value) {
  if (value is! String || value.contains(RegExp(r'[\x00-\x20\x7f\\]'))) {
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      (uri.host != 'www.gutenberg.org' && uri.host != 'gutenberg.org') ||
      uri.port != 443 ||
      uri.path.isEmpty) {
    return null;
  }
  return uri;
}

class GutendexFormat {
  const GutendexFormat(this.mimeType, this.url);
  final String mimeType;
  final Uri url;
  String get label => switch (mimeType.split(';').first.trim().toLowerCase()) {
    'application/epub+zip' => 'EPUB',
    'text/html' => 'HTML',
    'text/plain' => 'Texto plano',
    _ => mimeType,
  };
}

class GutendexBook {
  const GutendexBook({
    required this.id,
    this.title,
    this.authors = const [],
    this.translators = const [],
    this.languages = const [],
    this.subjects = const [],
    this.summaries = const [],
    this.formats = const {},
    this.copyright,
    this.downloadCount,
  });
  final int id;
  final String? title;
  final List<GutendexPerson> authors;
  final List<GutendexPerson> translators;
  final List<String> languages;
  final List<String> subjects;
  final List<String> summaries;
  final Map<String, String> formats;
  final bool? copyright;
  final int? downloadCount;

  factory GutendexBook.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int || id <= 0) {
      throw const FormatException('Invalid book identity');
    }
    final rawFormats = json['formats'];
    return GutendexBook(
      id: id,
      title: json['title'] is String ? json['title'] as String : null,
      authors: GutendexPerson.parseList(json['authors']),
      translators: GutendexPerson.parseList(json['translators']),
      languages: _strings(json['languages']),
      subjects: _strings(json['subjects']),
      summaries: _strings(json['summaries']),
      formats: Map.unmodifiable(
        rawFormats is Map
            ? {
                for (final entry in rawFormats.entries)
                  if (entry.key is String && entry.value is String)
                    entry.key as String: entry.value as String,
              }
            : <String, String>{},
      ),
      copyright: json['copyright'] is bool ? json['copyright'] as bool : null,
      downloadCount:
          json['download_count'] is int && (json['download_count'] as int) >= 0
          ? json['download_count'] as int
          : null,
    );
  }

  String get displayTitle =>
      title == null || title!.trim().isEmpty ? 'Título no disponible' : title!;
  String get displayAuthors => authors.isEmpty
      ? 'Autor no informado'
      : authors.map((p) => p.name).join(' · ');
  String get displayLanguages => languages.isEmpty
      ? 'Idioma no informado'
      : languages
            .map(
              (code) => switch (code) {
                'es' => 'Español (es)',
                'en' => 'Inglés (en)',
                _ => code,
              },
            )
            .join(' · ');
  Uri get source => Uri.https('www.gutenberg.org', '/ebooks/$id');

  Uri? get cover {
    for (final entry in formats.entries) {
      if ([
        'image/jpeg',
        'image/png',
        'image/webp',
      ].contains(entry.key.split(';').first.trim().toLowerCase())) {
        final uri = gutenbergResource(entry.value);
        if (uri != null) {
          final match = RegExp(r'/(?:cache/epub|files|ebooks)/(\d+)(?:/|[.])')
              .firstMatch(uri.path);
          if (match != null && int.tryParse(match.group(1)!) == id) {
            return uri;
          }
        }
      }
    }
    return null;
  }

  List<GutendexFormat> get readingFormats => [
    for (final entry in formats.entries)
      if ([
            'application/epub+zip',
            'text/html',
            'text/plain',
          ].contains(entry.key.split(';').first.trim().toLowerCase()) &&
          gutenbergResource(entry.value) != null)
        GutendexFormat(entry.key, gutenbergResource(entry.value)!),
  ];
}

class GutendexPage {
  const GutendexPage({
    required this.results,
    this.count,
    this.next,
    this.previous,
  });
  final List<GutendexBook> results;
  final int? count;
  final Uri? next;
  final Uri? previous;
}
