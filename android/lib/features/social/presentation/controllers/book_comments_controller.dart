import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../library/models/library_book.dart';
import '../../models/social_comment.dart';
import '../../data/social_api_repository.dart';
import '../../data/social_book_resolver.dart';

class BookCommentsController extends ChangeNotifier {
  BookCommentsController._(this._repository, this._resolve) {
    _subscription = _repository.api.auth.authStateChanges().listen((identity) {
      if (identity?.uid != _repository.expectedUid) {
        _invalidateSession();
      }
    });
  }

  factory BookCommentsController.home(
    ApiClient api, {
    required String expectedUid,
    required Map<String, dynamic> book,
  }) {
    final resolver = SocialBookResolver(api, expectedUid: expectedUid);
    final snapshot = Map<String, dynamic>.unmodifiable(book);
    return BookCommentsController._(
      SocialApiRepository(api, expectedUid: expectedUid),
      () => resolver.fromHome(snapshot),
    );
  }

  factory BookCommentsController.library(
    ApiClient api, {
    required String expectedUid,
    required LibraryBook book,
  }) {
    final resolver = SocialBookResolver(api, expectedUid: expectedUid);
    return BookCommentsController._(
      SocialApiRepository(api, expectedUid: expectedUid),
      () => resolver.fromLibrary(book),
    );
  }

  final SocialApiRepository _repository;
  final Future<SocialTarget> Function() _resolve;
  late final StreamSubscription<dynamic> _subscription;
  SocialTarget? _target;
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
  String? get error => _active ? _error : 'La sesión cambió. Vuelve a abrir el libro.';
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
    _target = null;
    _loaded = false;
    _busy = false;
    notifyListeners();
  }

  void _requireSession() {
    if (!_active) throw ApiFailure.forStatus(401);
  }

  Future<SocialTarget> _bookTarget() async {
    _requireSession();
    final target = _target ?? await _resolve();
    _requireSession();
    _target = target;
    return target;
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
      final target = await _bookTarget();
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
    if (text.isEmpty || text.length > 300) {
      throw const ApiFailure(400, 'Escribe un comentario de 1 a 300 caracteres.');
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
    if (text.isEmpty || text.length > 500) {
      throw const ApiFailure(400, 'Escribe un motivo de 1 a 500 caracteres.');
    }
    await _repository.reportComment(target, id, text);
  });

  @override
  void dispose() {
    _disposed = true;
    _comments = const [];
    _target = null;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
