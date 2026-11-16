import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/reader/models/reader_document.dart';
import 'package:android/features/reader/presentation/reader_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('measured text position round trips across font and width changes', () async {
    final document = await ReaderSource.text('Texto sintético para disposición. ' * 500).prepare();
    for (final width in [260.0, 660.0]) {
      for (final size in [14.0, 30.0]) {
        final layout = await ReaderLayout.prepare(document, width: width,
          style: TextStyle(fontSize: size, height: 1.8),
          scaler: TextScaler.linear(2), direction: TextDirection.ltr,
          isCancelled: () => false);
        expect(layout.heights.length, document.blocks.length);
        for (final index in [0, 3, document.blocks.length - 1]) {
          final position = document.blocks[index].start;
          final restored = layout.positionAt(layout.pixelsFor(position));
          expect(restored, position);
        }
        final anchor = document.blocks[5].start + 70;
        final lineStart = layout.positionAt(layout.pixelsFor(anchor));
        expect(lineStart, lessThanOrEqualTo(anchor));
        expect(anchor - lineStart, lessThan(100));
      }
    }
  });

  test('layout preparation yields and can be cancelled without building all blocks', () async {
    final document = await ReaderSource.text('Texto sintético. ' * 1000).prepare();
    var checks = 0;
    await expectLater(ReaderLayout.prepare(document, width: 300,
      style: const TextStyle(fontSize: 18), scaler: TextScaler.noScaling,
      direction: TextDirection.ltr, isCancelled: () => ++checks > 4),
      throwsA(isA<ReaderCancelled>()));
    expect(checks, 5);
  });
}
