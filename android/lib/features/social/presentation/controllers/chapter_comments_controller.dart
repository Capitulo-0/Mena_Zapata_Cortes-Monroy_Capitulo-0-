import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../models/social_comment.dart';
import '../../data/social_api_repository.dart';

class ChapterCommentsController extends ChangeNotifier {
  ChapterCommentsController._(this._repository, this._target) {
    _subscription = _repository.api.auth.authStateChanges().listen((identity) {
      if (identity?.uid != _repository.expectedUid) {
        _invalidateSession();
      }
    });
  }

  factory ChapterCommentsController(
    ApiClient api, {
    required String expectedUid,
    required String storyKey,
    required String chapterId,
  }) => ChapterCommentsController._(
    SocialApiRepository(api, expectedUid: expectedUid),
    SocialTarget.chapter(storyKey, chapterId),
  );

  final SocialApiRepository _repository;
  final SocialTarget _target;
  late final StreamSubscription<dynamic> _subscription;
  List<SocialComment> _comments = const [];
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
  List<SocialComment> get comments => _active ? _comments : const [];
  List<SocialComment> get roots => List.unmodifiable(
    comments.where((comment) => comment.parentId == null),
  );

  List<SocialComment> repliesTo(int commentId) => List.unmodifiable(
    comments.where((comment) => comment.parentId == commentId),
  );

  void _invalidateSession() {
    if (_disposed || _invalidated) return;
    _invalidated = true;
    _comments = const [];
    _loaded = false;
    _busy = false;
    notifyListeners();
  }

  void _requireSession() {
    if (!_active) throw ApiFailure.forStatus(401);
  }

  Future<void> _reload(SocialTarget target) async {
    final result = await _repository.listComments(target);
    _requireSession();
    _comments = List.unmodifiable(result);
    _loaded = true;
  }

  String _message(Object error) => error is ApiFailure
      ? error.message
      : 'No pudimos cargar o actualizar los comentarios.';

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
            ? 'El cambio se guardó, pero no se pudo actualizar la lista. Recarga los comentarios.'
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

  String _content(String value) {
    final text = value.trim();
    if (text.isEmpty || text.length > 220 || text.contains('\u0000')) {
      throw const ApiFailure(400, 'Escribe un comentario de 1 a 220 caracteres.');
    }
    return text;
  }

  Future<bool> publish(String text, {required bool anonymous, int? parentId}) =>
      _run((target) async {
        await _repository.createComment(target,
          content: _content(text), anonymous: anonymous, parentId: parentId);
      });

  Future<bool> edit(int id, String text, {required bool anonymous}) =>
      _run((target) async {
        await _repository.updateComment(target, id,
          content: _content(text), anonymous: anonymous);
      });

  Future<bool> delete(int id) =>
      _run((target) => _repository.deleteComment(target, id));

  Future<bool> setLiked(int id, bool liked) =>
      _run((target) => _repository.setLiked(target, id, liked));

  Future<bool> report(int id, String reason) => _run((target) async {
    final text = reason.trim();
    if (text.isEmpty || text.length > 500 || text.contains('\u0000')) {
      throw const ApiFailure(400, 'Escribe un motivo de 1 a 500 caracteres.');
    }
    await _repository.reportComment(target, id, text);
  });

  Future<bool> setHidden(int id, bool hidden) => _run((target) async {
    final allowed = comments.any((comment) =>
        comment.id == id && comment.canModerate && !comment.deleted);
    if (!allowed) throw ApiFailure.forStatus(403);
    await _repository.setHidden(target, id, hidden);
  });

  @override
  void dispose() {
    _disposed = true;
    _comments = const [];
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
