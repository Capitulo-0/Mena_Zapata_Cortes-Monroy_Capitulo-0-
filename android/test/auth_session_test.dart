import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/features/auth/domain/auth_repository.dart';
import 'package:android/features/auth/presentation/controllers/session_controller.dart';
import 'package:android/features/auth/presentation/controllers/forgot_password_controller.dart';

import 'support/auth_fakes.dart';

void main() {
  late FakeAuth auth;
  late FakeAccounts accounts;
  late SessionController session;
  Future<void> flush() => Future<void>.delayed(Duration.zero);
  setUp(() {
    auth = FakeAuth();
    accounts = FakeAccounts();
    session = SessionController(auth: auth, accounts: accounts);
  });
  tearDown(() async {
    session.dispose();
    await auth.close();
  });

  test('restores signed-out Firebase session', () async {
    session.start();
    await flush();
    expect(session.phase, SessionPhase.signedOut);
    expect(accounts.calls, 0);
  });
  test('restores authenticated session only after provisioning', () async {
    auth.identity = fixtureIdentity;
    final pending = Completer<dynamic>();
    accounts.handler = () async => await pending.future;
    session.start();
    await flush();
    expect(session.phase, SessionPhase.preparing);
    expect(session.user, isNull);
    pending.complete(fixtureUser);
    await flush();
    expect(session.phase, SessionPhase.ready);
    expect(session.user?.id, 42);
  });
  test('login prepares domain user and logout clears session', () async {
    session.start();
    await flush();
    await session.login('reader@example.test', 'fixture-password');
    expect(session.phase, SessionPhase.ready);
    await session.logout();
    expect(session.phase, SessionPhase.signedOut);
    expect(auth.logoutCalls, 1);
    expect(session.user, isNull);
    expect(auth.currentUser, isNull);
  });
  test('login error does not provision or enter main', () async {
    auth.loginFailure = const AuthFailure('Credenciales incorrectas.');
    await session.login('reader@example.test', 'incorrect');
    expect(session.phase, SessionPhase.signedOut);
    expect(session.message, 'Credenciales incorrectas.');
    expect(accounts.calls, 0);
  });
  for (final code in [401, 409, 503]) {
    test('backend $code preserves Firebase identity and blocks main', () async {
      accounts.failure = ApiFailure.forStatus(code);
      await session.login('reader@example.test', 'fixture-password');
      expect(auth.currentUser, isNotNull);
      expect(auth.logoutCalls, 0);
      expect(session.user, isNull);
      expect(session.phase, SessionPhase.backendFailure);
      expect(session.message, ApiFailure.forStatus(code).message);
      accounts.failure = null;
      await session.retry();
      expect(session.phase, SessionPhase.ready);
    });
  }
  test(
    'new password account waits for email verification then provisions',
    () async {
      await session.register(
        'Reader',
        'reader@example.test',
        'fixture-password',
      );
      expect(session.phase, SessionPhase.verificationRequired);
      expect(accounts.calls, 0);
      await session.resendVerification();
      expect(auth.verificationCalls, 2);
      auth.verifyOnReload = true;
      await session.retry();
      expect(session.phase, SessionPhase.ready);
      expect(auth.refreshes, contains(true));
    },
  );
  test('Google uses same provisioning flow', () async {
    await session.google();
    expect(session.phase, SessionPhase.ready);
    expect(accounts.calls, 1);
  });
  test('Google cancellation stays signed out', () async {
    auth.loginFailure = const AuthFailure('Google cancelado.', cancelled: true);
    await session.google();
    expect(session.phase, SessionPhase.signedOut);
    expect(accounts.calls, 0);
  });
  test('guest remains independent of null Firebase events', () async {
    session.start();
    await flush();
    session.enterGuest();
    auth.emit(null);
    await flush();
    expect(session.phase, SessionPhase.guest);
    expect(accounts.calls, 0);
    session.leaveGuest();
    expect(session.phase, SessionPhase.signedOut);
  });
  test('external signout supersedes a pending backend response', () async {
    auth.identity = fixtureIdentity;
    final pending = Completer<dynamic>();
    accounts.handler = () async => await pending.future;
    session.start();
    await flush();
    auth.emit(null);
    await flush();
    pending.complete(fixtureUser);
    await flush();
    expect(session.phase, SessionPhase.signedOut);
    expect(session.user, isNull);
  });
  test(
    'password recovery sends real service operation without local code',
    () async {
      final controller = ForgotPasswordController(auth);
      controller.emailController.text = 'reader@example.test';
      expect(await controller.sendResetEmail(), isNull);
      expect(auth.resetCalls, 1);
      expect(controller.currentStep, RecoveryStep.success);
      controller.dispose();
    },
  );
}
