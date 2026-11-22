class ReadingMood {
  const ReadingMood({
    required this.emoji,
    required this.label,
    required this.detail,
  });

  final String emoji;
  final String label;
  final String detail;

  factory ReadingMood.fromJson(Map<String, dynamic> json) => ReadingMood(
    emoji: json['emoji'] as String,
    label: json['label'] as String,
    detail: json['detail'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'label': label,
    'detail': detail,
  };
}
