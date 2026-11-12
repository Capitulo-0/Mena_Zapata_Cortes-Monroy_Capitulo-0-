import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/home/presentation/widgets/home_network_cover.dart';
import 'package:android/features/home/presentation/screens/home_book_detail_screen.dart';
import 'package:android/features/library/models/library_entry.dart';
import 'package:android/features/library/models/book_status.dart';
import 'package:android/features/library/models/personal_library_list.dart';
import 'package:android/features/library/presentation/widgets/library_book_card.dart';
import 'package:android/features/library/presentation/screens/library_book_detail_screen.dart';
import 'package:android/features/library/presentation/dialogs/personal_list_dialogs.dart';

import 'library_regression_test.dart' show installLocalTestAssets;
import 'support/library_fakes.dart' show bookJson;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const url = 'https://books.google.com/books/content?id=fixture&img=1';
  final book = LibraryEntry.parseBook({
    ...bookJson(),
    'coverUrl': url,
    'googleVolumeId': 'fixture',
  });
  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
  Image cover(WidgetTester tester) => tester
      .widgetList<Image>(find.byType(Image))
      .singleWhere(
        (image) =>
            image.image is NetworkImage &&
            (image.image as NetworkImage).url == url,
      );
  void checkCover(WidgetTester tester) {
    final image = cover(tester);
    expect(
      (image.image as NetworkImage).webHtmlElementStrategy,
      WebHtmlElementStrategy.fallback,
    );
    expect(image.fit, BoxFit.cover);
    expect(image.errorBuilder, isNotNull);
    final context = tester.element(find.byWidget(image));
    final fallback = image.errorBuilder!(
      context,
      StateError('fixture load failure'),
      null,
    ) as Container;
    expect(fallback.child, isA<Icon>());
    expect((fallback.child as Icon).icon, Icons.menu_book_rounded);
  }

  testWidgets(
    'shared Home cover retains size, clipping and fallback on Android target',
    (tester) async {
      await tester.pumpWidget(
        app(
          const HomeNetworkCover(url: url, width: 44, height: 62, radius: 11),
        ),
      );
      await tester.pumpAndSettle();
      checkCover(tester);
      expect(tester.getSize(find.byType(HomeNetworkCover)), const Size(44, 62));
      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(HomeNetworkCover),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(clip.borderRadius, BorderRadius.circular(11));
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    },
  );
  testWidgets('empty Home cover still renders original placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const HomeNetworkCover(url: '', width: 44, height: 62)),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(HomeNetworkCover)), const Size(44, 62));
  });
  testWidgets('library card retains cover dimensions and open callback', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      app(
        LibraryBookCard(
          book: book,
          status: BookStatus.porLeer,
          progress: 0,
          review: null,
          onOpen: () => opened = true,
          onStartReading: () {},
          onAdvance: () {},
          onFinish: () {},
          onReviewTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    checkCover(tester);
    expect(tester.getSize(find.byWidget(cover(tester))), const Size(62, 88));
    await tester.tap(find.text(book.title));
    expect(opened, true);
  });
  for (final library in [false, true]) {
    testWidgets(
      'detail retains hero stack and return navigation: library=$library',
      (tester) async {
        final Widget detail = library
            ? LibraryBookDetailScreen(
                book: book,
                currentUsername: 'fixture',
                initialReview: null,
                initiallyFavorite: false,
                status: BookStatus.porLeer,
                progress: 0,
                onReviewSaved: (_) {},
                onToggleFavorite: () {},
                onOpenOwnProfile: () {},
                onStatusChanged: (_) {},
                onProgressChanged: (_) {},
              )
            : HomeBookDetailScreen(
                book: LibraryEntry.homeData(book),
                currentUsername: 'fixture',
                initialReview: null,
                onReviewSaved: (_, _) {},
                initiallyFavorite: false,
                onToggleFavorite: () {},
                onOpenOwnProfile: () {},
                onAddToLibrary: () {},
                isGuest: false,
                onGuestRestrictedAction: () {},
              );
        await tester.pumpWidget(
          app(
            Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => detail)),
                child: const Text('Open fixture'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open fixture'));
        await tester.pumpAndSettle();
        checkCover(tester);
        final context = tester.element(find.byWidget(cover(tester)));
        final stack = context.findAncestorWidgetOfExactType<Stack>()!;
        expect(stack.fit, StackFit.expand);
        expect(stack.children.first, same(cover(tester)));
        expect(stack.children.length, greaterThan(1));
        expect(tester.getSize(find.byWidget(cover(tester))).height, 285);
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
        expect(find.text('Open fixture'), findsOneWidget);
      },
    );
  }
  testWidgets('personal list cover uses same strategy and preserves dismiss', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => PersonalListDialogs.showListDetail(
              context: context,
              list: const PersonalLibraryList(
                name: 'Fixture list',
                description: '',
                emoji: '',
                bookIds: [901],
              ),
              books: [book],
            ),
            child: const Text('Open list'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open list'));
    await tester.pumpAndSettle();
    checkCover(tester);
    Navigator.of(tester.element(find.byWidget(cover(tester)))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Open list'), findsOneWidget);
  });
}
