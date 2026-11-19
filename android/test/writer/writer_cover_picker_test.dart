import 'dart:typed_data';

import 'package:android/features/writer/services/writer_cover_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final formats = <String, Uint8List Function(image.Image)>{
    'JPEG': image.encodeJpg,
    'PNG': image.encodePng,
    'WebP': image.encodeWebP,
  };
  var width = 9;
  for (final format in formats.entries) {
    final w = width++;
    test('${format.key} decodifica bytes y dimensiones reales', () async {
      final bytes = format.value(image.Image(width: w, height: 17));
      final cover = await WriterCoverPicker.read(
        PlatformFile(
          name: 'portada.png', // The file signature takes precedence over the filename.
          size: bytes.length,
          bytes: bytes,
        ),
      );
      expect(cover.width, w);
      expect(cover.height, 17);
      expect(cover.bytes, orderedEquals(bytes));
    });
  }

  test('lectura de stream completa y archivo truncado', () async {
    final bytes = image.encodePng(image.Image(width: 12, height: 18));
    final file = PlatformFile(
      name: 'portada.png',
      size: bytes.length,
      readStream: Stream.fromIterable([
        bytes.sublist(0, 13),
        bytes.sublist(13),
      ]),
    );
    expect((await WriterCoverPicker.read(file)).width, 12);
    await expectLater(
      WriterCoverPicker.read(
        PlatformFile(
          name: 'incompleta.png',
          size: bytes.length,
          readStream: Stream.value(bytes.sublist(0, 13)),
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('leer'),
        ),
      ),
    );
  });

  test('distingue formato, corrupción, tamaño y dimensiones', () async {
    Future<void> reject(Uint8List bytes, String message) => expectLater(
      WriterCoverPicker.validate(bytes),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains(message),
        ),
      ),
    );
    await reject(Uint8List.fromList([1, 2, 3, 4]), 'JPEG, PNG o WebP');
    await reject(Uint8List.fromList([255, 216, 255, 0]), 'corrupta');
    await reject(Uint8List(WriterCoverPicker.maxBytes + 1), '5 MB');
    await reject(
      image.encodePng(image.Image(width: 4097, height: 2)),
      '4096 px',
    );
  });
}
