class BookInteractionStore {
  BookInteractionStore._();

  static final Map<String, List<Map<String, dynamic>>> _bookReplies =
      <String, List<Map<String, dynamic>>>{};

  static String _key(int bookId, int commentIndex) =>
      '$bookId:$commentIndex';

  static List<Map<String, dynamic>> repliesFor(
    int bookId,
    int commentIndex,
  ) {
    final stored = _bookReplies[_key(bookId, commentIndex)];

    if (stored == null) {
      return <Map<String, dynamic>>[];
    }

    return stored
        .map((reply) => Map<String, dynamic>.from(reply))
        .toList();
  }

  static void saveReplies(
    int bookId,
    int commentIndex,
    List<Map<String, dynamic>> replies,
  ) {
    _bookReplies[_key(bookId, commentIndex)] = replies
        .map((reply) => Map<String, dynamic>.from(reply))
        .toList();
  }
}
