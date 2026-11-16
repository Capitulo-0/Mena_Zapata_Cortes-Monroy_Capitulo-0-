import 'package:flutter/painting.dart';

import '../models/reader_document.dart';

/// Measured in short batches so a single huge Text widget is never laid out.
class ReaderLayout {
  ReaderLayout._(this.document, this.width, this.style, this.scaler,
    this.direction, this.heights, this.tops);

  final ReaderDocument document;
  final double width;
  final TextStyle style;
  final TextScaler scaler;
  final TextDirection direction;
  final List<double> heights;
  final List<double> tops;

  static Future<ReaderLayout> prepare(ReaderDocument document, {
    required double width, required TextStyle style, required TextScaler scaler,
    required TextDirection direction, required bool Function() isCancelled,
  }) async {
    final heights = <double>[];
    final tops = <double>[0];
    for (final block in document.blocks) {
      if (isCancelled()) throw const ReaderCancelled();
      final painter = TextPainter(text: TextSpan(text: block.text, style: style),
        textScaler: scaler, textDirection: direction)..layout(maxWidth: width);
      final height = painter.height + 16;
      painter.dispose();
      heights.add(height);
      tops.add(tops.last + height);
      if (heights.length % 4 == 0) await Future<void>.delayed(Duration.zero);
    }
    return ReaderLayout._(document, width, style, scaler, direction,
      List.unmodifiable(heights), List.unmodifiable(tops));
  }

  int _blockAt(double pixels) {
    var low = 0;
    var high = heights.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (tops[mid] <= pixels) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  int positionAt(double pixels) {
    final index = _blockAt(pixels);
    final block = document.blocks[index];
    final painter = TextPainter(text: TextSpan(text: block.text, style: style),
      textScaler: scaler, textDirection: direction)..layout(maxWidth: width);
    final local = painter.getPositionForOffset(Offset(
      direction == TextDirection.ltr ? 0 : width,
      (pixels - tops[index]).clamp(0, heights[index] - 16)));
    painter.dispose();
    return (block.start + local.offset).clamp(0, document.length);
  }

  double pixelsFor(int position) {
    var index = 0;
    while (index + 1 < document.blocks.length &&
        document.blocks[index + 1].start <= position) {
      index++;
    }
    final block = document.blocks[index];
    final painter = TextPainter(text: TextSpan(text: block.text, style: style),
      textScaler: scaler, textDirection: direction)..layout(maxWidth: width);
    final local = painter.getOffsetForCaret(TextPosition(
      offset: (position - block.start).clamp(0, block.text.length)), Rect.zero);
    painter.dispose();
    // Font leading may put the caret above the first line of its block.
    return tops[index] + local.dy.clamp(0, heights[index] - 16);
  }
}
