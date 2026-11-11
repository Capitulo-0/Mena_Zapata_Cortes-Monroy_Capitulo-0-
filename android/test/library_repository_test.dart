import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/features/auth/domain/auth_repository.dart';
import 'package:android/features/library/data/library_repository.dart';

import 'support/auth_fakes.dart';
import 'support/library_fakes.dart';

void main() {
  late FakeAuth auth;
  setUp(() => auth = FakeAuth()..identity = fixtureIdentity);
  tearDown(() => auth.close());
  ApiLibraryRepository repo(
    Future<http.Response> Function(http.Request) handler,
  ) => ApiLibraryRepository(
    ApiClient(
      auth: auth,
      baseUrl: 'https://api.example.test',
      client: MockClient(handler),
    ),
    ownerUid: fixtureIdentity.uid,
  );

  test('GET array restores DTO and SQL book identity', () async {
    final repository = repo((request) async {
      expect(request.url.path, '/api/me/library');
      expect(request.headers['authorization'], 'Bearer fixture-token');
      return http.Response(jsonEncode([entryJson()]), 200);
    });
    final entries = await repository.list();
    expect(entries.single.book.id, 901);
    expect(entries.single.currentPage, 45);
    expect(entries.single.record.format, 'Físico');
    repository.close();
  });
  test(
    'POST and PATCH send no client user id/UID, DELETE accepts 204',
    () async {
      final methods = <String>[];
      final repository = repo((request) async {
        methods.add(request.method);
        if (request.method == 'DELETE') return http.Response('', 204);
        final data = jsonDecode(request.body) as Map;
        expect(data.containsKey('userId'), false);
        expect(data.containsKey('firebaseUid'), false);
        if (request.method == 'POST') expect(data, {'bookId': 901});
        if (request.method == 'PATCH') {
          expect(request.url.path, '/api/me/library/901');
          expect(data['currentPage'], 73);
        }
        return http.Response(
          jsonEncode(entryJson()),
          request.method == 'POST' ? 201 : 200,
        );
      });
      await repository.add(901);
      await repository.update(901, {
        'currentPage': 73,
        'readingFormat': 'EBOOK',
      });
      await repository.remove(901);
      expect(methods, ['POST', 'PATCH', 'DELETE']);
      repository.close();
    },
  );
  test(
    '409 membership conflict is confirmed using own GET, not a false success',
    () async {
      final repository = repo(
        (request) async => request.method == 'POST'
            ? http.Response('{}', 409)
            : http.Response(jsonEncode([entryJson()]), 200),
      );
      expect((await repository.add(901)).book.id, 901);
      repository.close();
    },
  );
  test('old repository cannot send under a different account', () async {
    var calls = 0;
    final repository = repo((_) async {
      calls++;
      return http.Response('{}', 200);
    });
    auth.emit(const AuthIdentity(uid: 'second-user', emailVerified: true));
    await expectLater(
      repository.add(901),
      throwsA(isA<ApiFailure>().having((e) => e.statusCode, 'status', 401)),
    );
    expect(calls, 0);
    repository.close();
  });
  test('401 refresh happens once and error remains sanitized', () async {
    var calls = 0;
    final repository = repo((_) async {
      calls++;
      return http.Response('do-not-echo', 401);
    });
    await expectLater(
      repository.list(),
      throwsA(
        isA<ApiFailure>()
            .having((e) => e.statusCode, 'status', 401)
            .having(
              (e) => e.message.contains('do-not-echo'),
              'sanitized',
              false,
            ),
      ),
    );
    expect(calls, 2);
    repository.close();
  });
  test(
    'malformed library payload is not interpreted as empty library',
    () async {
      final repository = repo(
        (_) async => http.Response('{"not":"an array"}', 200),
      );
      await expectLater(
        repository.list(),
        throwsA(isA<ApiFailure>().having((e) => e.statusCode, 'status', 502)),
      );
      repository.close();
    },
  );
}
