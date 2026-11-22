import 'dart:async';
import 'dart:typed_data';

import '../models/reader_document.dart';
import 'local_txt_picker.dart';

class TxtImportCancellation {
  final _cancelled = Completer<void>();
  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;
  void cancel() {
    if (!isCancelled) _cancelled.complete();
  }
  void check() {
    if (isCancelled) throw const ReaderCancelled();
  }
}

class LocalTxtImporter {
  const LocalTxtImporter(this.picker);
  final LocalTxtPicker picker;

  Future<ReaderSource?> select(TxtImportCancellation cancellation) async {
    LocalTxtFile? file;
    try {
      // No await before the picker: browser file dialogs require a user gesture.
      file = await picker.pick();
      cancellation.check();
      if (file == null) return null;
      final name = file.name.split(RegExp(r'[/\\]')).last
        .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
      if (!name.toLowerCase().endsWith('.txt')) {
        throw const ReaderFailure('Elige un archivo con extensión .txt.');
      }
      if (file.size < 0 || file.size > ReaderSource.maxBytes) {
        throw const ReaderFailure('El archivo supera el límite de 8 MiB.');
      }
      if (file.size == 0) throw const ReaderFailure('El archivo TXT está vacío.');
      final bytes = BytesBuilder(copy: false);
      final iterator = StreamIterator(file.openRead());
      var exhausted = false;
      try {
        while (await Future.any<bool>([
          iterator.moveNext(),
          cancellation.whenCancelled.then((_) => false),
        ])) {
          cancellation.check();
          final chunk = iterator.current;
          if (bytes.length + chunk.length > ReaderSource.maxBytes) {
            throw const ReaderFailure('El archivo supera el límite de 8 MiB.');
          }
          bytes.add(chunk);
        }
        cancellation.check();
        exhausted = true;
      } finally {
        // EOF already closes the stream; cancel only an interrupted read.
        if (!exhausted) await iterator.cancel();
      }
      if (bytes.length != file.size) {
        throw const ReaderFailure('El tamaño del archivo cambió o la lectura quedó incompleta. Selecciónalo nuevamente.');
      }
      final source = ReaderSource.utf8(bytes.takeBytes(),
        title: 'Archivo local · $name');
      // Strict UTF-8, emptiness and the decoded-text limit are shared with 4.2A.
      return await source.validated(isCancelled: () => cancellation.isCancelled);
    } on ReaderCancelled {
      rethrow;
    } on ReaderFailure {
      rethrow;
    } catch (_) {
      // Never expose an exception body: it can include a private path.
      throw const ReaderFailure('No se pudo leer el archivo local. Inténtalo nuevamente.');
    } finally {
      if (file != null) {
        try {
          await file.release();
        } catch (_) {
          throw const ReaderFailure('No se pudo limpiar la copia temporal del selector. Inténtalo nuevamente.');
        }
      }
    }
  }
}
