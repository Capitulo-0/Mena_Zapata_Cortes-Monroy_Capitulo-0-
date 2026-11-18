import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/library/models/library_entry.dart';
import 'package:android/features/library/presentation/screens/library_screen.dart';
import 'package:android/features/library/presentation/widgets/library_book_card.dart';

import 'epub/epub_import_widgets_test.dart' show MemoryStore;
import 'library_regression_test.dart' show installLocalTestAssets;
import 'support/library_fakes.dart' show entryJson, bookJson;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  testWidgets(
    'each filter and search keeps its own decoded cover, including a delayed image',
    (tester) async {
      final entries = [
        for (var i = 0; i < 4; i++)
          LibraryEntry.fromJson({
            ...entryJson(
              id: 101 + i,
              status: ['LEYENDO', 'POR_LEER', 'LEIDO', 'POR_LEER'][i],
            ),
            'book': {
              ...bookJson(id: 101 + i),
              'coverUrl': i == 3
                  ? ''
                  : 'https://covers.invalid/book-${101 + i}.png',
            },
          }),
      ];
      final colors = [
        const Color(0xFFFF0000),
        const Color(0xFF0000FF),
        const Color(0xFF008000),
      ];
      final decoded = <ui.Image>[];
      for (final color in colors) {
        final image = await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          Canvas(
            recorder,
          ).drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint()..color = color);
          final picture = recorder.endRecording();
          final image = await picture.toImage(2, 2);
          picture.dispose();
          return image;
        });
        decoded.add(image!);
      }
      final delayed = Completer<ImageInfo>();
      for (var i = 0; i < 3; i++) {
        final provider = NetworkImage(
          entries[i].book.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        );
        PaintingBinding.instance.imageCache.putIfAbsent(
          provider,
          () => OneFrameImageStreamCompleter(
            i == 1
                ? delayed.future
                : Future.value(ImageInfo(image: decoded[i])),
          ),
        );
      }
      addTearDown(() {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: LibraryScreen(
              epubStore: MemoryStore(),
              books: entries.map((e) => e.book).toList(),
              statuses: {for (final e in entries) e.book.id: e.status},
              progresses: const {},
              reviews: const {},
              favorites: const {},
              currentName: 'Prueba',
              currentUsername: '@prueba',
              onOpenProfile: () {},
              onStatusChanged: (_, _) {},
              onProgressChanged: (_, _) {},
              onReviewSaved: (_, _) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder card(int id) => find.byWidgetPredicate(
        (w) => w is LibraryBookCard && w.book.id == id,
      );
      Future<void> check(int index) async {
        final c = card(101 + index);
        expect(c, findsOneWidget);
        final image = tester.widget<Image>(
          find.descendant(of: c, matching: find.byType(Image)),
        );
        expect((image.image as NetworkImage).url, entries[index].book.cover);
        final raw = tester.widget<RawImage>(
          find.descendant(of: c, matching: find.byType(RawImage)),
        );
        final pixels = await tester.runAsync(() => raw.image!.toByteData());
        final rgba = pixels!.buffer.asUint8List(
          pixels.offsetInBytes,
          pixels.lengthInBytes,
        );
        expect(rgba.take(3), switch (index) {
          0 => [255, 0, 0],
          1 => [0, 0, 255],
          _ => [0, 128, 0],
        });
      }

      await check(0);
      await tester.tap(find.text('Por leer'));
      await tester.pumpAndSettle();
      final pending = find.descendant(
        of: card(102),
        matching: find.byType(RawImage),
      );
      expect(
        pending.evaluate().isEmpty ||
            tester.widget<RawImage>(pending).image == null,
        isTrue,
        reason: 'The previous red cover must not be kept while the blue cover loads',
      );
      delayed.complete(ImageInfo(image: decoded[1]));
      await tester.pumpAndSettle();
      await check(1);
      expect(
        find.descendant(
          of: card(104),
          matching: find.byIcon(Icons.auto_stories_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card(104), matching: find.byType(RawImage)),
        findsNothing,
      );
      for (var repeat = 0; repeat < 3; repeat++) {
        for (final item in [
          (label: 'Leídos', index: 2),
          (label: 'Leyendo', index: 0),
          (label: 'Por leer', index: 1),
        ]) {
          await tester.tap(find.text(item.label));
          await tester.pumpAndSettle();
          await check(item.index);
        }
      }
      await tester.enterText(find.byType(TextField), 'SQL book 104');
      await tester.pumpAndSettle();
      expect(card(102), findsNothing);
      expect(
        find.descendant(
          of: card(104),
          matching: find.byIcon(Icons.auto_stories_outlined),
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await check(1);
      await tester.tap(find.text('Leyendo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'SQL book 101');
      await tester.pumpAndSettle();
      await check(0);
      await tester.enterText(find.byType(TextField), 'not found');
      await tester.pumpAndSettle();
      expect(find.byType(LibraryBookCard), findsNothing);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await check(0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
