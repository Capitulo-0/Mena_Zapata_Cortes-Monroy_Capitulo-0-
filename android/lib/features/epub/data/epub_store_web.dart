import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../models/imported_epub.dart';
import 'epub_store.dart';

EpubStore createStore() => IndexedDbEpubStore();

class IndexedDbEpubStore implements EpubStore {
  Future<web.IDBDatabase>? _opening;
  Future<JSAny?> _request(web.IDBRequest request) {
    final result = Completer<JSAny?>();
    request.onsuccess = ((web.Event e) {
      if (!result.isCompleted) result.complete(request.result);
    }).toJS;
    request.onerror = ((web.Event e) {
      if (!result.isCompleted) {
        result.completeError(
          const EpubFailure(
            'No se pudo acceder al almacenamiento EPUB del navegador.',
          ),
        );
      }
    }).toJS;
    return result.future;
  }

  Future<web.IDBDatabase> _db() => _opening ??= _open();
  Future<web.IDBDatabase> _open() async {
    try {
      final request = web.window.indexedDB.open(
        'capitulo0-imported-epubs-v1',
        1,
      );
      request.onupgradeneeded = ((web.Event e) {
        final db = request.result as web.IDBDatabase;
        db.createObjectStore('records');
        db.createObjectStore('files');
      }).toJS;
      request.onblocked = ((web.Event e) {}).toJS;
      final db = await _request(request).timeout(const Duration(seconds: 10));
      return db as web.IDBDatabase;
    } catch (_) {
      _opening = null;
      throw const EpubFailure(
        'IndexedDB no está disponible. Permite almacenamiento local en este navegador.',
      );
    }
  }

  String _key(String owner, String id) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(owner) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) {
      throw const EpubFailure('Identificador local no válido.');
    }
    return '$owner/$id';
  }

  Future<void> _commit(web.IDBTransaction transaction) {
    final result = Completer<void>();
    transaction.oncomplete = ((web.Event e) {
      if (!result.isCompleted) result.complete();
    }).toJS;
    void fail(web.Event e) {
      if (!result.isCompleted) {
        result.completeError(
          const EpubFailure(
            'No se guardó el EPUB. Revisa la cuota y los permisos de almacenamiento.',
          ),
        );
      }
    }

    transaction.onabort = fail.toJS;
    transaction.onerror = fail.toJS;
    return result.future;
  }

  @override
  Future<List<ImportedEpub>> list(String owner) async {
    _key(owner, '0' * 64);
    final tx = (await _db()).transaction('records'.toJS, 'readonly');
    final range = web.IDBKeyRange.bound('$owner/'.toJS, '$owner/~'.toJS);
    final result = await _request(tx.objectStore('records').getAll(range));
    return (result as JSArray<JSString>).toDart
        .map(
          (s) => ImportedEpub.fromJson(
            jsonDecode(s.toDart) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<bool> contains(String owner, String id) async {
    final tx = (await _db()).transaction('files'.toJS, 'readonly');
    final result = await _request(
      tx.objectStore('files').getKey(_key(owner, id).toJS),
    );
    return result != null && !result.isUndefinedOrNull;
  }

  @override
  Future<Uint8List?> read(String owner, String id) async {
    final tx = (await _db()).transaction('files'.toJS, 'readonly');
    final result = await _request(
      tx.objectStore('files').get(_key(owner, id).toJS),
    );
    return result == null || result.isUndefinedOrNull
        ? null
        : Uint8List.fromList((result as JSUint8Array).toDart);
  }

  @override
  Future<void> insert(String owner, ImportedEpub book, Uint8List bytes) async {
    final key = _key(owner, book.id).toJS;
    final tx = (await _db()).transaction(
      ['files'.toJS, 'records'.toJS].toJS,
      'readwrite',
    );
    final done = _commit(tx);
    tx.objectStore('files').put(bytes.toJS, key);
    tx.objectStore('records').put(jsonEncode(book.toJson()).toJS, key);
    await done;
  }

  @override
  Future<void> update(String owner, ImportedEpub book) async {
    final key = _key(owner, book.id).toJS;
    final tx = (await _db()).transaction(
      ['files'.toJS, 'records'.toJS].toJS,
      'readwrite',
    );
    final done = _commit(tx);
    final request = tx.objectStore('records').getKey(key);
    request.onsuccess = ((web.Event e) {
      final result = request.result;
      if (result == null || result.isUndefinedOrNull) {
        tx.abort();
        return;
      }
      tx.objectStore('records').put(jsonEncode(book.toJson()).toJS, key);
    }).toJS;
    await done;
  }

  @override
  Future<void> remove(String owner, String id) async {
    final key = _key(owner, id).toJS;
    final tx = (await _db()).transaction(
      ['files'.toJS, 'records'.toJS].toJS,
      'readwrite',
    );
    final done = _commit(tx);
    tx.objectStore('files').delete(key);
    tx.objectStore('records').delete(key);
    await done;
  }
}
