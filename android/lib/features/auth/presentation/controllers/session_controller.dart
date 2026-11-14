import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/account_repository.dart';
import '../../data/pending_username_store.dart';
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
  final PendingUsernameStore pendingUsernames = PendingUsernameStore();

  StreamSubscription<AuthIdentity?>? _subscription;

  SessionPhase phase = SessionPhase.signedOut;
  DomainUser? user;
  String? message;
  bool busy = false;
  bool usernameRequired = false;

  bool _disposed = false;
  bool _authOperation = false;
  String? _observedUid;
  int _generation = 0;
  String? _preparedUid;

  String? get uid => auth.currentUser?.uid;

  void start() {
    _subscription ??= auth.authStateChanges().listen(
      (identity) {
        if (_authOperation ||
            (identity == null && phase == SessionPhase.guest)) {
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
        usernameRequired = false;

        phase = auth.currentUser == null
            ? SessionPhase.signedOut
            : SessionPhase.backendFailure;

        message = 'No pudimos restaurar la sesión. Inténtalo nuevamente.';
        _notify();
      },
    );
  }

  Future<void> _prepare(AuthIdentity? identity) async {
    final generation = ++_generation;

    _observedUid = identity?.uid;
    user = null;
    _preparedUid = null;
    message = null;
    usernameRequired = false;

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
      final username = await pendingUsernames.get(identity.uid);

      if (!_current(generation, identity.uid)) return;

      final domain = await accounts.provisionAndLoad(username: username);

      if (!_current(generation, identity.uid)) return;

      user = domain;
      _preparedUid = identity.uid;
      phase = SessionPhase.ready;

      if (username != null) {
        try {
          await pendingUsernames.remove(identity.uid);
        } catch (_) {
          // No impedir el acceso si falla la limpieza local.
        }
      }
    } on ApiFailure catch (failure) {
      if (!_current(generation, identity.uid)) return;

      if (failure.code == 'USERNAME_TAKEN' ||
          failure.code == 'USERNAME_REQUIRED') {
        usernameRequired = true;
        message = failure.message;
      } else {
        usernameRequired = false;
        message = failure.message;
      }

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
  void applyUpdatedProfile(DomainUser updated, {required String expectedUid}) {
    if (_disposed ||
        phase != SessionPhase.ready ||
        auth.currentUser?.uid != expectedUid ||
        _preparedUid != expectedUid ||
        user?.id != updated.id) {
      return;
    }

    user = updated;
    _notify();
  }

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
      failureMessage =
          'No pudimos completar la autenticación. Inténtalo nuevamente.';
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

  Future<void> register(
    String name,
    String username,
    String email,
    String password,
  ) => _authenticate(() async {
    await auth.register(name, email, password);

    final uid = auth.currentUser?.uid;

    if (uid == null) {
      throw const AuthFailure(
        'No pudimos identificar la cuenta recién creada.',
      );
    }

    try {
      await pendingUsernames.save(uid, username);
    } catch (_) {
      throw const AuthFailure(
        'La cuenta Firebase se creó, pero no pudimos guardar '
        'temporalmente tu nombre de usuario. '
        'No intentes registrarte nuevamente con el mismo correo.',
      );
    }
  });

  Future<void> google() => _authenticate(auth.signInWithGoogle);

  Future<void> submitUsername(String username) async {
    if (busy || _disposed) return;

    final identity = auth.currentUser;

    if (identity == null || !identity.emailVerified) {
      message = 'Primero debes verificar tu correo electrónico.';
      _notify();
      return;
    }

    final value = username.trim();

    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(value)) {
      message =
          'El nombre de usuario debe tener entre 3 y 30 caracteres '
          'y solo puede contener letras minúsculas, números y guiones bajos (_).';
      _notify();
      return;
    }

    busy = true;
    message = null;
    _notify();

    try {
      await pendingUsernames.save(identity.uid, value);

      if (_disposed) return;

      await _prepare(identity);
    } catch (_) {
      if (_disposed) return;

      busy = false;
      message =
          'No pudimos guardar tu nombre de usuario. Inténtalo nuevamente.';
      _notify();
    }
  }

  Future<void> retry() async {
    if (busy) return;

    busy = true;
    message = null;
    _notify();

    try {
      await auth.reloadUser();
      await auth.getIdToken(forceRefresh: true);

      if (!_disposed) {
        await _prepare(auth.currentUser);
      }
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

      if (!_disposed) {
        message =
            'Enlace enviado. Revisa tu correo y luego pulsa '
            'Ya verifiqué mi correo.';
      }
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
    usernameRequired = false;
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
      usernameRequired = false;
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
