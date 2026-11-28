import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../models/social_review.dart';
import '../../models/social_rating_summary.dart';
import '../../data/social_api_repository.dart';

class StoryReviewsController extends ChangeNotifier {
  StoryReviewsController._(this._repository, this._target) {
    _subscription = _repository.api.auth.authStateChanges().listen((identity) {
      if (identity?.uid != _repository.expectedUid) {
        _invalidateSession();
      }
    });
  }

  factory StoryReviewsController(
    ApiClient api, {
    required String expectedUid,
    required String storyKey,
  }) => StoryReviewsController._(
    SocialApiRepository(api, expectedUid: expectedUid),
    SocialTarget.story(storyKey),
  );

  final SocialApiRepository _repository;
  final SocialTarget _target;
  late final StreamSubscription<dynamic> _subscription;
  List<SocialReview> _reviews = const [];
  SocialReview? _ownReview;
  SocialRatingSummary? _summary;
  bool _busy = false;
  bool _loaded = false;
  bool _disposed = false;
  bool _invalidated = false;
  String? _error;

  bool get _active => !_disposed && !_invalidated &&
      _repository.api.auth.currentUser?.uid == _repository.expectedUid;
  bool get busy => _active && _busy;
  bool get loaded => _active && _loaded;
  String? get error => _active ? _error : 'La sesión cambió. Vuelve a abrir la historia.';
  List<SocialReview> get reviews => _active ? _reviews : const [];
  SocialReview? get ownReview => _active ? _ownReview : null;
  SocialRatingSummary? get summary => _active ? _summary : null;

  void _invalidateSession() {
    if (_disposed || _invalidated) return;
    _invalidated = true;
    _reviews = const [];
    _ownReview = null;
    _summary = null;
    _loaded = false;
    _busy = false;
    notifyListeners();
  }

  void _requireSession() {
    if (!_active) throw ApiFailure.forStatus(401);
  }

  Future<void> _reload(SocialTarget target) async {
    final summary = await _repository.ratingSummary(target);
    final own = await _repository.ownReview(target);
    final reviews = await _repository.listReviews(target);
    _requireSession();
    _summary = summary;
    _ownReview = own;
    _reviews = List.unmodifiable(reviews);
    _loaded = true;
  }

  String _message(Object error) => error is ApiFailure
      ? error.message
      : 'No pudimos cargar o actualizar las reseñas.';

  Future<bool> refresh() => _run();

  Future<bool> _run([Future<void> Function(SocialTarget)? mutation]) async {
    if (_disposed || _busy) return false;
    if (!_active) {
      _invalidateSession();
      return false;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    var committed = false;
    try {
      _requireSession();
      final target = _target;
      if (mutation != null) {
        await mutation(target);
        committed = true;
        _requireSession();
      }
      await _reload(target);
      return true;
    } catch (error) {
      if (_active) {
        _error = committed
            ? 'El cambio se guardó, pero no se pudo actualizar la lista. Recarga las reseñas.'
            : _message(error);
      }
      return committed && _active;
    } finally {
      if (!_disposed) {
        _busy = false;
        if (!_active) {
          _invalidateSession();
        } else {
          notifyListeners();
        }
      }
    }
  }

  Future<bool> save({
    required int rating,
    required String text,
    required ReviewVisibility visibility,
  }) => _run((target) async {
    final content = text.trim();
    if (rating < 1 || rating > 5 || content.length > 500 || content.contains('\u0000')) {
      throw const ApiFailure(400, 'Selecciona de 1 a 5 estrellas y escribe hasta 500 caracteres.');
    }
    final saved = await _repository.saveReview(target,
      rating: rating, reviewText: content, visibility: visibility);
    if (_active) {
      _ownReview = saved;
      _summary = null;
      _reviews = const [];
      _loaded = false;
    }
  });

  Future<bool> delete() => _run((target) async {
    await _repository.deleteReview(target);
    if (_active) {
      _ownReview = null;
      _summary = null;
      _reviews = const [];
      _loaded = false;
    }
  });

  @override
  void dispose() {
    _disposed = true;
    _reviews = const [];
    _ownReview = null;
    _summary = null;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
