import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/session/local_account_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../data/epub_file_access.dart';
import '../data/epub_repository.dart';
import '../data/epub_store.dart';
import '../models/imported_epub.dart';
import 'epub_reader_screen.dart';

class ImportedEpubSection extends StatefulWidget {
  const ImportedEpubSection({
    super.key,
    this.store,
    this.files = const SystemEpubFileAccess(),
    this.readerBuilder,
    this.libraryBuilder,
    this.libraryBuilderWithImport,
  });
  final EpubStore? store;
  final EpubFileAccess files;
  final Widget Function(ValidatedEpub, EpubRepository, String)? readerBuilder;

  /// Places the existing local actions/cards in Mi Biblioteca's main list.
  final Widget Function(
    List<ImportedEpub>,
    Widget Function(ImportedEpub),
    Widget,
  )?
  libraryBuilder;

  /// For LibraryScreen: exposes the existing import action to its options
  /// menu without recreating the picker or changing the EPUB storage flow.
  /// Other callers can keep using [libraryBuilder] unchanged.
  final Widget Function(
    List<ImportedEpub>,
    Widget Function(ImportedEpub),
    Widget,
    VoidCallback?,
  )?
  libraryBuilderWithImport;

  @override
  State<ImportedEpubSection> createState() => _ImportedEpubSectionState();
}

