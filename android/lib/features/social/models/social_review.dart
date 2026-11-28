enum ReviewVisibility {
  public('PUBLIC'),
  anonymous('ANONYMOUS'),
  private('PRIVATE');

  const ReviewVisibility(this.apiValue);
  final String apiValue;

  factory ReviewVisibility.fromApi(String value) => values.firstWhere(
    (visibility) => visibility.apiValue == value,
    orElse: () => throw FormatException('Visibilidad de reseña inválida'),
  );
}

class SocialReview {
  const SocialReview({
    required this.id,
    required this.rating,
    required this.visibility,
    required this.ownReview,
    required this.createdAt,
    required this.updatedAt,
    this.bookId,
    this.storyKey,
    this.reviewText,
    this.username,
    this.avatarUrl,
  });

  final int id;
  final int? bookId;
  final String? storyKey;
  final int rating;
  final String? reviewText;
  final ReviewVisibility visibility;
  final String? username;
  final String? avatarUrl;
  final bool ownReview;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SocialReview.fromJson(Map<String, dynamic> json, {bool own = false}) {
    final visibility = ReviewVisibility.fromApi(json['visibility'] as String);
    if (!own && visibility == ReviewVisibility.private) {
      throw FormatException('Reseña privada en respuesta pública');
    }
    final rating = json['rating'] as int;
    if (rating < 1 || rating > 5) {
      throw FormatException('Calificación inválida');
    }
    return SocialReview(
      id: json['id'] as int,
      bookId: json['bookId'] as int?,
      storyKey: json['storyKey'] as String?,
      rating: rating,
      reviewText: json['reviewText'] as String?,
      visibility: visibility,
      username: own ? null : (visibility == ReviewVisibility.anonymous ? '@anonimo' : json['username'] as String?),
      avatarUrl: own || visibility != ReviewVisibility.public ? null : json['avatarUrl'] as String?,
      ownReview: own || (json['ownReview'] as bool),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
