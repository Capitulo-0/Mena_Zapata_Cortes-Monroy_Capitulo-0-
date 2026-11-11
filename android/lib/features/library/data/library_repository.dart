import '../../auth/domain/auth_repository.dart';
import '../../../core/network/api_client.dart';
import '../models/library_entry.dart';
import '../models/library_book.dart';

abstract interface class LibraryRepository {
  String get ownerUid;
  bool get isCurrentAccount;
  Future<List<LibraryEntry>> list();
  Future<List<LibraryBook>> catalog();
  Future<LibraryBook> createBook(Map<String, dynamic> metadata);
  Future<LibraryEntry> add(int bookId);
  Future<LibraryEntry> update(int bookId, Map<String, dynamic> changes);
  Future<void> remove(int bookId);
  void close();
}

class ApiLibraryRepository implements LibraryRepository {
  ApiLibraryRepository(this.api, {required this.ownerUid});
  final ApiClient api;
  @override
  final String ownerUid;
  AuthRepository get _auth => api.auth;
  @override
  bool get isCurrentAccount => _auth.currentUser?.uid == ownerUid;
  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) {
    if (!isCurrentAccount) throw ApiFailure.forStatus(401);
    return api.requestJson(method, path, body: body, expectedUid: ownerUid);
  }

  T _parse<T>(T Function() action) {
    try {
      return action();
    } catch (_) {
      throw const ApiFailure(
        502,
        'El backend devolvió datos de biblioteca no válidos.',
      );
    }
  }

  @override
  Future<List<LibraryEntry>> list() async {
    final data = await _request('GET', '/api/me/library');
    return _parse(
      () => (data as List)
          .map(
            (item) =>
                LibraryEntry.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<List<LibraryBook>> catalog() async {
    final data = await _request('GET', '/api/books');
    return _parse(
      () => (data as List)
          .map(
            (item) =>
                LibraryEntry.parseBook(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<LibraryBook> createBook(Map<String, dynamic> metadata) async {
    final data = await _request('POST', '/api/books', body: metadata);
    return _parse<LibraryBook>(
      () => LibraryEntry.parseBook(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<LibraryEntry> add(int bookId) async {
    try {
      final data = await _request(
        'POST',
        '/api/me/library',
        body: {'bookId': bookId},
      );
      return _parse<LibraryEntry>(
        () => LibraryEntry.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } on ApiFailure catch (failure) {
      if (failure.statusCode != 409) rethrow;
      // A previous timed-out POST may already have succeeded. Confirm via own library.
      final found = (await list()).where((entry) => entry.book.id == bookId);
      if (found.isNotEmpty) return found.first;
      throw const ApiFailure(
        409,
        'No se pudo añadir el libro. Recarga tu biblioteca para comprobar su estado.',
      );
    }
  }

  @override
  Future<LibraryEntry> update(int bookId, Map<String, dynamic> changes) async {
    final data = await _request(
      'PATCH',
      '/api/me/library/$bookId',
      body: changes,
    );
    return _parse<LibraryEntry>(
      () => LibraryEntry.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<void> remove(int bookId) async {
    try {
      await _request('DELETE', '/api/me/library/$bookId');
    } on ApiFailure catch (failure) {
      if (failure.statusCode != 404) rethrow;
      if ((await list()).any((entry) => entry.book.id == bookId)) rethrow;
    }
  }

  @override
  void close() => api.close();
}
