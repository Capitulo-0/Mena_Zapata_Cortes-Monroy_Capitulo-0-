import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/reader/data/local_txt_importer.dart';
import 'package:android/features/reader/models/reader_document.dart';

import 'support/local_txt_fakes.dart';

void main() {
  late FakeLocalTxtPicker picker;
  late TxtImportCancellation cancellation;
  setUp(() {
    picker = FakeLocalTxtPicker();
    cancellation = TxtImportCancellation();
  });
  tearDown(() => cancellation.cancel());

  test('reads full text once, preserves licenses and reuses its prepared document', () async {
    final text = 'Licencia sintética de prueba.\r\n${'Texto de prueba: ñ, ü y 📖.\n' * 6000}FIN DEL TXT.';
    final file = FakeLocalTxtFile(utf8.encode(text), name: 'obra.TXT');
    final future = LocalTxtImporter(picker).select(cancellation);
    picker.pending.single.complete(file.file);
    final source = (await future)!;
    final document = await source.prepare();
    expect(document.blocks.map((block) => block.text).join(), text);
    expect(source.title, 'Archivo local · obra.TXT');
    expect(source.author, isNull);
    expect(identical(await source.prepare(), document), isTrue);
    expect(file.reads, 1);
    expect(file.releases, 1);
  });

  test('cancelled picker returns without content or error', () async {
    final future = LocalTxtImporter(picker).select(cancellation);
    picker.pending.single.complete(null);
    expect(await future, isNull);
  });

  for (final invalid in [
    (name: 'libro.epub', size: 3),
    (name: 'libro.txt.html', size: 3),
    (name: 'libro.txt', size: 0),
    (name: 'libro.txt', size: ReaderSource.maxBytes + 1),
  ]) {
    test('rejects metadata before reading: ${invalid.name} size=${invalid.size}', () async {
      final file = FakeLocalTxtFile([65, 66, 67], name: invalid.name, reportedSize: invalid.size);
      final future = LocalTxtImporter(picker).select(cancellation);
      picker.pending.single.complete(file.file);
      await expectLater(future, throwsA(isA<ReaderFailure>()));
      expect(file.reads, 0);
      expect(file.releases, 1);
    });
  }

  for (final bytes in [[0xff], utf8.encode(' \n\t '),
    utf8.encode('x' * (ReaderSource.maxCodeUnits + 1))]) {
    test('shared reader rejects invalid, whitespace or decoded oversized input: ${bytes.length}', () async {
      final file = FakeLocalTxtFile(bytes);
      final future = LocalTxtImporter(picker).select(cancellation);
      picker.pending.single.complete(file.file);
      await expectLater(future, throwsA(isA<ReaderFailure>()));
      expect(file.reads, 1);
      expect(file.releases, 1);
    });
  }

  test('enforces actual streamed byte limit even when metadata is wrong', () async {
    final file = FakeLocalTxtFile([], reportedSize: 1,
      stream: Stream.value(List.filled(ReaderSource.maxBytes + 1, 65)));
    final future = LocalTxtImporter(picker).select(cancellation);
    picker.pending.single.complete(file.file);
    await expectLater(future, throwsA(isA<ReaderFailure>()));
    expect(file.releases, 1);
  });

  test('rejects incomplete content instead of accepting a truncated file', () async {
    final file = FakeLocalTxtFile(utf8.encode('Texto'), reportedSize: 20);
    final future = LocalTxtImporter(picker).select(cancellation);
    picker.pending.single.complete(file.file);
    await expectLater(future, throwsA(isA<ReaderFailure>()));
    expect(file.releases, 1);
  });

  test('read errors are sanitized without disclosing private paths', () async {
    final file = FakeLocalTxtFile([], reportedSize: 1,
      stream: Stream.error(StateError('/ruta/privada/secreto.txt')));
    final future = LocalTxtImporter(picker).select(cancellation);
    picker.pending.single.complete(file.file);
    await expectLater(future, throwsA(isA<ReaderFailure>()
      .having((error) => error.message, 'message', isNot(contains('/ruta/privada')))));
    expect(file.releases, 1);
  });

  test('late picker result is released without reading after cancellation', () async {
    final file = FakeLocalTxtFile(utf8.encode('Texto sintético.'));
    final future = LocalTxtImporter(picker).select(cancellation);
    cancellation.cancel();
    picker.pending.single.complete(file.file);
    await expectLater(future, throwsA(isA<ReaderCancelled>()));
    expect(file.reads, 0);
    expect(file.releases, 1);
  });

  test('cancellation stops an idle stream and releases the file', () async {
    var stopped = false;
    final stream = StreamController<List<int>>(onCancel: () { stopped = true; });
    final file = FakeLocalTxtFile([], reportedSize: 100, stream: stream.stream);
    final future = LocalTxtImporter(picker).select(cancellation);
    picker.pending.single.complete(file.file);
    await Future<void>.delayed(Duration.zero);
    cancellation.cancel();
    await expectLater(future, throwsA(isA<ReaderCancelled>()));
    expect(stopped, isTrue);
    expect(file.releases, 1);
    await stream.close();
  });

  test('sanitizes only the displayed file name, leaving content unchanged', () async {
    const text = '<script>No se ejecuta: es texto sintético.</script>';
    final file = FakeLocalTxtFile(utf8.encode(text), name: 'carpeta/privada/archivo.txt');
    final future = LocalTxtImporter(picker).select(cancellation);
    picker.pending.single.complete(file.file);
    final source = (await future)!;
    expect(source.title, 'Archivo local · archivo.txt');
    expect((await source.prepare()).blocks.single.text, text);
  });
}
