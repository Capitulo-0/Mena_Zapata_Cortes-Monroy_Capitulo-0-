import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/auth/data/firebase_auth_repository.dart';
import 'package:android/features/auth/domain/auth_repository.dart';

class FakeCredential extends Fake implements UserCredential {}

class PopupAuth extends Fake implements FirebaseAuth {
  bool popupCalled = false;
  String? failureCode;
  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async {
    expect(provider, isA<GoogleAuthProvider>());
    popupCalled = true;
    return FakeCredential();
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(
      code: failureCode!,
      message: 'do-not-echo-internal-payload',
    );
  }
}

void main() {
  test(
    'Chrome Google uses Firebase popup without invoking native Google SDK',
    () async {
      final auth = PopupAuth();
      await FirebaseAuthRepository(auth: auth).signInWithGoogle();
      expect(auth.popupCalled, true);
    },
    skip: !kIsWeb,
  );
  final expectedMessages = <String, String>{
    'unauthorized-domain': 'no está autorizado',
    'popup-blocked': 'bloqueó',
    'web-storage-unsupported': 'almacenamiento',
    'operation-not-supported-in-this-environment': 'HTTPS o localhost',
    'invalid-api-key': 'configuración Firebase',
    'popup-closed-by-user': 'canceló',
    'configuration-not-found': 'configuración Firebase',
  };
  for (final code in expectedMessages.keys) {
    test('sanitizes Web Auth error $code', () async {
      final auth = PopupAuth()..failureCode = code;
      await expectLater(
        FirebaseAuthRepository(auth: auth)
            .login('fixture@example.test', 'fixture-only'),
        throwsA(
          isA<AuthFailure>()
              .having(
                (failure) => failure.message,
                'actionable message',
                contains(expectedMessages[code]!),
              )
              .having(
                (failure) => failure.message.contains('do-not-echo'),
                'sanitized',
                false,
              ),
        ),
      );
    });
  }
}
