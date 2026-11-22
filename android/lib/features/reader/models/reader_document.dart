import 'dart:convert';
import 'dart:math' as math;

/// A local input supplied by the caller. This class never fetches a URL.
class ReaderSource {
  const ReaderSource.text(this.text, {this.title, this.author}) : bytes = null, _prepared = null;

  ReaderSource.utf8(List<int> value, {this.title, this.author})
      : bytes = List<int>.unmodifiable(value), text = null, _prepared = null;

  const ReaderSource._validated(this._prepared, {this.title, this.author})
      : text = null, bytes = null;

  final ReaderDocument? _prepared;

  /// Validates once, then retains only prepared text blocks for the reader.
  Future<ReaderSource> validated({bool Function()? isCancelled}) async =>
    ReaderSource._validated(await prepare(isCancelled: isCancelled),
      title: title, author: author);

  final String? text;
  final List<int>? bytes;
  final String? title;
  final String? author;

  static const maxCodeUnits = 2 * 1024 * 1024;
  static const maxBytes = 8 * 1024 * 1024;

  Future<ReaderDocument> prepare({bool Function()? isCancelled}) async {
    void check() {
      if (isCancelled?.call() == true) throw const ReaderCancelled();
    }

    check();
    if (_prepared != null) return _prepared;
    await Future<void>.delayed(Duration.zero);
    check();
    var content = text;
    if (content == null) {
      final input = bytes!;
      if (input.length > maxBytes) {
        throw const ReaderFailure('El archivo supera el límite de 8 MiB.');
      }
      final decoded = <String>[];
      final sink = const Utf8Decoder(allowMalformed: false)
          .startChunkedConversion(StringConversionSink.fromStringSink(
            _ChunkSink(decoded)));
      try {
        for (var start = 0; start < input.length; start += 16384) {
          check();
          sink.add(input.sublist(start, math.min(start + 16384, input.length)));
          await Future<void>.delayed(Duration.zero);
        }
        sink.close();
        content = decoded.join();
      } on FormatException {
        throw const ReaderFailure('El contenido no tiene una codificación UTF-8 válida.');
      } on RangeError {
        throw const ReaderFailure('El contenido no tiene una codificación UTF-8 válida.');
      }
    }
    if (content.length > maxCodeUnits) {
      throw const ReaderFailure('El texto supera el límite de 2 millones de unidades de texto.');
    }
    // Validate UTF-16 Strings as well as strict UTF-8 input, without replacing data.
    var nextYield = 0;
    for (var i = 0; i < content.length; i++) {
      final unit = content.codeUnitAt(i);
      if (unit >= 0xd800 && unit <= 0xdbff) {
        if (++i >= content.length ||
            content.codeUnitAt(i) < 0xdc00 || content.codeUnitAt(i) > 0xdfff) {
          throw const ReaderFailure('El texto contiene una codificación Unicode inválida.');
        }
      } else if (unit >= 0xdc00 && unit <= 0xdfff) {
        throw const ReaderFailure('El texto contiene una codificación Unicode inválida.');
      }
      if (i >= nextYield) {
        nextYield = i + 16384;
        check();
        await Future<void>.delayed(Duration.zero);
      }
    }
    final blocks = <ReaderBlock>[];
    var hasText = false;
    final whitespace = RegExp(r'\s');
    for (var start = 0; start < content.length;) {
      check();
      var end = math.min(start + 1200, content.length);
      if (end < content.length) {
        // Prefer a whitespace boundary, preserving every original code unit.
        var boundary = end;
        while (boundary > end - 200 &&
            !whitespace.hasMatch(content[boundary - 1])) {
          boundary--;
        }
        if (boundary > end - 200) end = boundary;
        if (content.codeUnitAt(end - 1) >= 0xd800 &&
            content.codeUnitAt(end - 1) <= 0xdbff) {
          end--;
        }
      }
      final part = content.substring(start, end);
      hasText = hasText || part.trim().isNotEmpty;
      blocks.add(ReaderBlock(start, part));
      start = end;
      if (blocks.length % 8 == 0) await Future<void>.delayed(Duration.zero);
    }
    check();
    if (!hasText) throw const ReaderFailure('No hay texto disponible para leer.');
    return ReaderDocument(List.unmodifiable(blocks), content.length);
  }
}

class _ChunkSink implements StringSink {
  _ChunkSink(this.chunks);
  final List<String> chunks;
  @override
  void write(Object? object) => chunks.add(object.toString());
  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      write(objects.join(separator));
  @override
  void writeCharCode(int charCode) => write(String.fromCharCode(charCode));
  @override
  void writeln([Object? object = '']) => write('$object\n');
}

class ReaderBlock {
  const ReaderBlock(this.start, this.text);
  final int start;
  final String text;
}

class ReaderDocument {
  const ReaderDocument(this.blocks, this.length);
  final List<ReaderBlock> blocks;
  /// UTF-16 offsets in the supplied, unmodified text; never editorial pages.
  final int length;
}

class ReaderFailure implements Exception {
  const ReaderFailure(this.message);
  final String message;
}

class ReaderCancelled implements Exception {
  const ReaderCancelled();
}
