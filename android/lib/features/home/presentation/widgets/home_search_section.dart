import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import 'home_network_cover.dart';

class HomeSearchSection extends StatefulWidget {
  const HomeSearchSection({
    super.key,
    required this.books,
    required this.onBookTap,
    required this.onSearchModeChanged,
  });

  final List<Map<String, dynamic>> books;
  final ValueChanged<Map<String, dynamic>> onBookTap;
  final ValueChanged<bool> onSearchModeChanged;

  @override
  State<HomeSearchSection> createState() => _HomeSearchSectionState();
}

class _HomeSearchSectionState extends State<HomeSearchSection> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  String searchFilter = 'titulo';
  final Set<String> selectedGenres = <String>{};

  bool searchSubmitted = false;
  bool showFilters = false;
  bool showEmptySearchError = false;

  Color get _background => AppColors.backgroundOf(context);
  Color get _surface => AppColors.surfaceOf(context);
  Color get _deepSurface => AppColors.deepOf(context);
  Color get _textPrimary => AppColors.textPrimaryOf(context);
  Color get _textSecondary => AppColors.textSecondaryOf(context);
  Color get _gold => AppColors.goldOf(context);
  Color get _accent => AppColors.accentOf(context);
  Color get _onAccent => AppColors.isDark(context)
      ? AppColors.darkTextPrimary
      : AppColors.background;

  List<Map<String, dynamic>> get books => widget.books;

  List<Map<String, dynamic>> get filteredBooks {
    final query = searchQuery.trim().toLowerCase();

    var result = [...books];

    if (query.isNotEmpty) {
      result = result.where((book) {
        final title = book['title'].toString().toLowerCase();
        final author = book['authorReal'].toString().toLowerCase();

        return title.contains(query) || author.contains(query);
      }).toList();
    }

    if (selectedGenres.isNotEmpty) {
      result = result.where((book) {
        final genre = book['genre'].toString().toLowerCase();

        return selectedGenres.any(
          (selected) => genre.contains(selected.toLowerCase()),
        );
      }).toList();
    }

    if (searchFilter == 'recientes') {
      result.sort((a, b) => (b['year'] as int).compareTo(a['year'] as int));
    }

    if (searchFilter == 'calificados') {
      result.sort(
        (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
      );
    }

    return result;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _flashEmptySearchError() async {
    if (!mounted) return;

    setState(() {
      showEmptySearchError = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      showEmptySearchError = false;
    });
  }

  Widget _networkCover(
    String url, {
    required double width,
    required double height,
    double radius = 8,
  }) {
    return HomeNetworkCover(
      url: url,
      width: width,
      height: height,
      radius: radius,
    );
  }

  Widget _availabilityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2E793E),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: Text(
        'GRATIS',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 42,
            padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showEmptySearchError
                    ? _accent
                    : _gold,
                width: showEmptySearchError ? 1.7 : 1.15,
              ),
              boxShadow: showEmptySearchError
                  ? [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: _gold,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textAlignVertical: TextAlignVertical.center,
                    style: GoogleFonts.inter(
                      color: _textPrimary,
                      fontSize: 10,
                      height: 1.0,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar libros...',
                      hintStyle: GoogleFonts.inter(
                        color: _textSecondary,
                        fontSize: 10,
                      ),
                      isDense: true,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 11,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      suffixIcon: searchQuery.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                });
                              },
                              splashRadius: 14,
                              icon: Icon(
                                Icons.close_rounded,
                                color: _textSecondary,
                                size: 15,
                              ),
                            ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    onSubmitted: (_) {
                      final query = searchController.text.trim();

                      if (query.isEmpty) {
                        setState(() {
                          searchSubmitted = false;
                          searchQuery = '';
                          showFilters = false;
                        });
                        widget.onSearchModeChanged(false);
                        _flashEmptySearchError();
                        return;
                      }

                      setState(() {
                        searchQuery = query;
                        searchSubmitted = true;
                        showFilters = false;
                      });
                      widget.onSearchModeChanged(true);
                    },
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  height: 27,
                  child: TextButton.icon(
                    onPressed: _showSearchFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: _textPrimary,
                      backgroundColor: selectedGenres.isNotEmpty
                          ? _gold.withValues(alpha: 0.16)
                          : _surface,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 27),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: _gold,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    icon: Icon(
                      Icons.filter_alt_outlined,
                      size: 13,
                      color: _gold,
                    ),
                    label: Text(
                      selectedGenres.isEmpty
                          ? 'Filtrar'
                          : 'Filtrar (${selectedGenres.length})',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  height: 27,
                  child: FilledButton(
                    onPressed: () {
                      final query = searchController.text.trim();

                      if (query.isEmpty) {
                        setState(() {
                          searchSubmitted = false;
                          searchQuery = '';
                          showFilters = false;
                        });
                        widget.onSearchModeChanged(false);
                        _flashEmptySearchError();
                        return;
                      }

                      setState(() {
                        searchQuery = query;
                        searchSubmitted = true;
                        showFilters = false;
                      });
                      widget.onSearchModeChanged(true);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _onAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      minimumSize: const Size(0, 27),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Buscar',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
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

  Future<void> _showSearchFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 9, 18, 20),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: _gold.withValues(alpha: 0.34),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _deepSurface,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FILTRAR BÚSQUEDA',
                                style: GoogleFonts.cinzel(
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.35,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Refina tu búsqueda para encontrar tu próxima lectura.',
                                style: GoogleFonts.inter(
                                  color: _textSecondary,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _searchFilterMenuTile(
                      icon: Icons.menu_book_outlined,
                      title: 'Géneros',
                      value: selectedGenres.isEmpty
                          ? 'Todos los géneros'
                          : '1 seleccionado • ${selectedGenres.first}',
                      onTap: () async {
                        final changed = await _showGenreSubmenu();

                        if (changed && sheetContext.mounted) {
                          setSheetState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _searchFilterMenuTile(
                      icon: Icons.star_outline_rounded,
                      title: 'Orden',
                      value: searchFilter == 'calificados'
                          ? 'Mejor calificados'
                          : searchFilter == 'recientes'
                              ? 'Más recientes'
                              : 'Predeterminado',
                      onTap: () {
                        setState(() {
                          searchFilter = switch (searchFilter) {
                            'recientes' => 'calificados',
                            'calificados' => 'titulo',
                            _ => 'recientes',
                          };
                        });
                        setSheetState(() {});
                      },
                    ),
                    if (selectedGenres.isNotEmpty ||
                        searchFilter == 'recientes' ||
                        searchFilter == 'calificados') ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedGenres.clear();
                              searchFilter = 'titulo';
                            });
                            setSheetState(() {});
                          },
                          icon: Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: _accent,
                          ),
                          label: Text(
                            'Limpiar filtros',
                            style: GoogleFonts.inter(
                              color: _accent,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          setState(() {
                            searchSubmitted = true;
                          });
                          widget.onSearchModeChanged(true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        icon: const Icon(
                          Icons.tune_rounded,
                          size: 16,
                        ),
                        label: Text(
                          'Aplicar filtros',
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
            );
          },
        );
      },
    );
  }

  Widget _searchFilterMenuTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _gold.withValues(alpha: 0.38),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _gold,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.merriweather(
                  color: _textPrimary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                color: _textSecondary,
                fontSize: 7.5,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.chevron_right_rounded,
              color: _gold,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showGenreSubmenu() async {
    const genres = <Map<String, dynamic>>[
      {'name': 'Romance', 'icon': Icons.favorite_border_rounded},
      {'name': 'Fantasía', 'icon': Icons.auto_awesome_outlined},
      {'name': 'Misterio', 'icon': Icons.search_rounded},
      {'name': 'Gótico', 'icon': Icons.dark_mode_outlined},
      {'name': 'Drama', 'icon': Icons.theater_comedy_outlined},
      {'name': 'Clásico', 'icon': Icons.account_balance_outlined},
    ];

    var changed = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.48,
              maxChildSize: 0.90,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: _gold.withValues(alpha: 0.34),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 9, 18, 20),
                      children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _deepSurface,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: _gold,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GÉNEROS',
                                style: GoogleFonts.cinzel(
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Selecciona uno o más géneros.',
                                style: GoogleFonts.inter(
                                  color: _textSecondary,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ...genres.map((genre) {
                      final name = genre['name'] as String;
                      final icon = genre['icon'] as IconData;
                      final active = selectedGenres.contains(name);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (active) {
                                selectedGenres.clear();
                              } else {
                                selectedGenres
                                  ..clear()
                                  ..add(name);
                              }
                            });
                            setSheetState(() {});
                            changed = true;
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? _gold.withValues(alpha: 0.16)
                                  : _surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active
                                    ? _gold
                                    : _gold.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? _deepSurface
                                        : _gold.withValues(alpha: 0.09),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: active ? _gold : _textSecondary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.merriweather(
                                      color: _textPrimary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 160),
                                  child: active
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          key: const ValueKey('selected'),
                                          color: _gold,
                                          size: 19,
                                        )
                                      : Icon(
                                          Icons.circle_outlined,
                                          key: const ValueKey('unselected'),
                                          color: _textSecondary,
                                          size: 18,
                                        ),
                                ),
                              ],
                            ),
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

    return changed;
  }

  Widget _buildSearchPreview() {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return const SizedBox.shrink();
    }

    final previewResults = books.where((book) {
      final title = book['title'].toString().toLowerCase();
      final author = book['authorReal'].toString().toLowerCase();
      final genre = book['genre'].toString().toLowerCase();

      return title.contains(query) ||
          author.contains(query) ||
          genre.contains(query);
    }).take(1).toList();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey(query),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _gold.withValues(alpha: 0.34),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: previewResults.isEmpty
            ? Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      color: _gold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No se encontró nada relacionado con “${searchQuery.trim()}”.',
                      style: GoogleFonts.inter(
                        color: _textSecondary,
                        fontSize: 8.3,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: _gold,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SUGERENCIA',
                        style: GoogleFonts.cinzel(
                          color: _textPrimary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  InkWell(
                    onTap: () => widget.onBookTap(previewResults.first),
                    borderRadius: BorderRadius.circular(11),
                    child: Row(
                      children: [
                        _networkCover(
                          previewResults.first['cover'] as String,
                          width: 44,
                          height: 62,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                previewResults.first['title'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.merriweather(
                                  color: _textPrimary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                previewResults.first['authorReal'] as String,
                                style: GoogleFonts.inter(
                                  color: _textSecondary,
                                  fontSize: 7.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: _gold,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${previewResults.first['rating']}',
                                    style: GoogleFonts.inter(
                                      color: _gold,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _availabilityBadge(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: _gold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = filteredBooks;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                searchController.clear();

                setState(() {
                  searchQuery = '';
                  searchSubmitted = false;
                  showFilters = false;
                  selectedGenres.clear();
                  searchFilter = 'titulo';
                });
                widget.onSearchModeChanged(false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _textPrimary,
                backgroundColor: _surface,
                side: BorderSide(
                  color: _gold.withValues(alpha: 0.55),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 15,
                color: _gold,
              ),
              label: Text(
                'Volver',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'RESULTADOS',
            style: GoogleFonts.cinzel(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${results.length} ${results.length == 1 ? 'obra encontrada' : 'obras encontradas'}',
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 8.5,
            ),
          ),
          if (selectedGenres.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: selectedGenres.map((genre) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    genre,
                    style: GoogleFonts.inter(
                      color: _textPrimary,
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          if (results.isEmpty)
            _emptySearch()
          else
            ...results.asMap().entries.map((entry) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.97, end: 1),
                duration: Duration(
                  milliseconds: 220 + (entry.key * 45),
                ),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: ((value - 0.97) / 0.03).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: value,
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                  );
                },
                child: _buildSearchBook(entry.value),
              );
            }),
        ],
      ),
    );
  }

  Widget _emptySearch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              color: _gold,
              size: 26,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'No encontramos resultados',
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              color: _textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Prueba con otro título, autor o cambia los filtros seleccionados.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 7.8,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBook(Map<String, dynamic> book) {
    final synopsis = book['synopsis']?.toString() ?? '';
    final genre = book['genre']?.toString() ?? '';
    final year = book['year']?.toString() ?? '';

    return InkWell(
      onTap: () => widget.onBookTap(book),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _gold.withValues(alpha: 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _networkCover(
              book['cover'] as String,
              width: 78,
              height: 108,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          book['title'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            color: _textPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: _gold,
                        size: 19,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book['authorReal'] as String,
                    style: GoogleFonts.inter(
                      color: _textSecondary,
                      fontSize: 8.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: _gold,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${book['rating']}',
                        style: GoogleFonts.inter(
                          color: _gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 8.5,
                        ),
                      ),
                      const SizedBox(width: 7),
                      _availabilityBadge(),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      if (genre.isNotEmpty)
                        _searchResultMetaChip(
                          Icons.auto_stories_outlined,
                          genre,
                        ),
                      if (year.isNotEmpty)
                        _searchResultMetaChip(
                          Icons.calendar_today_outlined,
                          year,
                        ),
                    ],
                  ),
                  if (synopsis.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      synopsis,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _textSecondary,
                        fontSize: 7.4,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchResultMetaChip(
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _gold,
            size: 10,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 6.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearch(),
        if (searchSubmitted)
          _buildSearchResults()
        else
          _buildSearchPreview(),
      ],
    );
  }
}
