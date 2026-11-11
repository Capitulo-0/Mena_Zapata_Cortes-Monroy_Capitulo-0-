import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/library_repository.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../models/book_status.dart';
import '../../models/library_book.dart';
import '../../models/library_entry.dart';
import '../../models/reading_record.dart';

class LibraryController extends ChangeNotifier {
  LibraryController(this.repository, {this.isGuest = false});
  final LibraryRepository repository;
  final bool isGuest;
  final Map<int, LibraryEntry> _entries = {};
  final Map<int, LibraryBook> _catalog = {};
  Map<int, LibraryEntry> get entries => Map.unmodifiable(_entries);
  List<LibraryBook> get catalog => List.unmodifiable(_catalog.values);
  bool loading = false;
  bool saving = false;
  bool loaded = false;
  bool _closed = false;
  String? error;
  Future<bool> Function()? _retry;
  bool get busy => loading || saving;
  bool get canWrite =>
      !isGuest && loaded && !busy && repository.isCurrentAccount && !_closed;

  void _ensureAccount() {
    if (_closed || isGuest || !repository.isCurrentAccount) {
      throw ApiFailure.forStatus(401);
    }
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  String _message(Object failure) => failure is ApiFailure
      ? failure.message
      : failure is AuthFailure
      ? failure.message
      : 'No pudimos sincronizar tu biblioteca. Revisa la conexión y reintenta.';

  Future<bool> load() async {
    if (_closed || busy || isGuest) return false;
    loading = true;
    error = null;
    _notify();
    List<LibraryEntry>? entries;
    List<LibraryBook>? catalog;
    Object? libraryFailure;
    Object? catalogFailure;
    try {
      _ensureAccount();
      await Future.wait([
        (() async {
          try {
            entries = await repository.list();
          } catch (e) {
            libraryFailure = e;
          }
        })(),
        (() async {
          try {
            catalog = await repository.catalog();
          } catch (e) {
            catalogFailure = e;
          }
        })(),
      ]);
      _ensureAccount();
      if (entries != null) {
        _entries
          ..clear()
          ..addEntries(entries!.map((entry) => MapEntry(entry.book.id, entry)));
        loaded = true;
      }
      if (catalog != null) {
        _catalog
          ..clear()
          ..addEntries(catalog!.map((book) => MapEntry(book.id, book)));
      }
      for (final entry in _entries.values) {
        _catalog[entry.book.id] = entry.book;
      }
      error = libraryFailure != null
          ? _message(libraryFailure!)
          : catalogFailure != null
          ? 'No se pudo cargar el catálogo. Puedes reintentar.'
          : null;
      _retry = error == null ? null : load;
      return libraryFailure == null;
    } catch (failure) {
      if (!_closed) {
        error = _message(failure);
        _retry = load;
      }
      return false;
    } finally {
      if (!_closed) {
        loading = false;
        _notify();
      }
    }
  }

  Future<bool> _mutate(
    Future<void> Function() operation, {
    Future<bool> Function()? retry,
  }) async {
    if (!canWrite) return false;
    saving = true;
    error = null;
    _notify();
    try {
      _ensureAccount();
      await operation();
      _ensureAccount();
      _retry = null;
      return true;
    } catch (failure) {
      if (!_closed) {
        error = _message(failure);
        _retry = retry ?? load;
      }
      return false;
    } finally {
      if (!_closed) {
        saving = false;
        _notify();
      }
    }
  }

  void _store(LibraryEntry entry) {
    _ensureAccount();
    _entries[entry.book.id] = entry;
    _catalog[entry.book.id] = entry.book;
  }

  Future<bool> add(int sqlBookId) async {
    if (!canWrite) return false;
    if (_entries.containsKey(sqlBookId)) return true;
    return _mutate(() async {
      if (!_catalog.containsKey(sqlBookId)) {
        throw const ApiFailure(
          400,
          'Selecciona un libro del catálogo real. Los identificadores demo no se importan.',
        );
      }
      final entry = await repository.add(sqlBookId);
      _store(entry);
    }, retry: () => add(sqlBookId));
  }

  Future<bool> setStatus(int sqlBookId, BookStatus status) => _mutate(() async {
    if (!_entries.containsKey(sqlBookId)) throw ApiFailure.forStatus(404);
    _store(
      await repository.update(sqlBookId, {
        'status': LibraryEntry.statusValue(status),
      }),
    );
  }, retry: () => setStatus(sqlBookId, status));

  Future<bool> saveRecord(int sqlBookId, ReadingRecord record) =>
      _mutate(() async {
        final previous = _entries[sqlBookId];
        if (previous == null) throw ApiFailure.forStatus(404);
        if (record.currentPage < 0 ||
            record.totalPages < 0 ||
            (record.totalPages > 0 && record.currentPage > record.totalPages)) {
          throw const ApiFailure(
            400,
            'La página actual debe estar entre cero y el total conocido.',
          );
        }
        if (record.totalPages == 0 && previous.totalPages != null) {
          throw const ApiFailure(
            400,
            'Conserva el total de páginas registrado; el contrato actual no permite vaciarlo.',
          );
        }
        final page = record.status == BookStatus.porLeer
            ? 0
            : record.status == BookStatus.leido && record.totalPages > 0
            ? record.totalPages
            : record.currentPage;
        final changes = <String, dynamic>{
          'status': LibraryEntry.statusValue(record.status),
          'readingFormat': LibraryEntry.formatValue(record.format),
          'currentPage': page,
          'publisherOverride': record.publisher,
          if (record.totalPages > 0) 'totalPages': record.totalPages,
        };
        _store(await repository.update(sqlBookId, changes));
      }, retry: () => saveRecord(sqlBookId, record));

  Future<bool> setProgress(int sqlBookId, int percentage) async {
    if (percentage == 100) return setStatus(sqlBookId, BookStatus.leido);
    final entry = _entries[sqlBookId];
    if (entry == null || entry.totalPages == null) {
      if (!_closed) {
        error = 'Registra las páginas y su total para guardar ese avance.';
        _notify();
      }
      return false;
    }
    final page = ((percentage.clamp(0, 100) * entry.totalPages! + 99) ~/ 100)
        .clamp(0, entry.totalPages!);
    return saveRecord(
      sqlBookId,
      ReadingRecord(
        format: entry.record.format,
        currentPage: page,
        totalPages: entry.totalPages!,
        publisher: entry.publisher,
        status: BookStatus.leyendo,
      ),
    );
  }

  Future<bool> remove(int sqlBookId) => _mutate(() async {
    await repository.remove(sqlBookId);
    _ensureAccount();
    _entries.remove(sqlBookId);
  }, retry: () => remove(sqlBookId));

  Future<bool> createAndAdd(Map<String, dynamic> metadata) async {
    LibraryBook? created;
    return _mutate(
      () async {
        created = await repository.createBook(metadata);
        _ensureAccount();
        _catalog[created!.id] = created!;
        _notify();
        _store(await repository.add(created!.id));
      },
      retry: () async {
        // Do not repeat catalog POST after an ambiguous network failure.
        if (created == null) return load();
        return add(created!.id);
      },
    );
  }

  Future<bool> retry() => (_retry ?? load)();

  @override
  void dispose() {
    _closed = true;
    _entries.clear();
    _catalog.clear();
    repository.close();
    super.dispose();
  }
}
