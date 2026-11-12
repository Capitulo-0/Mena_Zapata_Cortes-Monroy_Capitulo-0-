import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/features/catalog/data/catalog_repository.dart';
import 'package:android/features/catalog/presentation/catalog_controller.dart';
import 'package:android/features/library/models/library_entry.dart';
import 'package:android/features/library/presentation/controllers/library_controller.dart';

import 'support/auth_fakes.dart';
import 'support/library_fakes.dart';

Map<String, dynamic> metadata(String id) => {
  'volumeId': id,
  'title': 'Real fixture $id',
  'authors': ['Author One', 'Author Two'],
  'identifiers': {'ISBN_13': '9780000000001'},
  'language': 'es',
};

class CatalogFake implements CatalogRepository {
  final requests = <String>[];
  final pending = <String, Completer<CatalogPage>>{};
  bool fail = false;
  @override
  Future<CatalogPage> search(
    String query, {
    String mode = 'all',
    int start = 0,
  }) {
    requests.add('$mode:$query:$start');
    if (fail) throw const ApiFailure(503, 'Catálogo no disponible');
    return (pending[query] ??= Completer<CatalogPage>()).future;
  }

  @override
  Future<Map<String, dynamic>> detail(String id) async =>
      ApiCatalogRepository.presentation(metadata(id));
  @override
  Future<Map<String, dynamic>> importBook(String id) async => bookJson();
}

void main() {
  test('public search encodes query without bearer and import requires Firebase identity', () async {
    final auth = FakeAuth();
    addTearDown(auth.close);
    final requests = <http.Request>[];
    final api = ApiClient(
      auth: auth,
      baseUrl: 'https://api.example.test',
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'items': [metadata('external')],
            'nextStartIndex': 20,
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final repo = ApiCatalogRepository(api);
    final page = await repo.search('título & autor', mode: 'author');
    expect(requests.single.url.queryParameters['q'], 'título & autor');
    expect(requests.single.url.queryParameters['mode'], 'author');
    expect(requests.single.headers.containsKey('Authorization'), false);
    expect(page.items.single.containsKey('id'), false);
    expect(page.items.single['googleVolumeId'], 'external');
    expect(page.items.single['authorReal'], 'Author One, Author Two');
    expect(page.items.single['availability'], 'REGISTRO');
    expect(page.nextStartIndex, 20);
    await expectLater(repo.importBook('external'), throwsA(isA<ApiFailure>()));
    expect(requests.length, 1);
  });
  test(
    'import body has only external identity and parses stored SQL metadata',
    () async {
      final auth = FakeAuth()..identity = fixtureIdentity;
      addTearDown(auth.close);
      final api = ApiClient(
        auth: auth,
        baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
          expect(jsonDecode(request.body), {'volumeId': 'external'});
          expect(request.headers['Authorization'], isNotEmpty);
          return http.Response(
            jsonEncode({
              ...bookJson(),
              'googleVolumeId': 'external',
              'googleBooks': metadata('external'),
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final saved = LibraryEntry.parseBook(
        await ApiCatalogRepository(api).importBook('external'),
      );
      expect(saved.id, 901);
      expect(saved.googleVolumeId, 'external');
      expect(saved.googleBooks!['authors'], hasLength(2));
      expect(saved.isFree, false);
    },
  );
  test(
    'malformed catalog is an error rather than fabricated empty success',
    () async {
      final auth = FakeAuth();
      addTearDown(auth.close);
      final api = ApiClient(
        auth: auth,
        baseUrl: 'https://api.example.test',
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      addTearDown(api.close);
      await expectLater(
        ApiCatalogRepository(api).search('a'),
        throwsA(isA<ApiFailure>()),
      );
    },
  );
  test(
    'controller loads, ignores stale results and avoids empty requests',
    () async {
      final repo = CatalogFake();
      final controller = CatalogController(repo);
      addTearDown(controller.dispose);
      await controller.search(' ');
      expect(repo.requests, isEmpty);
      final first = controller.search('one');
      expect(controller.loading, true);
      final second = controller.search('two');
      repo.pending['two']!.complete(
        CatalogPage([ApiCatalogRepository.presentation(metadata('two'))], null),
      );
      await second;
      repo.pending['one']!.complete(
        CatalogPage([ApiCatalogRepository.presentation(metadata('one'))], null),
      );
      await first;
      expect(controller.items.single['googleVolumeId'], 'two');
      expect(controller.loading, false);
    },
  );
  test('errors and retry and empty success are distinct', () async {
    final repo = CatalogFake()..fail = true;
    final controller = CatalogController(repo);
    addTearDown(controller.dispose);
    await controller.search('x');
    expect(controller.error, isNotNull);
    repo.fail = false;
    final retry = controller.retry();
    repo.pending['x']!.complete(const CatalogPage([], null));
    await retry;
    expect(controller.error, isNull);
    expect(controller.items, isEmpty);
  });
  test('more appends and deduplicates volumes', () async {
    final repo = CatalogFake();
    final controller = CatalogController(repo);
    addTearDown(controller.dispose);
    final first = controller.search('x');
    repo.pending['x']!.complete(
      CatalogPage([ApiCatalogRepository.presentation(metadata('x'))], 20),
    );
    await first;
    repo.pending['x'] = Completer<CatalogPage>();
    final more = controller.more();
    repo.pending['x']!.complete(
      CatalogPage([
        ApiCatalogRepository.presentation(metadata('x')),
        ApiCatalogRepository.presentation(metadata('y')),
      ], null),
    );
    await more;
    expect(controller.items, hasLength(2));
    expect(repo.requests.last, 'all:x:20');
  });
  test('external import adds via existing private repository without changing prior progress', () async {
    final auth = FakeAuth()..identity = fixtureIdentity;
    addTearDown(auth.close);
    final memory = LibraryMemory();
    final repo = MemoryLibraryRepository(auth, memory);
    final library = LibraryController(repo);
    addTearDown(library.dispose);
    await library.load();
    await library.add(901);
    final before = library.entries[901]!.currentPage;
    final success = await library.addExternal(
      () async => {
        ...bookJson(id: 902),
        'googleVolumeId': 'external',
        'googleBooks': metadata('external'),
      },
    );
    expect(success, true);
    expect(library.entries[901]!.currentPage, before);
    expect(library.entries.containsKey(902), true);
  });
}
