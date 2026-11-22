import 'dart:async';

import 'package:flutter/material.dart';

import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/presentation/catalog_controller.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../profile/data/user_search_repository.dart';
import '../../../profile/domain/user_search_result.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_network_cover.dart';

class HomeSearchSection extends StatefulWidget {
  const HomeSearchSection({
    super.key,
    required this.books,
    this.catalogRepository,
    this.userSearchRepository,
    required this.onBookTap,
    this.onUserTap,
    required this.onSearchModeChanged,
  });

  final CatalogRepository? catalogRepository;
  final UserSearchRepository? userSearchRepository;
  final List<Map<String, dynamic>> books;
  final ValueChanged<Map<String, dynamic>> onBookTap;
  // La navegación hacia otros perfiles se conectará en la fase 2.
  final ValueChanged<String>? onUserTap;
  final ValueChanged<bool> onSearchModeChanged;

  @override
  State<HomeSearchSection> createState() => _HomeSearchSectionState();
}

class _HomeSearchSectionState extends State<HomeSearchSection> {
  final TextEditingController searchController = TextEditingController();

  CatalogController? _catalog;
  CatalogController? _suggestions;
  Timer? _debounce;
  bool _suggestionsPending = false;
  static const _modes = {
    'all': 'Texto libre',
    'title': 'Título',
    'author': 'Autor',
    'isbn': 'ISBN',
  };

  // Cada categoría conserva su carga, resultados y error independientes.
  int _previewGeneration = 0;
  List<UserSearchResult> _previewUsers = [];
  String? _previewError;
  bool _previewUsersLoading = false;
  bool _previewBooksReady = false;

  void _invalidatePreview() {
    _previewGeneration++;
    _debounce?.cancel();
    _suggestionsPending = false;
    _previewUsers = [];
    _previewError = null;
    _previewUsersLoading = false;
    _previewBooksReady = false;
  }

