import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/session/local_account_scope.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/core/theme/app_colors.dart';
import 'package:android/features/epub/data/epub_file_access.dart';
import 'package:android/features/epub/data/epub_store.dart';
import 'package:android/features/epub/data/epub_validator.dart';
import 'package:android/features/epub/models/imported_epub.dart';
import 'package:android/features/epub/presentation/imported_epub_section.dart';

import '../fixtures/epub/fixture_bytes.dart';

import 'package:android/features/library/presentation/widgets/library_book_card.dart';
import 'package:android/features/library/presentation/widgets/library_status_counters.dart';

import 'package:android/features/library/presentation/screens/library_screen.dart';
import 'package:android/features/epub/data/epub_repository.dart';
import 'package:android/features/epub/data/epub_store_native.dart';
// Existing transitive platform interface; isolate test storage without new dependencies.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../library_regression_test.dart' show installLocalTestAssets;

class MemoryStore implements EpubStore {
  final records = <String, ImportedEpub>{};
  final files = <String, Uint8List>{};
  bool full = false;
  @override
  Future<List<ImportedEpub>> list(String owner) async => records.entries
      .where((e) => e.key.startsWith('$owner/'))
      .map((e) => e.value)
      .toList();
  @override
  Future<bool> contains(String owner, String id) async =>
      files.containsKey('$owner/$id');
  @override
  Future<Uint8List?> read(String owner, String id) async => files['$owner/$id'];
  @override
  Future<void> insert(String owner, ImportedEpub book, Uint8List bytes) async {
    if (full) throw StateError('quota');
    records['$owner/${book.id}'] = book;
    files['$owner/${book.id}'] = Uint8List.fromList(bytes);
  }

  @override
  Future<void> update(String owner, ImportedEpub book) async {
    if (full) throw StateError('quota');
    records['$owner/${book.id}'] = book;
  }

  @override
  Future<void> remove(String owner, String id) async {
    records.remove('$owner/$id');
    files.remove('$owner/$id');
  }
}

class Files implements EpubFileAccess {
  ValidatedEpub? result;
  Completer<ValidatedEpub?>? pending;
  Uint8List? exported;
  EpubFailure? failure;
  @override
  Future<ValidatedEpub?> pick() async {
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return result;
  }

  @override
  Future<bool> export(ImportedEpub book, Uint8List bytes) async {
    exported = Uint8List.fromList(bytes);
    return true;
  }
}