class _ImportedEpubSectionState extends State<ImportedEpubSection> {
  late final EpubStore _store = widget.store ?? createEpubStore();
  EpubRepository? _repository;
  String? _account, _error;
  List<ImportedEpub> _books = [];
  bool _busy = false;
  int _generation = 0;
  bool _current(int g) =>
      mounted &&
      g == _generation &&
      (LocalAccountScope.read(context) ?? 'guest') == _account;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final account =
        context.dependOnInheritedWidgetOfExactType<LocalAccountScope>()?.uid ??
        'guest';
    if (account == _account) return;
    _generation++;
    _account = account;
    _books = [];
    _error = null;
    _busy = false;
    _repository = EpubRepository(account: account, store: _store);
    unawaited(_refresh(_generation));
  }

  Future<void> _refresh(int g) async {
    try {
      final books = await _repository!.list();
      if (_current(g)) setState(() => _books = books);
    } catch (e) {
      if (_current(g)) {
        setState(
          () => _error = e is EpubFailure
              ? e.message
              : 'No se pudo abrir el almacenamiento EPUB.',
        );
      }
    }
  }

  Future<void> _run(Future<void> Function(int, EpubRepository) task) async {
    if (_busy) return;
    final g = _generation;
    final repository = _repository!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await task(g, repository);
    } catch (e) {
      if (_current(g)) {
        setState(
          () => _error = e is EpubFailure
              ? e.message
              : 'No pudimos completar la acción EPUB.',
        );
      }
    } finally {
      if (_current(g)) {
        await _refresh(g);
        if (_current(g)) setState(() => _busy = false);
      }
    }
  }

  Future<void> _open(
    ImportedEpub book,
    int g,
    EpubRepository repository,
  ) async {
    final source = await repository.open(book);
    if (!mounted || !_current(g)) return;
    final account = _account!;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            widget.readerBuilder?.call(source, repository, account) ??
            EpubReaderScreen(
              source: source,
              repository: repository,
              account: account,
            ),
      ),
    );
  }

  Future<void> _import({ImportedEpub? replace}) => _run((g, repository) async {
    // Picker is invoked before the first await that could lose the user gesture.
    final source = await widget.files.pick();
    if (source == null || !mounted || !_current(g)) return;
    if (replace != null && replace.id != source.book.id) {
      throw const EpubFailure(
        'Selecciona el mismo EPUB original para recuperar esta lectura.',
      );
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Incorporar EPUB'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(source.book.title),
            Text(source.book.author),
            const SizedBox(height: 12),
            Text('${source.book.chapters.length} entradas en el índice · EPUB'),
            const SizedBox(height: 12),
            const Text(
              'Se guardará solo en este navegador o dispositivo para esta cuenta. No se sincroniza con otros equipos.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('epub-confirm-import'),
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Guardar y leer'),
          ),
        ],
      ),
    );
    if (confirm != true || !_current(g)) return;
    final book = await repository.import(source);
    if (!mounted || !_current(g)) return;
    await _refresh(g);
    if (_current(g)) await _open(book, g, repository);
  });
  Future<void> _export(ImportedEpub book) => _run((g, repository) async {
    final bytes = await repository.bytes(book);
    if (!mounted || !_current(g)) return;
    final saved = await widget.files.export(book, bytes);
    if (mounted && _current(g) && saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Copia EPUB exportada sin modificar el archivo original.',
          ),
        ),
      );
    }
  });
  Future<void> _remove(ImportedEpub book) => _run((g, repository) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Eliminar EPUB de Mi Biblioteca'),
        content: Text(
          'Se eliminarán la copia local y el avance de «${book.title}» de esta cuenta. Exporta antes si quieres conservar una copia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('epub-confirm-delete'),
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && _current(g)) await repository.remove(book);
  });
  @override
  Widget build(BuildContext context) {
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('epub-import'),
            onPressed: _busy ? null : () => _import(),
            icon: const Icon(Icons.file_open_outlined, size: 19),
            label: const Text('Importar EPUB', textAlign: TextAlign.center),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimaryOf(context),
              backgroundColor: AppColors.surfaceOf(context),
              side: BorderSide(
                color: AppColors.goldOf(context).withValues(alpha: .7),
              ),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_busy) const Text('Procesando EPUB...'),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _error!,
              key: const ValueKey('epub-error'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
    // The import button can live in LibraryScreen's options sheet, while
    // progress/errors stay visible in the library body. The same _import()
    // callback still performs picking, confirmation, validation and saving.
    final importFeedback = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Procesando EPUB...'),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _error!,
              key: const ValueKey('epub-error'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
    if (widget.libraryBuilderWithImport != null) {
      return widget.libraryBuilderWithImport!(
        List<ImportedEpub>.unmodifiable(_books),
        _buildCard,
        importFeedback,
        _busy ? null : () => _import(),
      );
    }
    return widget.libraryBuilder?.call(
          List<ImportedEpub>.unmodifiable(_books),
          _buildCard,
          controls,
        ) ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [controls, for (final book in _books) _buildCard(book)],
        );
  }

  Widget _buildCard(ImportedEpub book) => Card(
    key: ValueKey('imported-epub-${book.id}'),
    color: AppColors.surfaceOf(context),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _busy
          ? null
          : book.fileAvailable
          ? () => _run((g, r) => _open(book, g, r))
          : () => _import(replace: book),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.deep,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.menu_book,
                          color: AppColors.gold,
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 7,
                            color: AppColors.background,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(book.author),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'EPUB local',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'EPUB · ${book.status} · ${(book.progress * 100).round()} %',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!book.fileAvailable)
              const Text(
                'El archivo local no está disponible. Reimporta el EPUB original para recuperar esta lectura.',
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: ValueKey('epub-read-${book.id}'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.surface,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _busy
                    ? null
                    : book.fileAvailable
                    ? () => _run((g, r) => _open(book, g, r))
                    : () => _import(replace: book),
                icon: Icon(
                  book.fileAvailable
                      ? Icons.menu_book_rounded
                      : Icons.file_open_outlined,
                  size: 20,
                ),
                label: Text(
                  !book.fileAvailable
                      ? 'Reimportar EPUB'
                      : book.cfi.isEmpty
                      ? 'Leer EPUB'
                      : 'Continuar leyendo',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('epub-export-${book.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryOf(context),
                      backgroundColor: AppColors.surfaceOf(context),
                      side: BorderSide(color: AppColors.goldOf(context)),
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _busy || !book.fileAvailable
                        ? null
                        : () => _export(book),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text(
                      'Exportar EPUB',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: ValueKey('epub-delete-${book.id}'),
                  tooltip: 'Eliminar de mi biblioteca',
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryOf(context),
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _busy ? null : () => _remove(book),
                  icon: const Icon(Icons.delete_outline_rounded, size: 21),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
