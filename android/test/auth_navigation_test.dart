import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android/app.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/core/session/local_account_scope.dart';
import 'package:android/features/auth/presentation/controllers/session_controller.dart';
import 'package:android/features/auth/presentation/screens/auth_screen.dart';
import 'package:android/features/auth/presentation/screens/session_preparation_screen.dart';
import 'package:android/features/home/presentation/screens/main_shell_screen.dart';

import 'support/auth_fakes.dart';
import 'library_regression_test.dart' show installLocalTestAssets;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  late FakeAuth auth;
  late FakeAccounts accounts;
  late SessionController session;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuth();
    accounts = FakeAccounts();
    session = SessionController(auth: auth, accounts: accounts);
  });
  tearDown(() async {
    session.dispose();
    await auth.close();
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(CapituloCeroApp(session: session));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('signed-out starts at Auth and guest remains available', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(AuthScreen), findsOneWidget);
    tester.widget<AuthScreen>(find.byType(AuthScreen)).onAuthenticated(true);
    await tester.pumpAndSettle();
    expect(
      tester.widget<MainShellScreen>(find.byType(MainShellScreen)).isGuest,
      true,
    );
    expect(accounts.calls, 0);
    session.leaveGuest();
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
  });
  testWidgets(
    'restored identity enters main only after backend and logout returns to Auth',
    (tester) async {
      auth.identity = fixtureIdentity;
      await open(tester);
      expect(find.byType(MainShellScreen), findsOneWidget);
      expect(
        tester.widget<MainShellScreen>(find.byType(MainShellScreen)).isGuest,
        false,
      );
      await session.logout();
      await tester.pumpAndSettle();
      expect(find.byType(MainShellScreen), findsNothing);
      expect(find.byType(AuthScreen), findsOneWidget);
    },
  );
  testWidgets(
    'backend failure after Firebase login blocks main and allows retry',
    (tester) async {
      auth.identity = fixtureIdentity;
      accounts.failure = ApiFailure.forStatus(503);
      await open(tester);
      expect(find.byType(SessionPreparationScreen), findsOneWidget);
      expect(find.byType(MainShellScreen), findsNothing);
      expect(auth.currentUser, isNotNull);
      accounts.failure = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.byType(MainShellScreen), findsOneWidget);
    },
  );
  testWidgets('pending provisioning never presents a prepared session', (
    tester,
  ) async {
    auth.identity = fixtureIdentity;
    final pending = Completer<dynamic>();
    accounts.handler = () async => await pending.future;
    await tester.pumpWidget(CapituloCeroApp(session: session));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byType(SessionPreparationScreen), findsOneWidget);
    expect(find.byType(MainShellScreen), findsNothing);
    pending.complete(fixtureUser);
    await tester.pumpAndSettle();
    expect(find.byType(MainShellScreen), findsOneWidget);
  });
  testWidgets('secondary routes inherit account scope and close on logout', (
    tester,
  ) async {
    auth.identity = fixtureIdentity;
    await open(tester);
    final shellContext = tester.element(find.byType(MainShellScreen));
    unawaited(
      Navigator.of(shellContext).push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: Text(LocalAccountScope.read(context) ?? 'missing-scope'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('fixture-user'), findsOneWidget);
    await session.logout();
    await tester.pumpAndSettle();
    expect(find.text('fixture-user'), findsNothing);
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
