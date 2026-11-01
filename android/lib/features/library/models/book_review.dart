class BookReview {
  const BookReview({
    required this.rating,
    required this.text,
    this.isPublic = true,
  });

  final int rating;
  final String text;
  final bool isPublic;
}
