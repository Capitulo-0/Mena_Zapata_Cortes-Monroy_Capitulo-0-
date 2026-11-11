import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/network/api_client.dart';
import 'package:android/features/auth/domain/auth_repository.dart';
import 'package:android/features/library/models/book_status.dart';
import 'package:android/features/library/models/library_entry.dart';
import 'package:android/features/library/models/reading_record.dart';
import 'package:android/features/library/presentation/controllers/library_controller.dart';

import 'support/auth_fakes.dart';
import 'support/library_fakes.dart';

void main() {
  late FakeAuth auth;
  late LibraryMemory memory;
  late MemoryLibraryRepository repository;
  late LibraryController controller;
  setUp(() {
    auth = FakeAuth()..identity = fixtureIdentity;
    memory = LibraryMemory();
    repository = MemoryLibraryRepository(auth, memory);
    controller = LibraryController(repository);
  });
  tearDown(() async {
    controller.dispose();
    await auth.close();
  });

  test(
    'empty successful load differs from failed initial load and retry',
    () async {
      repository.listFailure = ApiFailure.forStatus(503);
      expect(await controller.load(), false);
      expect(controller.loaded, false);
      expect(controller.error, isNotNull);
      repository.listFailure = null;
      expect(await controller.retry(), true);
      expect(controller.loaded, true);
      expect(controller.entries, isEmpty);
      expect(controller.error, isNull);
    },
  );
  test('add uses SQL id and survives new controller/session reload', () async {
    await controller.load();
    expect(await controller.add(901), true);
    expect(controller.entries[901]!.status, BookStatus.porLeer);
    final restored = LibraryController(MemoryLibraryRepository(auth, memory));
    await restored.load();
    expect(restored.entries.keys, [901]);
    expect(restored.entries[901]!.book.isBackendBook, true);
    restored.dispose();
  });
  test('demo id cannot be silently treated as SQL id', () async {
    await controller.load();
    expect(await controller.add(1), false);
    expect(repository.calls.where((call) => call == 'add'), isEmpty);
    expect(controller.error, contains('demo'));
  });
  test(
    'saves exact pages, format and publisher; reload restores them',
    () async {
      await controller.load();
      await controller.add(901);
      expect(
        await controller.saveRecord(
          901,
          const ReadingRecord(
            format: 'Ebook',
            currentPage: 73,
            totalPages: 300,
            publisher: 'Personal edition',
            status: BookStatus.leyendo,
          ),
        ),
        true,
      );
      expect(repository.lastChanges!['currentPage'], 73);
      expect(repository.lastChanges!['readingFormat'], 'EBOOK');
      await controller.load();
      expect(controller.entries[901]!.currentPage, 73);
      expect(controller.entries[901]!.record.publisher, 'Personal edition');
      expect(controller.entries[901]!.progressPercentage.floor(), 24);
    },
  );
  test(
    'server status normalization is canonical without fabricating resume pages',
    () async {
      await controller.load();
      await controller.add(901);
      await controller.setStatus(901, BookStatus.leido);
      expect(controller.entries[901]!.currentPage, 300);
      await controller.setStatus(901, BookStatus.leyendo);
      expect(controller.entries[901]!.currentPage, 300);
      await controller.setStatus(901, BookStatus.porLeer);
      expect(controller.entries[901]!.currentPage, 0);
    },
  );
  test(
    'mutation failure preserves confirmed values and explicit retry succeeds',
    () async {
      await controller.load();
      await controller.add(901);
      repository.mutationFailure = ApiFailure.forStatus(503);
      expect(await controller.setStatus(901, BookStatus.leido), false);
      expect(controller.entries[901]!.status, BookStatus.porLeer);
      expect(controller.error, isNotNull);
      repository.mutationFailure = null;
      expect(await controller.retry(), true);
      expect(controller.entries[901]!.status, BookStatus.leido);
    },
  );
  test(
    'pending save does not publish success until server acknowledges',
    () async {
      await controller.load();
      await controller.add(901);
      final pending = Completer<LibraryEntry>();
      repository.updateHandler = () => pending.future;
      final save = controller.setStatus(901, BookStatus.leido);
      expect(controller.saving, true);
      expect(controller.entries[901]!.status, BookStatus.porLeer);
      pending.complete(
        LibraryEntry.fromJson(entryJson(status: 'LEIDO', page: 300)),
      );
      expect(await save, true);
      expect(controller.entries[901]!.status, BookStatus.leido);
    },
  );
  test(
    'delete membership preserves catalog and fails without false removal',
    () async {
      await controller.load();
      await controller.add(901);
      repository.mutationFailure = ApiFailure.forStatus(503);
      expect(await controller.remove(901), false);
      expect(controller.entries, contains(901));
      repository.mutationFailure = null;
      expect(await controller.retry(), true);
      expect(controller.entries, isEmpty);
      expect(memory.catalog, contains(901));
    },
  );
  test(
    'two users cannot reuse a repository or expose each others entries',
    () async {
      await controller.load();
      await controller.add(901);
      auth.emit(const AuthIdentity(uid: 'second-user', emailVerified: true));
      expect(await controller.setStatus(901, BookStatus.leido), false);
      final second = LibraryController(
        MemoryLibraryRepository(auth, memory, ownerUid: 'second-user'),
      );
      await second.load();
      expect(second.entries, isEmpty);
      second.dispose();
      auth.emit(fixtureIdentity);
      final restored = LibraryController(MemoryLibraryRepository(auth, memory));
      await restored.load();
      expect(restored.entries[901]!.status, BookStatus.porLeer);
      restored.dispose();
    },
  );
  test('guest does not execute GET or private mutations', () async {
    final guestRepo = MemoryLibraryRepository(auth, memory);
    final guest = LibraryController(guestRepo, isGuest: true);
    expect(await guest.load(), false);
    expect(await guest.add(901), false);
    expect(await guest.remove(901), false);
    expect(guestRepo.calls, isEmpty);
    guest.dispose();
  });
  test(
    'late response after account change cannot change current UI state',
    () async {
      await controller.load();
      await controller.add(901);
      final pending = Completer<LibraryEntry>();
      repository.updateHandler = () => pending.future;
      final save = controller.setStatus(901, BookStatus.leido);
      auth.emit(const AuthIdentity(uid: 'second-user', emailVerified: true));
      pending.complete(
        LibraryEntry.fromJson(entryJson(status: 'LEIDO', page: 300)),
      );
      expect(await save, false);
      expect(controller.entries[901]!.status, BookStatus.porLeer);
      expect(memory.byOwner['second-user'], isNull);
    },
  );
  test('catalog creation is not repeated when membership POST fails', () async {
    await controller.load();
    repository.mutationFailure = ApiFailure.forStatus(503);
    expect(await controller.createAndAdd({'title': 'Registered book'}), false);
    expect(controller.entries, isEmpty);
    expect(controller.catalog.any((book) => book.id == 902), true);
    repository.mutationFailure = null;
    expect(await controller.retry(), true);
    expect(repository.calls.where((call) => call == 'create').length, 1);
    expect(controller.entries, contains(902));
  });
  test('unknown totals and finished status do not invent pages', () async {
    repository.store[901] = LibraryEntry.fromJson(
      entryJson(status: 'LEIDO', page: 0, total: null),
    );
    await controller.load();
    expect(controller.entries[901]!.totalPages, isNull);
    expect(controller.entries[901]!.record.progress, 100);
    expect(controller.entries[901]!.record.currentPage, 0);
  });
}
