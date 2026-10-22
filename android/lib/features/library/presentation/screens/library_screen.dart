import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

enum BookStatus { porLeer, leyendo, leido }

class LibraryBook {
  const LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.year,
    required this.genre,
    required this.isbn,
    required this.cover,
    required this.synopsis,
    this.authorHandle,
    this.isFree = true,
  });

  final int id;
  final String title;
  final String author;
  final String? authorHandle;
  final int year;
  final String genre;
  final String isbn;
  final String cover;
  final String synopsis;
  final bool isFree;
}

class BookReview {
  const BookReview({
    required this.rating,
    required this.text,
    this.isPublic = true,
  });

  final int rating;
  final String text;
  final bool isPublic;
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.books,
    required this.statuses,
    required this.progresses,
    required this.reviews,
    required this.favorites,
    required this.currentName,
    required this.onStatusChanged,
    required this.onProgressChanged,
    required this.onReviewSaved,
    required this.onToggleFavorite,
  });

  final List<LibraryBook> books;
  final Map<int, BookStatus> statuses;
  final Map<int, int> progresses;
  final Map<int, BookReview> reviews;
  final Set<int> favorites;
  final String currentName;

  final void Function(int bookId, BookStatus status) onStatusChanged;
  final void Function(int bookId, int progress) onProgressChanged;
  final void Function(int bookId, BookReview review) onReviewSaved;
  final void Function(int bookId) onToggleFavorite;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _view = 'libros';
  String _filter = 'todos';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LibraryBook> get _booksInLibrary {
    return widget.books
        .where((book) => widget.statuses.containsKey(book.id))
        .toList();
  }

  List<LibraryBook> get _filteredBooks {
    var result = _booksInLibrary;

    if (_filter != 'todos') {
      result = result.where((book) {
        final status = widget.statuses[book.id];
        if (_filter == 'leyendo') return status == BookStatus.leyendo;
        if (_filter == 'porLeer') return status == BookStatus.porLeer;
        if (_filter == 'leidos') return status == BookStatus.leido;
        return true;
      }).toList();
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((book) {
        return book.title.toLowerCase().contains(q) ||
            book.author.toLowerCase().contains(q) ||
            book.genre.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  int _count(BookStatus status) {
    return widget.statuses.values.where((value) => value == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundOf(context),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildViewSelector(),
            const SizedBox(height: 12),
            if (_view == 'libros') ...[
              _buildSearch(),
              const SizedBox(height: 10),
              _buildCounters(),
              const SizedBox(height: 10),
              _buildFilters(),
              const SizedBox(height: 12),
              if (_filteredBooks.isEmpty)
                _buildEmptyState()
              else
                ..._filteredBooks.map(_buildBookCard),
            ] else
              _buildListsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final displayName = widget.currentName.trim().isEmpty
        ? 'LECTOR/A'
        : widget.currentName.trim().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MI BIBLIOTECA',
          style: GoogleFonts.cinzel(
            color: AppColors.textPrimaryOf(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Tus libros, progreso y estados en un solo lugar, ',
                style: GoogleFonts.merriweather(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 9.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextSpan(
                text: '$displayName ✦',
                style: GoogleFonts.cinzel(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 9.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewSelector() {
    final isBooks = _view == 'libros';

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.55),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment:
                    isBooks ? Alignment.centerLeft : Alignment.centerRight,
                child: SizedBox(
                  width: constraints.maxWidth / 2,
                  height: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.deepOf(context),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepOf(context)
                              .withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _viewButton(
                      'libros',
                      '📚 Libros',
                    ),
                  ),
                  Expanded(
                    child: _viewButton(
                      'listas',
                      '☷ Mis listas',
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _viewButton(String id, String label) {
    final active = _view == id;

    return InkWell(
      onTap: () {
        if (_view == id) return;

        setState(() {
          _view = id;
        });
      },
      borderRadius: BorderRadius.circular(9),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 210),
        curve: Curves.easeOutCubic,
        style: GoogleFonts.inter(
          color: active
              ? AppColors.gold
              : AppColors.textPrimaryOf(context),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
        child: SizedBox(
          height: 36,
          child: Center(
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.60),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _query = value;
          });
        },
        style: GoogleFonts.inter(
          color: AppColors.textPrimaryOf(context),
          fontSize: 9.5,
        ),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 7,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.gold.withValues(alpha: 0.88),
            size: 16,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 34,
          ),
          hintText: 'Buscar en mi biblioteca...',
          hintStyle: GoogleFonts.inter(
            color: AppColors.textSecondaryOf(context)
                .withValues(alpha: 0.82),
            fontSize: 9,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _query = '';
                    });
                  },
                  splashRadius: 15,
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondaryOf(context)
                        .withValues(alpha: 0.72),
                    size: 15,
                  ),
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 34,
          ),
        ),
      ),
    );
  }

  Widget _buildCounters() {
    return Row(
      children: [
        Expanded(
          child: _counterCard(
            'Leyendo',
            _count(BookStatus.leyendo),
            AppColors.accent,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _counterCard(
            'Por leer',
            _count(BookStatus.porLeer),
            AppColors.gold,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _counterCard(
            'Leídos',
            _count(BookStatus.leido),
            AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _counterCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.75), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondaryOf(context),
              fontSize: 7.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final tabs = <Map<String, String>>[
      {'id': 'todos', 'label': 'Todos'},
      {'id': 'leyendo', 'label': 'Leyendo'},
      {'id': 'porLeer', 'label': 'Por leer'},
      {'id': 'leidos', 'label': 'Leídos'},
    ];

    return Row(
      children: List.generate(
        tabs.length,
        (index) {
          final tab = tabs[index];
          final active = _filter == tab['id'];

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < tabs.length - 1 ? 5 : 0,
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _filter = tab['id']!;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.deepOf(context)
                        : AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active
                          ? AppColors.deepOf(context)
                          : AppColors.gold.withValues(alpha: 0.46),
                    ),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: GoogleFonts.inter(
                      color: active
                          ? AppColors.gold
                          : AppColors.textSecondaryOf(context),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text(
                      tab['label']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            color: AppColors.gold,
            size: 34,
          ),
          const SizedBox(height: 9),
          Text(
            _booksInLibrary.isEmpty
                ? 'Todavía no tienes libros en tu biblioteca.'
                : 'No encontramos libros con este filtro.',
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              color: AppColors.textSecondaryOf(context),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(LibraryBook book) {
    final status = widget.statuses[book.id] ?? BookStatus.porLeer;
    final progress = widget.progresses[book.id] ?? 0;
    final review = widget.reviews[book.id];

    return InkWell(
      onTap: () => _openBookDetail(book),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.42)),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepOf(context).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cover(book.cover, 62, 88),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.author,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (status == BookStatus.leyendo) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Progreso',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondaryOf(context),
                              fontSize: 7.5,
                            ),
                          ),
                        ),
                        Text(
                          '$progress%',
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _progressBar(progress / 100),
                    const SizedBox(height: 8),
                  ],
                  if (status == BookStatus.leido && review != null) ...[
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < review.rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 12,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          review.isPublic ? 'Reseña pública' : 'Reseña privada',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                  ],
                  _buildStatusActions(book, status, progress, review),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActions(
    LibraryBook book,
    BookStatus status,
    int progress,
    BookReview? review,
  ) {
    if (status == BookStatus.porLeer) {
      return _primaryButton(
        label: 'Comenzar lectura',
        onTap: () {
          widget.onStatusChanged(book.id, BookStatus.leyendo);
          widget.onProgressChanged(book.id, 0);
          setState(() {});
        },
      );
    }

    if (status == BookStatus.leyendo) {
      return Row(
        children: [
          Expanded(
            child: _primaryButton(
              label: '+ Avanzar',
              onTap: () {
                final next = (progress + 10).clamp(0, 100).toInt();
                widget.onProgressChanged(book.id, next);
                if (next >= 100) {
                  widget.onStatusChanged(book.id, BookStatus.leido);
                }
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _secondaryButton(
              label: 'Finalizar ✓',
              onTap: () {
                widget.onProgressChanged(book.id, 100);
                widget.onStatusChanged(book.id, BookStatus.leido);
                setState(() {});
              },
            ),
          ),
        ],
      );
    }

    return _secondaryButton(
      label: review == null ? 'Calificar y reseñar' : 'Ver / editar reseña',
      onTap: () => _openReviewEditor(book),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 30,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          minimumSize: const Size(0, 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryOf(context),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.85)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _statusBadge(BookStatus status) {
    String text;
    Color color;

    switch (status) {
      case BookStatus.leyendo:
        text = 'LEYENDO';
        color = AppColors.accent;
        break;
      case BookStatus.porLeer:
        text = 'POR LEER';
        color = AppColors.gold;
        break;
      case BookStatus.leido:
        text = 'LEÍDO';
        color = AppColors.textPrimaryOf(context);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 6.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _progressBar(double value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppColors.surfaceSoftOf(context)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0).toDouble(),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.accent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListsView() {
    final favorites = widget.books
        .where((book) => widget.favorites.contains(book.id))
        .toList();
    final reading = widget.books
        .where((book) => widget.statuses[book.id] == BookStatus.leyendo)
        .toList();
    final pending = widget.books
        .where((book) => widget.statuses[book.id] == BookStatus.porLeer)
        .toList();

    return Column(
      children: [
        _listCollectionCard(
          title: 'Favoritos',
          subtitle: 'Libros que marcaste con ♥',
          icon: Icons.favorite_rounded,
          books: favorites,
        ),
        const SizedBox(height: 10),
        _listCollectionCard(
          title: 'Leyendo ahora',
          subtitle: 'Tus lecturas activas',
          icon: Icons.auto_stories_rounded,
          books: reading,
        ),
        const SizedBox(height: 10),
        _listCollectionCard(
          title: 'Próximas lecturas',
          subtitle: 'Libros guardados para después',
          icon: Icons.bookmark_outline_rounded,
          books: pending,
        ),
      ],
    );
  }

  Widget _listCollectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<LibraryBook> books,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.merriweather(
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondaryOf(context),
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${books.length}',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (books.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return InkWell(
                    onTap: () => _openBookDetail(book),
                    borderRadius: BorderRadius.circular(8),
                    child: _cover(book.cover, 58, 84),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openBookDetail(LibraryBook book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _BookDetailScreen(
          book: book,
          status: widget.statuses[book.id],
          progress: widget.progresses[book.id] ?? 0,
          review: widget.reviews[book.id],
          isFavorite: widget.favorites.contains(book.id),
          onStatusChanged: (status) {
            widget.onStatusChanged(book.id, status);
            if (status == BookStatus.leido) {
              widget.onProgressChanged(book.id, 100);
            }
            setState(() {});
          },
          onProgressChanged: (progress) {
            widget.onProgressChanged(book.id, progress);
            if (progress >= 100) {
              widget.onStatusChanged(book.id, BookStatus.leido);
            }
            setState(() {});
          },
          onReviewSaved: (review) {
            widget.onReviewSaved(book.id, review);
            setState(() {});
          },
          onToggleFavorite: () {
            widget.onToggleFavorite(book.id);
            setState(() {});
          },
        ),
      ),
    );
  }

  void _openReviewEditor(LibraryBook book) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _ReviewDialog(
          initial: widget.reviews[book.id],
          bookTitle: book.title,
          onSave: (review) {
            widget.onReviewSaved(book.id, review);
            setState(() {});
          },
        );
      },
    );
  }

  Widget _cover(String url, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return Container(
              color: AppColors.deepOf(context),
              alignment: Alignment.center,
              child: const Icon(Icons.menu_book_rounded, color: AppColors.gold),
            );
          },
        ),
      ),
    );
  }
}

class _BookDetailScreen extends StatefulWidget {
  const _BookDetailScreen({
    required this.book,
    required this.status,
    required this.progress,
    required this.review,
    required this.isFavorite,
    required this.onStatusChanged,
    required this.onProgressChanged,
    required this.onReviewSaved,
    required this.onToggleFavorite,
  });

  final LibraryBook book;
  final BookStatus? status;
  final int progress;
  final BookReview? review;
  final bool isFavorite;
  final ValueChanged<BookStatus> onStatusChanged;
  final ValueChanged<int> onProgressChanged;
  final ValueChanged<BookReview> onReviewSaved;
  final VoidCallback onToggleFavorite;

  @override
  State<_BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<_BookDetailScreen> {
  late BookStatus? _status;
  late int _progress;
  late BookReview? _review;
  late bool _favorite;

  final List<Map<String, dynamic>> _comments = [
    {
      'user': '@niblai.y.libros',
      'text': 'La atmósfera es intensa y oscura; los personajes se sienten imperfectos y profundamente humanos.',
      'likes': 9,
      'liked': false,
    },
    {
      'user': '@lecturanotcturna',
      'text': 'Una novela compleja que deja mucho para debatir después de terminarla.',
      'likes': 20,
      'liked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _progress = widget.progress;
    _review = widget.review;
    _favorite = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            _buildTopBar(),
            _buildHero(book),
            _sectionTitle('SINOPSIS'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                book.synopsis,
                style: GoogleFonts.merriweather(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 10.5,
                  height: 1.7,
                ),
              ),
            ),
            _buildRatingStrip(),
            _sectionTitle('INFORMACIÓN DEL LIBRO'),
            _buildInfoCard(book),
            if (book.isFree) _buildReadFreeButton(),
            _sectionTitle('COMENTARIOS DE LA COMUNIDAD'),
            _buildComments(),
            _buildLibraryButton(),
            _sectionTitle('TU RESEÑA'),
            _buildReviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Volver atrás'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            color: AppColors.surfaceOf(context),
            onSelected: (value) async {
              if (value == 'share') {
                await Clipboard.setData(
                  ClipboardData(
                    text: '${widget.book.title} — ${widget.book.author}',
                  ),
                );
                if (!mounted) return;
                _message('Ficha copiada para compartir.');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'share', child: Text('Compartir')),
            ],
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.55),
                ),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                color: AppColors.textPrimaryOf(context),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(LibraryBook book) {
    return SizedBox(
      height: 205,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            book.cover,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                ColoredBox(color: AppColors.deepOf(context)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xE6381D14)],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 5,
                        children: [
                          _heroTag(book.genre.toUpperCase()),
                          if (book.isFree) _heroTag('▣ LIBRO'),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        book.title,
                        style: GoogleFonts.merriweather(
                          color: AppColors.background,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'por ${book.author}',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    widget.onToggleFavorite();
                    setState(() => _favorite = !_favorite);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC381D14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: AppColors.gold,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _favorite ? 'Favorito' : 'Favoritos',
                          style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xD6381D14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.65)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 6.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildRatingStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
          Text(
            ' 4.8',
            style: GoogleFonts.inter(
              color: AppColors.gold,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '125 reseñas',
            style: GoogleFonts.inter(
              color: AppColors.textSecondaryOf(context),
              fontSize: 7.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(LibraryBook book) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepOf(context).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoLine('Autor', book.author),
          _infoLine('Publicación', '${book.year}'),
          _infoLine('ISBN', book.isbn),
          _infoLine('Disponibilidad', book.isFree ? 'GRATIS' : 'Catálogo'),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
            color: AppColors.textSecondaryOf(context),
            fontSize: 8,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: GoogleFonts.inter(
                color: label == 'Disponibilidad'
                    ? const Color(0xFF3D7A45)
                    : AppColors.textPrimaryOf(context),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadFreeButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: SizedBox(
        width: double.infinity,
        height: 37,
        child: FilledButton(
          onPressed: _openFreeReader,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            backgroundColor: AppColors.deepAlt,
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B4B30), Color(0xFF4A2A1A)],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                '📖 Leer gratis',
                style: GoogleFonts.inter(
                  color: AppColors.background,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComments() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        children: List.generate(_comments.length, (index) {
          final comment = _comments[index];
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment['user'] as String,
                        style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondaryOf(context),
                      size: 15,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment['text'] as String,
                  style: GoogleFonts.merriweather(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 8.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          final liked = comment['liked'] as bool;
                          comment['liked'] = !liked;
                          comment['likes'] =
                              (comment['likes'] as int) + (liked ? -1 : 1);
                        });
                      },
                      child: Text(
                        '${comment['liked'] == true ? '♥' : '♡'} ${comment['likes']} Me gusta',
                        style: GoogleFonts.inter(
                          color: comment['liked'] == true
                              ? AppColors.accent
                              : AppColors.textSecondaryOf(context),
                          fontSize: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    InkWell(
                      onTap: () => _replyTo(comment['user'] as String),
                      child: Text(
                        'Responder',
                        style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLibraryButton() {
    String label;

    if (_status == null) {
      label = 'Añadir a mi biblioteca';
    } else if (_status == BookStatus.leido) {
      label = '✓ Libro finalizado';
    } else if (_status == BookStatus.leyendo) {
      label = 'Leyendo · $_progress%';
    } else {
      label = '✓ Añadido a mi biblioteca';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: SizedBox(
        width: double.infinity,
        height: 38,
        child: FilledButton(
          onPressed: () {
            if (_status == null) {
              widget.onStatusChanged(BookStatus.porLeer);
              setState(() => _status = BookStatus.porLeer);
              _message('Libro añadido a Mi Biblioteca.');
              return;
            }

            if (_status == BookStatus.porLeer) {
              widget.onStatusChanged(BookStatus.leyendo);
              widget.onProgressChanged(0);
              setState(() {
                _status = BookStatus.leyendo;
                _progress = 0;
              });
              return;
            }

            if (_status == BookStatus.leyendo) {
              widget.onProgressChanged(100);
              widget.onStatusChanged(BookStatus.leido);
              setState(() {
                _status = BookStatus.leido;
                _progress = 100;
              });
              return;
            }

            _message('Este libro ya está registrado como leído.');
          },
          style: FilledButton.styleFrom(
            backgroundColor: _status == BookStatus.leido
                ? AppColors.gold
                : AppColors.accent,
            foregroundColor: _status == BookStatus.leido
                ? AppColors.deepOf(context)
                : AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      child: _review == null
          ? SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed: _openReviewEditor,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimaryOf(context),
                  side: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.55),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  '★ Calificar y reseñar',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < _review!.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.gold,
                          size: 14,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _openReviewEditor,
                        child: Text(
                          'Editar',
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '“${_review!.text}”',
                    style: GoogleFonts.merriweather(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _review!.isPublic ? '🌐 Pública' : '🔒 Privada',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 9),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.cinzel(
              color: AppColors.textPrimaryOf(context),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.6),
                    AppColors.gold.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openReviewEditor() {
    showDialog<void>(
      context: context,
      builder: (_) => _ReviewDialog(
        initial: _review,
        bookTitle: widget.book.title,
        onSave: (review) {
          widget.onReviewSaved(review);
          setState(() => _review = review);
        },
      ),
    );
  }

  void _openFreeReader() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.book.title,
                  style: GoogleFonts.cinzel(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Lectura gratuita · muestra',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 8.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Capítulo 1\n\n'
                  'La tarde caía lentamente sobre las páginas abiertas. Cada frase parecía guardar una voz antigua, '
                  'como si el libro hubiese esperado exactamente este momento para ser leído.\n\n'
                  'La habitación quedó en silencio y, por unos minutos, todo lo que existía era la historia.',
                  style: GoogleFonts.merriweather(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 12,
                    height: 1.9,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    if (_status == null || _status == BookStatus.porLeer) {
                      widget.onStatusChanged(BookStatus.leyendo);
                      widget.onProgressChanged(_progress == 0 ? 5 : _progress);
                      setState(() {
                        _status = BookStatus.leyendo;
                        _progress = _progress == 0 ? 5 : _progress;
                      });
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Guardar progreso y cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _replyTo(String user) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundOf(context),
          title: Text(
            'Responder a $user',
            style: GoogleFonts.cinzel(
              color: AppColors.textPrimaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Escribe tu respuesta...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _message('Respuesta publicada.');
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Publicar'),
            ),
          ],
        );
      },
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
      );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({
    required this.initial,
    required this.bookTitle,
    required this.onSave,
  });

  final BookReview? initial;
  final String bookTitle;
  final ValueChanged<BookReview> onSave;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late int _rating;
  late bool _isPublic;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _rating = widget.initial?.rating ?? 5;
    _isPublic = widget.initial?.isPublic ?? true;
    _controller = TextEditingController(text: widget.initial?.text ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Calificar y reseñar',
        style: GoogleFonts.cinzel(
          color: AppColors.textPrimaryOf(context),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookTitle,
              style: GoogleFonts.merriweather(
                color: AppColors.textPrimaryOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = value),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  icon: Icon(
                    value <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.gold,
                    size: 27,
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 5,
              style: GoogleFonts.inter(fontSize: 10),
              decoration: InputDecoration(
                hintText: '¿Qué te pareció este libro?',
                filled: true,
                fillColor: AppColors.surfaceOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Reseña pública',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                _isPublic
                    ? 'Visible para la comunidad'
                    : 'Solo visible para ti',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 7.5,
                ),
              ),
              value: _isPublic,
              activeTrackColor: AppColors.gold,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            widget.onSave(
              BookReview(rating: _rating, text: text, isPublic: _isPublic),
            );
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Guardar reseña'),
        ),
      ],
    );
  }
}
