import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/book_interaction_store.dart';

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


class _PersonalLibraryList {
  const _PersonalLibraryList({
    required this.name,
    required this.description,
    required this.emoji,
    this.bookIds = const <int>[],
  });

  final String name;
  final String description;
  final String emoji;
  final List<int> bookIds;

  _PersonalLibraryList copyWith({
    String? name,
    String? description,
    String? emoji,
    List<int>? bookIds,
  }) {
    return _PersonalLibraryList(
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      bookIds: bookIds ?? this.bookIds,
    );
  }
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
    required this.currentUsername,
    required this.onOpenProfile,
    required this.onStatusChanged,
    required this.onProgressChanged,
    required this.onReviewSaved,
    required this.onToggleFavorite,
    this.isGuest = false,
    this.onGuestRestrictedAction,
  });

  final List<LibraryBook> books;
  final Map<int, BookStatus> statuses;
  final Map<int, int> progresses;
  final Map<int, BookReview> reviews;
  final Set<int> favorites;
  final String currentName;
  final String currentUsername;
  final VoidCallback onOpenProfile;

  final void Function(int bookId, BookStatus status) onStatusChanged;
  final void Function(int bookId, int progress) onProgressChanged;
  final void Function(int bookId, BookReview review) onReviewSaved;
  final void Function(int bookId) onToggleFavorite;
  final bool isGuest;
  final VoidCallback? onGuestRestrictedAction;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _blockGuestAction() {
    if (!widget.isGuest) return false;
    widget.onGuestRestrictedAction?.call();
    return true;
  }

  final TextEditingController _searchController = TextEditingController();

  String _view = 'libros';
  String _filter = 'leyendo';
  String _query = '';
  bool _showFinishSuccess = false;

  final List<_PersonalLibraryList> _personalLists = <_PersonalLibraryList>[];

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

    result = result.where((book) {
      final status = widget.statuses[book.id];
      if (_filter == 'leyendo') return status == BookStatus.leyendo;
      if (_filter == 'porLeer') return status == BookStatus.porLeer;
      if (_filter == 'leidos') return status == BookStatus.leido;
      return false;
    }).toList();

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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _showFinishSuccess
                    ? Padding(
                        key: const ValueKey('finish-success'),
                        padding: const EdgeInsets.only(top: 10),
                        child: _buildFinishSuccessMessage(),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('finish-success-empty'),
                      ),
              ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _showLibraryOptions,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.55),
              ),
            ),
            child: Icon(
              Icons.more_vert_rounded,
              size: 19,
              color: AppColors.textPrimaryOf(context),
            ),
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
          child: _statusCounterCard(
            id: 'leyendo',
            label: 'Leyendo',
            count: _count(BookStatus.leyendo),
            activeColor: AppColors.accentOf(context),
            activeForeground: AppColors.backgroundOf(context),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _statusCounterCard(
            id: 'porLeer',
            label: 'Por leer',
            count: _count(BookStatus.porLeer),
            activeColor: AppColors.goldOf(context),
            activeForeground: AppColors.deepOf(context),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _statusCounterCard(
            id: 'leidos',
            label: 'Leídos',
            count: _count(BookStatus.leido),
            activeColor: AppColors.deepOf(context),
            activeForeground: AppColors.goldOf(context),
          ),
        ),
      ],
    );
  }

  Widget _statusCounterCard({
    required String id,
    required String label,
    required int count,
    required Color activeColor,
    required Color activeForeground,
  }) {
    final active = _filter == id;

    return InkWell(
      onTap: () {
        if (_filter == id) return;

        setState(() {
          _filter = id;
        });
      },
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? activeColor
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: active
                ? activeColor
                : activeColor.withValues(alpha: 0.72),
            width: active ? 1.4 : 1.05,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          style: GoogleFonts.inter(
            color: active
                ? activeForeground
                : activeColor,
            fontWeight: FontWeight.w800,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                scale: active ? 1.08 : 1,
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    color: active
                        ? activeForeground
                        : activeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: active
                      ? activeForeground
                      : AppColors.textSecondaryOf(context),
                  fontSize: 7.5,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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

                setState(() {
                  _showFinishSuccess = true;
                });

                Future<void>.delayed(
                  const Duration(milliseconds: 2500),
                  () {
                    if (!mounted) return;

                    setState(() {
                      _showFinishSuccess = false;
                    });
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return _reviewLibraryButton(
      hasReview: review != null,
      onTap: () => _openReviewEditor(book),
    );
  }

  Widget _reviewLibraryButton({
    required bool hasReview,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: hasReview
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(
                Icons.rate_review_outlined,
                size: 13,
              ),
              label: Text(
                'Ver / editar reseña',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentOf(context),
                backgroundColor:
                    AppColors.accentOf(context).withValues(alpha: 0.05),
                side: BorderSide(
                  color: AppColors.accentOf(context)
                      .withValues(alpha: 0.45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(
                Icons.star_outline_rounded,
                size: 14,
              ),
              label: Text(
                'Calificar y reseñar',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepOf(context),
                foregroundColor: AppColors.goldOf(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
    );
  }

  Widget _buildFinishSuccessMessage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF283125)
            : const Color(0xFFF4F7EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF78935F).withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF708A56),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Libro finalizado correctamente',
              style: GoogleFonts.merriweather(
                color: isDark
                    ? const Color(0xFFE7EEDC)
                    : const Color(0xFF3F4F33),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.auto_stories_rounded,
            color: AppColors.gold.withValues(alpha: 0.76),
            size: 20,
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MIS LISTAS PERSONALES',
          style: GoogleFonts.cinzel(
            color: AppColors.textPrimaryOf(context),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        if (_personalLists.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.library_add_outlined,
                  color: AppColors.goldOf(context),
                  size: 26,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aún no has creado listas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.merriweather(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Crea una lista personal para organizar tus libros como quieras.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 7.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: _showCreateListSheet,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepOf(context),
                      foregroundColor: AppColors.goldOf(context),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.add_box_outlined,
                      size: 16,
                    ),
                    label: Text(
                      'Crear lista',
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ..._personalLists.map(
            (list) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _personalListCard(list),
            ),
          ),
      ],
    );
  }

  Widget _personalListCard(_PersonalLibraryList list) {
    final index = _personalLists.indexOf(list);

    return InkWell(
      onTap: () => _showPersonalListDetail(index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.40),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                list.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.merriweather(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (list.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      list.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondaryOf(context),
                        fontSize: 7.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${list.bookIds.length}',
              style: GoogleFonts.inter(
                color: AppColors.accentOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _showPersonalListMiniMenu(index),
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPersonalListMiniMenu(int index) async {
    final list = _personalLists[index];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 9, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.backgroundOf(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.32),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.deepOf(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      list.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.merriweather(
                          color: AppColors.textPrimaryOf(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _libraryOptionTile(
                  icon: Icons.playlist_add_rounded,
                  title: 'Agregar libro',
                  highlighted: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Future<void>.delayed(
                      const Duration(milliseconds: 160),
                      () => _showAddBookToListSheet(index),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _libraryOptionTile(
                  icon: Icons.edit_outlined,
                  title: 'Editar lista',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Future<void>.delayed(
                      const Duration(milliseconds: 160),
                      () => _showEditListSheet(index),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddBookToListSheet(int index) async {
    final originalList = _personalLists[index];
    final selectedBookIds = <int>{...originalList.bookIds};
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final availableBooks = _booksInLibrary.where((book) {
              final status = widget.statuses[book.id];
              final validStatus =
                  status == BookStatus.leyendo ||
                  status == BookStatus.porLeer;

              return validStatus && !selectedBookIds.contains(book.id);
            }).toList();

            final selectedBooks = _booksInLibrary.where((book) {
              return selectedBookIds.contains(book.id);
            }).toList();

            final hasChanges =
                !Set<int>.from(originalList.bookIds)
                    .containsAll(selectedBookIds) ||
                !selectedBookIds.containsAll(originalList.bookIds);
            final canSave = hasChanges && !isSaving;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.58,
              maxChildSize: 0.94,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOf(context),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 9, 18, 24),
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.deepOf(context),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.goldOf(context)
                                    .withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Text(
                                originalList.emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AGREGAR LIBROS',
                                    style: GoogleFonts.cinzel(
                                      color: AppColors.textPrimaryOf(context),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    originalList.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.merriweather(
                                      color: AppColors.textPrimaryOf(context),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 34,
                              child: FilledButton.icon(
                                onPressed: canSave
                                    ? () async {
                                        setSheetState(() {
                                          isSaving = true;
                                        });

                                        await Future<void>.delayed(
                                          const Duration(milliseconds: 1000),
                                        );

                                        if (!sheetContext.mounted) return;

                                        setState(() {
                                          _personalLists[index] =
                                              _personalLists[index].copyWith(
                                            bookIds: selectedBookIds.toList(),
                                          );
                                        });

                                        Navigator.of(sheetContext).pop();

                                        final isDark =
                                            Theme.of(context).brightness ==
                                                Brightness.dark;

                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin:
                                                  const EdgeInsets.fromLTRB(
                                                16,
                                                0,
                                                16,
                                                18,
                                              ),
                                              duration: const Duration(
                                                milliseconds: 2500,
                                              ),
                                              padding: EdgeInsets.zero,
                                              content: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 13,
                                                  vertical: 11,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF283125)
                                                      : const Color(0xFFF4F7EE),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFF78935F)
                                                            .withValues(
                                                      alpha: 0.72,
                                                    ),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                        alpha: 0.08,
                                                      ),
                                                      blurRadius: 12,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 34,
                                                      height: 34,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color:
                                                            Color(0xFF708A56),
                                                        shape:
                                                            BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.check_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 11),
                                                    Expanded(
                                                      child: Text(
                                                        selectedBookIds.isEmpty
                                                            ? 'Guardado correctamente'
                                                            : 'Libros guardados correctamente a ${originalList.name}',
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: GoogleFonts
                                                            .merriweather(
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFFE7EEDC,
                                                                )
                                                              : const Color(
                                                                  0xFF3F4F33,
                                                                ),
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons
                                                          .playlist_add_check_rounded,
                                                      color: AppColors.gold
                                                          .withValues(
                                                        alpha: 0.76,
                                                      ),
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                      }
                                    : null,
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.8,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.save_outlined,
                                        size: 14,
                                      ),
                                label: Text(
                                  isSaving ? 'Guardando...' : 'Guardar',
                                  style: GoogleFonts.inter(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      AppColors.deepOf(context),
                                  disabledBackgroundColor: isSaving
                                      ? Colors.grey.shade600
                                      : AppColors.deepOf(context)
                                          .withValues(alpha: 0.22),
                                  foregroundColor:
                                      AppColors.backgroundOf(context),
                                  disabledForegroundColor: isSaving
                                      ? Colors.white
                                      : AppColors.textSecondaryOf(context),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selecciona libros que ya estén en tu biblioteca con estado Leyendo o Por leer.',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 8,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          'LIBROS DISPONIBLES',
                          style: GoogleFonts.cinzel(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 9.4,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.35,
                          ),
                        ),
                        const SizedBox(height: 9),

                        if (availableBooks.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 22,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceOf(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.gold
                                    .withValues(alpha: 0.30),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.library_books_outlined,
                                  size: 26,
                                  color: AppColors.goldOf(context),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No hay más libros disponibles',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.merriweather(
                                    color:
                                        AppColors.textPrimaryOf(context),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Todos los libros disponibles ya están agregados o no están en Leyendo / Por leer.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color:
                                        AppColors.textSecondaryOf(context),
                                    fontSize: 7.4,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...availableBooks.map((book) {
                            final status = widget.statuses[book.id];
                            final statusLabel =
                                status == BookStatus.leyendo
                                    ? 'LEYENDO'
                                    : 'POR LEER';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceOf(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.gold
                                        .withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _cover(book.cover, 46, 64),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.title,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: GoogleFonts.merriweather(
                                              color:
                                                  AppColors.textPrimaryOf(
                                                context,
                                              ),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              height: 1.35,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            book.author,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color:
                                                  AppColors.textSecondaryOf(
                                                context,
                                              ),
                                              fontSize: 7.2,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  status ==
                                                          BookStatus.leyendo
                                                      ? AppColors.accentOf(
                                                          context,
                                                        ).withValues(
                                                          alpha: 0.10,
                                                        )
                                                      : AppColors.goldOf(
                                                          context,
                                                        ).withValues(
                                                          alpha: 0.10,
                                                        ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: GoogleFonts.inter(
                                                color:
                                                    status ==
                                                            BookStatus.leyendo
                                                        ? AppColors.accentOf(
                                                            context,
                                                          )
                                                        : AppColors.goldOf(
                                                            context,
                                                          ),
                                                fontSize: 5.8,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.25,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed: isSaving
                                          ? null
                                          : () {
                                        setSheetState(() {
                                          selectedBookIds.add(book.id);
                                        });
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            AppColors.deepOf(context),
                                        foregroundColor:
                                            AppColors.backgroundOf(context),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                      ),
                                      child: Text(
                                        'Agregar',
                                        style: GoogleFonts.inter(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              'LIBROS AGREGADOS',
                              style: GoogleFonts.cinzel(
                                color:
                                    AppColors.textPrimaryOf(context),
                                fontSize: 9.4,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.35,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentOf(context)
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${selectedBooks.length}',
                                style: GoogleFonts.inter(
                                  color: AppColors.accentOf(context),
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),

                        if (selectedBooks.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 22,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceOf(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.gold
                                    .withValues(alpha: 0.24),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.playlist_add_rounded,
                                  size: 26,
                                  color: AppColors.goldOf(context),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Aún no agregas libros',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.merriweather(
                                    color:
                                        AppColors.textPrimaryOf(context),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Los libros que selecciones aparecerán en esta sección antes de guardar.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color:
                                        AppColors.textSecondaryOf(context),
                                    fontSize: 7.4,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...selectedBooks.map((book) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceOf(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.accentOf(context)
                                        .withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _cover(book.cover, 46, 64),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.title,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: GoogleFonts.merriweather(
                                              color:
                                                  AppColors.textPrimaryOf(
                                                context,
                                              ),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            book.author,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color:
                                                  AppColors.textSecondaryOf(
                                                context,
                                              ),
                                              fontSize: 7.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: isSaving
                                          ? null
                                          : () {
                                        setSheetState(() {
                                          selectedBookIds.remove(book.id);
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                        size: 13,
                                      ),
                                      label: Text(
                                        'Quitar',
                                        style: GoogleFonts.inter(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.accentOf(context),
                                        side: BorderSide(
                                          color: AppColors.accentOf(context)
                                              .withValues(alpha: 0.42),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showEditListSheet(int index) async {
    final list = _personalLists[index];
    final nameController = TextEditingController(text: list.name);
    final descriptionController =
        TextEditingController(text: list.description);

    var selectedEmoji = list.emoji;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canSave = nameController.text.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 9, 18, 20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundOf(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.deepOf(context),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'EDITAR LISTA',
                          style: GoogleFonts.cinzel(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _createListLabel('Ícono de la lista *'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 58,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.deepOf(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                selectedEmoji,
                                style: const TextStyle(fontSize: 23),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final emoji =
                                      await _showEmojiPicker(selectedEmoji);

                                  if (emoji == null ||
                                      !sheetContext.mounted) {
                                    return;
                                  }

                                  setSheetState(() {
                                    selectedEmoji = emoji;
                                  });
                                },
                                borderRadius: BorderRadius.circular(11),
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceOf(context),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Más emojis',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimaryOf(context),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _createListLabel('Nombre de la lista *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          maxLength: 50,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: _createListInputDecoration(
                            hint: 'Nombre de la lista',
                            icon: Icons.menu_book_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: 13),
                        _createListLabel('Descripción (opcional)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descriptionController,
                          minLines: 3,
                          maxLines: 4,
                          maxLength: 180,
                          decoration: _createListInputDecoration(
                            hint: 'Descripción de tu lista...',
                            icon: Icons.description_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: 17),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: FilledButton(
                            onPressed: canSave
                                ? () {
                                    setState(() {
                                      _personalLists[index] =
                                          list.copyWith(
                                        name: nameController.text.trim(),
                                        description:
                                            descriptionController.text.trim(),
                                        emoji: selectedEmoji,
                                      );
                                    });

                                    Navigator.of(sheetContext).pop();
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppColors.deepOf(context),
                              foregroundColor:
                                  AppColors.backgroundOf(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: Text(
                              'Guardar cambios',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));
    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showPersonalListDetail(int index) async {
    if (_blockGuestAction()) return;
    final list = _personalLists[index];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.50,
          maxChildSize: 0.90,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundOf(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 9, 18, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.deepOf(context),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            list.emoji,
                            style: const TextStyle(fontSize: 25),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                list.name,
                                style: GoogleFonts.cinzel(
                                  color: AppColors.textPrimaryOf(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (list.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  list.description,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondaryOf(context),
                                    fontSize: 8.5,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'LIBROS AGREGADOS',
                          style: GoogleFonts.cinzel(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.35,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${list.bookIds.length}',
                          style: GoogleFonts.inter(
                            color: AppColors.accentOf(context),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (list.bookIds.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              color: AppColors.goldOf(context),
                              size: 28,
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Aún no hay libros agregados',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.merriweather(
                                color: AppColors.textPrimaryOf(context),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Acá aparecerán los libros que agregues a tu lista personal.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondaryOf(context),
                                fontSize: 7.8,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...list.bookIds.map((bookId) {
                        LibraryBook? book;

                        for (final candidate in widget.books) {
                          if (candidate.id == bookId) {
                            book = candidate;
                            break;
                          }
                        }

                        if (book == null) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceOf(context),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color:
                                    AppColors.gold.withValues(alpha: 0.26),
                              ),
                            ),
                            child: Row(
                              children: [
                                _cover(book.cover, 40, 56),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.merriweather(
                                          color:
                                              AppColors.textPrimaryOf(context),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        book.author,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: AppColors
                                              .textSecondaryOf(context),
                                          fontSize: 7,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showLibraryOptions() async {
    if (_blockGuestAction()) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 9, 18, 22),
              decoration: BoxDecoration(
                color: AppColors.backgroundOf(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.deepOf(context),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'OPCIONES DE BIBLIOTECA',
                            style: GoogleFonts.cinzel(
                              color: AppColors.textPrimaryOf(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Text(
                          '✦',
                          style: TextStyle(
                            color: AppColors.goldOf(context),
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _libraryOptionTile(
                      icon: Icons.add_box_outlined,
                      title: 'Crear lista',
                      highlighted: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Future<void>.delayed(
                          const Duration(milliseconds: 180),
                          _showCreateListSheet,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _libraryOptionTile(
                      icon: Icons.download_outlined,
                      title: 'Exportar mi biblioteca',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Future<void>.delayed(
                          const Duration(milliseconds: 160),
                          _showExportLibraryDialog,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _libraryOptionTile(
                      icon: Icons.ios_share_outlined,
                      title: 'Exportar mi lista',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Future<void>.delayed(
                          const Duration(milliseconds: 160),
                          _showExportListDialog,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _libraryOptionTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.goldOf(context).withValues(alpha: 0.14)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.goldOf(context).withValues(
              alpha: highlighted ? 0.70 : 0.42,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.deepOf(context),
              size: 20,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconTheme(
              data: IconThemeData(
                color: AppColors.textPrimaryOf(context),
                size: 20,
              ),
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExportLibraryDialog() async {
    if (_blockGuestAction()) return;
    final total = _booksInLibrary.length;
    final reading = _count(BookStatus.leyendo);
    final pending = _count(BookStatus.porLeer);
    final read = _count(BookStatus.leido);

    await _showLibraryShareDialog(
      barrierLabel: 'Exportar biblioteca',
      eyebrow: 'EXPORTAR MI BIBLIOTECA',
      title: '¿Dónde deseas compartir?',
      summaryTitle: 'Se exportarán estos libros:',
      summaryMain:
          '$total ${total == 1 ? 'libro en tu biblioteca' : 'libros en tu biblioteca'}',
      summaryDetail:
          '$read leídos · $reading leyendo · $pending por leer',
      linkText:
          'Capítulo 0 · Mi biblioteca · $total libros · $read leídos · $reading leyendo · $pending por leer',
    );
  }

  Future<void> _showExportListDialog() async {
    if (_blockGuestAction()) return;
    if (_personalLists.isEmpty) {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Sin listas personales',
        barrierColor: Colors.black.withValues(alpha: 0.62),
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return SafeArea(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(dialogContext).size.width * 0.80,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: AppColors.goldOf(context)
                          .withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.playlist_add_rounded,
                        color: AppColors.goldOf(context),
                        size: 28,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'NO HAY LISTAS PARA EXPORTAR',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          color: AppColors.textPrimaryOf(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Crea una lista personal y luego podrás compartirla desde aquí.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondaryOf(context),
                          fontSize: 8,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.deepOf(context),
                            foregroundColor:
                                AppColors.backgroundOf(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Entendido',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      );
      return;
    }

    int? selectedIndex;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Exportar lista',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  final selected = selectedIndex == null
                      ? null
                      : _personalLists[selectedIndex!];

                  return Container(
                    width:
                        MediaQuery.of(dialogContext).size.width * 0.84,
                    constraints: BoxConstraints(
                      maxWidth: 380,
                      maxHeight:
                          MediaQuery.of(dialogContext).size.height * 0.78,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: AppColors.goldOf(context)
                            .withValues(alpha: 0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'EXPORTAR MI LISTA',
                                      style: GoogleFonts.cinzel(
                                        color:
                                            AppColors.accentOf(context),
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.65,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '¿Qué lista deseas exportar?',
                                      style: GoogleFonts.merriweather(
                                        color:
                                            AppColors.textPrimaryOf(context),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _exportCloseButton(dialogContext),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...List.generate(
                            _personalLists.length,
                            (index) {
                              final list = _personalLists[index];
                              final active = selectedIndex == index;

                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedIndex = index;
                                    });
                                  },
                                  borderRadius:
                                      BorderRadius.circular(11),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.goldOf(context)
                                              .withValues(alpha: 0.18)
                                          : AppColors.backgroundOf(context),
                                      borderRadius:
                                          BorderRadius.circular(11),
                                      border: Border.all(
                                        color: active
                                            ? AppColors.goldOf(context)
                                            : AppColors.goldOf(context)
                                                .withValues(alpha: 0.30),
                                        width: active ? 1.3 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: active
                                                ? AppColors.deepOf(context)
                                                : AppColors.goldOf(context)
                                                    .withValues(alpha: 0.10),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            list.emoji,
                                            style: const TextStyle(
                                              fontSize: 19,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                list.name,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    GoogleFonts.merriweather(
                                                  color: AppColors
                                                      .textPrimaryOf(
                                                    context,
                                                  ),
                                                  fontSize: 9.5,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${list.bookIds.length} ${list.bookIds.length == 1 ? 'libro' : 'libros'}',
                                                style: GoogleFonts.inter(
                                                  color: AppColors
                                                      .textSecondaryOf(
                                                    context,
                                                  ),
                                                  fontSize: 7.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 160,
                                          ),
                                          child: active
                                              ? Icon(
                                                  Icons
                                                      .check_circle_rounded,
                                                  key: const ValueKey(
                                                    'selected',
                                                  ),
                                                  color: AppColors
                                                      .goldOf(context),
                                                  size: 19,
                                                )
                                              : Icon(
                                                  Icons.circle_outlined,
                                                  key: const ValueKey(
                                                    'unselected',
                                                  ),
                                                  color: AppColors
                                                      .textSecondaryOf(
                                                    context,
                                                  ),
                                                  size: 18,
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedSize(
                            duration:
                                const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            child: selected == null
                                ? const SizedBox.shrink()
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 7),
                                      Divider(
                                        color: AppColors.goldOf(context)
                                            .withValues(alpha: 0.24),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'LISTA SELECCIONADA',
                                        style: GoogleFonts.cinzel(
                                          color: AppColors
                                              .accentOf(context),
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.55,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${selected.emoji} ${selected.name}',
                                        style: GoogleFonts.merriweather(
                                          color: AppColors
                                              .textPrimaryOf(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${selected.bookIds.length} ${selected.bookIds.length == 1 ? 'libro agregado' : 'libros agregados'}',
                                        style: GoogleFonts.inter(
                                          color: AppColors
                                              .textSecondaryOf(context),
                                          fontSize: 7.5,
                                        ),
                                      ),
                                      const SizedBox(height: 13),
                                      Text(
                                        '¿Dónde deseas compartir?',
                                        style: GoogleFonts.merriweather(
                                          color: AppColors
                                              .textPrimaryOf(context),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                      _exportShareGrid(
                                        dialogContext:
                                            dialogContext,
                                        linkText:
                                            'Capítulo 0 · Lista ${selected.name} · ${selected.bookIds.length} libros',
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showLibraryShareDialog({
    required String barrierLabel,
    required String eyebrow,
    required String title,
    required String summaryTitle,
    required String summaryMain,
    required String summaryDetail,
    required String linkText,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.80,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.goldOf(context)
                        .withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                eyebrow,
                                style: GoogleFonts.cinzel(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.65,
                                  color: AppColors.accentOf(context),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                title,
                                style: GoogleFonts.merriweather(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppColors.textPrimaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _exportCloseButton(dialogContext),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: AppColors.goldOf(context)
                              .withValues(alpha: 0.28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summaryTitle,
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.textSecondaryOf(context),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summaryMain,
                            style: GoogleFonts.merriweather(
                              color:
                                  AppColors.textPrimaryOf(context),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            summaryDetail,
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.textSecondaryOf(context),
                              fontSize: 7.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _exportShareGrid(
                      dialogContext: dialogContext,
                      linkText: linkText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _exportCloseButton(BuildContext dialogContext) {
    return InkWell(
      onTap: () => Navigator.of(dialogContext).pop(),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color:
                AppColors.goldOf(context).withValues(alpha: 0.38),
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 15,
          color: AppColors.textSecondaryOf(context),
        ),
      ),
    );
  }

  Widget _exportShareGrid({
    required BuildContext dialogContext,
    required String linkText,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _exportShareOption(
                label: 'W · WhatsApp',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _exportShareOption(
                label: 'I · Instagram',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _exportShareOption(
                label: 'X · X',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _exportShareOption(
                label: '↗ · Enlace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _exportShareOption({
    required String label,
  }) {
    return InkWell(
      onTap: null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                AppColors.goldOf(context).withValues(alpha: 0.34),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 7.4,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateListSheet() async {
    if (_blockGuestAction()) return;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    var selectedEmoji = '♥';
    var isCreating = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canCreate =
                nameController.text.trim().isNotEmpty && !isCreating;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 9, 18, 20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundOf(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.deepOf(context),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'CREAR NUEVA LISTA',
                                style: GoogleFonts.cinzel(
                                  color: AppColors.textPrimaryOf(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '✦',
                              style: TextStyle(
                                color: AppColors.goldOf(context),
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ícono de la lista *',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 58,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.deepOf(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.goldOf(context)
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                selectedEmoji,
                                style: const TextStyle(fontSize: 23),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: isCreating
                                    ? null
                                    : () async {
                                  final emoji =
                                      await _showEmojiPicker(selectedEmoji);

                                  if (emoji == null ||
                                      !sheetContext.mounted) {
                                    return;
                                  }

                                  setSheetState(() {
                                    selectedEmoji = emoji;
                                  });
                                },
                                borderRadius: BorderRadius.circular(11),
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceOf(context),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.emoji_emotions_outlined,
                                        size: 16,
                                        color: AppColors.goldOf(context),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Más emojis',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textPrimaryOf(context),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _createListLabel('Nombre de la lista *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          enabled: !isCreating,
                          maxLength: 50,
                          onChanged: (_) => setSheetState(() {}),
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 9.5,
                          ),
                          decoration: _createListInputDecoration(
                            hint: 'Ej: Clásicos, Lecturas 2026...',
                            icon: Icons.menu_book_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: 13),
                        _createListLabel('Descripción (opcional)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descriptionController,
                          enabled: !isCreating,
                          minLines: 3,
                          maxLines: 4,
                          maxLength: 180,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 9,
                            height: 1.4,
                          ),
                          decoration: _createListInputDecoration(
                            hint: 'Cuéntanos de qué trata esta lista...',
                            icon: Icons.description_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: 17),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: OutlinedButton(
                                  onPressed: isCreating
                                      ? null
                                      : () =>
                                          Navigator.of(sheetContext).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        AppColors.textPrimaryOf(context),
                                    side: BorderSide(
                                      color: AppColors.goldOf(context),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: FilledButton(
                                  onPressed: canCreate
                                      ? () async {
                                          FocusScope.of(context).unfocus();

                                          setSheetState(() {
                                            isCreating = true;
                                          });

                                          await Future<void>.delayed(
                                            const Duration(milliseconds: 1000),
                                          );

                                          if (!sheetContext.mounted) return;

                                          final list = _PersonalLibraryList(
                                            name: nameController.text.trim(),
                                            description: descriptionController
                                                .text
                                                .trim(),
                                            emoji: selectedEmoji,
                                          );

                                          setState(() {
                                            _personalLists.add(list);
                                            _view = 'listas';
                                          });

                                          Navigator.of(sheetContext).pop();
                                        }
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        AppColors.deepOf(context),
                                    disabledBackgroundColor: isCreating
                                        ? Colors.grey.shade600
                                        : AppColors.deepOf(context)
                                            .withValues(alpha: 0.30),
                                    foregroundColor:
                                        AppColors.backgroundOf(context),
                                    disabledForegroundColor:
                                        AppColors.backgroundOf(context)
                                            .withValues(alpha: 0.88),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                  child: isCreating
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 13,
                                              height: 13,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 1.8,
                                                color: AppColors
                                                    .backgroundOf(context),
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                            Text(
                                              'Creando lista...',
                                              style: GoogleFonts.inter(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Crear lista',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));
    nameController.dispose();
    descriptionController.dispose();
  }

  Widget _createListLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textPrimaryOf(context),
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _createListInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: AppColors.textSecondaryOf(context),
        fontSize: 8.5,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.deepOf(context),
        size: 18,
      ),
      filled: true,
      fillColor: AppColors.surfaceOf(context),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: AppColors.gold.withValues(alpha: 0.50),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: AppColors.goldOf(context),
          width: 1.4,
        ),
      ),
    );
  }

  Future<String?> _showEmojiPicker(String selectedEmoji) async {
    const emojis = <String>[
      '♥',
      '📖',
      '🔖',
      '☆',
      '✦',
      '📚',
      '☕',
      '🎧',
      '🎬',
      '🍃',
      '☾',
      '☀',
      '🌸',
      '⛰',
      '🔥',
    ];

    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.backgroundOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Seleccionar emoji',
                        style: GoogleFonts.merriweather(
                          color: AppColors.textPrimaryOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: emojis.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 7,
                    crossAxisSpacing: 7,
                  ),
                  itemBuilder: (context, index) {
                    final emoji = emojis[index];
                    final active = emoji == selectedEmoji;

                    return InkWell(
                      onTap: () =>
                          Navigator.of(dialogContext).pop(emoji),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.goldOf(context)
                                  .withValues(alpha: 0.22)
                              : AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active
                                ? AppColors.goldOf(context)
                                : AppColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openBookDetail(LibraryBook book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LibraryUniversalBookDetailScreen(
          book: book,
          currentUsername: widget.currentUsername,
          initialReview: widget.reviews[book.id],
          initiallyFavorite: widget.favorites.contains(book.id),
          status: widget.statuses[book.id],
          progress: widget.progresses[book.id] ?? 0,
          onReviewSaved: (review) {
            widget.onReviewSaved(book.id, review);
            setState(() {});
          },
          onToggleFavorite: () {
            widget.onToggleFavorite(book.id);
            setState(() {});
          },
          onOpenOwnProfile: widget.onOpenProfile,
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

class _LibraryUniversalBookDetailScreen extends StatefulWidget {
  const _LibraryUniversalBookDetailScreen({
    required this.book,
    required this.currentUsername,
    required this.initialReview,
    required this.initiallyFavorite,
    required this.status,
    required this.progress,
    required this.onReviewSaved,
    required this.onToggleFavorite,
    required this.onOpenOwnProfile,
    required this.onStatusChanged,
    required this.onProgressChanged,
  });

  final LibraryBook book;
  final String currentUsername;
  final BookReview? initialReview;
  final bool initiallyFavorite;
  final BookStatus? status;
  final int progress;

  final ValueChanged<BookReview> onReviewSaved;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenOwnProfile;
  final ValueChanged<BookStatus> onStatusChanged;
  final ValueChanged<int> onProgressChanged;

  @override
  State<_LibraryUniversalBookDetailScreen> createState() =>
      _LibraryUniversalBookDetailScreenState();
}

class _LibraryUniversalBookDetailScreenState extends State<_LibraryUniversalBookDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  late final List<TextEditingController> _replyControllers;
  final TextEditingController _reviewController = TextEditingController();

  bool _compactHeader = false;
  bool _favorite = false;

  late BookStatus? _status;
  late int _progress;

  bool _hasReview = false;
  bool _reviewEditorOpen = false;
  bool _reviewIsPublic = true;
  bool _draftReviewIsPublic = true;

  int _rating = 5;
  int _draftRating = 5;

  String _reviewText = '';

  final List<Map<String, dynamic>> _comments = [
    {
      'user': '@lectora_clasica',
      'text':
          'La evolución entre Elizabeth y Darcy me sigue pareciendo brillante en cada relectura.',
      'likes': 11,
      'liked': false,
      'replying': false,
      'repliesExpanded': false,
      'replyPublic': true,
      'replies': <Map<String, dynamic>>[],
    },
    {
      'user': '@clubdelasletras',
      'text':
          'Una lectura muy entretenida para conversar sobre orgullo, prejuicios y primeras impresiones.',
      'likes': 3,
      'liked': false,
      'replying': false,
      'repliesExpanded': false,
      'replyPublic': true,
      'replies': <Map<String, dynamic>>[],
    },
  ];

  Color get _background => AppColors.backgroundOf(context);
  Color get _surface => AppColors.surfaceOf(context);
  Color get _textPrimary => AppColors.textPrimaryOf(context);
  Color get _textSecondary => AppColors.textSecondaryOf(context);
  Color get _gold => AppColors.goldOf(context);
  Color get _accent => AppColors.accentOf(context);
  Color get _deep => AppColors.deepOf(context);

  String get _title => widget.book.title;
  String get _author => widget.book.author;
  String get _authorHandle => widget.book.authorHandle ?? '';
  String get _genre => widget.book.genre;
  String get _cover => widget.book.cover;
  String get _synopsis => widget.book.synopsis;
  String get _isbn => widget.book.isbn;
  int get _year => widget.book.year;
  bool get _isFree => widget.book.isFree;

  double get _bookRating {
    return switch (widget.book.id) {
      1 => 4.9,
      2 => 4.8,
      3 => 4.7,
      4 => 4.8,
      14 => 4.6,
      _ => 4.5,
    };
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _replyControllers = List.generate(
      _comments.length,
      (_) => TextEditingController(),
    );

    for (var index = 0; index < _comments.length; index++) {
      _comments[index]['replies'] =
          BookInteractionStore.repliesFor(widget.book.id, index);
    }

    _favorite = widget.initiallyFavorite;
    _status = widget.status;
    _progress = widget.progress;

    final initialReview = widget.initialReview;
    if (initialReview != null) {
      _hasReview = true;
      _rating = initialReview.rating;
      _draftRating = initialReview.rating;
      _reviewIsPublic = initialReview.isPublic;
      _draftReviewIsPublic = initialReview.isPublic;
      _reviewText = initialReview.text;
      _reviewController.text = initialReview.text;
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    for (final controller in _replyControllers) {
      controller.dispose();
    }

    _reviewController.dispose();

    super.dispose();
  }

  void _handleScroll() {
    final compact = _scrollController.offset > 185;

    if (compact != _compactHeader && mounted) {
      setState(() {
        _compactHeader = compact;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _buildHero(),
              ),
              SliverToBoxAdapter(
                child: _buildContent(),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _compactHeader
                ? _buildCompactHeader()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 285,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _cover,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: _deep,
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.gold,
                size: 52,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.76),
                ],
                stops: const [0.10, 0.48, 1],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: 17,
                        ),
                        label: const Text('Volver atrás'),
                        style: TextButton.styleFrom(
                          foregroundColor: _accent,
                          padding: EdgeInsets.zero,
                          textStyle: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _heroMenuButton(),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _favoriteButton(),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 5,
                              children: [
                                _heroTag(_genre.toUpperCase()),
                                _heroTag('LIBRO', dark: true),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _title,
                              style: GoogleFonts.merriweather(
                                color: const Color(0xFFF9F1E5),
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  'por ',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFEADFCB),
                                    fontSize: 8,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    _authorHandle.isEmpty
                                        ? _author
                                        : _authorHandle,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: _gold,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: _gold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _showShareDialog(context),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.20),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.78),
                            ),
                          ),
                          child: Icon(
                            Icons.share_outlined,
                            color: _gold,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 64,
            child: Text(
              'PUBLICADO · $_year',
              style: GoogleFonts.inter(
                color: const Color(0xFFF3E6D1),
                fontSize: 6.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Material(
      key: const ValueKey('compact-book-header'),
      elevation: 6,
      color: _deep,
      shadowColor: Colors.black.withValues(alpha: 0.20),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: _gold,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.merriweather(
                        color: const Color(0xFFF7EFE3),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _authorHandle.isEmpty ? _author : _authorHandle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _gold,
                        fontSize: 6.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '· LIBRO',
                style: GoogleFonts.inter(
                  color: _gold,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      color: _background,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('SINOPSIS'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _gold,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              _synopsis,
              style: GoogleFonts.merriweather(
                color: _textPrimary,
                fontSize: 10.5,
                height: 1.65,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Divider(
            color: _gold.withValues(alpha: 0.26),
            height: 1,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_rounded,
                color: _gold,
                size: 13,
              ),
              const SizedBox(width: 3),
              Text(
                _bookRating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  color: _textPrimary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '·',
                style: GoogleFonts.inter(
                  color: _textSecondary,
                  fontSize: 8,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '136 reseñas',
                style: GoogleFonts.inter(
                  color: _textSecondary,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(
            color: _gold.withValues(alpha: 0.26),
            height: 1,
          ),
          const SizedBox(height: 18),
          _sectionTitle('INFORMACIÓN DEL LIBRO'),
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _gold.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _infoRow('Autor', _author),
                _infoRow('Publicación', '$_year'),
                _infoRow('ISBN', _isbn),
                _infoRow(
                  'Disponibilidad',
                  _isFree ? 'GRATIS' : 'CATÁLOGO',
                  valueColor: _isFree
                      ? const Color(0xFF2F7C39)
                      : _textPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle('COMENTARIOS DE LA COMUNIDAD'),
          const SizedBox(height: 10),
          ..._comments.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _commentCard(entry.key),
            ),
          ),
          const SizedBox(height: 15),
          _buildLibraryStatusAction(),
          const SizedBox(height: 18),
          Divider(
            color: _gold.withValues(alpha: 0.28),
          ),
          const SizedBox(height: 10),
          _sectionTitle('TU RESEÑA'),
          const SizedBox(height: 11),
          _buildReviewSection(),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 1,
                      color: _gold.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '✦',
                      style: TextStyle(
                        color: _gold.withValues(alpha: 0.55),
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 1,
                      color: _gold.withValues(alpha: 0.35),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'CAPÍTULO 0',
                  style: GoogleFonts.cinzel(
                    color: _textSecondary,
                    fontSize: 7,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryStatusAction() {
    final isRead = _status == BookStatus.leido;
    final isReading = _status == BookStatus.leyendo;

    final label = isRead
        ? '✓ Libro finalizado'
        : isReading
            ? 'Continuar lectura · $_progress%'
            : 'Comenzar lectura';

    return SizedBox(
      width: double.infinity,
      height: 42,
      child: FilledButton(
        onPressed: isRead
            ? null
            : () {
                if (_status == BookStatus.porLeer || _status == null) {
                  setState(() {
                    _status = BookStatus.leyendo;
                    if (_progress <= 0) {
                      _progress = 1;
                    }
                  });
                  widget.onStatusChanged(BookStatus.leyendo);
                  widget.onProgressChanged(_progress);
                  return;
                }

                final nextProgress = (_progress + 10).clamp(0, 100).toInt();

                setState(() {
                  _progress = nextProgress;
                  if (_progress >= 100) {
                    _status = BookStatus.leido;
                  }
                });

                widget.onProgressChanged(nextProgress);

                if (nextProgress >= 100) {
                  widget.onStatusChanged(BookStatus.leido);
                }
              },
        style: FilledButton.styleFrom(
          backgroundColor: isRead ? _gold : _accent,
          disabledBackgroundColor: _gold,
          foregroundColor: isRead ? _deep : AppColors.background,
          disabledForegroundColor: _deep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.cinzel(
            color: _textPrimary,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Container(
            height: 1,
            color: _gold.withValues(alpha: 0.30),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '◆',
          style: TextStyle(
            color: _gold,
            fontSize: 7,
          ),
        ),
      ],
    );
  }

  Widget _heroTag(String text, {bool dark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: 0.42)
            : const Color(0xFF8E5F22).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: _gold.withValues(alpha: 0.65),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: const Color(0xFFF8EAD4),
          fontSize: 5.8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.45,
        ),
      ),
    );
  }

  Widget _favoriteButton() {
    return InkWell(
      onTap: () {
        widget.onToggleFavorite();

        setState(() {
          _favorite = !_favorite;
        });
      },
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: _gold.withValues(alpha: 0.75),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _favorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _gold,
              size: 12,
            ),
            const SizedBox(width: 5),
            Text(
              'Favoritos',
              style: GoogleFonts.inter(
                color: const Color(0xFFF7EAD7),
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroMenuButton() {
    return InkWell(
      onTap: () => _showReportMenu(context),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: _gold.withValues(alpha: 0.42),
          ),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: _textPrimary,
          size: 18,
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                color: _textSecondary,
                fontSize: 7.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: valueColor ?? _textPrimary,
                fontSize: 7.5,
                fontWeight: valueColor != null
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentCard(int index) {
    final comment = _comments[index];
    final liked = comment['liked'] as bool;
    final replying = comment['replying'] as bool;
    final repliesExpanded = comment['repliesExpanded'] as bool;
    final replies = comment['replies'] as List<Map<String, dynamic>>;
    final replyPublic = comment['replyPublic'] as bool;
    final controller = _replyControllers[index];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _gold.withValues(alpha: 0.22),
        ),
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
                    color: _accent,
                    fontSize: 6.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showCommentMenu(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 15,
                    color: _textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment['text'] as String,
            style: GoogleFonts.merriweather(
              color: _textPrimary,
              fontSize: 7.8,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    comment['liked'] = !liked;
                    comment['likes'] =
                        (comment['likes'] as int) + (liked ? -1 : 1);
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 11,
                        color: liked ? _accent : _textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment['likes']} Me gusta',
                        style: GoogleFonts.inter(
                          fontSize: 6.3,
                          fontWeight:
                              liked ? FontWeight.w700 : FontWeight.w500,
                          color: liked ? _accent : _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              InkWell(
                onTap: () {
                  setState(() {
                    comment['replying'] = !replying;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Text(
                    'Responder',
                    style: GoogleFonts.inter(
                      fontSize: 6.3,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                setState(() {
                  comment['repliesExpanded'] = !repliesExpanded;
                });
              },
              child: Text(
                repliesExpanded
                    ? 'Ocultar respuestas (${replies.length})'
                    : 'Ver respuestas (${replies.length})',
                style: GoogleFonts.inter(
                  fontSize: 6.2,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                ),
              ),
            ),
          ],
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: replying
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: controller,
                            minLines: 2,
                            maxLines: 4,
                            style: GoogleFonts.inter(
                              color: _textPrimary,
                              fontSize: 7,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Responder a ${comment['user']}...',
                              hintStyle: GoogleFonts.inter(
                                color: _textSecondary,
                                fontSize: 6.7,
                              ),
                              filled: true,
                              fillColor: _surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide(
                                  color: _gold.withValues(alpha: 0.26),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide(color: _gold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PRIVACIDAD DE LA RESPUESTA',
                            style: GoogleFonts.cinzel(
                              color: _textPrimary,
                              fontSize: 6.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 32,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        comment['replyPublic'] = true;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: replyPublic
                                            ? _deep
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🌐 Pública',
                                        style: GoogleFonts.inter(
                                          fontSize: 6.4,
                                          fontWeight: FontWeight.w700,
                                          color: replyPublic
                                              ? AppColors.background
                                              : _textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        comment['replyPublic'] = false;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: !replyPublic
                                            ? _deep
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🔒 Privada',
                                        style: GoogleFonts.inter(
                                          fontSize: 6.4,
                                          fontWeight: FontWeight.w700,
                                          color: !replyPublic
                                              ? AppColors.background
                                              : _textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: 34,
                              child: FilledButton(
                                onPressed: () {
                                  final reply = controller.text.trim();
                                  if (reply.isEmpty) return;

                                  setState(() {
                                    replies.add({
                                      'text': reply,
                                      'isPublic': replyPublic,
                                    });
                                    BookInteractionStore.saveReplies(
                                      widget.book.id,
                                      index,
                                      replies,
                                    );
                                    comment['replying'] = false;
                                    comment['repliesExpanded'] = true;
                                    comment['replyPublic'] = true;
                                    controller.clear();
                                  });
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor:
                                      AppColors.background,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(9),
                                  ),
                                ),
                                child: Text(
                                  'Responder',
                                  style: GoogleFonts.inter(
                                    fontSize: 6.6,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: repliesExpanded && replies.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Column(
                      children: replies.map((reply) {
                        final isPublic =
                            reply['isPublic'] as bool? ?? true;
                        final replyText = reply['text'] as String? ?? '';

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _background,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isPublic
                                          ? widget.currentUsername
                                          : '@anonimo',
                                      style: GoogleFonts.inter(
                                        color: _accent,
                                        fontSize: 6.2,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    isPublic ? '🌐 Pública' : '🔒 Privada',
                                    style: GoogleFonts.inter(
                                      color: _textSecondary,
                                      fontSize: 5.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                replyText,
                                style: GoogleFonts.merriweather(
                                  color: _textPrimary,
                                  fontSize: 6.8,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _showCommentMenu(int index) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Opciones del comentario',
      barrierColor: Colors.black.withValues(alpha: 0.10),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              right: 22,
              top: MediaQuery.of(dialogContext).size.height * 0.58,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 152,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _showCommentReportDialog(index);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reportar comentario',
                            style: GoogleFonts.inter(
                              fontSize: 7.4,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            alignment: Alignment.topRight,
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showCommentReportDialog(int index) async {
    final comment = _comments[index];
    final detailController = TextEditingController();
    final reasons = <String>[
      'Spam o contenido engañoso',
      'Acoso o lenguaje ofensivo',
      'Contenido inapropiado',
      'Otro motivo',
    ];
    String? selectedReason;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reportar comentario',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SafeArea(
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(dialogContext).size.width * 0.84,
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MODERACIÓN',
                                    style: GoogleFonts.cinzel(
                                      fontSize: 7.2,
                                      fontWeight: FontWeight.w700,
                                      color: _accent,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reportar comentario',
                                    style: GoogleFonts.merriweather(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  Navigator.of(dialogContext).pop(),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _gold.withValues(alpha: 0.36),
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _background,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['user'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 6.6,
                                  fontWeight: FontWeight.w800,
                                  color: _accent,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '“${comment['text']}”',
                                style: GoogleFonts.merriweather(
                                  fontSize: 7,
                                  height: 1.4,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...reasons.map((reason) {
                          final selected = selectedReason == reason;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedReason = reason;
                                });
                              },
                              borderRadius: BorderRadius.circular(9),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _accent.withValues(alpha: 0.07)
                                      : _background,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: selected
                                        ? _accent.withValues(alpha: 0.40)
                                        : _gold.withValues(alpha: 0.20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reason,
                                        style: GoogleFonts.inter(
                                          fontSize: 7.2,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 13,
                                        color: AppColors.accent,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 5),
                        TextField(
                          controller: detailController,
                          minLines: 2,
                          maxLines: 4,
                          maxLength: 300,
                          style: GoogleFonts.inter(
                            fontSize: 7.2,
                            color: _textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Añade un detalle opcional...',
                            counterText: '',
                            filled: true,
                            fillColor: _background,
                            hintStyle: GoogleFonts.inter(
                              fontSize: 7,
                              color: _textSecondary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 10,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(
                                color: _gold.withValues(alpha: 0.28),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(color: _gold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: selectedReason == null
                                ? null
                                : () {
                                    Navigator.of(dialogContext).pop();
                                    _showModerationSuccess(
                                      title: 'Comentario reportado',
                                      message:
                                          'Gracias. El reporte fue registrado para revisión de moderación.',
                                    );
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              disabledBackgroundColor:
                                  _accent.withValues(alpha: 0.32),
                              foregroundColor: AppColors.background,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: Text(
                              'Enviar reporte',
                              style: GoogleFonts.inter(
                                fontSize: 7.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    detailController.dispose();
  }

  Future<void> _showReportMenu(BuildContext pageContext) async {
    await showGeneralDialog<void>(
      context: pageContext,
      barrierDismissible: true,
      barrierLabel: 'Opciones de publicación',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(dialogContext);
        final top = media.padding.top + 54;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: top,
              right: 18,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 170,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _showBookReportDialog();
                    },
                    borderRadius: BorderRadius.circular(13),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            size: 15,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Reportar publicación',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            alignment: Alignment.topRight,
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showBookReportDialog() async {
    final reasons = <String>[
      'Contenido inapropiado',
      'Spam o contenido engañoso',
      'Acoso o lenguaje ofensivo',
      'Otro motivo',
    ];

    final detailController = TextEditingController();
    String? selectedReason;
    var isSending = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSending,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AbsorbPointer(
                  absorbing: isSending,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _accent.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Icon(
                              Icons.flag_rounded,
                              color: _accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MODERACIÓN',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 7.2,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.65,
                                    color: _accent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reportar publicación',
                                  style: GoogleFonts.merriweather(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Selecciona el motivo que mejor describe el problema.',
                                  style: GoogleFonts.inter(
                                    fontSize: 7.5,
                                    height: 1.4,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                Navigator.of(dialogContext).pop(),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _gold.withValues(alpha: 0.34),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...reasons.map((reason) {
                        final selected = selectedReason == reason;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedReason = reason;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 170),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _accent.withValues(alpha: 0.08)
                                    : _background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? _accent.withValues(alpha: 0.42)
                                      : _gold.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons
                                            .radio_button_checked_rounded
                                        : Icons
                                            .radio_button_unchecked_rounded,
                                    size: 15,
                                    color: selected
                                        ? _accent
                                        : _textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 5),
                      Text(
                        'DETALLE ADICIONAL · OPCIONAL',
                        style: GoogleFonts.cinzel(
                          fontSize: 6.7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.45,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: detailController,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 300,
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          color: _textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Cuéntanos brevemente qué ocurrió...',
                          counterText: '',
                          filled: true,
                          fillColor: _background,
                          hintStyle: GoogleFonts.inter(
                            fontSize: 7.2,
                            color: _textSecondary,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: _gold.withValues(alpha: 0.28),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(color: _gold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: FilledButton(
                          onPressed: selectedReason == null
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isSending = true;
                                  });

                                  await Future<void>.delayed(
                                    const Duration(milliseconds: 1000),
                                  );

                                  if (!dialogContext.mounted) return;
                                  Navigator.of(dialogContext).pop();

                                  if (!mounted) return;
                                  _showModerationSuccess(
                                    title: 'Publicación reportada',
                                    message:
                                        'Gracias. El reporte fue enviado para revisión.',
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            disabledBackgroundColor: isSending
                                ? Colors.grey.shade600
                                : _accent.withValues(alpha: 0.30),
                            foregroundColor: AppColors.background,
                            disabledForegroundColor: isSending
                                ? Colors.white
                                : AppColors.background
                                    .withValues(alpha: 0.72),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isSending
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'Enviando reporte...',
                                      style: GoogleFonts.inter(
                                        fontSize: 7.8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Enviar reporte',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    detailController.dispose();
  }

  Future<void> _showShareDialog(BuildContext pageContext) async {
    await showGeneralDialog<void>(
      context: pageContext,
      barrierDismissible: true,
      barrierLabel: 'Compartir obra',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.76,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COMPARTIR OBRA',
                                style: GoogleFonts.cinzel(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.65,
                                  color: _accent,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '¿Dónde deseas compartir?',
                                style: GoogleFonts.merriweather(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              Navigator.of(dialogContext).pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.38),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _shareOption(
                            label: 'W · WhatsApp',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _shareOption(
                            label: 'I · Instagram',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _shareOption(
                            label: 'X · X',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _shareOption(
                            label: '↗ · Enlace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _shareOption({
    required String label,
  }) {
    return InkWell(
      onTap: null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _gold.withValues(alpha: 0.34),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 7.4,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _showModerationSuccess({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _gold.withValues(alpha: 0.24),
            ),
          ),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.accent,
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 8,
              height: 1.45,
              color: _textSecondary,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: AppColors.background,
              ),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewSection() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _reviewEditorOpen
          ? _buildReviewEditor()
          : _hasReview
              ? _buildPublishedReview()
              : _buildReviewCallToAction(),
    );
  }

  Widget _buildReviewCallToAction() {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: OutlinedButton(
        onPressed: _openReviewEditor,
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: BorderSide(
            color: _gold.withValues(alpha: 0.40),
          ),
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: Text(
          '★ Calificar y reseñar',
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewEditor() {
    final canPublish =
        _draftRating > 0 && _reviewController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _gold.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TU CALIFICACIÓN',
            style: GoogleFonts.cinzel(
              color: _textPrimary,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= _draftRating;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _draftRating = value;
                    });
                  },
                  customBorder: const CircleBorder(),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(
                      'review-star-$value-$_draftRating',
                    ),
                    tween: Tween<double>(
                      begin: 0.72,
                      end: 1,
                    ),
                    duration: const Duration(milliseconds: 190),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Icon(
                      selected
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: _gold,
                      size: 23,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            minLines: 4,
            maxLines: 6,
            maxLength: 500,
            onChanged: (_) {
              setState(() {});
            },
            style: GoogleFonts.merriweather(
              color: _textPrimary,
              fontSize: 8.2,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: '¿Qué te pareció esta lectura?',
              counterText: '',
              filled: true,
              fillColor: _background,
              hintStyle: GoogleFonts.merriweather(
                color: _textSecondary,
                fontSize: 8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                11,
                10,
                11,
                10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(
                  color: _gold.withValues(alpha: 0.34),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: _gold),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'PRIVACIDAD DE LA RESEÑA',
            style: GoogleFonts.cinzel(
              color: _textPrimary,
              fontSize: 7.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _gold.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _reviewPrivacyButton(
                    label: '🌐  Pública',
                    selected: _draftReviewIsPublic,
                    onTap: () {
                      setState(() {
                        _draftReviewIsPublic = true;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _reviewPrivacyButton(
                    label: '🔒  Privada',
                    selected: !_draftReviewIsPublic,
                    onTap: () {
                      setState(() {
                        _draftReviewIsPublic = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _draftReviewIsPublic
                  ? 'Visible para todos los lectores.'
                  : 'Anonimo para todos los lectores.',
              key: ValueKey(_draftReviewIsPublic),
              style: GoogleFonts.inter(
                color: _textSecondary,
                fontSize: 6.7,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_reviewController.text.length} / 500',
              style: GoogleFonts.inter(
                color: _textSecondary,
                fontSize: 6.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: _cancelReviewEditing,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textPrimary,
                      side: BorderSide(
                        color: _gold.withValues(alpha: 0.34),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.inter(
                        fontSize: 7.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: canPublish ? _publishReview : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      disabledBackgroundColor:
                          _accent.withValues(alpha: 0.32),
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      _hasReview
                          ? 'Guardar cambios'
                          : 'Publicar reseña',
                      style: GoogleFonts.inter(
                        fontSize: 7.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewPrivacyButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _deep : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected
                ? AppColors.background
                : _textPrimary,
            fontSize: 6.8,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPublishedReview() {
    final displayedUser = _reviewIsPublic
        ? widget.currentUsername
        : '@anonimo';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: _gold.withValues(alpha: 0.23),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  onTap: _reviewIsPublic
                      ? widget.onOpenOwnProfile
                      : null,
                  borderRadius: BorderRadius.circular(5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                    ),
                    child: Text(
                      displayedUser,
                      style: GoogleFonts.inter(
                        color: _accent,
                        fontSize: 6.8,
                        fontWeight: FontWeight.w800,
                        decoration: _reviewIsPublic
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: _accent,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  _reviewIsPublic ? '🌐 Pública' : '🔒 Privada',
                  style: GoogleFonts.inter(
                    color: _textSecondary,
                    fontSize: 6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              InkWell(
                onTap: _openReviewEditor,
                child: Text(
                  'Editar reseña',
                  style: GoogleFonts.inter(
                    color: _accent,
                    fontSize: 6.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < _rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: _gold,
                size: 13,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _reviewText,
            style: GoogleFonts.merriweather(
              color: _textPrimary,
              fontSize: 7.7,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  void _openReviewEditor() {
    setState(() {
      _draftRating = _rating;
      _draftReviewIsPublic = _reviewIsPublic;
      _reviewController.text = _reviewText;
      _reviewEditorOpen = true;
    });
  }

  void _cancelReviewEditing() {
    setState(() {
      _reviewEditorOpen = false;
      _draftRating = _rating;
      _draftReviewIsPublic = _reviewIsPublic;
      _reviewController.text = _reviewText;
    });
  }

  void _publishReview() {
    final text = _reviewController.text.trim();

    if (text.isEmpty || _draftRating <= 0) {
      return;
    }

    final review = BookReview(
      rating: _draftRating,
      text: text,
      isPublic: _draftReviewIsPublic,
    );

    widget.onReviewSaved(review);

    setState(() {
      _rating = review.rating;
      _reviewIsPublic = review.isPublic;
      _reviewText = review.text;
      _hasReview = true;
      _reviewEditorOpen = false;
    });
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

  bool get _isEditing => widget.initial != null;

  Color get _background => AppColors.backgroundOf(context);
  Color get _surface => AppColors.surfaceOf(context);
  Color get _textPrimary => AppColors.textPrimaryOf(context);
  Color get _textSecondary => AppColors.textSecondaryOf(context);
  Color get _gold => AppColors.goldOf(context);
  Color get _accent => AppColors.accentOf(context);
  Color get _deep => AppColors.deepOf(context);

  @override
  void initState() {
    super.initState();
    _rating = widget.initial?.rating ?? 5;
    _isPublic = widget.initial?.isPublic ?? true;
    _controller =
        TextEditingController(text: widget.initial?.text ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _rating > 0 && _controller.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _gold.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.11),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.26),
                      ),
                    ),
                    child: Icon(
                      _isEditing
                          ? Icons.rate_review_outlined
                          : Icons.star_outline_rounded,
                      color: _gold,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing
                              ? 'EDITAR RESEÑA'
                              : 'CALIFICAR Y RESEÑAR',
                          style: GoogleFonts.cinzel(
                            color: _accent,
                            fontSize: 7.4,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.65,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.bookTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            color: _textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.34),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                'TU CALIFICACIÓN',
                style: GoogleFonts.cinzel(
                  color: _textPrimary,
                  fontSize: 7.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: List.generate(5, (index) {
                  final value = index + 1;
                  final selected = value <= _rating;

                  return Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: InkWell(
                      onTap: () => setState(() => _rating = value),
                      customBorder: const CircleBorder(),
                      child: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _gold,
                        size: 24,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 6,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.merriweather(
                  color: _textPrimary,
                  fontSize: 8.2,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  hintText: '¿Qué te pareció esta lectura?',
                  counterText: '',
                  filled: true,
                  fillColor: _background,
                  hintStyle: GoogleFonts.merriweather(
                    color: _textSecondary,
                    fontSize: 8,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(
                    11,
                    10,
                    11,
                    10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(
                      color: _gold.withValues(alpha: 0.34),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: _gold),
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'PRIVACIDAD DE LA RESEÑA',
                style: GoogleFonts.cinzel(
                  color: _textPrimary,
                  fontSize: 7.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                height: 34,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _privacyButton(
                        label: '🌐  Pública',
                        selected: _isPublic,
                        onTap: () =>
                            setState(() => _isPublic = true),
                      ),
                    ),
                    Expanded(
                      child: _privacyButton(
                        label: '🔒  Privada',
                        selected: !_isPublic,
                        onTap: () =>
                            setState(() => _isPublic = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isPublic
                    ? 'Visible para todos los lectores y en Mis reseñas.'
                    : 'Se mostrará como anónima para la comunidad.',
                style: GoogleFonts.inter(
                  color: _textSecondary,
                  fontSize: 6.7,
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_controller.text.length} / 500',
                  style: GoogleFonts.inter(
                    color: _textSecondary,
                    fontSize: 6.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textPrimary,
                          side: BorderSide(
                            color: _gold.withValues(alpha: 0.34),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(
                            fontSize: 7.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 38,
                      child: FilledButton(
                        onPressed: canSave
                            ? () {
                                final review = BookReview(
                                  rating: _rating,
                                  text: _controller.text.trim(),
                                  isPublic: _isPublic,
                                );

                                widget.onSave(review);
                                Navigator.of(context).pop();
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          disabledBackgroundColor:
                              _accent.withValues(alpha: 0.30),
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: Text(
                          _isEditing
                              ? 'Guardar cambios'
                              : 'Publicar reseña',
                          style: GoogleFonts.inter(
                            fontSize: 7.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _deep : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected
                ? AppColors.background
                : _textPrimary,
            fontSize: 6.8,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
