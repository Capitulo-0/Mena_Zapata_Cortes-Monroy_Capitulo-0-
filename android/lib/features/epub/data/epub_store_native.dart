import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/imported_epub.dart';
import 'epub_store.dart';

EpubStore createStore() => NativeEpubStore();

class NativeEpubStore implements EpubStore {
  NativeEpubStore({this.baseDirectory});
  final Directory? baseDirectory;
  Future<Directory> _directory(String owner) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(owner)) {
      throw const EpubFailure('Cuenta local no válida.');
    }
    final base = baseDirectory ?? await getApplicationSupportDirectory();
    return Directory('${base.path}/imported_epubs_v1/$owner')
      ..createSync(recursive: true);
  }

  void _id(String id) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) {
      throw const EpubFailure('Identificador EPUB no válido.');
    }
  }

  Future<File> _file(String owner, String id, String extension) async {
    _id(id);
    return File('${(await _directory(owner)).path}/$id.$extension');
  }

  @override
  Future<List<ImportedEpub>> list(String owner) async {
    final directory = await _directory(owner);
    final result = <ImportedEpub>[];
    await for (final file in directory.list(followLinks: false)) {
      if (file is File && file.path.endsWith('.json')) {
        result.add(
          ImportedEpub.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>,
          ),
        );
      }
    }
    return result;
  }

  @override
  Future<bool> contains(String owner, String id) async =>
      (await _file(owner, id, 'epub')).exists();
  @override
  Future<Uint8List?> read(String owner, String id) async {
    final file = await _file(owner, id, 'epub');
    return await file.exists() ? file.readAsBytes() : null;
  }

  Future<void> _metadata(String owner, ImportedEpub book) async {
    final file = await _file(owner, book.id, 'json');
    final temp = File('${file.path}.pending');
    await temp.writeAsString(jsonEncode(book.toJson()), flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<void> insert(String owner, ImportedEpub book, Uint8List bytes) async {
    final file = await _file(owner, book.id, 'epub');
    final existed = await file.exists();
    final temp = File('${file.path}.pending');
    try {
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);
      await _metadata(owner, book);
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      if (!existed && await file.exists()) await file.delete();
      rethrow;
    }
  }

  @override
  Future<void> update(String owner, ImportedEpub book) async {
    if (!await contains(owner, book.id) ||
        !await (await _file(owner, book.id, 'json')).exists()) {
      throw const EpubFailure('La copia local ya no existe. Reimportar EPUB.');
    }
    await _metadata(owner, book);
  }

  @override
  Future<void> remove(String owner, String id) async {
    // Remove availability first; if metadata deletion fails the UI marks it missing.
    final file = await _file(owner, id, 'epub');
    if (await file.exists()) await file.delete();
    final meta = await _file(owner, id, 'json');
    if (await meta.exists()) await meta.delete();
  }
}
