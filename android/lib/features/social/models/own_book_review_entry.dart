import 'social_review.dart';

class OwnBookReviewEntry {
  const OwnBookReviewEntry({required this.review, required this.title,
    required this.author, this.coverUrl, this.googleVolumeId});

  final SocialReview review;
  final String title;
  final String author;
  final String? coverUrl;
  final String? googleVolumeId;

  int get bookId => review.bookId!;

  factory OwnBookReviewEntry.fromJson(Map<String, dynamic> json) {
    final review = SocialReview.fromJson(
      json['review'] as Map<String, dynamic>, own: true,
    );
    if (review.bookId == null || review.bookId! <= 0) {
      throw const FormatException('Identificador de libro inválido');
    }
    return OwnBookReviewEntry(
      review: review,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      googleVolumeId: json['googleVolumeId'] as String?,
    );
  }
}
