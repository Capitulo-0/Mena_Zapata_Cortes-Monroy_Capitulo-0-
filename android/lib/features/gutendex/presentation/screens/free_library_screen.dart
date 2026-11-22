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
  String _query = '';
  String? _genre;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      color: AppColors.textSecondaryOf(context),
      fontSize: 13,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.surfaceOf(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: AppColors.goldOf(context).withValues(alpha: .52),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.goldOf(context), width: 1.6),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  Future<void> _showGenrePicker(List<String> genres) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetGold = AppColors.goldOf(sheetContext);
        final textPrimary = AppColors.textPrimaryOf(sheetContext);
        final textSecondary = AppColors.textSecondaryOf(sheetContext);
        final currentGenre = _genre ?? '';
        final options = <String>['', ...genres];

        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .72,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(sheetContext),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: sheetGold.withValues(alpha: .65)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 11),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetGold.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        color: sheetGold,
                        size: 22,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ELIGE UN GÉNERO',
                              style: GoogleFonts.cinzel(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Encuentra tu próxima lectura',
                              style: GoogleFonts.merriweather(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar géneros',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: Icon(Icons.close_rounded, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: sheetGold.withValues(alpha: .3)),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 9, 14, 18),
                    itemCount: options.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 3),
                    itemBuilder: (context, index) {
                      final value = options[index];
                      final active = currentGenre == value;
                      return Material(
                        color: active
                            ? sheetGold.withValues(alpha: .12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(sheetContext).pop(value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  value.isEmpty
                                      ? Icons.library_books_outlined
                                      : Icons.book_outlined,
                                  size: 19,
                                  color: active ? sheetGold : textSecondary,
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Text(
                                    value.isEmpty ? 'Todos los géneros' : value,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                if (active)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: sheetGold,
                                    size: 21,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() => _genre = selected.isEmpty ? null : selected);
  }

  Widget _workCard(BuildContext context, FreeWork work) {
    final gold = AppColors.goldOf(context);
    final secondary = AppColors.textSecondaryOf(context);
    final accent = AppColors.accentOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: ValueKey('free-work-${work.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) =>
                  FreeWorkDetailScreen(work: work, source: widget.source),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withValues(alpha: .65)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .10),
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      width: 70,
                      height: 103,
                      child: TypographicWorkCover(work: work),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        work.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.merriweather(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        work.author,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: secondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: work.available
                              ? const Color(0xFF38724C).withValues(alpha: .09)
                              : gold.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          work.available
                              ? 'Lectura disponible'
                              : 'Solo información · texto no incluido',
                          style: GoogleFonts.inter(
                            color: work.available
                                ? (AppColors.isDark(context)
                                      ? const Color(0xFF9ED4A9)
                                      : const Color(0xFF38724C))
                                : accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver edición',
                            style: GoogleFonts.inter(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final gold = AppColors.goldOf(context);
    final secondary = AppColors.textSecondaryOf(context);
    final genres =
        widget.works.map((w) => w.genre).whereType<String>().toSet().toList()
          ..sort();
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: _appBar(context, 'Biblioteca gratuita'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Text(
            'Obras completas para leer aquí',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ediciones verificadas incluidas en Capítulo 0. Descubre sus portadas y lee sin conexión, sin importar archivos.',
            style: GoogleFonts.merriweather(
              color: secondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 21),
          TextField(
            key: const ValueKey('free-library-search'),
            controller: _searchController,
            style: GoogleFonts.inter(
              color: AppColors.textPrimaryOf(context),
              fontSize: 13,
            ),
            decoration: _fieldDecoration(
              context,
              hint: 'Buscar por título o autor',
              prefixIcon: Icon(Icons.search_rounded, color: gold, size: 21),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: secondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          if (genres.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 13, bottom: 6),
                  child: Text(
                    'GÉNERO',
                    style: GoogleFonts.cinzel(
                      color: secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Material(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    key: const ValueKey('free-library-genre'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showGenrePicker(genres),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 51),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: gold, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 20, color: gold),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              _genre ?? 'Todos los géneros',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimaryOf(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: gold,
                            size: 23,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'EXPLORAR OBRAS',
                style: GoogleFonts.cinzel(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Divider(color: gold.withValues(alpha: .5))),
              const SizedBox(width: 10),
              Text(
                '${results.length} obras',
                style: GoogleFonts.inter(color: secondary, fontSize: 11),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 14),
            child: Text(
              '${widget.works.where((w) => w.available).length} con lectura disponible',
              style: GoogleFonts.inter(color: secondary, fontSize: 11),
            ),
          ),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 25),
              child: Column(
                children: [
                  Icon(Icons.menu_book_outlined, size: 32, color: gold),
                  const SizedBox(height: 9),
                  Text(
                    'No hay obras que coincidan.',
                    style: GoogleFonts.inter(color: secondary),
                  ),
                ],
              ),
            ),
          for (final work in results) _workCard(context, work),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
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
