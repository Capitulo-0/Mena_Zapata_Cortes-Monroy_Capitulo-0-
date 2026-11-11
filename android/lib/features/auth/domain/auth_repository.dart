class AuthIdentity {
  const AuthIdentity({
    required this.uid,
    this.email,
    required this.emailVerified,
  });
  final String uid;
  final String? email;
  final bool emailVerified;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
}

abstract interface class AuthRepository {
  AuthIdentity? get currentUser;
  Stream<AuthIdentity?> authStateChanges();
  Future<void> login(String email, String password);
  Future<void> register(String name, String email, String password);
  Future<void> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> reloadUser();
  Future<String?> getIdToken({bool forceRefresh = false});
  Future<void> signOut();
}
