import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../reader/models/reader_document.dart';
import '../../../reader/presentation/screens/text_reader_screen.dart';
import '../../data/asset_reader_source.dart';
import '../../models/free_work.dart';
import '../widgets/free_work_cover.dart';

class FreeLibraryScreen extends StatefulWidget {
  const FreeLibraryScreen({
    super.key,
    this.onlineBuilder,
    this.works = freeWorks,
    this.source = const AssetReaderSource(),
  });
  // Kept optional for compatibility with other catalog callers; no external UI action.
  final WidgetBuilder? onlineBuilder;
  final List<FreeWork> works;
  final AssetReaderSource source;
  @override
  State<FreeLibraryScreen> createState() => _FreeLibraryScreenState();
}

class _FreeLibraryScreenState extends State<FreeLibraryScreen> {
  final _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _query = '';
  String? _genre;
  String _searchKey(String value) {
    var result = value.toLowerCase().trim();
    const accents = 'áéíóúüñ';
    const plain = 'aeiouun';
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], plain[i]);
    }
    return result;
  }

  List<FreeWork> get _filtered => widget.works
      .where(
        (work) =>
            (_genre == null || work.genre == _genre) &&
            _searchKey('${work.title} ${work.author}')
                .contains(_searchKey(_query)),
      )
      .toList();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundOf(context),
    appBar: _appBar(context, 'Biblioteca gratuita'),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Obras completas para leer aquí',
          style: GoogleFonts.merriweather(
            fontSize: 21,
            height: 1.4,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ediciones verificadas incluidas en Capítulo 0. Descubre sus portadas y lee sin conexión, sin importar archivos.',
          style: TextStyle(
            height: 1.5,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey('free-library-search'),
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar por título o autor',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        if (widget.works.any((w) => w.genre != null)) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('free-library-genre'),
            isExpanded: true,
            initialValue: _genre ?? '',
            decoration: const InputDecoration(labelText: 'Género'),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Todos los géneros'),
              ),
              for (final genre
                  in (widget.works
                      .map((w) => w.genre)
                      .whereType<String>()
                      .toSet()
                      .toList()
                    ..sort()))
                DropdownMenuItem(value: genre, child: Text(genre)),
            ],
            onChanged: (value) =>
                setState(() => _genre = value == '' ? null : value),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          '${_filtered.length} obras · ${widget.works.where((w) => w.available).length} con lectura disponible',
        ),
        if (_filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No hay obras que coincidan.'),
          ),
        const SizedBox(height: 12),
        for (final work in _filtered)
          Card(
            color: AppColors.surfaceOf(context),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.goldOf(context)),
            ),
            child: InkWell(
              key: ValueKey('free-work-${work.id}'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      FreeWorkDetailScreen(work: work, source: widget.source),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 110,
                      child: TypographicWorkCover(work: work),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            work.title,
                            style: GoogleFonts.merriweather(
                              fontSize: 16,
                              height: 1.4,
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            work.author,
                            style: TextStyle(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            work.available
                                ? 'Lectura disponible'
                                : 'Solo información · texto no incluido',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentOf(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ver edición',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

AppBar _appBar(BuildContext context, String title) => AppBar(
  backgroundColor: AppColors.deep,
  foregroundColor: AppColors.background,
  title: Text(
    title,
    style: GoogleFonts.cinzel(color: AppColors.gold, fontSize: 16),
  ),
);

/// Compatibility wrapper used by the local catalogue and edition screen.
class TypographicWorkCover extends StatelessWidget {
  const TypographicWorkCover({
    super.key,
    required this.work,
    this.large = false,
  });
  final FreeWork work;
  final bool large;
  @override
  Widget build(BuildContext context) => FreeWorkCover(work: work);
}

class FreeWorkDetailScreen extends StatefulWidget {
  const FreeWorkDetailScreen({
    super.key,
    required this.work,
    this.source = const AssetReaderSource(),
  });
  final FreeWork work;
  final AssetReaderSource source;
  @override
  State<FreeWorkDetailScreen> createState() => _FreeWorkDetailScreenState();
}

class _FreeWorkDetailScreenState extends State<FreeWorkDetailScreen> {
  bool _opening = false;
  String? _error;
  Future<void> _read() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final work = widget.work;
      final source = await widget.source.load(
        work,
        isCancelled: () => !mounted || work != widget.work,
      );
      if (!mounted || work != widget.work) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => TextReaderScreen(source: source)),
      );
    } on ReaderCancelled {
      // Route was closed during preparation.
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ReaderFailure
              ? error.message
              : 'No pudimos abrir el texto incluido. Inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final work = widget.work;
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: _appBar(context, 'Edición de lectura'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: SizedBox(
              width: 170,
              height: 245,
              child: TypographicWorkCover(work: work, large: true),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Diseño original de Capítulo 0 · no reproduce una cubierta comercial',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            work.title,
            style: GoogleFonts.merriweather(
              fontSize: 23,
              height: 1.4,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(work.author),
          const SizedBox(height: 12),
          Text(work.language == 'es' ? 'Español' : work.language),
          const SizedBox(height: 12),
          Text(work.edition, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 20),
          if (work.available)
            FilledButton.icon(
              key: const ValueKey('free-work-read'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deep,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
              onPressed: _opening ? null : _read,
              icon: const Icon(Icons.menu_book_outlined, color: AppColors.gold),
              label: Text(_opening ? 'Preparando lectura…' : 'Leer ahora'),
            )
          else
            const Text('Esta obra no tiene texto local disponible.'),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: AppColors.accentOf(context)),
                semanticsLabel: _error,
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Fuente y condiciones',
            style: GoogleFonts.merriweather(fontSize: 16),
          ),
          const SizedBox(height: 12),
          SelectableText(
            work.source,
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            work.conditions,
            style: const TextStyle(fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
