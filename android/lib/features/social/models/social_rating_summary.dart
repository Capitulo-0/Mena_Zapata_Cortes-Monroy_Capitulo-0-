class SocialRatingSummary {
  const SocialRatingSummary({
    required this.averageRating,
    required this.ratingCount,
    this.bookId,
    this.storyKey,
  });

  final int? bookId;
  final String? storyKey;
  final double averageRating;
  final int ratingCount;

  factory SocialRatingSummary.fromJson(Map<String, dynamic> json) =>
      SocialRatingSummary(
        bookId: json['bookId'] as int?,
        storyKey: json['storyKey'] as String?,
        averageRating: (json['averageRating'] as num).toDouble(),
        ratingCount: json['ratingCount'] as int,
      );
}
