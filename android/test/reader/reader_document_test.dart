import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/reader/models/reader_document.dart';

void main() {
  test('preserves the supplied text, accents, line breaks and supplementary Unicode', () async {
    const text = 'Texto sintético para esta prueba.\r\nEspaña: áéíóú, ñ, ü, ¿sí? ¡Sí! 📖\n\nFinal.';
    final document = await const ReaderSource.text(text).prepare();
    expect(document.blocks.map((block) => block.text).join(), text);
    expect(document.length, text.length);
  });

  test('strict UTF-8 handles a code point split between decoding batches', () async {
    final text = '${'x' * 16383}ñ📖\nÚltima línea sintética.';
    final source = ReaderSource.utf8(utf8.encode(text));
    final document = await source.prepare();
    expect(document.blocks.map((block) => block.text).join(), text);
  });

  test('takes an immutable snapshot of UTF-8 bytes', () async {
    final bytes = utf8.encode('Contenido autorizado de prueba.');
    final source = ReaderSource.utf8(bytes);
    bytes[0] = 0xff;
    expect((await source.prepare()).blocks.first.text, 'Contenido autorizado de prueba.');
  });

  for (final value in ['', ' \r\n\t ']) {
    test('empty or whitespace input reports an understandable error: ${value.length}', () async {
      await expectLater(ReaderSource.text(value).prepare(),
        throwsA(isA<ReaderFailure>().having((error) => error.message, 'message', contains('No hay texto'))));
    });
  }

  test('rejects malformed and truncated UTF-8 rather than replacing characters', () async {
    for (final bytes in [[0xff], [0xc3], [0xc0, 0xaf], [0xed, 0xa0, 0x80]]) {
      await expectLater(ReaderSource.utf8(bytes).prepare(), throwsA(isA<ReaderFailure>()));
    }
  });

  test('rejects unpaired UTF-16 surrogate in String input', () async {
    await expectLater(ReaderSource.text(String.fromCharCode(0xd800)).prepare(),
      throwsA(isA<ReaderFailure>()));
    await expectLater(ReaderSource.text(String.fromCharCode(0xdc00)).prepare(),
      throwsA(isA<ReaderFailure>()));
  });

  test('long unbroken text remains complete and blocks never split surrogate pairs', () async {
    final text = '📖' * 50000;
    final document = await ReaderSource.text(text).prepare();
    expect(document.blocks.map((block) => block.text).join(), text);
    var offset = 0;
    for (final block in document.blocks) {
      expect(block.start, offset);
      expect(block.text.length, lessThanOrEqualTo(1200));
      expect(() => utf8.encode(block.text), returnsNormally);
      expect(block.text.codeUnitAt(0), isNot(inInclusiveRange(0xdc00, 0xdfff)));
      expect(block.text.codeUnitAt(block.text.length - 1), isNot(inInclusiveRange(0xd800, 0xdbff)));
      offset += block.text.length;
    }
    expect(offset, document.length);
  });

  test('rejects oversized input before building reading blocks', () async {
    await expectLater(ReaderSource.text('x' * (ReaderSource.maxCodeUnits + 1)).prepare(),
      throwsA(isA<ReaderFailure>()));
    await expectLater(ReaderSource.utf8(List.filled(ReaderSource.maxBytes + 1, 65)).prepare(),
      throwsA(isA<ReaderFailure>()));
  });

  test('preparation yields and observes cancellation', () async {
    var cancelled = false;
    final future = ReaderSource.text('Texto sintético. ' * 20000)
      .prepare(isCancelled: () => cancelled);
    cancelled = true;
    await expectLater(future, throwsA(isA<ReaderCancelled>()));
  });
}
