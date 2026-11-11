import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/account_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/domain_user.dart';

enum SessionPhase {
  signedOut,
  preparing,
  verificationRequired,
  backendFailure,
  ready,
  guest,
}

class SessionController extends ChangeNotifier {
  SessionController({required this.auth, required this.accounts});
  final AuthRepository auth;
  final AccountRepository accounts;
  StreamSubscription<AuthIdentity?>? _subscription;
  SessionPhase phase = SessionPhase.signedOut;
  DomainUser? user;
  String? message;
  bool busy = false;
  bool _disposed = false;
  bool _authOperation = false;
  String? _observedUid;
  int _generation = 0;
  String? _preparedUid;
  String? get uid => auth.currentUser?.uid;

  void start() {
    _subscription ??= auth.authStateChanges().listen(
      (identity) {
        if (_authOperation || (identity == null && phase == SessionPhase.guest)) {
          return;
        }
        if (busy && identity?.uid == _observedUid) return;
        if (identity?.uid == _preparedUid && phase == SessionPhase.ready) {
          return;
        }
        unawaited(_prepare(identity));
      },
      onError: (Object _) {
        if (_disposed) return;
        _generation++;
        user = null;
        _preparedUid = null;
        busy = false;
        phase = auth.currentUser == null
            ? SessionPhase.signedOut
            : SessionPhase.backendFailure;
        message = 'No pudimos restaurar la sesión. Inténtalo nuevamente.';
        notifyListeners();
      },
    );
  }

  Future<void> _prepare(AuthIdentity? identity) async {
    final generation = ++_generation;
    _observedUid = identity?.uid;
    user = null;
    _preparedUid = null;
    message = null;
    if (identity == null) {
      phase = SessionPhase.signedOut;
      busy = false;
      _notify();
      return;
    }
    if (!identity.emailVerified) {
      phase = SessionPhase.verificationRequired;
      busy = false;
      _notify();
      return;
    }
    phase = SessionPhase.preparing;
    busy = true;
    _notify();
    try {
      final domain = await accounts.provisionAndLoad();
      if (!_current(generation, identity.uid)) return;
      user = domain;
      _preparedUid = identity.uid;
      phase = SessionPhase.ready;
    } on ApiFailure catch (failure) {
      if (!_current(generation, identity.uid)) return;
      message = failure.message;
      phase = SessionPhase.backendFailure;
    } on AuthFailure catch (failure) {
      if (!_current(generation, identity.uid)) return;
      message = failure.message;
      phase = SessionPhase.backendFailure;
    } catch (_) {
      if (!_current(generation, identity.uid)) return;
      message =
          'No pudimos preparar tu cuenta. Tu sesión Firebase se conserva.';
      phase = SessionPhase.backendFailure;
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  bool _current(int generation, String uid) =>
      !_disposed && generation == _generation && auth.currentUser?.uid == uid;

  Future<void> _authenticate(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    String? failureMessage;
    _authOperation = true;
    try {
      await action();
    } on AuthFailure catch (failure) {
      failureMessage = failure.message;
    } catch (_) {
      failureMessage = 'No pudimos iniciar sesión. Inténtalo nuevamente.';
    }
    if (_disposed) return;
    _authOperation = false;
    busy = false;
    await _prepare(auth.currentUser);
    if (!_disposed && failureMessage != null) {
      message = failureMessage;
      _notify();
    }
  }

  Future<void> login(String email, String password) =>
      _authenticate(() => auth.login(email, password));
  Future<void> register(String name, String email, String password) =>
      _authenticate(() => auth.register(name, email, password));
  Future<void> google() => _authenticate(auth.signInWithGoogle);

  Future<void> retry() async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    try {
      await auth.reloadUser();
      await auth.getIdToken(forceRefresh: true);
      if (!_disposed) await _prepare(auth.currentUser);
    } on AuthFailure catch (failure) {
      if (_disposed) return;
      busy = false;
      message = failure.message;
      _notify();
    } catch (_) {
      if (_disposed) return;
      busy = false;
      message = 'No pudimos actualizar la sesión. Revisa tu conexión.';
      _notify();
    }
  }

  Future<void> resendVerification() async {
    if (busy) return;
    busy = true;
    _notify();
    try {
      await auth.sendEmailVerification();
      if (!_disposed) message = 'Enlace enviado. Revisa tu correo y luego pulsa Ya verifiqué mi correo.';
    } on AuthFailure catch (failure) {
      if (!_disposed) message = failure.message;
    } finally {
      if (!_disposed) {
        busy = false;
        _notify();
      }
    }
  }

  void enterGuest() {
    if (busy || auth.currentUser != null) return;
    _generation++;
    user = null;
    _preparedUid = null;
    message = null;
    phase = SessionPhase.guest;
    _notify();
  }

  void leaveGuest() {
    if (phase != SessionPhase.guest) return;
    phase = SessionPhase.signedOut;
    message = null;
    _notify();
  }

  Future<void> logout() async {
    if (busy) return;
    ++_generation;
    _authOperation = true;
    busy = true;
    _notify();
    try {
      await auth.signOut();
      if (_disposed) return;
      user = null;
      _preparedUid = null;
      message = null;
      phase = SessionPhase.signedOut;
    } on AuthFailure catch (failure) {
      if (!_disposed) message = failure.message;
    } finally {
      if (!_disposed) {
        _authOperation = false;
        busy = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
