/// Recommendation-only identity. Never changes displayed bibliographic text or general search.
class RecommendationTitles {
  static String key(String title) {
    var value = title.toLowerCase();
    final editorial = RegExp(
      r'\s*[\(\[]\s*(?:edici[oó]n|edition|illustrated|ilustrad[oa]|spanish edition|english edition|tapa blanda|tapa dura|ebook|e-book)\b[^\)\]]*[\)\]]\s*$',
      unicode: true,
    );
    final suffix = RegExp(
      r'\s*[:–—-]\s*(?:edici[oó]n|edition|illustrated edition|una novela|a novel)\b.*$',
      unicode: true,
    );
    for (var pass = 0; pass < 4; pass++) {
      final previous = value;
      value = value.replaceFirst(editorial, '').replaceFirst(suffix, '');
      if (value == previous) break;
    }
    const accents = {
      'àáâãäåāăą': 'a',
      'èéêëēĕėęě': 'e',
      'ìíîïĩīĭį': 'i',
      'òóôõöōŏő': 'o',
      'ùúûüũūŭůűų': 'u',
      'ñńņň': 'n',
      'çćĉċč': 'c',
      'ýÿŷ': 'y',
      'śŝşš': 's',
      'źżž': 'z',
      'ď': 'd',
      'ğĝģġ': 'g',
      'ĺļľ': 'l',
      'ŕŗř': 'r',
      'ţť': 't',
    };
    for (final entry in accents.entries) {
      for (final rune in entry.key.runes) {
        value = value.replaceAll(String.fromCharCode(rune), entry.value);
      }
    }
    return value
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
        .trim();
  }

  static int _quality(Map<String, dynamic> book) {
    int present(String field) =>
        (book[field]?.toString().trim().isNotEmpty ?? false) ? 1 : 0;
    return present('recommendationReason') * 16 +
        present('cover') * 8 +
        present('author') * 4 +
        present('genre') * 2 +
        present('isbn') * 2 +
        present('synopsis') +
        present('publisher');
  }

  static String? isbn(Object? raw) {
    var value = (raw?.toString() ?? '')
        .replaceAll(RegExp(r'[\s-]'), '')
        .toUpperCase();
    if (RegExp(r'^[0-9]{9}[0-9X]$').hasMatch(value)) {
      var sum = 0;
      for (var i = 0; i < 10; i++) {
        sum += (10 - i) * (value[i] == 'X' ? 10 : int.parse(value[i]));
      }
      if (sum % 11 != 0) return null;
      value = '978${value.substring(0, 9)}';
      var check = 0;
      for (var i = 0; i < 12; i++) {
        check += int.parse(value[i]) * (i.isEven ? 1 : 3);
      }
      return '$value${(10 - check % 10) % 10}';
    }
    if (!RegExp(r'^[0-9]{13}$').hasMatch(value)) return null;
    var sum = 0;
    for (var i = 0; i < 13; i++) {
      sum += int.parse(value[i]) * (i.isEven ? 1 : 3);
    }
    return sum % 10 == 0 ? value : null;
  }

  static Set<String> identities(Map<String, dynamic> book) {
    final keys = <String>{};
    final metadata = book['googleBooks'];
    final google = book['googleVolumeId'];
    final local = book['freeWorkId'];
    if (google is String && google.isNotEmpty) keys.add('google:$google');
    if (local is String && local.isNotEmpty) keys.add('local:$local');
    final identifiers = [
      book['isbn'],
      if (metadata is Map && metadata['identifiers'] is Map)
        ...(metadata['identifiers'] as Map).values,
    ];
    for (final raw in identifiers) {
      final valid = isbn(raw);
      if (valid != null) keys.add('isbn:$valid');
    }
    final title = key(book['title']?.toString() ?? '');
    if (title.isNotEmpty) {
      // Keep the conservative unique-title policy as well as title/author aliases.
      keys.add('title:$title');
      keys.add(
        'work:$title|${key((book['authorReal'] ?? book['author'])?.toString() ?? '')}',
      );
    }
    return keys;
  }

  static String identity(Map<String, dynamic> book) =>
      (book['freeWorkId'] is String
      ? 'local:${book['freeWorkId']}'
      : book['googleVolumeId'] is String
      ? 'google:${book['googleVolumeId']}'
      : 'work:${key(book['title']?.toString() ?? '')}|${key(book['author']?.toString() ?? '')}');

  static List<Map<String, dynamic>> unique(List<Map<String, dynamic>> books) {
    final valid = books
        .where((b) => key(b['title']?.toString() ?? '').isNotEmpty)
        .toList();
    final parent = List.generate(valid.length, (i) => i);
    int root(int index) {
      while (parent[index] != index) {
        parent[index] = parent[parent[index]];
        index = parent[index];
      }
      return index;
    }

    final first = <String, int>{};
    for (var i = 0; i < valid.length; i++) {
      for (final alias in identities(valid[i])) {
        final previous = first[alias];
        if (previous == null) {
          first[alias] = i;
        } else {
          final a = root(i), b = root(previous);
          if (a != b) parent[a > b ? a : b] = a < b ? a : b;
        }
      }
    }
    final winners = <int, Map<String, dynamic>>{};
    for (var i = 0; i < valid.length; i++) {
      final group = root(i), previous = winners[group];
      if (previous == null || _quality(valid[i]) > _quality(previous)) {
        winners[group] = valid[i];
      }
    }
    return List.unmodifiable(winners.values);
  }
}
