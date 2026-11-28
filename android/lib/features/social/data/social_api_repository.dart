import '../../../core/network/api_client.dart';
import '../models/social_comment.dart';
import '../models/social_rating_summary.dart';
import '../models/social_review.dart';
import '../models/own_book_review_entry.dart';

/// A book, a published story, or a chapter of a published story.
class SocialTarget {
  const SocialTarget._(this.bookId, this.storyKey, this.chapterId);

  factory SocialTarget.book(int bookId) {
    if (bookId <= 0) throw ArgumentError.value(bookId, 'bookId');
    return SocialTarget._(bookId, null, null);
  }

  factory SocialTarget.story(String storyKey) =>
      SocialTarget._(null, _key(storyKey), null);

  factory SocialTarget.chapter(String storyKey, String chapterId) =>
      SocialTarget._(null, _key(storyKey), _key(chapterId));

  final int? bookId;
  final String? storyKey;
  final String? chapterId;

  static String _key(String value) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(value)) {
      throw ArgumentError('Identificador de Writer inválido.');
    }
    return value;
  }

  String get _base => bookId != null
      ? '/api/books/$bookId'
      : '/api/writer/stories/$storyKey';

  String get _comments {
    if (bookId != null) return '$_base/comments';
    if (chapterId == null) {
      throw ArgumentError('Los comentarios de Writer requieren un capítulo.');
    }
    return '$_base/chapters/$chapterId/comments';
  }

  String get _reviews {
    if (chapterId != null) {
      throw ArgumentError('La reseña corresponde a la historia completa.');
    }
    return '$_base/reviews';
  }
}

/// Uses the existing HTTP client and is scoped to one authenticated account.
/// Recreate this repository whenever the signed-in account changes.
class SocialApiRepository {
  SocialApiRepository(this.api, {required this.expectedUid}) {
    if (expectedUid.isEmpty) throw ArgumentError('Se requiere una sesión.');
  }

  final ApiClient api;
  final String expectedUid;

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => api.requestJson(
    method,
    path,
    body: body,
    expectedUid: expectedUid,
  );

  T _object<T>(Object? data, T Function(Map<String, dynamic>) parse) {
    try {
      return parse(data as Map<String, dynamic>);
    } on FormatException {
      throw const ApiFailure(502, 'La respuesta social no es válida.');
    } on TypeError {
      throw const ApiFailure(502, 'La respuesta social no es válida.');
    }
  }

  List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) parse) {
    if (data is! List) {
      throw const ApiFailure(502, 'La respuesta social no es válida.');
    }
    return data.map((item) => _object(item, parse)).toList(growable: false);
  }

  String _commentPath(SocialTarget target, int id) {
    if (id <= 0) throw ArgumentError.value(id, 'commentId');
    return '${target._comments}/$id';
  }

  Future<List<SocialComment>> listComments(SocialTarget target) async =>
      _list(await _request('GET', target._comments), SocialComment.fromJson);

  Future<SocialComment> createComment(
    SocialTarget target, {
    required String content,
    required bool anonymous,
    int? parentId,
  }) async => _object(
    await _request('POST', target._comments, body: {
      'content': content,
      'anonymous': anonymous,
      'parentId': ?parentId,
    }),
    SocialComment.fromJson,
  );

  Future<SocialComment> updateComment(
    SocialTarget target,
    int commentId, {
    required String content,
    required bool anonymous,
  }) async => _object(
    await _request('PATCH', _commentPath(target, commentId), body: {
      'content': content,
      'anonymous': anonymous,
    }),
    SocialComment.fromJson,
  );

  Future<void> deleteComment(SocialTarget target, int commentId) async {
    await _request('DELETE', _commentPath(target, commentId));
  }

  Future<void> setLiked(SocialTarget target, int commentId, bool liked) async {
    await _request(
      liked ? 'POST' : 'DELETE',
      '${_commentPath(target, commentId)}/likes',
    );
  }

  Future<void> reportComment(
    SocialTarget target,
    int commentId,
    String reason,
  ) async {
    await _request('POST', '${_commentPath(target, commentId)}/reports', body: {
      'reason': reason,
    });
  }

  Future<void> setHidden(
    SocialTarget target,
    int commentId,
    bool hidden,
  ) async {
    if (target.chapterId == null) {
      throw ArgumentError('La moderación de Writer requiere un capítulo.');
    }
    await _request('PATCH', '${_commentPath(target, commentId)}/visibility',
        body: {'hidden': hidden});
  }

  Future<List<SocialReview>> listReviews(SocialTarget target) async =>
      _list(await _request('GET', target._reviews),
          (json) => SocialReview.fromJson(json));

  Future<SocialRatingSummary> ratingSummary(SocialTarget target) async =>
      _object(await _request('GET', '${target._reviews}/summary'),
          SocialRatingSummary.fromJson);

  /// The API uses 404 both for an absent review and an absent target.
  /// Check the target using ratingSummary before interpreting null as no review.
  Future<List<OwnBookReviewEntry>> listOwnBookReviews() async => _list(
    await _request('GET', '/api/me/book-reviews'),
    OwnBookReviewEntry.fromJson,
  );

  Future<SocialReview?> ownReview(SocialTarget target) async {
    try {
      return _object<SocialReview>(await _request('GET', '${target._reviews}/mine'),
          (json) => SocialReview.fromJson(json, own: true));
    } on ApiFailure catch (error) {
      if (error.statusCode != 404) rethrow;
      await ratingSummary(target);
      return null;
    }
  }

  Future<SocialReview> saveReview(
    SocialTarget target, {
    required int rating,
    String? reviewText,
    required ReviewVisibility visibility,
  }) async => _object(
    await _request('PUT', '${target._reviews}/mine', body: {
      'rating': rating,
      'reviewText': reviewText,
      'visibility': visibility.apiValue,
    }),
    (json) => SocialReview.fromJson(json, own: true),
  );

  Future<void> deleteReview(SocialTarget target) async {
    await _request('DELETE', '${target._reviews}/mine');
  }
}
