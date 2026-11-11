import 'dart:async';

import 'package:android/features/auth/domain/auth_repository.dart';
import 'package:android/features/library/data/library_repository.dart';
import 'package:android/features/library/models/library_entry.dart';
import 'package:android/features/library/models/library_book.dart';

Map<String, dynamic> bookJson({int id = 901}) => {
  'id': id,
  'title': 'SQL book $id',
  'author': 'Catalog author',
  'publisher': 'Catalog publisher',
  'totalPages': 300,
};
Map<String, dynamic> entryJson({
  int id = 901,
  String status = 'LEYENDO',
  int page = 45,
  int? total = 300,
  String format = 'FISICO',
}) => {
  'id': id + 1000,
  'userId': 42,
  'book': bookJson(id: id),
  'status': status,
  'readingFormat': format,
  'currentPage': page,
  'totalPages': total,
  'publisherOverride': 'Reader edition',
  'progressPercentage': status == 'LEIDO'
      ? 100.0
      : total == null
      ? 0.0
      : page * 100 / total,
  'updatedAt': '2026-11-11T12:00:00Z',
};

class LibraryMemory {
  final catalog = <int, LibraryBook>{901: LibraryEntry.parseBook(bookJson())};
  final byOwner = <String, Map<int, LibraryEntry>>{};
}

class MemoryLibraryRepository implements LibraryRepository {
  MemoryLibraryRepository(
    this.auth,
    this.memory, {
    this.ownerUid = 'fixture-user',
  });
  final AuthRepository auth;
  final LibraryMemory memory;
  @override
  final String ownerUid;
  @override
  bool get isCurrentAccount => auth.currentUser?.uid == ownerUid;
  final calls = <String>[];
  Object? listFailure;
  Object? mutationFailure;
  Map<String, dynamic>? lastChanges;
  Future<LibraryEntry> Function()? updateHandler;
  bool closed = false;
  Map<int, LibraryEntry> get store =>
      memory.byOwner.putIfAbsent(ownerUid, () => {});
  void check(String action) {
    if (closed || !isCurrentAccount) throw StateError('Wrong owner');
    calls.add(action);
  }

  @override
  Future<List<LibraryEntry>> list() async {
    check('list');
    if (listFailure != null) throw listFailure!;
    return store.values.toList();
  }

  @override
  Future<List<LibraryBook>> catalog() async {
    check('catalog');
    return memory.catalog.values.toList();
  }

  @override
  Future<LibraryEntry> add(int bookId) async {
    check('add');
    if (mutationFailure != null) throw mutationFailure!;
    return store.putIfAbsent(
      bookId,
      () => LibraryEntry.fromJson(
        entryJson(id: bookId, status: 'POR_LEER', page: 0),
      ),
    );
  }

  @override
  Future<LibraryEntry> update(int bookId, Map<String, dynamic> changes) async {
    check('update');
    lastChanges = changes;
    if (mutationFailure != null) throw mutationFailure!;
    if (updateHandler != null) return updateHandler!();
    final current = store[bookId]!;
    final total = changes['totalPages'] as int? ?? current.totalPages;
    final status =
        changes['status'] as String? ??
        LibraryEntry.statusValue(current.status);
    var page = changes['currentPage'] as int? ?? current.currentPage;
    if (status == 'POR_LEER') page = 0;
    if (status == 'LEIDO' && total != null) page = total;
    final data = entryJson(
      id: bookId,
      status: status,
      page: page,
      total: total,
      format: changes['readingFormat'] as String? ?? current.readingFormat,
    );
    data['publisherOverride'] =
        changes['publisherOverride'] ?? current.publisher;
    return store[bookId] = LibraryEntry.fromJson(data);
  }

  @override
  Future<void> remove(int bookId) async {
    check('remove');
    if (mutationFailure != null) throw mutationFailure!;
    store.remove(bookId);
  }

  @override
  Future<LibraryBook> createBook(Map<String, dynamic> metadata) async {
    check('create');
    final book = LibraryEntry.parseBook({...bookJson(id: 902), ...metadata});
    memory.catalog[902] = book;
    return book;
  }

  @override
  void close() {
    closed = true;
  }
}
