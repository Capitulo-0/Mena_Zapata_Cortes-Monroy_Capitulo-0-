class SpanishRecommendations {
  static bool accepts(Map<String, dynamic> book) {
    final metadata = book['googleBooks'];
    final language =
        (book['language'] ?? (metadata is Map ? metadata['language'] : null))
            ?.toString()
            .toLowerCase()
            .trim() ??
        '';
    if (language != 'es' && !language.startsWith('es-')) {
      return false;
    }
    final title = book['title']?.toString().toLowerCase() ?? '';
    if (RegExp(
      r'^(the |how to |a tale of |stories of )|english edition|in english',
    ).hasMatch(title)) {
      return false;
    }
    final text = '$title ${book['synopsis'] ?? ''}'.toLowerCase();
    final en = RegExp(
      r'\b(the|and|with|from|that|this|her|his|was|were|your)\b',
    ).allMatches(text).length;
    final es = RegExp(
      r'\b(el|la|los|las|de|del|una|un|y|con|para|que|en|su|por)\b',
    ).allMatches(text).length;
    return en < 5 || en <= es * 2;
  }
}
