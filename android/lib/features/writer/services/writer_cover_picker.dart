import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

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
      withData: false,
      withReadStream: true,
    );
    if (result == null) {
      return null;
    }
    final file = result.files.single;
    if (file.size > maxBytes) {
      throw const FormatException('La portada debe pesar hasta 5 MB.');
    }
    final stream = file.readStream;
    if (stream == null) {
      throw const FormatException('No se pudo leer esta imagen.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const FormatException('La portada debe pesar hasta 5 MB.');
      }
      bytes.add(chunk);
    }
    return validate(bytes.takeBytes());
  }

  static Future<WriterCoverSelection> validate(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const FormatException('La portada debe pesar hasta 5 MB.');
    }
    bool at(List<int> signature, int offset) =>
        bytes.length >= signature.length + offset &&
        List.generate(
          signature.length,
          (i) => bytes[offset + i] == signature[i],
        ).every((same) => same);
    final supported =
        at([137, 80, 78, 71, 13, 10, 26, 10], 0) ||
        at([255, 216, 255], 0) ||
        (at([82, 73, 70, 70], 0) && at([87, 69, 66, 80], 8));
    if (!supported) {
      throw const FormatException('Elige una imagen JPEG, PNG o WebP real.');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width > 4096 ||
          descriptor.height > 4096 ||
          descriptor.width * descriptor.height > 16000000) {
        throw const FormatException(
          'La imagen debe medir hasta 4096 px por lado y 16 megapíxeles.',
        );
      }
      // Decode too: an extension or a valid header alone does not prove an image is valid.
      final codec = await descriptor.instantiateCodec();
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      return WriterCoverSelection(bytes, descriptor.width, descriptor.height);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('La imagen está dañada o no es compatible.');
    } finally {
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
