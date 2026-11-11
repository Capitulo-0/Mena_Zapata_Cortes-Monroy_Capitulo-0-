import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/config/firebase_configuration.dart';

FirebaseWebConfiguration fixture({
  String apiKey = 'not-a-real-api-key',
  String appId = '1:123456:web:fixture',
  String sender = '123456',
  String authDomain = 'fixture.example.test',
}) => FirebaseWebConfiguration(
  apiKey: apiKey,
  appId: appId,
  messagingSenderId: sender,
  projectId: 'fixture-project',
  authDomain: authDomain,
);

void main() {
  test(
    'native initialization keeps native options even when Web is absent',
    () {
      expect(FirebaseWebConfiguration.optionsForPlatform(isWeb: false), isNull);
    },
  );
  test('missing Web configuration fails before SDK initialization', () {
    expect(
      () => FirebaseWebConfiguration.optionsForPlatform(isWeb: true),
      throwsA(
        isA<FirebaseConfigurationException>().having(
          (failure) => failure.message,
          'help',
          contains('--dart-define-from-file'),
        ),
      ),
    );
  });
  test('external Web configuration builds explicit options', () {
    final options = FirebaseWebConfiguration.optionsForPlatform(
      isWeb: true,
      web: fixture(),
    );
    expect(options, isA<FirebaseOptions>());
    expect(options!.appId, '1:123456:web:fixture');
    expect(options.projectId, 'fixture-project');
    expect(options.authDomain, 'fixture.example.test');
  });
  test('Android app id cannot be reused for Web', () {
    expect(
      () => fixture(appId: '1:123456:android:fixture').toOptions(),
      throwsA(isA<FirebaseConfigurationException>()),
    );
  });
  test('Web app id and messaging sender must agree', () {
    expect(
      () => fixture(sender: '999999').toOptions(),
      throwsA(isA<FirebaseConfigurationException>()),
    );
  });
  test(
    'auth domain is a hostname without protocol, paths, credentials or port',
    () {
      for (final domain in [
        'https://fixture.example.test',
        'fixture.example.test/path',
        'fixture.example.test:443',
        'user:password@fixture.example.test',
        'fixture.example.test?query=value',
      ]) {
        expect(
          () => fixture(authDomain: domain).toOptions(),
          throwsA(isA<FirebaseConfigurationException>()),
        );
      }
    },
  );
  test('invalid config errors never echo supplied values', () {
    expect(
      () => fixture(apiKey: ' do-not-echo-value ').toOptions(),
      throwsA(
        isA<FirebaseConfigurationException>().having(
          (failure) => failure.message.contains('do-not-echo-value'),
          'sanitized',
          false,
        ),
      ),
    );
  });
}
