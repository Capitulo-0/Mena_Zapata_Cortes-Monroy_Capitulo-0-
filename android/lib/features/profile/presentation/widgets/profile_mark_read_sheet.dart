part of '../screens/profile_screen.dart';

extension _ProfileMarkReadSheet on _ProfileScreenState {
  void _showMarkBookAsRead() {
    final readingBooks = widget.books
        .where((book) => widget.statuses[book.id] == BookStatus.leyendo)
        .toList();

    bool showSuccessMessage = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.64,
              minChildSize: 0.42,
              maxChildSize: 0.86,
              builder: (context, scrollController) {
                return Container(
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.45),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 9),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _textSecondaryColor.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 14, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: _goldColor.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              color: _accentColor,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REGISTRAR LIBRO FINALIZADO',
                                  style: GoogleFonts.cinzel(
                                    color: _headingColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Solo aparecen los libros que tienes actualmente en Leyendo.',
                                  style: GoogleFonts.inter(
                                    color: _textSecondaryColor,
                                    fontSize: 8,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: _headingColor,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: _goldColor.withValues(alpha: 0.18),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: showSuccessMessage
                          ? Padding(
                              key: const ValueKey('register-success'),
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? const Color(0xFF283125)
                                      : const Color(0xFFF4F7EE),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF78935F)
                                        .withValues(alpha: 0.72),
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
                                        'Libro registrado correctamente',
                                        style: GoogleFonts.merriweather(
                                          color: _isDarkMode
                                              ? const Color(0xFFE7EEDC)
                                              : const Color(0xFF3F4F33),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.auto_stories_rounded,
                                      color: _goldColor.withValues(alpha: 0.76),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('register-success-empty'),
                            ),
                    ),
                    Expanded(
                      child: readingBooks.isEmpty
                          ? ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                34,
                                22,
                                26,
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: _surfaceColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _goldColor.withValues(alpha: 0.30),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: _goldColor.withValues(alpha: 0.10),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.menu_book_rounded,
                                          color: _goldColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No tienes libros en lectura',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.merriweather(
                                          color: _headingColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Cuando tengas un libro en el estante Leyendo, aparecerá aquí para poder registrarlo como finalizado.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          color: _textSecondaryColor,
                                          fontSize: 8,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                24,
                              ),
                              itemCount: readingBooks.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 9),
                              itemBuilder: (context, index) {
                                final book = readingBooks[index];
                                final progress =
                                    (widget.progresses[book.id] ?? 0)
                                        .clamp(0, 100)
                                        .toInt();

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(15),
                                    onTap: () {
                                      widget.onStatusChanged(
                                        book.id,
                                        BookStatus.leido,
                                      );
                                      widget.onProgressChanged(book.id, 100);

                                      setSheetState(() {
                                        readingBooks.removeWhere(
                                          (candidate) => candidate.id == book.id,
                                        );
                                        showSuccessMessage = true;
                                      });

                                      Future<void>.delayed(
                                        const Duration(milliseconds: 2500),
                                        () {
                                          if (!sheetContext.mounted) return;

                                          setSheetState(() {
                                            showSuccessMessage = false;
                                          });
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _surfaceColor,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: _goldColor.withValues(alpha: 0.34),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              book.cover,
                                              width: 47,
                                              height: 66,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  Container(
                                                width: 47,
                                                height: 66,
                                                color: _deepSurfaceColor,
                                                child: Icon(
                                                  Icons.menu_book_rounded,
                                                  color: _goldColor,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 11),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  book.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      GoogleFonts.merriweather(
                                                    color: _headingColor,
                                                    fontSize: 9,
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
                                                        _textSecondaryColor,
                                                    fontSize: 7.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          LinearProgressIndicator(
                                                        value:
                                                            progress / 100,
                                                        minHeight: 4,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          99,
                                                        ),
                                                        backgroundColor:
                                                            _goldColor.withValues(
                                                          alpha: 0.14,
                                                        ),
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          _accentColor,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 7),
                                                    Text(
                                                      '$progress%',
                                                      style:
                                                          GoogleFonts.inter(
                                                        color:
                                                            _accentColor,
                                                        fontSize: 7.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: _accentColor
                                                  .withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: _accentColor
                                                    .withValues(alpha: 0.24),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.check_rounded,
                                              color: _accentColor,
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
                    ),
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


}
