import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/features/gutendex/data/gutendex_repository.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';

import 'support/gutendex_fakes.dart';

void main() {
  test('empty is valid but incomplete envelopes are not empty successes', () async {
    final empty = HttpGutendexRepository(client: MockClient((_) async =>
      http.Response(jsonEncode(pageJson(books: [])), 200)));
    addTearDown(empty.close);
    expect((await empty.list(query: '', language: GutendexLanguage.all)).results, isEmpty);
    for (final body in [{'results': null}, {'count': 1},
      {'results': [{'title': 'No ID'}]}, {'results': [], 'count': -1}, 'html']) {
      final repo = HttpGutendexRepository(client: MockClient((_) async =>
        http.Response(jsonEncode(body), 200)));
      addTearDown(repo.close);
      await expectLater(repo.list(query: '', language: GutendexLanguage.all),
        throwsA(isA<GutendexFailure>()));
    }
  });

  for (final status in [301, 404, 429, 500]) {
    test('HTTP $status gives a controlled error', () async {
      final repo = HttpGutendexRepository(client: MockClient((_) async =>
        http.Response('unexpected response', status)));
      addTearDown(repo.close);
      await expectLater(repo.list(query: '', language: GutendexLanguage.all),
        throwsA(isA<GutendexFailure>()));
    });
  }

  test('connection failure and timeout have controlled messages', () async {
    final offline = HttpGutendexRepository(client: MockClient((_) async =>
      throw http.ClientException('internal diagnostic')));
    addTearDown(offline.close);
    await expectLater(offline.list(query: '', language: GutendexLanguage.all),
      throwsA(isA<GutendexFailure>().having((e) => e.message, 'message',
        'No pudimos conectar con Gutendex.')));
    final slow = HttpGutendexRepository(
      client: MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 1));
    addTearDown(slow.close);
    await expectLater(slow.list(query: '', language: GutendexLanguage.all),
      throwsA(isA<GutendexFailure>()));
  });

  test('detail uses ID endpoint and rejects inconsistent identity', () async {
    var mismatch = false;
    final repo = HttpGutendexRepository(client: MockClient((request) async {
      expect(request.url.path, '/books/12/');
      return http.Response(jsonEncode(bookJson(mismatch ? 13 : 12)), 200);
    }));
    addTearDown(repo.close);
    expect((await repo.detail(12)).id, 12);
    mismatch = true;
    await expectLater(repo.detail(12), throwsA(isA<GutendexFailure>()));
    await expectLater(repo.detail(0), throwsA(isA<GutendexFailure>()));
  });

  for (final query in ['Don Quijote', 'Miguel de Cervantes']) {
    test('search title or author with documented parameter: $query', () async {
      late http.Request captured;
      final repo = HttpGutendexRepository(client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(pageJson()), 200);
      }));
      addTearDown(repo.close);
      final page = await repo.list(query: query, language: GutendexLanguage.spanish);
      expect(captured.url.host, 'gutendex.com');
      expect(captured.url.path, '/books/');
      expect(captured.url.queryParameters['search'], query);
      expect(captured.headers.containsKey('Authorization'), false);
      expect(captured.followRedirects, false);
      expect(page.results.single.id, 1);
      expect(page.count, 1);
    });
  }

  for (final language in GutendexLanguage.values) {
    test('language parameter and metadata: ${language.code}', () async {
      final repo = HttpGutendexRepository(client: MockClient((request) async {
        expect(request.url.queryParameters['languages'],
          language == GutendexLanguage.all ? null : language.code);
        expect(request.url.queryParameters.containsKey('search'), false);
        return http.Response(jsonEncode(pageJson(books: [bookJson(1,
          language: language == GutendexLanguage.all ? 'fr' : language.code)])), 200);
      }));
      addTearDown(repo.close);
      final page = await repo.list(query: '', language: language);
      expect(page.results.single.languages.single,
        language == GutendexLanguage.all ? 'fr' : language.code);
    });
  }

  test('uses provider next URL and reads previous without computing offsets', () async {
    final next = Uri.https('gutendex.com', '/books/',
      {'search': 'autor', 'languages': 'es', 'page': '3'});
    final previous = Uri.https('gutendex.com', '/books/',
      {'search': 'autor', 'languages': 'es', 'page': '1'});
    final requests = <Uri>[];
    final repo = HttpGutendexRepository(client: MockClient((request) async {
      requests.add(request.url);
      return http.Response(jsonEncode(pageJson(
        next: requests.length == 1 ? next.toString() : null,
        previous: previous.toString())), 200);
    }));
    addTearDown(repo.close);
    final page = await repo.list(query: 'autor', language: GutendexLanguage.spanish);
    expect(page.next, next);
    expect(page.previous, previous);
    final last = await repo.list(query: 'autor',
      language: GutendexLanguage.spanish, next: page.next);
    expect(requests.last, next);
    expect(last.next, isNull);
  });

  for (final next in [
    'https://evil.test/books/?page=2', 'http://gutendex.com/books/?page=2',
    'https://gutendex.com/books/?page=2&languages=en',
    'https://gutendex.com/books/1/?page=2',
    'https://gutendex.com/books/?page=0',
    'https://gutendex.com/books/?page=2&page=3',
  ]) {
    test('untrusted or foreign-query page never sends HTTP: $next', () async {
      var calls = 0;
      final repo = HttpGutendexRepository(client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }));
      addTearDown(repo.close);
      await expectLater(repo.list(query: '', language: GutendexLanguage.all,
        next: Uri.parse(next)), throwsA(isA<GutendexFailure>()));
      expect(calls, 0);
    });
  }
}
