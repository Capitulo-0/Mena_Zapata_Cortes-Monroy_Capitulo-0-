import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/features/auth/data/account_repository.dart';

import 'support/auth_fakes.dart';

void main() {
  late FakeAuth auth;
  setUp(() => auth = FakeAuth()..identity = fixtureIdentity);
  tearDown(() => auth.close());

  test(
    'provisions then loads me with token and no client identity payload',
    () async {
      final paths = <String>[];
      final client = ApiClient(
        auth: auth,
        baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
          paths.add('${request.method} ${request.url.path}');
          expect(request.headers['authorization'], 'Bearer fixture-token');
          expect(request.followRedirects, false);
          expect(request.body, isEmpty);
          return http.Response(
            jsonEncode({'id': 42, 'email': 'reader@example.test'}),
            200,
          );
        }),
      );
      final me = await ApiAccountRepository(client).provisionAndLoad();
      expect(me.id, 42);
      expect(paths, ['POST /api/me/provision', 'GET /api/me']);
      client.close();
    },
  );
  test('refreshes once on 401 then uses new token', () async {
    var count = 0;
    final client = ApiClient(
      auth: auth,
      baseUrl: 'https://api.example.test',
      client: MockClient((request) async {
        count++;
        expect(
          request.headers['authorization'],
          count == 1
              ? 'Bearer fixture-token'
              : 'Bearer refreshed-fixture-token',
        );
        return http.Response(
          count == 1 ? '{}' : '{"id":42}',
          count == 1 ? 401 : 200,
        );
      }),
    );
    expect(await client.request('GET', '/api/me'), {'id': 42});
    expect(auth.refreshes, [false, true]);
    client.close();
  });
  for (final code in [400, 401, 403, 404, 409, 422, 503]) {
    test('maps $code without leaking response payload', () async {
      var count = 0;
      final client = ApiClient(
        auth: auth,
        baseUrl: 'https://api.example.test',
        client: MockClient((_) async {
          count++;
          return http.Response('sensitive-internal-details', code);
        }),
      );
      await expectLater(
        client.request('GET', '/api/me'),
        throwsA(
          isA<ApiFailure>()
              .having((e) => e.statusCode, 'status', code)
              .having(
                (e) => e.message.contains('sensitive'),
                'sanitized',
                false,
              ),
        ),
      );
      expect(count, code == 401 ? 2 : 1);
      client.close();
    });
  }
  test(
    'rejects credentialed/missing/non-HTTPS production URL before sending',
    () async {
      for (final url in [
        '',
        'https://user:password@api.example.test',
        'http://api.example.test',
        'https://api.example.test/?secret=x',
      ]) {
        final client = ApiClient(
          auth: auth,
          baseUrl: url,
          allowInsecureHttp: false,
          client: MockClient((_) async => throw StateError('must not send')),
        );
        await expectLater(
          client.request('GET', '/api/me'),
          throwsA(isA<ApiFailure>()),
        );
        client.close();
      }
    },
  );
  test('bounds network timeout', () async {
    final client = ApiClient(
      auth: auth,
      baseUrl: 'https://api.example.test',
      timeout: const Duration(milliseconds: 10),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    await expectLater(
      client.request('GET', '/api/me'),
      throwsA(isA<ApiFailure>().having((e) => e.statusCode, 'status', 503)),
    );
    client.close();
  });
  test(
    'does not accept response or retry under a different Firebase account',
    () async {
      final client = ApiClient(
        auth: auth,
        baseUrl: 'https://api.example.test',
        client: MockClient((_) async {
          auth.emit(null);
          return http.Response('{"id":42}', 200);
        }),
      );
      await expectLater(
        client.request('GET', '/api/me'),
        throwsA(isA<ApiFailure>().having((e) => e.statusCode, 'status', 401)),
      );
      client.close();
    },
  );
}
