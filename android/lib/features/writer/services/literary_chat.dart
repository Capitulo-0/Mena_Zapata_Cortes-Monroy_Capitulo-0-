typedef ChatChoice = ({String id, String title});
typedef ChatSection = ({String heading, String text, String action});
typedef ChatReply = ({
  List<ChatSection> sections,
  List<Map<String, dynamic>> books,
});
typedef ChatTurn = ({String role, String text});

enum ChatEditor { none, story, chapter }

abstract interface class LiteraryChatRepository {
  bool get chatAccountIsCurrent;
  Stream<bool> get chatAccountActive;
  Future<List<ChatChoice>> chatStories({String? storyId});
  Future<ChatReply> chat({
    required String message,
    required List<ChatTurn> history,
    String? storyId,
    String? chapterId,
    required bool useLibrary,
    required String excerpt,
    required String genre,
  });
}
