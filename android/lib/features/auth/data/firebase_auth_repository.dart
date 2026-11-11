import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;
  static Future<void>? _googleInitialization;

  AuthIdentity? _identity(User? user) => user == null
      ? null
      : AuthIdentity(
          uid: user.uid,
          email: user.email,
          emailVerified: user.emailVerified,
        );
  @override
  AuthIdentity? get currentUser => _identity(_auth.currentUser);
  @override
  Stream<AuthIdentity?> authStateChanges() =>
      _auth.authStateChanges().map(_identity);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(switch (error.code) {
        'invalid-email' => 'Ingresa un correo electrónico válido.',
        'email-already-in-use' => 'Ese correo ya está registrado. Inicia sesión o recupera tu contraseña.',
        'weak-password' =>
          'La contraseña no cumple los requisitos de seguridad.',
        'invalid-credential' || 'wrong-password' || 'user-not-found' =>
          'No pudimos iniciar sesión. Revisa tus credenciales.',
        'user-disabled' => 'Esta cuenta está deshabilitada.',
        'network-request-failed' =>
          'No hay conexión. Revisa tu red e inténtalo otra vez.',
        'too-many-requests' =>
          'Demasiados intentos. Espera un momento antes de reintentar.',
        'account-exists-with-different-credential' =>
          'Ya existe una cuenta con otro método de acceso. Utiliza ese método.',
        'unauthorized-domain' => 'Este dominio no está autorizado en Firebase Authentication. Revisa los dominios autorizados del proyecto.',
        'popup-blocked' => 'Chrome bloqueó la ventana de Google. Permite ventanas emergentes para esta aplicación y reintenta.',
        'operation-not-supported-in-this-environment' => 'Este navegador no permite iniciar sesión en este entorno. Usa HTTPS o localhost.',
        'web-storage-unsupported' => 'El navegador bloquea el almacenamiento necesario para la sesión. Revisa sus permisos.',
        'invalid-api-key' ||
        'app-not-authorized' ||
        'configuration-not-found' ||
        'auth-domain-config-required' => 'La configuración Firebase de esta plataforma no es válida o no está autorizada. Revisa la app Web del proyecto.',
        'popup-closed-by-user' ||
        'cancelled-popup-request' => 'Se canceló el acceso con Google.',
        _ => 'No pudimos completar la autenticación. Inténtalo nuevamente.',
      });
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure(
          'Se canceló el acceso con Google.',
          cancelled: true,
        );
      }
      throw const AuthFailure(
        'No pudimos conectar con Google. Revisa tu conexión y la configuración de acceso.',
      );
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'No pudimos completar la operación. Inténtalo nuevamente.',
      );
    }
  }

  @override
  Future<void> login(String email, String password) => _guard(() async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  });
  @override
  Future<void> register(String name, String email, String password) =>
      _guard(() async {
        final result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await result.user!.updateDisplayName(name.trim());
        await result.user!.sendEmailVerification();
      });
  @override
  Future<void> signInWithGoogle() => _guard(() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      return;
    }
    _googleInitialization ??= GoogleSignIn.instance.initialize();
    await _googleInitialization;
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const AuthFailure(
        'El acceso con Google no está disponible en esta plataforma.',
      );
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthFailure('Google no pudo confirmar tu identidad.');
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  });
  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  @override
  Future<void> sendEmailVerification() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Inicia sesión nuevamente.');
    await user.sendEmailVerification();
  });
  @override
  Future<void> reloadUser() => _guard(() async {
    await _auth.currentUser?.reload();
  });
  @override
  Future<String?> getIdToken({bool forceRefresh = false}) =>
      _guard(() async => _auth.currentUser?.getIdToken(forceRefresh));
  @override
  Future<void> signOut() => _guard(() async {
    // Google cleanup is best effort; it must never prevent Firebase signOut.
    if (!kIsWeb && _googleInitialization != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        /* Firebase remains authoritative. */
      }
    }
    await _auth.signOut();
  });
}
