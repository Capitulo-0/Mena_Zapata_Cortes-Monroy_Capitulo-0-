import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as image;

class WriterCoverSelection {
  const WriterCoverSelection(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width, height;
}

class WriterCoverPicker {
  static const maxBytes = 5 * 1024 * 1024;

  Future<WriterCoverSelection?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: kIsWeb,
      withReadStream: !kIsWeb,
    );
    if (result == null) return null;
    return read(result.files.single);
  }

  static Future<WriterCoverSelection> read(PlatformFile file) async {
    if (file.size > maxBytes) {
      throw const FormatException('La portada debe pesar hasta 5 MB.');
    }
    final Uint8List bytes;
    if (file.bytes case final data?) {
      bytes = data;
    } else if (file.readStream case final stream?) {
      final collected = BytesBuilder();
      try {
        await for (final chunk in stream.timeout(const Duration(seconds: 15))) {
          if (collected.length + chunk.length > maxBytes) {
            throw const FormatException('La portada debe pesar hasta 5 MB.');
          }
          collected.add(chunk);
        }
      } on FormatException {
        rethrow;
      } catch (_) {
        throw const FormatException('No se pudo leer el archivo seleccionado.');
      }
      bytes = collected.takeBytes();
    } else {
      throw const FormatException('No se pudo leer el archivo seleccionado.');
    }
    if (bytes.length != file.size || bytes.isEmpty) {
      throw const FormatException('No se pudo leer la imagen completa.');
    }
    return validate(bytes);
  }

  static Future<WriterCoverSelection> validate(Uint8List bytes) async {
    if (bytes.length > maxBytes) {
      throw const FormatException('La portada debe pesar hasta 5 MB.');
    }
    if (bytes.isEmpty) {
      throw const FormatException('No se pudo leer la imagen completa.');
    }
    bool at(List<int> signature, [int offset = 0]) {
      if (bytes.length < signature.length + offset) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[offset + i] != signature[i]) return false;
      }
      return true;
    }

    final decoder = switch ((
      at([137, 80, 78, 71, 13, 10, 26, 10]),
      at([255, 216, 255]),
      at([82, 73, 70, 70]) && at([87, 69, 66, 80], 8),
    )) {
      (true, _, _) => image.PngDecoder(),
      (_, true, _) => image.JpegDecoder(),
      (_, _, true) => image.WebPDecoder(),
      _ => throw const FormatException(
        'Elige una imagen JPEG, PNG o WebP real.',
      ),
    };
    const corrupt = FormatException('La imagen parece incompleta o corrupta.');
    try {
      // Flutter Web does not expose dimensions on an encoded ImageDescriptor.
      final info = decoder.startDecode(bytes);
      if (info == null || info.width <= 0 || info.height <= 0) throw corrupt;
      _checkDimensions(info.width, info.height);
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        try {
          _checkDimensions(frame.image.width, frame.image.height);
          return WriterCoverSelection(
            bytes,
            frame.image.width,
            frame.image.height,
          );
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } on FormatException catch (error) {
      if (identical(error, corrupt) || identical(error, _sizeError)) rethrow;
      throw corrupt;
    } catch (_) {
      throw corrupt;
    }
  }

  static const _sizeError = FormatException(
    'La imagen debe medir hasta 4096 px por lado y 16 megapíxeles.',
  );

  static void _checkDimensions(int width, int height) {
    if (width > 4096 || height > 4096 || width * height > 16000000) {
      throw _sizeError;
    }
  }
}
