class PersonalLibraryList {
  const PersonalLibraryList({
    required this.name,
    required this.description,
    required this.emoji,
    this.bookIds = const <int>[],
  });

  final String name;
  final String description;
  final String emoji;
  final List<int> bookIds;

  PersonalLibraryList copyWith({
    String? name,
    String? description,
    String? emoji,
    List<int>? bookIds,
  }) {
    return PersonalLibraryList(
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      bookIds: bookIds ?? this.bookIds,
    );
  }
}
