import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/imported_epub.dart';
import 'epub_store.dart';
import 'epub_validator.dart';

class EpubRepository {
  EpubRepository({required String account, required this.store})
    : owner = sha256
          .convert(utf8.encode('capitulo0-epub-v1:$account'))
          .toString();
  final String owner;
  final EpubStore store;
  Future<List<ImportedEpub>> list() async {
    try {
      final records = await store.list(owner);
      final result = <ImportedEpub>[];
      for (final record in records) {
        result.add(
          record.position(
            fileAvailable: await store.contains(owner, record.id),
          ),
        );
      }
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    } on EpubFailure {
      rethrow;
    } catch (_) {
      throw const EpubFailure(
        'No pudimos recuperar tus EPUB locales. Revisa el almacenamiento.',
      );
    }
  }

  Future<ImportedEpub> import(ValidatedEpub source) async {
    try {
      final records = await list();
      final duplicate = records
          .where((r) => r.id == source.book.id)
          .firstOrNull;
      if (duplicate?.fileAvailable == true) {
        try {
          await bytes(duplicate!);
          return duplicate;
        } on EpubFailure {
          /* A valid reimport repairs a missing/corrupt private copy. */
        }
      }
      if (records.fold<int>(0, (n, b) => n + b.size) +
              (duplicate == null ? source.bytes.length : 0) >
          200 * 1024 * 1024) {
        throw const EpubFailure(
          'La colección local supera 200 MiB. Exporta y elimina algún EPUB.',
        );
      }
      final book = duplicate?.position(fileAvailable: true) ?? source.book;
      await store.insert(owner, book, source.bytes);
      return book;
    } on EpubFailure {
      rethrow;
    } catch (_) {
      throw const EpubFailure(
        'El EPUB no quedó almacenado. Revisa espacio y permisos y vuelve a importarlo.',
      );
    }
  }

  Future<Uint8List> bytes(ImportedEpub book) async {
    try {
      final bytes = await store.read(owner, book.id);
      if (bytes == null) {
        throw const EpubFailure('La copia local no existe. Reimportar EPUB.');
      }
      if (bytes.length != book.size ||
          sha256.convert(bytes).toString() != book.id) {
        throw const EpubFailure('La copia local está dañada. Reimportar EPUB.');
      }
      return bytes;
    } on EpubFailure {
      rethrow;
    } catch (_) {
      throw const EpubFailure(
        'No se pudo recuperar el EPUB local. Reimportar EPUB.',
      );
    }
  }

  Future<ValidatedEpub> open(ImportedEpub book) async {
    final data = await bytes(book);
    final validated = const EpubValidator().validate(data, book.fileName);
    return ValidatedEpub(
      book.position(chapters: validated.book.chapters),
      data,
    );
  }

  Future<void> progress(ImportedEpub book) async {
    try {
      await store.update(owner, book);
    } on EpubFailure {
      rethrow;
    } catch (_) {
      throw const EpubFailure(
        'No se pudo guardar el avance. Revisa el almacenamiento antes de salir.',
      );
    }
  }

  Future<void> remove(ImportedEpub book) async {
    try {
      await store.remove(owner, book.id);
    } catch (_) {
      throw const EpubFailure(
        'No se pudo completar la eliminación del EPUB. Inténtalo nuevamente.',
      );
    }
  }
}
