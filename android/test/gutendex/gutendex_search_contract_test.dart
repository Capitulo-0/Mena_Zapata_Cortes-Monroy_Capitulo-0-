import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/features/gutendex/data/gutendex_repository.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';

import 'support/gutendex_fakes.dart';

void main() {
  for (final language in [GutendexLanguage.spanish, GutendexLanguage.english]) {
    test('combined title and language preserve encoded search parameters: ${language.code}', () async {
      final repository = HttpGutendexRepository(client: MockClient((request) async {
        expect(request.url.queryParameters, {
          'search': 'Don Quijote & ñ', 'languages': language.code,
        });
        expect(request.followRedirects, isFalse);
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response.bytes(utf8.encode(jsonEncode(pageJson(books: []))), 200);
      }));
      addTearDown(repository.close);
      expect(repository.timeout, const Duration(seconds: 15));
      final page = await repository.list(query: ' Don Quijote & ñ ', language: language);
      expect(page.results, isEmpty);
    });
  }

  test('HTTP 522, timeout and valid empty response have distinct outcomes', () async {
    final httpFailure = HttpGutendexRepository(client: MockClient((_) async => http.Response('', 522)));
    addTearDown(httpFailure.close);
    await expectLater(httpFailure.list(query: 'Título', language: GutendexLanguage.spanish),
      throwsA(isA<GutendexFailure>().having((e) => e.message, 'message', contains('HTTP 522'))));
    final pending = Completer<http.Response>();
    final slow = HttpGutendexRepository(client: MockClient((_) => pending.future),
      timeout: const Duration(milliseconds: 5));
    addTearDown(slow.close);
    await expectLater(slow.list(query: 'Título', language: GutendexLanguage.english),
      throwsA(isA<GutendexFailure>().having((e) => e.message, 'message', contains('tardó demasiado'))));
    pending.complete(http.Response(jsonEncode(pageJson(books: [])), 200));
    final empty = HttpGutendexRepository(client: MockClient((_) async =>
      http.Response(jsonEncode(pageJson(books: [])), 200)));
    addTearDown(empty.close);
    expect((await empty.list(query: 'Título', language: GutendexLanguage.spanish)).results, isEmpty);
  });

  test('Spanish work keeps its original English synopsis from delayed provider metadata', () async {
    final pending = Completer<http.Response>();
    final repository = HttpGutendexRepository(client: MockClient((_) => pending.future));
    addTearDown(repository.close);
    var completed = false;
    final task = repository.list(query: 'Título', language: GutendexLanguage.spanish)
      ..then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    pending.complete(http.Response.bytes(utf8.encode(jsonEncode(pageJson(books: [{
      ...bookJson(1), 'summaries': ['An English synopsis from the provider.'],
    }]))), 200));
    final book = (await task).results.single;
    expect(book.languages, ['es']);
    expect(book.summaries, ['An English synopsis from the provider.']);
  });
}