class IsolatedEpubPaths extends PathProviderPlatform {
  IsolatedEpubPaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestAssets);
  late MemoryStore store;
  late Files files;
  setUp(() {
    store = MemoryStore();
    files = Files()
      ..result = const EpubValidator().validate(
        base64Decode(fixtureEpubBase64),
        'fixture.epub',
      );
  });
  Widget app(String account) => MaterialApp(
    theme: AppTheme.light,
    builder: (c, child) => LocalAccountScope(uid: account, child: child!),
    home: Scaffold(
      body: ListView(
        children: [
          ImportedEpubSection(
            store: store,
            files: files,
            readerBuilder: (source, repo, account) => Scaffold(
              appBar: AppBar(title: Text(source.book.title)),
              body: Column(
                children: [
                  Text('${source.book.chapters.length} capítulos reales'),
                  FilledButton(
                    onPressed: () async {
                      await repo.progress(
                        source.book.position(
                          cfi: 'epubcfi(/6/4!/4/2/1:0)',
                          progress: .5,
                          fontSize: 22,
                        ),
                      );
                      if (cNavigator.currentContext
                          case final BuildContext context) {
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Guardar posición de prueba'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    navigatorKey: cNavigator,
  );
  Future<void> select(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('epub-import')));
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets(
      'import confirm read restore export delete and account isolation $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app('A'));
        await tester.pumpAndSettle();
        await select(tester);
        await tester.tap(find.byKey(const ValueKey('epub-confirm-import')));
        await tester.pumpAndSettle();
        expect(find.text('3 capítulos reales'), findsOneWidget);
        await tester.tap(find.text('Guardar posición de prueba'));
        await tester.pumpAndSettle();
        expect(find.text('Continuar leyendo'), findsOneWidget);
        expect(store.records, hasLength(1));
        final book = store.records.values.single;
        expect(book.cfi, isNotEmpty);
        expect(book.fontSize, 22);
        final export = find.byKey(ValueKey('epub-export-${book.id}'));
        await tester.ensureVisible(export);
        await tester.pumpAndSettle();
        await tester.tap(export);
        await tester.pumpAndSettle();
        expect(files.exported, orderedEquals(base64Decode(fixtureEpubBase64)));
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.pumpWidget(app('A'));
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        expect(find.text('Continuar leyendo'), findsOneWidget);
        await tester.pumpWidget(app('B'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('epub-imported-toggle')),
          findsNothing,
        );
        expect(find.text('Continuar leyendo'), findsNothing);
        await tester.pumpWidget(app('A'));
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        final delete = find.byKey(ValueKey('epub-delete-${book.id}'));
        await tester.ensureVisible(delete);
        await tester.pumpAndSettle();
        await tester.tap(delete);
        await tester.pumpAndSettle();
        expect(
          find.text('Eliminar EPUB de Mi Biblioteca'),
          findsOneWidget,
          reason:
              'Visible: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(" | ")}',
        );
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(store.records, hasLength(1));
        await tester.tap(delete);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('epub-confirm-delete')));
        await tester.pumpAndSettle();
        expect(store.records, isEmpty);
        expect(store.files, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'changing account while file selection is pending discards the old import',
    (tester) async {
      final pending = Completer<ValidatedEpub?>();
      files.pending = pending;
      await tester.pumpWidget(app('A'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('epub-import')));
      await tester.pump();
      await tester.pumpWidget(app('B'));
      await tester.pumpAndSettle();
      pending.complete(files.result);
      await tester.pumpAndSettle();
      expect(store.records, isEmpty);
      expect(store.files, isEmpty);
      expect(find.byKey(const ValueKey('epub-imported-toggle')), findsNothing);
      expect(find.text('Incorporar EPUB'), findsNothing);
      await tester.pumpWidget(app('A'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('epub-imported-toggle')), findsNothing);
    },
  );
  testWidgets(
    'Mi Biblioteca can continue a real local EPUB when server data is unavailable',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync(
        'capitulo0_epub_offline_',
      );
      final previous = PathProviderPlatform.instance;
      PathProviderPlatform.instance = IsolatedEpubPaths(directory.path);
      addTearDown(() async {
        PathProviderPlatform.instance = previous;
        final allowed =
            '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}'
                .toLowerCase();
        if (!directory.absolute.path.toLowerCase().startsWith(allowed)) {
          throw StateError('Unsafe test cleanup path');
        }
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final repository = EpubRepository(
        account: 'offline-A',
        store: NativeEpubStore(baseDirectory: directory),
      );
      final book = (await tester.runAsync(() async {
        final book = await repository.import(files.result!);
        await repository.progress(
          book.position(
            cfi: 'epubcfi(/6/4!/4/2/1:0)',
            progress: .5,
            fontSize: 22,
          ),
        );
        return book;
      }))!;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) =>
              LocalAccountScope(uid: 'offline-A', child: child!),
          home: Scaffold(
            body: LibraryScreen(
              dataAvailable: false,
              books: const [],
              statuses: const {},
              progresses: const {},
              reviews: const {},
              favorites: const {},
              currentName: 'Lector',
              currentUsername: '@offline',
              onOpenProfile: () {},
              onStatusChanged: (_, _) {},
              onProgressChanged: (_, _) {},
              onReviewSaved: (_, _) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );
      for (
        var i = 0;
        i < 50 && find.text('EPUB local').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('EPUB local'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('epub-read-${book.id}')), findsOneWidget);
      expect(find.text('Continuar leyendo'), findsOneWidget);
      expect(find.text('Exportar EPUB'), findsOneWidget);
      expect(
        tester.widget<LibraryScreen>(find.byType(LibraryScreen)).statuses,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('one main list searches counts opens exports deletes EPUB $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = EpubRepository(account: 'unified', store: store);
      final imported = await repo.import(files.result!);
      await repo.progress(
        imported.position(cfi: 'epubcfi(/6/4!/4/2/1:0)', progress: .5),
      );
      const normal = LibraryBook(
        id: 1,
        title: 'Libro sincronizado',
        author: 'Autor normal',
        year: 1900,
        genre: 'Novela',
        isbn: '',
        cover: '',
        synopsis: 'Sinopsis',
      );
      var openedEpub = false;
      var openedNormal = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewPadding: const EdgeInsets.only(bottom: 34),
              padding: const EdgeInsets.only(bottom: 34),
            ),
            child: LocalAccountScope(uid: 'unified', child: child!),
          ),
          home: Scaffold(
            extendBody: true,
            bottomNavigationBar: SafeArea(
              key: const ValueKey('test-floating-navigation'),
              minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: SizedBox(
                height: 76,
                child: ColoredBox(color: AppColors.deep),
              ),
            ),
            body: LibraryScreen(
              epubStore: store,
              epubFiles: files,
              epubReaderBuilder: (source, repository, account) {
                openedEpub = true;
                expect(source.book.cfi, 'epubcfi(/6/4!/4/2/1:0)');
                return Scaffold(
                  appBar: AppBar(title: const Text('Lector EPUB existente')),
                );
              },
              books: const [normal],
              statuses: const {1: BookStatus.leyendo},
              progresses: const {1: 25},
              reviews: const {},
              favorites: const {},
              currentName: 'Prueba',
              currentUsername: '@prueba',
              onOpenProfile: () {},
              onStatusChanged: (_, _) {},
              onProgressChanged: (_, _) {},
              onReviewSaved: (_, _) {},
              onToggleFavorite: (_) {},
              onReadBook: (_, id) async {
                openedNormal = true;
                expect(id, 1);
                return null;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final epub = find.byKey(ValueKey('imported-epub-${imported.id}'));
      expect(epub, findsOneWidget);
      expect(find.byType(LibraryBookCard), findsOneWidget);
      expect(find.text('EPUB local'), findsOneWidget);
      expect(
        find.descendant(of: epub, matching: find.text(imported.title)),
        findsNWidgets(2),
        reason: 'The EPUB keeps its own typographic cover and title',
      );
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final navTop = tester
          .getTopLeft(find.byKey(const ValueKey('test-floating-navigation')))
          .dy;
      for (final name in ['read', 'export', 'delete']) {
        final action = find.byKey(ValueKey('epub-$name-${imported.id}'));
        final rect = tester.getRect(action);
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(navTop - 8));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(action.hitTestable(), findsOneWidget);
      }
      final primary = tester.widget<FilledButton>(
        find.byKey(ValueKey('epub-read-${imported.id}')),
      );
      expect(primary.style!.backgroundColor!.resolve({}), AppColors.accent);
      final secondary = tester.widget<OutlinedButton>(
        find.byKey(ValueKey('epub-export-${imported.id}')),
      );
      expect(secondary.style!.side!.resolve({})!.color, AppColors.gold);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.byTooltip('Eliminar de mi biblioteca'), findsOneWidget);
      // Return to the main controls before the search assertions.
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.textContaining('Mis libros importados'), findsNothing);
      expect(find.byKey(const ValueKey('epub-imported-toggle')), findsNothing);
      final mainList = find
          .ancestor(of: epub, matching: find.byType(ListView))
          .first;
      expect(
        find.descendant(of: mainList, matching: find.byType(LibraryBookCard)),
        findsOneWidget,
      );
      final counts = tester.widget<LibraryStatusCounters>(
        find.byType(LibraryStatusCounters),
      );
      expect(counts.readingCount, 2);
      expect(counts.pendingCount, 0);
      expect(counts.readCount, 0);
      // Both kinds keep independent navigation/callbacks.
      tester.widget<LibraryBookCard>(find.byType(LibraryBookCard)).onAdvance();
      await tester.pumpAndSettle();
      expect(openedNormal, isTrue);
      for (final q in [
        imported.title,
        imported.author,
        imported.fileName,
        'EPUB local',
      ]) {
        await tester.enterText(find.byType(TextField), q);
        await tester.pumpAndSettle();
        expect(epub, findsOneWidget);
        expect(find.byType(LibraryBookCard), findsNothing);
      }
      await tester.enterText(find.byType(TextField), 'no existe');
      await tester.pumpAndSettle();
      expect(epub, findsNothing);
      await tester.enterText(find.byType(TextField), '');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(ValueKey('epub-read-${imported.id}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('epub-read-${imported.id}')));
      await tester.pumpAndSettle();
      expect(openedEpub, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      // A tap on the integrated card also opens the EPUB reader.
      await tester.ensureVisible(epub);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: epub, matching: find.text('EPUB local')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lector EPUB existente'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      final export = find.byKey(ValueKey('epub-export-${imported.id}'));
      await tester.ensureVisible(export);
      await tester.pumpAndSettle();
      await tester.tap(export);
      await tester.pumpAndSettle();
      expect(files.exported, orderedEquals(files.result!.bytes));
      // The header may be lazily unmounted while the list is scrolled down.
      // Scroll back through the actual main list before importing again.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('epub-import')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('epub-import')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('epub-confirm-import')));
      await tester.pumpAndSettle();
      expect(find.text('Lector EPUB existente'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(epub, findsOneWidget);
      expect(store.records, hasLength(1));
      final delete = find.byKey(ValueKey('epub-delete-${imported.id}'));
      expect(find.text('Lector EPUB existente'), findsNothing);
      expect(tester.widget<IconButton>(delete).onPressed, isNotNull);
      await tester.ensureVisible(delete);
      await tester.pumpAndSettle();
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(delete.hitTestable(), findsOneWidget);
      if (find.byType(SnackBar).evaluate().isNotEmpty) {
        expect(
          tester
              .getRect(delete)
              .overlaps(tester.getRect(find.byType(SnackBar))),
          isFalse,
          reason:
              'delete=${tester.getRect(delete)} snackbar=${tester.getRect(find.byType(SnackBar))}',
        );
      }
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(
        find.text('Eliminar EPUB de Mi Biblioteca'),
        findsOneWidget,
        reason:
            'Visible: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(" | ")}',
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(epub, findsOneWidget);
      await tester.ensureVisible(delete);
      await tester.pumpAndSettle();
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(delete.hitTestable(), findsOneWidget);
      if (find.byType(SnackBar).evaluate().isNotEmpty) {
        expect(
          tester
              .getRect(delete)
              .overlaps(tester.getRect(find.byType(SnackBar))),
          isFalse,
          reason:
              'delete=${tester.getRect(delete)} snackbar=${tester.getRect(find.byType(SnackBar))}',
        );
      }
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('epub-confirm-delete')));
      await tester.pumpAndSettle();
      expect(store.records, isEmpty);
      expect(epub, findsNothing);
      expect(find.byType(LibraryBookCard), findsOneWidget);
      expect(
        tester
            .widget<LibraryStatusCounters>(find.byType(LibraryStatusCounters))
            .readingCount,
        1,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('picker and confirmation cancellation do not create entries', (
    tester,
  ) async {
    files.result = null;
    await tester.pumpWidget(app('A'));
    await tester.pumpAndSettle();
    await select(tester);
    expect(store.records, isEmpty);
    files.result = const EpubValidator().validate(
      base64Decode(fixtureEpubBase64),
      'fixture.epub',
    );
    await select(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(store.records, isEmpty);
  });
  testWidgets(
    'quota failure and corrupt file have clear errors and no empty cards',
    (tester) async {
      store.full = true;
      await tester.pumpWidget(app('A'));
      await tester.pumpAndSettle();
      await select(tester);
      await tester.tap(find.byKey(const ValueKey('epub-confirm-import')));
      await tester.pumpAndSettle();
      expect(find.textContaining('no quedó almacenado'), findsOneWidget);
      expect(store.records, isEmpty);
      files.failure = const EpubFailure('El EPUB está corrupto.');
      await select(tester);
      expect(find.text('El EPUB está corrupto.'), findsOneWidget);
      expect(store.records, isEmpty);
    },
  );
}

final cNavigator = GlobalKey<NavigatorState>();
