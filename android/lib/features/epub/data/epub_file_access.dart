import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/imported_epub.dart';
import 'epub_validator.dart';

abstract interface class EpubFileAccess {
  Future<ValidatedEpub?> pick();
  Future<bool> export(ImportedEpub book, Uint8List bytes);
}

class SystemEpubFileAccess implements EpubFileAccess {
  const SystemEpubFileAccess();
  @override
  Future<ValidatedEpub?> pick() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        allowMultiple: false,
        withData: false,
        withReadStream: true,
        cancelUploadOnWindowBlur: false,
      );
      if (result == null) return null;
      if (result.files.length != 1) {
        throw const EpubFailure('Selecciona un único EPUB.');
      }
      final file = result.files.single;
      if (file.size <= 0) {
        throw const EpubFailure('El archivo EPUB está vacío.');
      }
      if (file.size > EpubValidator.maxBytes) {
        throw const EpubFailure('El EPUB supera el máximo de 20 MiB.');
      }
      final stream = file.readStream;
      if (stream == null) {
        throw const EpubFailure('No se pudo abrir el archivo seleccionado.');
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in stream) {
        if (bytes.length + chunk.length > EpubValidator.maxBytes) {
          throw const EpubFailure('El EPUB supera el máximo de 20 MiB.');
        }
        bytes.add(chunk);
      }
      if (bytes.length != file.size) {
        throw const EpubFailure(
          'La lectura del EPUB quedó incompleta. Selecciónalo nuevamente.',
        );
      }
      return const EpubValidator().validate(bytes.takeBytes(), file.name);
    } on EpubFailure {
      rethrow;
    } catch (_) {
      throw const EpubFailure('No se pudo importar el EPUB seleccionado.');
    } finally {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          await FilePicker.clearTemporaryFiles();
        } catch (_) {}
      }
    }
  }

  @override
  Future<bool> export(ImportedEpub book, Uint8List bytes) async {
    try {
      final name = book.fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9áéíóúñÁÉÍÓÚÑ._ -]'),
        '_',
      );
      final result = await FilePicker.saveFile(
        dialogTitle: 'Exportar copia EPUB',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: ['epub'],
        bytes: bytes,
      );
      return result != null;
    } catch (_) {
      throw const EpubFailure(
        'No se pudo exportar la copia EPUB. El libro local permanece guardado.',
      );
    }
  }
}
