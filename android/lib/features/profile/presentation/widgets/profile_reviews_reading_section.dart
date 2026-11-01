part of '../screens/profile_screen.dart';

extension _ProfileReviewsReadingSection on _ProfileScreenState {
  Widget _buildReviews() {
    final reviewEntries = widget.reviews.entries
        .where((entry) => entry.value.isPublic)
        .toList();
    if (reviewEntries.isEmpty) {
      return _emptyCard('Aún no has publicado reseñas.');
    }
    return Column(
      children: reviewEntries.map((entry) {
        final book = _bookById(entry.key);
        if (book == null) return const SizedBox.shrink();
        final review = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: InkWell(
            onTap: () => _openBookDetail(book),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.36),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      book.cover,
                      width: 52,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 52,
                        height: 74,
                        color: _deepSurfaceColor,
                        child: const Icon(
                          Icons.menu_book,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: GoogleFonts.merriweather(
                            color: _textPrimaryColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          List<String>.filled(review.rating, '★').join(),
                          style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          review.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            color: _textSecondaryColor,
                            fontSize: 7.7,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _smallBadge(
                              review.isPublic ? 'Pública' : 'Privada',
                            ),
                            const Spacer(),
                            Text(
                              'Abrir libro →',
                              style: GoogleFonts.inter(
                                color: AppColors.accent,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                              ),
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
        );
      }).toList(),
    );
  }

  Widget _smallBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _headingColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: _headingColor,
          fontSize: 6.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildShelf() {
    return _sectionCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
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
                      'MI ESTANTE LEÍDO',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cada lectura terminada deja un libro en tu colección.',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_readBooks.length} libros',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _showExpandedShelf,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                      minimumSize: const Size(0, 26),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ver estante',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_readBooks.isEmpty)
            Text(
              'Cuando finalices un libro desde Mi Biblioteca aparecerá automáticamente aquí.',
              style: GoogleFonts.merriweather(
                color: _textSecondaryColor,
                fontSize: 8,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            _buildShelfVisual(compact: true),
        ],
      ),
    );
  }

  Widget _buildShelfVisual({
    required bool compact,
    List<Object>? sourceItems,
  }) {
    final books = sourceItems ?? _readBooks.cast<Object>();
    final rowCount = compact ? 2 : 4;
    final perRow = compact ? 5 : 6;
    final maxBooks = rowCount * perRow;
    final visibleBooks = books.take(maxBooks).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 10,
        compact ? 8 : 10,
        compact ? 8 : 10,
        compact ? 9 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFC58C61),
        borderRadius: BorderRadius.circular(compact ? 15 : 19),
        border: Border.all(color: const Color(0xFF9A623C), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C321D).withValues(alpha: 0.22),
            blurRadius: compact ? 8 : 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(compact ? 12 : 16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD7A57C),
                    Color(0xFFC38E66),
                    Color(0xFFB77C54),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _shelfSideRail(compact),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _shelfSideRail(compact),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 11),
            child: Column(
              children: List.generate(rowCount, (rowIndex) {
                final start = rowIndex * perRow;
                final end = (start + perRow).clamp(0, visibleBooks.length);
                final rowBooks = start < visibleBooks.length
                    ? visibleBooks.sublist(start, end)
                    : <Object>[];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: rowIndex == rowCount - 1 ? 0 : (compact ? 8 : 10),
                  ),
                  child: _buildShelfRow(
                    books: rowBooks,
                    compact: compact,
                    rowIndex: rowIndex,
                    globalStartIndex: start,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shelfSideRail(bool compact) {
    return Container(
      width: compact ? 7 : 10,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF774528), Color(0xFFB36F43), Color(0xFF6E3D23)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 4,
            offset: const Offset(1, 0),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfRow({
    required List<Object> books,
    required bool compact,
    required int rowIndex,
    required int globalStartIndex,
  }) {
    final rowHeight = compact ? 91.0 : 122.0;

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 9 : 12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD8AE89), Color(0xFFC39169), Color(0xFFB47B52)],
        ),
        border: Border.all(color: const Color(0xFF99603A), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: compact ? 7 : 9,
            right: compact ? 7 : 9,
            bottom: compact ? 10 : 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _leftShelfDecoration(rowIndex, compact),
                SizedBox(width: compact ? 5 : 7),
                ...books.asMap().entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(right: compact ? 3 : 4),
                    child: _shelfSpine(
                      entry.value,
                      index: globalStartIndex + entry.key,
                      compact: compact,
                    ),
                  );
                }),
                const Spacer(),
                _rightShelfDecoration(rowIndex, compact),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: compact ? 9 : 12,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFA86239),
                    Color(0xFF774023),
                    Color(0xFF5B2F1A),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftShelfDecoration(int rowIndex, bool compact) {
    switch (rowIndex % 4) {
      case 0:
        return _plantDecoration(compact, flower: false);
      case 1:
        return _flowerPotDecoration(compact);
      case 2:
        return _candleDecoration(compact);
      default:
        return _bookendDecoration(compact);
    }
  }

  Widget _rightShelfDecoration(int rowIndex, bool compact) {
    switch (rowIndex % 4) {
      case 0:
        return _flowerPotDecoration(compact);
      case 1:
        return _candleDecoration(compact);
      case 2:
        return _plantDecoration(compact, flower: false);
      default:
        return _lighthouseDecoration(compact);
    }
  }

  Widget _shelfSpine(
    Object item, {
    required int index,
    required bool compact,
  }) {
    const colors = [
      Color(0xFF2E6293),
      Color(0xFFE8D7B8),
      Color(0xFF283C37),
      Color(0xFFB8794D),
      Color(0xFF2C4D68),
      Color(0xFF71573C),
      Color(0xFF5F785C),
      Color(0xFFD2A851),
      Color(0xFF85433B),
      Color(0xFF3D5E78),
      Color(0xFF6E4933),
      Color(0xFF9E5A49),
    ];

    final String title;
    final VoidCallback onTap;

    if (item is LibraryBook) {
      title = item.title;
      onTap = () => _openBookDetail(item);
    } else if (item is WriterStory) {
      title = item.title;
      onTap = () => _openFavoriteCommunityStory(item);
    } else {
      title = 'Favorito';
      onTap = () {};
    }

    final color = colors[index % colors.length];
    final width = compact ? 17.0 + (index % 3) : 21.0 + (index % 3) * 1.5;
    final height =
        compact ? 53.0 + (index % 4) * 6 : 76.0 + (index % 4) * 8;
    final lightText = color.computeLuminance() < 0.48;

    return Tooltip(
      message: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.20),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 2,
                offset: const Offset(1.3, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 2,
                right: 2,
                top: compact ? 5 : 7,
                child: Container(
                  height: 1,
                  color: lightText
                      ? Colors.white.withValues(alpha: 0.28)
                      : AppColors.deep.withValues(alpha: 0.28),
                ),
              ),
              Positioned(
                left: 2,
                right: 2,
                bottom: compact ? 5 : 7,
                child: Container(
                  height: 1,
                  color: lightText
                      ? Colors.white.withValues(alpha: 0.28)
                      : AppColors.deep.withValues(alpha: 0.28),
                ),
              ),
              Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: lightText
                            ? const Color(0xFFF8EEDB)
                            : const Color(0xFF4A2B1D),
                        fontSize: compact ? 4.3 : 5.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plantDecoration(bool compact, {required bool flower}) {
    return SizedBox(
      width: compact ? 23 : 30,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            flower ? '🌸' : '🌿',
            style: TextStyle(fontSize: compact ? 15 : 21),
          ),
          Container(
            width: compact ? 13 : 17,
            height: compact ? 8 : 11,
            decoration: BoxDecoration(
              color: const Color(0xFFB56F48),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(5),
              ),
              border: Border.all(color: const Color(0xFF77452C), width: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowerPotDecoration(bool compact) {
    return _plantDecoration(compact, flower: true);
  }

  Widget _candleDecoration(bool compact) {
    return SizedBox(
      width: compact ? 17 : 22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: const Color(0xFFF3B34B),
            size: compact ? 9 : 12,
          ),
          Container(
            width: compact ? 7 : 9,
            height: compact ? 15 : 20,
            decoration: BoxDecoration(
              color: const Color(0xFFF1E7D1),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFFCAB58A), width: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookendDecoration(bool compact) {
    return Container(
      width: compact ? 9 : 12,
      height: compact ? 22 : 30,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE1CB),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFFB89A73), width: 0.7),
      ),
    );
  }

  Widget _lighthouseDecoration(bool compact) {
    return SizedBox(
      width: compact ? 20 : 28,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.light_mode_rounded,
            color: const Color(0xFFF4C568),
            size: compact ? 9 : 12,
          ),
          Container(
            width: compact ? 9 : 12,
            height: compact ? 24 : 33,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF3E8D4),
                  Color(0xFFA94A3F),
                  Color(0xFFF3E8D4),
                ],
                stops: [0, 0.52, 1],
              ),
            ),
          ),
          Container(
            width: compact ? 15 : 20,
            height: compact ? 3 : 4,
            decoration: BoxDecoration(
              color: const Color(0xFF67402A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  void _showExpandedFavoriteShelf() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _backgroundColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MI BIBLIOTECA PERSONAL',
                            style: GoogleFonts.inter(
                              color: _textSecondaryColor,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'MIS FAVORITOS',
                            style: GoogleFonts.cinzel(
                              color: _headingColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Todos tus libros y obras favoritas, reunidos en un solo estante.',
                            style: GoogleFonts.merriweather(
                              color: _textSecondaryColor,
                              fontSize: 8,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8A5939),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Confirmar',
                        style: GoogleFonts.inter(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E0D0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD4B18F),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        '$_favoriteCount favoritos guardados',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8C5A37),
                          fontSize: 6.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Toca un lomo para abrir el libro.',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 6.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: _favoriteShelfItems.isEmpty
                        ? _emptyCard(
                            'Cuando marques algo como favorito, aparecerá aquí.',
                          )
                        : _buildShelfVisual(
                            compact: false,
                            sourceItems: _favoriteShelfItems,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExpandedShelf() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _backgroundColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MI BIBLIOTECA PERSONAL',
                            style: GoogleFonts.inter(
                              color: _textSecondaryColor,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'MIS LECTURAS',
                            style: GoogleFonts.cinzel(
                              color: _headingColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Portadas, lomos y pequeñas historias de una colección que sigue creciendo.',
                            style: GoogleFonts.merriweather(
                              color: _textSecondaryColor,
                              fontSize: 8,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8A5939),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Confirmar',
                        style: GoogleFonts.inter(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E0D0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD4B18F),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        '${_readBooks.length} lecturas registradas',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8C5A37),
                          fontSize: 6.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Los libros del usuario son interactivos.',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 6.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: _readBooks.isEmpty
                        ? _emptyCard(
                            'Cuando finalices libros, aparecerán aquí.',
                          )
                        : _buildShelfVisual(compact: false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
