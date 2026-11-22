import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/reader_document.dart';

abstract interface class LocalTxtPicker {
  Future<LocalTxtFile?> pick();
}

/// Metadata and a one-shot local stream; never an upload or a remote URL.
class LocalTxtFile {
  const LocalTxtFile({
    required this.name, required this.size, required this.openRead,
    required this.release,
  });
  final String name;
  final int size;
  final Stream<List<int>> Function() openRead;
  final Future<void> Function() release;
}

class SystemLocalTxtPicker implements LocalTxtPicker {
  const SystemLocalTxtPicker();
  // Held until the stream is consumed and the plugin's temporary copy is released.
  static bool _busy = false;

  static Future<void> _release() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        if (await FilePicker.clearTemporaryFiles() != true) {
          throw const ReaderFailure('No se pudo limpiar la copia temporal del selector.');
        }
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Future<LocalTxtFile?> pick() async {
    if (_busy) throw const ReaderFailure('Ya hay una selección de archivo en curso.');
    _busy = true;
    try {
      // Version 11.0.2 API; keeps the web user gesture and avoids eager byte loading.
      final result = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['txt'],
        allowMultiple: false, withData: false, withReadStream: true,
        cancelUploadOnWindowBlur: false,
      );
      if (result == null) {
        await _release();
        return null;
      }
      if (result.files.length != 1) {
        throw const ReaderFailure('Selecciona un único archivo TXT.');
      }
      final file = result.files.single;
      var released = false;
      return LocalTxtFile(
        name: file.name, size: file.size,
        openRead: () => file.readStream ??
          Stream<List<int>>.error(const ReaderFailure('No se pudo abrir el archivo local.')),
        release: () async {
          if (released) return;
          released = true;
          await _release();
        },
      );
    } catch (_) {
      if (_busy) await _release();
      rethrow;
    }
  }
}
