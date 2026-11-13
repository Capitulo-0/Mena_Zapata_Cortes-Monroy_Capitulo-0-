import 'dart:async';

import 'package:android/features/auth/domain/auth_repository.dart';
import 'package:android/features/auth/domain/domain_user.dart';
import 'package:android/features/auth/data/account_repository.dart';

const fixtureIdentity = AuthIdentity(
  uid: 'fixture-user',
  email: 'reader@example.test',
  emailVerified: true,
);
const fixtureUser = DomainUser(
  id: 42,
  email: 'reader@example.test',
  displayName: 'Reader',
);

class FakeAuth implements AuthRepository {
  AuthIdentity? identity;
  Object? loginFailure;
  final events = StreamController<AuthIdentity?>.broadcast(sync: true);
  final refreshes = <bool>[];
  int logoutCalls = 0;
  int resetCalls = 0;
  int verificationCalls = 0;
  bool verifyOnReload = false;
  @override
  AuthIdentity? get currentUser => identity;
  @override
  Stream<AuthIdentity?> authStateChanges() async* {
    yield identity;
    yield* events.stream;
  }

  void emit(AuthIdentity? value) {
    identity = value;
    events.add(value);
  }

  @override
  Future<void> login(String email, String password) async {
    if (loginFailure != null) throw loginFailure!;
    emit(fixtureIdentity);
  }

  @override
  Future<void> register(String name, String email, String password) async {
    emit(AuthIdentity(uid: 'fixture-user', email: email, emailVerified: false));
    verificationCalls++;
  }

  @override
  Future<void> signInWithGoogle() => login('', '');
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCalls++;
  }

  @override
  Future<void> sendEmailVerification() async {
    verificationCalls++;
  }

  @override
  Future<void> reloadUser() async {
    if (verifyOnReload && identity != null) {
      identity = AuthIdentity(
        uid: identity!.uid,
        email: identity!.email,
        emailVerified: true,
      );
    }
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    refreshes.add(forceRefresh);
    return identity == null
        ? null
        : forceRefresh
        ? 'refreshed-fixture-token'
        : 'fixture-token';
  }

  @override
  Future<void> signOut() async {
    logoutCalls++;
    emit(null);
  }

  Future<void> close() => events.close();
}

class FakeAccounts implements AccountRepository {
  Object? failure;
  int calls = 0;
  Future<DomainUser> Function()? handler;
  @override
  Future<DomainUser> provisionAndLoad({String? username}) async {
    calls++;
    if (handler != null) return handler!();
    if (failure != null) throw failure!;
    return fixtureUser;
  }
}
