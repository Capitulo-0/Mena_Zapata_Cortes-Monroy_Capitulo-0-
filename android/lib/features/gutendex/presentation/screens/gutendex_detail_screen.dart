import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/gutendex_repository.dart';
import '../../models/gutendex_models.dart';
import '../widgets/gutendex_cover.dart';

class GutendexDetailScreen extends StatefulWidget {
  const GutendexDetailScreen({super.key, required this.repository, required this.bookId,
    this.initialBook});
  final GutendexRepository repository;
  final int bookId;
  final GutendexBook? initialBook;

  @override
  State<GutendexDetailScreen> createState() => _GutendexDetailScreenState();
}

class _GutendexDetailScreenState extends State<GutendexDetailScreen> {
  GutendexBook? _book;
  Object? _error;
  bool _loading = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant GutendexDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.repository != widget.repository) {
      _reset();
    }
  }

  void _reset() {
    _generation++;
    final initial = widget.initialBook;
    _book = initial != null && initial.id == widget.bookId ? initial : null;
    _loading = false;
    _error = null;
    _refresh();
  }

  void _refresh() {
    if (_loading) return;
    final generation = ++_generation;
    final id = widget.bookId;
    final repository = widget.repository;
    setState(() {
      _loading = true;
      _error = null;
    });
    unawaited(_fetch(repository, id, generation));
  }

  Future<void> _fetch(GutendexRepository repository, int id, int generation) async {
    try {
      final result = await repository.detail(id);
      if (!mounted || generation != _generation) return;
      if (result.id != id) {
        throw const GutendexFailure('Gutendex devolvió una ficha no válida.');
      }
      setState(() => _book = _merge(_book, result));
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = error);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  // An incomplete refresh must not erase metadata already received for this ID.
  GutendexBook _merge(GutendexBook? previous, GutendexBook current) {
    if (previous == null || previous.id != current.id) return current;
    return GutendexBook(
      id: current.id,
      title: current.title?.trim().isNotEmpty == true ? current.title : previous.title,
      authors: current.authors.isNotEmpty ? current.authors : previous.authors,
      translators: current.translators.isNotEmpty ? current.translators : previous.translators,
      languages: current.languages.isNotEmpty ? current.languages : previous.languages,
      subjects: current.subjects.isNotEmpty ? current.subjects : previous.subjects,
      summaries: current.summaries.isNotEmpty ? current.summaries : previous.summaries,
      formats: {...previous.formats, ...current.formats},
      copyright: current.copyright ?? previous.copyright,
      downloadCount: current.downloadCount ?? previous.downloadCount,
    );
  }

  String get _errorMessage => _error is GutendexFailure
      ? (_error as GutendexFailure).message : 'No pudimos cargar la ficha.';

  @override
  void dispose() {
    _generation++;
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
      title: Text('Ficha · Gutendex', style: GoogleFonts.cinzel(
        color: AppColors.goldOf(context), fontSize: 16,
        fontWeight: FontWeight.w700)),
    ),
    body: Builder(
      builder: (context) {
        if (_book == null && _loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        if (_book == null) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textPrimaryOf(context), height: 1.5)),
              TextButton(
                onPressed: _refresh,
                child: const Text('Reintentar ficha'),
              ),
            ]),
          ));
        }
        final book = _book!;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              if (_loading) ...[
                const LinearProgressIndicator(color: AppColors.gold),
                const SizedBox(height: 12),
              ],
              if (_error != null) ...[
                Text('No se pudo actualizar. Se conservan los datos disponibles.',
                  style: GoogleFonts.inter(color: AppColors.textSecondaryOf(context))),
                Text(_errorMessage),
                TextButton(onPressed: _refresh, child: const Text('Reintentar ficha')),
                const SizedBox(height: 12),
              ],
              Center(child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.goldOf(context).withValues(alpha: .45)),
                  boxShadow: [BoxShadow(color: AppColors.deep.withValues(alpha: .12),
                    blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: GutendexCover(url: book.cover, width: 130, height: 190))),
              const SizedBox(height: 20),
              Text(book.displayTitle, style: GoogleFonts.merriweather(
                color: AppColors.textPrimaryOf(context), fontSize: 22,
                fontWeight: FontWeight.w700, height: 1.4)),
              const SizedBox(height: 10),
              Text(book.displayAuthors, style: GoogleFonts.inter(
                color: AppColors.accentOf(context), fontSize: 15, fontWeight: FontWeight.w600, height: 1.5)),
              const SizedBox(height: 10),
              Text('Idioma: ${book.displayLanguages}', style: GoogleFonts.inter(
                color: AppColors.textSecondaryOf(context), height: 1.5)),
              if (book.translators.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Traductores: ${book.translators.map((p) => p.name).join(' · ')}'),
              ],
              const SizedBox(height: 20),
              Text('Sinopsis', style: GoogleFonts.cinzel(color: AppColors.textPrimaryOf(context),
                fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(book.summaries.isEmpty
                ? 'Este libro no tiene una sinopsis disponible.'
                : book.summaries.join('\n\n'), style: GoogleFonts.inter(
                  color: AppColors.textPrimaryOf(context), fontSize: 14, height: 1.7)),
              const SizedBox(height: 20),
              Divider(color: AppColors.goldOf(context).withValues(alpha: .35)),
              const SizedBox(height: 12),
              Text('Materias', style: GoogleFonts.cinzel(color: AppColors.textPrimaryOf(context),
                fontSize: 15, fontWeight: FontWeight.w700)),
              Text(book.subjects.isEmpty ? 'Materias no informadas.'
                : book.subjects.join(' · ')),
              const SizedBox(height: 20),
              Divider(color: AppColors.goldOf(context).withValues(alpha: .35)),
              const SizedBox(height: 12),
              Text('Formatos disponibles', style: GoogleFonts.cinzel(color: AppColors.textPrimaryOf(context),
                fontSize: 15, fontWeight: FontWeight.w700)),
              const Text('Enlaces externos de Project Gutenberg. Puedes seleccionar y copiar '
                'la dirección para consultarla fuera de la aplicación.'),
              if (book.readingFormats.isEmpty)
                const Text('No hay enlaces seguros de EPUB, HTML o texto plano disponibles.'),
              for (final format in book.readingFormats)
                Container(margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.goldOf(context).withValues(alpha: .35))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${format.label} · ${format.mimeType}', style: GoogleFonts.inter(
                      color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SelectableText(format.url.toString()),
                  ]),
                ),
              const SizedBox(height: 20),
              Text('Fuente: Project Gutenberg · Gutendex · ID ${book.id}',
                style: GoogleFonts.inter(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w700)),
              SelectableText(book.source.toString()),
              if (book.downloadCount != null)
                Text('Descargas informadas: ${book.downloadCount}'),
              Text(switch (book.copyright) {
                true => 'Copyright informado por el proveedor: sí.',
                false => 'Copyright informado por el proveedor: no (referencia de EE. UU.).',
                null => 'Copyright no informado por el proveedor.',
              }),
              TextButton(
                onPressed: _loading ? null : _refresh,
                child: const Text('Actualizar ficha'),
              ),
              const SizedBox(height: 12),
              const Text('La disponibilidad técnica y el dato de copyright no garantizan '
                'dominio público en todos los países. Comprueba los derechos aplicables '
                'antes de utilizar una obra.'),
            ]),
          ),
        );
      },
    ),
  );
}
