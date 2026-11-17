import 'dart:typed_data';

import '../models/imported_epub.dart';
import 'epub_store_stub.dart'
    if (dart.library.io) 'epub_store_native.dart'
    if (dart.library.js_interop) 'epub_store_web.dart'
    as platform;

abstract interface class EpubStore {
  Future<List<ImportedEpub>> list(String owner);
  Future<bool> contains(String owner, String id);
  Future<Uint8List?> read(String owner, String id);
  Future<void> insert(String owner, ImportedEpub book, Uint8List bytes);
  Future<void> update(String owner, ImportedEpub book);
  Future<void> remove(String owner, String id);
}

EpubStore createEpubStore() => platform.createStore();
