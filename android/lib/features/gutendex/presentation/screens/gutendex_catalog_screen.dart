import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/gutendex_repository.dart';
import '../../models/gutendex_models.dart';
import '../gutendex_controller.dart';
import '../widgets/gutendex_cover.dart';
import 'gutendex_detail_screen.dart';

/// Standalone module entry point. Main navigation is intentionally unchanged.
class GutendexCatalogScreen extends StatefulWidget {
  const GutendexCatalogScreen({super.key, this.repository});
  final GutendexRepository? repository;

  @override
  State<GutendexCatalogScreen> createState() => _GutendexCatalogScreenState();
}

class _GutendexCatalogScreenState extends State<GutendexCatalogScreen> {
  late final GutendexRepository _repository;
  late final GutendexController _catalog;
  final _query = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HttpGutendexRepository();
    _catalog = GutendexController(_repository);
    unawaited(_catalog.search());
  }

  void _search() {
    _debounce?.cancel();
    unawaited(_catalog.search(query: _query.text, refresh: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _catalog.dispose();
    if (widget.repository == null) {
      (_repository as HttpGutendexRepository).close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundOf(context),
    appBar: AppBar(
      backgroundColor: AppColors.deepOf(context),
      foregroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(bottom: BorderSide(
        color: AppColors.goldOf(context).withValues(alpha: .5))),
      title: Text('Catálogo · Gutendex', style: GoogleFonts.cinzel(
        color: AppColors.goldOf(context), fontSize: 16,
        fontWeight: FontWeight.w700)),
    ),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900),
        child: AnimatedBuilder(
          animation: _catalog,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Obras de Project Gutenberg',
                style: GoogleFonts.merriweather(color: AppColors.textPrimaryOf(context),
                  fontSize: 20, fontWeight: FontWeight.w700, height: 1.4)),
              const SizedBox(height: 8),
              Text('Busca por título o autor. Este catálogo es independiente de Mi Biblioteca.',
                style: GoogleFonts.inter(color: AppColors.textSecondaryOf(context), height: 1.5)),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('gutendex-search'),
                controller: _query,
                decoration: InputDecoration(
                  labelText: 'Título o autor',
                  filled: true, fillColor: AppColors.surfaceOf(context),
                  prefixIcon: Icon(Icons.auto_stories_outlined, color: AppColors.goldOf(context)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.goldOf(context).withValues(alpha: .45))),
                  suffixIcon: IconButton(
                    tooltip: 'Buscar', onPressed: _search, icon: const Icon(Icons.search)),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                onChanged: (value) {
                  _debounce?.cancel();
                  _catalog.prepare(query: value);
                  _debounce = Timer(const Duration(milliseconds: 400),
                    () => unawaited(_catalog.search(query: _query.text)));
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<GutendexLanguage>(
                key: const ValueKey('gutendex-language'),
                isExpanded: true,
                initialValue: _catalog.language,
                dropdownColor: AppColors.surfaceOf(context),
                iconEnabledColor: AppColors.goldOf(context),
                decoration: InputDecoration(labelText: 'Idioma de la obra',
                  filled: true, fillColor: AppColors.surfaceOf(context),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.goldOf(context).withValues(alpha: .45)))),
                items: [
                  for (final language in GutendexLanguage.values)
                    DropdownMenuItem(value: language, child: Text(language.label)),
                ],
                onChanged: (language) {
                  if (language == null) return;
                  _debounce?.cancel();
                  unawaited(_catalog.search(query: _query.text, language: language));
                },
              ),
              const SizedBox(height: 18),
              if (_catalog.loading && !_catalog.hasSearched)
                const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              if (_catalog.loading && _catalog.hasSearched) ...[
                const LinearProgressIndicator(color: AppColors.gold),
                const SizedBox(height: 8),
                _message(context, 'Actualizando esta búsqueda. Se conservan sus resultados anteriores.'),
              ] else if (_catalog.fromSessionCache)
                _message(context, 'Resultados recientes de esta sesión. Pulsa Buscar para actualizarlos.'),
              if (_catalog.error != null && _catalog.hasSearched)
                _message(context, 'No se pudo actualizar. Se conservan los resultados de esta misma búsqueda.'),
              if (_catalog.error != null) ...[
                _message(context, _catalog.error!, error: true),
                TextButton(onPressed: _search, child: const Text('Reintentar catálogo')),
              ],
              if (_catalog.hasSearched && !_catalog.loading && _catalog.error == null && _catalog.items.isEmpty)
                _message(context, 'No encontramos obras para esta búsqueda e idioma.'),
              if (_catalog.count != null)
                Padding(padding: const EdgeInsets.only(bottom: 10),
                  child: Text('Obras informadas por Gutendex: ${_catalog.count}',
                    style: GoogleFonts.inter(color: AppColors.textSecondaryOf(context), fontSize: 12))),
              for (final book in _catalog.items)
                Card(
                  color: AppColors.surfaceOf(context),
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.goldOf(context).withValues(alpha: .35)),
                  ),
                  child: ListTile(
                    key: ValueKey('gutendex-book-${book.id}'),
                    contentPadding: const EdgeInsets.all(12),
                    leading: GutendexCover(url: book.cover, width: 44, height: 64),
                    title: Text(book.displayTitle, style: GoogleFonts.merriweather(
                      color: AppColors.textPrimaryOf(context), fontSize: 14,
                      fontWeight: FontWeight.w700, height: 1.4)),
                    subtitle: Padding(padding: const EdgeInsets.only(top: 6),
                      child: Text('${book.displayAuthors}\n${book.displayLanguages}',
                        style: GoogleFonts.inter(color: AppColors.textSecondaryOf(context),
                          fontSize: 12, height: 1.5))),
                    trailing: Icon(Icons.chevron_right, color: AppColors.goldOf(context)),
                    onTap: () => Navigator.of(context).push<void>(MaterialPageRoute(
                      builder: (_) => GutendexDetailScreen(
                        repository: _repository, bookId: book.id, initialBook: book),
                    )),
                  ),
                ),
              if (_catalog.loadingMore) const LinearProgressIndicator(color: AppColors.gold),
              if (_catalog.moreError != null) ...[
                _message(context, _catalog.moreError!, error: true),
                if (_catalog.next != null)
                  TextButton(onPressed: _catalog.loadingMore ? null : _catalog.more,
                    child: const Text('Reintentar página')),
              ] else if (_catalog.next != null)
                TextButton(onPressed: _catalog.loadingMore ? null : _catalog.more,
                  child: const Text('Más obras')),
              if (_catalog.hasSearched && !_catalog.loading && _catalog.error == null && _catalog.items.isNotEmpty &&
                  _catalog.next == null && _catalog.moreError == null)
                _message(context, 'Fin de resultados.'),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _message(BuildContext context, String text, {bool error = false}) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldOf(context).withValues(alpha: .35)),
      ),
      child: Text(text, textAlign: TextAlign.center,
        style: GoogleFonts.inter(height: 1.5,
          color: error ? AppColors.accentOf(context) : AppColors.textSecondaryOf(context))),
    );
}