  void _queueSuggestions() {
    _invalidatePreview();
    _suggestions?.clear();
    final query = searchQuery.trim();
    if (query.isEmpty) return;

    final generation = _previewGeneration;
    _suggestionsPending = true;
    _previewUsersLoading = _searchesUsers;
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || generation != _previewGeneration || searchSubmitted) {
        return;
      }
      unawaited(_loadPreview(query, generation));
    });
  }

  Future<void> _loadPreview(String query, int generation) async {
    unawaited(_loadBookPreview(query, generation));
    if (_searchesUsers) {
      unawaited(_loadUserPreview(query, generation));
    }
  }

  Future<void> _loadUserPreview(String query, int generation) async {
    if (!mounted || generation != _previewGeneration || searchSubmitted) return;
    setState(() {
      _previewUsersLoading = true;
      _previewError = null;
    });
    try {
      final users = await widget.userSearchRepository!.searchUsers(query);
      if (!mounted || generation != _previewGeneration || searchSubmitted) {
        return;
      }
      setState(() => _previewUsers = users);
    } catch (_) {
      if (!mounted || generation != _previewGeneration || searchSubmitted) {
        return;
      }
      setState(() => _previewError = 'No pudimos buscar usuarios. Reintentar');
    } finally {
      if (mounted && generation == _previewGeneration && !searchSubmitted) {
        setState(() => _previewUsersLoading = false);
      }
    }
  }

  Future<void> _loadBookPreview(String query, int generation) async {
    if (!mounted || generation != _previewGeneration || searchSubmitted) return;
    setState(() {
      _suggestionsPending = true;
      _previewBooksReady = false;
    });
    await _suggestions?.search(query, mode: _mode);
    if (!mounted || generation != _previewGeneration || searchSubmitted) return;
    setState(() {
      _previewBooksReady = true;
      _suggestionsPending = false;
    });
  }

  void _retryPreview() {
    unawaited(_loadBookPreview(searchQuery.trim(), _previewGeneration));
  }

  String _mode = 'all';
  @override
  void initState() {
    super.initState();
    if (widget.catalogRepository != null) {
      _catalog = CatalogController(widget.catalogRepository!)
        ..addListener(_changed);
      _suggestions = CatalogController(widget.catalogRepository!)
        ..addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool get _bookFiltersActive =>
      _mode != 'all' || selectedGenres.isNotEmpty || searchFilter != 'titulo';

  bool get _searchesUsers =>
      widget.userSearchRepository != null && !_bookFiltersActive;

  void _submitSearch() {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      _resetSearch();
      unawaited(_flashEmptySearchError());
      return;
    }
    setState(() {
      searchQuery = query;
      searchSubmitted = true;
      showFilters = false;
    });
    widget.onSearchModeChanged(true);
    _search();
  }

  void _resetSearch({bool resetFilters = false}) {
    _invalidatePreview();
    _suggestions?.clear();
    _catalog?.clear();
    searchController.clear();
    setState(() {
      _invalidateUserSearch();
      _bookResults = [];
      _booksLoading = false;
      _bookError = null;
      searchQuery = '';
      searchSubmitted = false;
      showFilters = false;
      if (resetFilters) {
        selectedGenres.clear();
        searchFilter = 'titulo';
        _mode = 'all';
      }
    });
    widget.onSearchModeChanged(false);
  }

  void _search() {
    _invalidatePreview();
    _suggestions?.clear();
    final query = searchController.text.trim();
    _invalidateUserSearch();
    final generation = _searchGeneration;
    if (query.isEmpty) return;

    unawaited(_searchBooks(query, generation));
    if (_searchesUsers) {
      unawaited(_searchUsers(query, generation));
    }
  }

  Future<void> _searchBooks(String query, int generation) async {
    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _booksLoading = true;
      _bookError = null;
      _bookResults = [];
    });
    if (_catalog == null) {
      if (mounted && generation == _searchGeneration) {
        setState(() => _booksLoading = false);
      }
      return;
    }
    try {
      await _catalog!.search(query, mode: _mode);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _bookResults = List<Map<String, dynamic>>.of(_catalog!.items);
        _booksLoading = false;
        _bookError = _catalog!.error;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _booksLoading = false;
        _bookError = 'No pudimos buscar libros. Inténtalo nuevamente.';
      });
    }
  }

  Future<void> _loadMoreBooks() async {
    final catalog = _catalog;
    if (catalog == null || catalog.loading || _booksLoading) return;
    final generation = _searchGeneration;
    try {
      await catalog.more();
      if (!mounted || generation != _searchGeneration) {
        return;
      }
      setState(() {
        _bookResults = List<Map<String, dynamic>>.of(catalog.items);
        _bookError = catalog.error;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _bookError = 'No se pudieron cargar más libros.';
      });
    }
  }

  Future<void> _searchUsers(String query, int generation) async {
    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _usersLoading = true;
      _usersError = null;
    });
    try {
      final users = await widget.userSearchRepository!.searchUsers(query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _userResults = users);
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _usersError = 'No pudimos buscar usuarios. Revisa tu conexión e inténtalo nuevamente.';
      });
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _usersLoading = false);
      }
    }
  }

  void _retryBooks() {
    if (_catalog?.next != null) {
      unawaited(_loadMoreBooks());
    } else {
      unawaited(_searchBooks(searchQuery.trim(), _searchGeneration));
    }
  }

  String searchQuery = '';
  String searchFilter = 'titulo';
  final Set<String> selectedGenres = <String>{};

  bool searchSubmitted = false;
  bool showFilters = false;
  bool showEmptySearchError = false;

  List<UserSearchResult> _userResults = [];

  bool _usersLoading = false;

  String? _usersError;

  int _searchGeneration = 0;

  bool _booksLoading = false;
  String? _bookError;
  List<Map<String, dynamic>> _bookResults = [];

  void _invalidateUserSearch() {
    _searchGeneration++;
    _userResults = [];
    _usersLoading = false;
    _usersError = null;
  }

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

  List<Map<String, dynamic>> get books =>
      searchSubmitted && _catalog != null ? _bookResults : widget.books;

  List<Map<String, dynamic>> get filteredBooks {
    final query = searchQuery.trim().toLowerCase();

    var result = [...books];

    if (query.isNotEmpty && _catalog == null) {
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
    _invalidatePreview();
    _searchGeneration++;
    _suggestions
      ?..removeListener(_changed)
      ..dispose();
    _catalog
      ?..removeListener(_changed)
      ..dispose();
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
    String title = '',
    String author = '',
  }) {
    return HomeNetworkCover(
      url: url,
      title: title,
      author: author,
      width: width,
      height: height,
      radius: radius,
    );
  }

  Widget _availabilityBadge(Map<String, dynamic> book) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2E793E),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: Text(
        book['availability'] == 'GRATIS' ? 'Gratis' : 'Lectura externa',
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
                color: showEmptySearchError ? _accent : _gold,
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
                Icon(Icons.search_rounded, color: _gold, size: 16),
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
                      hintText: 'Buscar libros o usuarios...',
                      hintStyle: GoogleFonts.inter(
                        color: _textSecondary,
                        fontSize: 10,
                      ),
                      isDense: true,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      suffixIcon: searchQuery.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => _resetSearch(),
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
                        _invalidateUserSearch();
                        _bookResults = [];
                        _booksLoading = false;
                        _bookError = null;
                        searchQuery = value;
                        searchSubmitted = false;
                        _catalog?.clear();
                        _queueSuggestions();
                      });
                      widget.onSearchModeChanged(false);
                    },
                    onSubmitted: (_) => _submitSearch(),
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
                      side: BorderSide(color: _gold, width: 1),
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
                    onPressed: _submitSearch,
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
                  top: BorderSide(color: _gold.withValues(alpha: 0.34)),
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
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(Icons.close_rounded, color: _textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_catalog != null) ...[
                      for (final mode in _modes.entries)
                        _searchFilterMenuTile(
                          icon: _mode == mode.key
                              ? Icons.check_circle_outline
                              : Icons.search_rounded,
                          title: mode.value,
                          value: _mode == mode.key
                              ? 'Seleccionado'
                              : 'Buscar por ${mode.value.toLowerCase()}',
                          onTap: () {
                            setState(() {
                              _mode = mode.key;
                              _queueSuggestions();
                            });
                            setSheetState(() {});
                          },
                        ),
                      const SizedBox(height: 8),
                    ],
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
                        searchFilter == 'calificados' ||
                        _mode != 'all') ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedGenres.clear();
                              searchFilter = 'titulo';
                              _mode = 'all';
                              _queueSuggestions();
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
                            searchSubmitted = searchController.text
                                .trim()
                                .isNotEmpty;
                          });
                          widget.onSearchModeChanged(searchSubmitted);
                          if (searchSubmitted) {
                            _search();
                          } else {
                            setState(() {
                              _invalidateUserSearch();
                              _bookResults = [];
                              _booksLoading = false;
                              _bookError = null;
                            });
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 16),
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
          border: Border.all(color: _gold.withValues(alpha: 0.38)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _gold, size: 19),
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
              style: GoogleFonts.inter(color: _textSecondary, fontSize: 7.5),
            ),
            const SizedBox(width: 5),
            Icon(Icons.chevron_right_rounded, color: _gold, size: 18),
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
                      top: BorderSide(color: _gold.withValues(alpha: 0.34)),
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
                              onPressed: () => Navigator.of(sheetContext).pop(),
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
                                _queueSuggestions();
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
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
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

    return Column(
      children: [
        _buildBookPreview(query),
        if (_searchesUsers)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USUARIOS',
                  style: GoogleFonts.cinzel(
                    color: _textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_previewUsersLoading) const LinearProgressIndicator(),
                if (_previewError != null)
                  TextButton(
                    key: const ValueKey('retry-user-preview'),
                    onPressed: () => unawaited(
                      _loadUserPreview(searchQuery.trim(), _previewGeneration),
                    ),
                    child: Text(_previewError!),
                  ),
                if (!_previewUsersLoading &&
                    _previewError == null &&
                    _previewUsers.isEmpty)
                  const Text('No se encontraron usuarios.'),
                for (final user in _previewUsers) _buildUserRow(user),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBookPreview(String query) {
    final previewResults = _suggestions != null
        ? _suggestions!.items.take(1).toList()
        : books
              .where((book) {
                final title = book['title'].toString().toLowerCase();
                final author = book['authorReal'].toString().toLowerCase();
                final genre = book['genre'].toString().toLowerCase();

                return title.contains(query) ||
                    author.contains(query) ||
                    genre.contains(query);
              })
              .take(1)
              .toList();

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
          border: Border.all(color: _gold.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child:
            _suggestionsPending || (_suggestions != null && !_previewBooksReady)
            ? const LinearProgressIndicator()
            : _suggestions?.error != null
            ? TextButton(
                onPressed: _retryPreview,
                child: const Text(
                  'No se pudieron cargar sugerencias. Reintentar',
                ),
              )
            : previewResults.isEmpty
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
                      'No se encontraron libros relacionados con “${searchQuery.trim()}”.',
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
                      Icon(Icons.search_rounded, color: _gold, size: 14),
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
                          title: previewResults.first['title'] as String? ?? '',
                          author:
                              previewResults.first['author'] as String? ?? '',
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
                                  _availabilityBadge(previewResults.first),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: _gold),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUserResults() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USUARIOS',
            style: GoogleFonts.cinzel(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          if (_usersLoading) const LinearProgressIndicator(),
          if (_usersError != null) ...[
            Text(_usersError!, style: GoogleFonts.inter(color: _textPrimary)),
            TextButton(
              key: const ValueKey('retry-users'),
              onPressed: () => unawaited(
                _searchUsers(searchQuery.trim(), _searchGeneration),
              ),
              child: const Text('Reintentar usuarios'),
            ),
          ],
          if (!_usersLoading && _usersError == null)
            Text(
              '${_userResults.length} ${_userResults.length == 1 ? 'usuario encontrado' : 'usuarios encontrados'}',
              style: GoogleFonts.inter(color: _textSecondary, fontSize: 8.5),
            ),
          const SizedBox(height: 12),
          for (final user in _userResults) _buildUserRow(user),
        ],
      ),
    );
  }

  Widget _buildUserRow(UserSearchResult user) {
    final displayName = user.displayName?.trim();
    final name = displayName == null || displayName.isEmpty
        ? user.username
        : displayName;
    final avatarUrl = user.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return InkWell(
      // El perfil visitante se implementará en la siguiente fase.
      onTap: widget.onUserTap == null
          ? null
          : () => widget.onUserTap!(user.username),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _gold.withValues(alpha: 0.38)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _gold.withValues(alpha: 0.13),
              foregroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
              child: Text(
                initial,
                style: GoogleFonts.cinzel(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.merriweather(
                      color: _textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniversalResults() {
    return Column(
      children: [
        _buildSearchResults(),
        if (_searchesUsers) _buildUserResults(),
      ],
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
              onPressed: () => _resetSearch(resetFilters: true),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textPrimary,
                backgroundColor: _surface,
                side: BorderSide(color: _gold.withValues(alpha: 0.55)),
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
              icon: Icon(Icons.arrow_back_rounded, size: 15, color: _gold),
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
            _mode == 'author'
                ? 'LIBROS DEL AUTOR: ${searchController.text.trim()}'
                : 'LIBROS',
            style: GoogleFonts.cinzel(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          if (!_booksLoading && _bookError == null && _catalog?.error == null)
            Text(
              '${results.length} ${results.length == 1 ? 'obra encontrada' : 'obras encontradas'}',
              style: GoogleFonts.inter(color: _textSecondary, fontSize: 8.5),
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
                    border: Border.all(color: _gold.withValues(alpha: 0.28)),
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
          if (_booksLoading) const LinearProgressIndicator(),
          if (_bookError != null || _catalog?.error != null)
            TextButton(
              key: const ValueKey('retry-books'),
              onPressed: _catalog?.loading == true ? null : _retryBooks,
              child: Text('${_bookError ?? _catalog?.error} Reintentar libros'),
            ),
          if (!_booksLoading &&
              _bookError == null &&
              _catalog?.error == null &&
              results.isEmpty)
            _emptySearch(),
          if (!_booksLoading)
            ...results.asMap().entries.map((entry) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.97, end: 1),
                duration: Duration(milliseconds: 220 + (entry.key * 45)),
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
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
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
            child: Icon(Icons.search_off_rounded, color: _gold, size: 26),
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
          border: Border.all(color: _gold.withValues(alpha: 0.38)),
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
              title: book['title'] as String? ?? '',
              author: book['author'] as String? ?? '',
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
                      Icon(Icons.chevron_right_rounded, color: _gold, size: 19),
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
                      Icon(Icons.star_rounded, color: _gold, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        book['googleVolumeId'] != null
                            ? 'Sin valorar'
                            : '${book['rating']}',
                        style: GoogleFonts.inter(
                          color: _gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 8.5,
                        ),
                      ),
                      const SizedBox(width: 7),
                      _availabilityBadge(book),
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

  Widget _searchResultMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: 10),
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
          _buildUniversalResults()
        else
          _buildSearchPreview(),
        if (searchSubmitted && !_booksLoading && _catalog?.next != null)
          TextButton(
            onPressed: _catalog!.loading ? null : _loadMoreBooks,
            child: const Text('Más resultados'),
          ),
      ],
    );
  }
}
