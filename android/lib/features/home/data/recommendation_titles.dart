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

  static List<Map<String, dynamic>> unique(List<Map<String, dynamic>> books) {
    final byTitle = <String, Map<String, dynamic>>{};
    for (final book in books) {
      final title = key(book['title'] as String? ?? '');
      if (title.isEmpty) continue;
      final previous = byTitle[title];
      if (previous == null || _quality(book) > _quality(previous)) {
        byTitle[title] = book;
      }
    }
    return List.unmodifiable(byTitle.values);
  }
}
