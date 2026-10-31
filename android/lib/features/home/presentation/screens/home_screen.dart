import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/profile_gender_preference.dart';
import '../../../clubs/models/reading_club.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../library/presentation/widgets/book_interaction_store.dart';
import '../../../writer/models/writer_chapter.dart';
import '../../../writer/models/writer_story.dart';
import '../../../writer/presentation/screens/published_story_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isGuest,
    required this.onOpenLibrary,
    required this.onOpenWriter,
    required this.onOpenPoints,
    required this.onOpenProfile,
    required this.currentName,
    required this.currentUsername,
    required this.reviews,
    required this.onReviewSaved,
    required this.favoriteBookIds,
    required this.onToggleFavoriteBook,
    required this.favoriteCommunityStoryIds,
    required this.onToggleCommunityStoryFavorite,
    required this.clubs,
    required this.joinedClubIds,
    required this.onToggleClub,
    required this.continueReadingBook,
    required this.continueReadingProgress,
    required this.onContinueReadingProgressChanged,
  });

  final bool isGuest;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenWriter;
  final VoidCallback onOpenPoints;
  final VoidCallback onOpenProfile;
  final String currentName;
  final String currentUsername;
  final Map<int, BookReview> reviews;
  final void Function(int bookId, BookReview review) onReviewSaved;

  final Set<int> favoriteBookIds;
  final ValueChanged<int> onToggleFavoriteBook;

  final Set<String> favoriteCommunityStoryIds;
  final ValueChanged<WriterStory> onToggleCommunityStoryFavorite;

  final List<ReadingClub> clubs;
  final Set<int> joinedClubIds;
  final ValueChanged<int> onToggleClub;

  final LibraryBook? continueReadingBook;
  final int continueReadingProgress;
  final void Function(int bookId, int progress)
      onContinueReadingProgressChanged;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController geminiController = TextEditingController();
  final TextEditingController isbnController = TextEditingController();
  final Random random = Random();

  Timer? quoteTimer;

  String searchQuery = '';
  String searchFilter = 'titulo';
  final Set<String> selectedGenres = <String>{};

  bool searchSubmitted = false;
  bool showFilters = false;
  bool showEmptySearchError = false;
  bool showQuoteShare = false;
  String? quoteSharedOn;

  int currentQuote = 0;
  int carouselOffset = 0;

  // Colores adaptativos al tema global.
  Color get _background => AppColors.backgroundOf(context);
  Color get _surface => AppColors.surfaceOf(context);
  Color get _surfaceSoft => AppColors.surfaceSoftOf(context);
  Color get _deepSurface => AppColors.deepOf(context);
  Color get _deepAltSurface => AppColors.deepAltOf(context);
  Color get _textPrimary => AppColors.textPrimaryOf(context);
  Color get _textSecondary => AppColors.textSecondaryOf(context);
  Color get _gold => AppColors.goldOf(context);
  Color get _accent => AppColors.accentOf(context);

  // Colores de contenido sobre fondos oscuros, burdeos o dorados.
  Color get _onDeep => AppColors.isDark(context)
      ? AppColors.darkTextPrimary
      : AppColors.background;
  Color get _onAccent => AppColors.isDark(context)
      ? AppColors.darkTextPrimary
      : AppColors.background;
  Color get _goldInk => AppColors.deep;

  final List<Map<String, String>> quotes = [
    {
      'text': 'No hay encanto igual a la ternura del corazón.',
      'author': 'Jane Austen',
      'work': 'Emma',
    },
    {
      'text': 'El que lee mucho y anda mucho, ve mucho y sabe mucho.',
      'author': 'Miguel de Cervantes',
      'work': 'Don Quijote de la Mancha',
    },
    {
      'text': 'Una historia puede comenzar en cualquier página.',
      'author': 'Capítulo 0',
      'work': '',
    },
    {
      'text': 'A veces un libro llega justo cuando más lo necesitamos.',
      'author': 'Capítulo 0',
      'work': '',
    },
  ];

  final List<Map<String, dynamic>> books = [
    {
      'id': 1,
      'title': 'Orgullo y Prejuicio',
      'author': '@JaneAusten1',
      'authorReal': 'Jane Austen',
      'rating': 4.9,
      'year': 1813,
      'genre': 'Romance Clásico',
      'availability': 'GRATIS',
      'isbn': '978-84-9105-027-8',
      'cover': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400&h=560&fit=crop&auto=format',
      'synopsis': 'Elizabeth Bennet y el enigmático señor Darcy se encuentran envueltos en un juego de prejuicios, primeras impresiones y sentimientos inesperados.',
    },
    {
      'id': 2,
      'title': 'Cumbres Borrascosas',
      'author': 'Emily Brontë',
      'authorReal': 'Emily Brontë',
      'rating': 4.8,
      'year': 1847,
      'genre': 'Ficción Gótica',
      'availability': 'GRATIS',
      'isbn': '978-84-206-6415-6',
      'cover': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=560&fit=crop&auto=format',
      'synopsis': 'En los páramos de Yorkshire, el amor tortuoso entre Heathcliff y Catherine trasciende el tiempo en una historia oscura y apasionada.',
    },
    {
      'id': 3,
      'title': 'Jane Eyre',
      'author': 'Charlotte Brontë',
      'authorReal': 'Charlotte Brontë',
      'rating': 4.7,
      'year': 1847,
      'genre': 'Romance Victoriano',
      'availability': 'GRATIS',
      'isbn': '978-84-9794-061-0',
      'cover': 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400&h=560&fit=crop&auto=format',
      'synopsis': 'Huérfana y sin fortuna, Jane Eyre descubre en Thornfield Hall secretos oscuros y un amor prohibido.',
    },
    {
      'id': 14,
      'title': 'Sentido y Sensibilidad',
      'author': 'Jane Austen',
      'authorReal': 'Jane Austen',
      'rating': 4.6,
      'year': 1811,
      'genre': 'Drama Clásico',
      'availability': 'GRATIS',
      'isbn': '978-84-9105-028-5',
      'cover': 'https://images.unsplash.com/photo-1495640388908-05fa85288e61?w=400&h=560&fit=crop&auto=format',
      'synopsis': 'Las hermanas Dashwood experimentan las dificultades del amor, la decepción y el matrimonio en la sociedad inglesa.',
    },
    {
      'id': 4,
      'title': 'Frankenstein',
      'author': 'Mary Shelley',
      'authorReal': 'Mary Shelley',
      'rating': 4.8,
      'year': 1818,
      'genre': 'Terror Gótico',
      'availability': 'GRATIS',
      'isbn': '978-84-670-4965-7',
      'cover': 'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=400&h=560&fit=crop&auto=format',
      'synopsis': 'Un científico obsesionado desafía las leyes naturales creando una criatura que deberá enfrentarse al rechazo del mundo.',
    },
  ];

  final List<Map<String, String>> stories = [
    {
      'title': 'El Jardín de los Recuerdos',
      'author': 'Valentina Cruz',
      'user': '@valentinacruz',
      'bio': 'Escritora independiente. Historias de memoria, naturaleza y pequeños lugares que guardan grandes recuerdos.',
      'memberSince': 'Enero 2025',
      'extract': '“Las flores que plantamos en silencio son las que más fragantes florecen cuando nadie las mira...”',
      'full':
          'Capítulo 1: El silencio del rosal\n\n'
          'Las flores que plantamos en silencio son las que más fragantes florecen cuando nadie las mira. '
          'Caminé entre los senderos de piedra húmeda recordando que cada hoja caída guardaba una promesa rota.\n\n'
          'Capítulo 2: La memoria del jardín\n\n'
          'El jardín no olvida. Cada primavera vuelve a hablar en el idioma de las semillas que dejamos atrás.',
    },
    {
      'title': 'Cartas desde el Faro',
      'author': '@MarcoIbanez17',
      'user': '@MarcoIbanez17',
      'bio': 'Autor independiente de relatos melancólicos, mar, distancia y personajes que escriben para no olvidar.',
      'memberSince': 'Agosto 2024',
      'extract': '“Cada noche enciendo la luz para los barcos perdidos, sin saber que yo mismo soy el más perdido de todos...”',
      'full':
          'El faro despertaba cada tarde antes que el sol desapareciera detrás del horizonte.\n\n'
          'Yo encendía su luz sin saber si alguien realmente la estaba esperando. '
          'Las cartas seguían llegando, aunque ninguna llevaba remitente.',
    },
    {
      'title': 'Sombras bajo la lluvia',
      'author': '@constanza.lectora',
      'user': '@constanza.lectora',
      'bio': 'Amante de las novelas góticas victorianas y los clásicos de siempre 🌹 Estudiante de Ingeniería en Informática.',
      'memberSince': 'Marzo 2024',
      'extract': 'Una estudiante encuentra cartas anónimas escondidas entre los libros de una vieja biblioteca y descubre que todas parecen dirigidas a ella.',
      'full':
          'La lluvia golpeaba los ventanales de la biblioteca cuando encontré la primera carta.\n\n'
          'No tenía nombre ni fecha. Solo una frase escrita con tinta oscura: '
          '“Si estás leyendo esto, llegaste antes de que fuera demasiado tarde.”',
    },
  ];

  @override
  void initState() {
    super.initState();

    quoteTimer = Timer.periodic(
      const Duration(seconds: 40),
      (_) => _changeQuote(),
    );
  }

  @override
  void dispose() {
    quoteTimer?.cancel();
    searchController.dispose();
    geminiController.dispose();
    isbnController.dispose();
    super.dispose();
  }

  void _changeQuote() {
    if (!mounted || quotes.length < 2) {
      return;
    }

    var next = currentQuote;

    while (next == currentQuote) {
      next = random.nextInt(quotes.length);
    }

    setState(() {
      currentQuote = next;
      showQuoteShare = false;
      quoteSharedOn = null;
    });
  }

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

  ButtonStyle _accentButtonStyle({double height = 31}) {
    return FilledButton.styleFrom(
      backgroundColor: _accent,
      foregroundColor: _onAccent,
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    );
  }

  ButtonStyle _outlineButtonStyle({double height = 31}) {
    return OutlinedButton.styleFrom(
      foregroundColor: _textPrimary,
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: _gold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    );
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

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            if (!searchSubmitted) _buildWelcome(),
            _buildSearch(),
            if (searchSubmitted)
              _buildSearchResults()
            else ...[
              _buildSearchPreview(),
              _buildQuote(),
              _buildContinueReading(),
              _buildRecommendedBooks(),
              _buildReadingClubs(),
              _buildCommunityStories(),
              _buildNearbyReadingPoint(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<ProfileGender>(
            valueListenable: ProfileGenderStore.notifier,
            builder: (context, gender, _) {
              final name = widget.currentName.trim().isEmpty
                  ? 'lector/a'
                  : widget.currentName.trim();

              final greeting = widget.isGuest
                  ? '¡Qué gusto verte en Capítulo 0! ✦'
                  : switch (gender) {
                      ProfileGender.woman => 'Bienvenida, $name ✦',
                      ProfileGender.man => 'Bienvenido, $name ✦',
                      ProfileGender.preferNotToSay ||
                      ProfileGender.selfDescribe =>
                        '¡Qué gusto verte, $name! ✦',
                    };

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  greeting,
                  key: ValueKey(greeting),
                  style: GoogleFonts.cinzel(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué historia quieres descubrir hoy?',
            style: GoogleFonts.merriweather(
              color: _textSecondary,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
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
                        _flashEmptySearchError();
                        return;
                      }

                      setState(() {
                        searchQuery = query;
                        searchSubmitted = true;
                        showFilters = false;
                      });
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
                        _flashEmptySearchError();
                        return;
                      }

                      setState(() {
                        searchQuery = query;
                        searchSubmitted = true;
                        showFilters = false;
                      });
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
                    onTap: () => _showBookDetails(previewResults.first),
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
      onTap: () => _showBookDetails(book),
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

  Widget _buildQuote() {
    final quote = quotes[currentQuote];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: Container(
        key: ValueKey(currentQuote),
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_deepSurface, const Color(0xFF63252D), _deepAltSurface],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: _deepSurface.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 8,
              top: -24,
              child: Text(
                '“',
                style: GoogleFonts.merriweather(
                  fontSize: 84,
                  height: 1,
                  color: _gold.withValues(alpha: 0.09),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: -12,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 54,
                  color: _gold.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _gold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'CITA DEL DÍA',
                          style: GoogleFonts.cinzel(
                            color: _gold,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            showQuoteShare = !showQuoteShare;
                            quoteSharedOn = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            showQuoteShare ? 'Cerrar' : 'Compartir',
                            style: GoogleFonts.inter(
                              color: _gold,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '“${quote['text']}”',
                    style: GoogleFonts.merriweather(
                      color: const Color(0xFFF7EFE2),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${quote['author']}'
                      '${quote['work']!.isEmpty ? '' : ', ${quote['work']}'}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        color: _gold,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showQuoteShare)
              Positioned.fill(
                child: GestureDetector(
                  onTap: quoteSharedOn == null
                      ? () {
                          setState(() {
                            showQuoteShare = false;
                            quoteSharedOn = null;
                          });
                        }
                      : null,
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: const Color(0x8A2B1713),
                      alignment: Alignment.center,
                      child: quoteSharedOn == null
                          ? _buildShareOptions()
                          : _buildSharedConfirmation(quoteSharedOn!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'COMPARTIR',
          style: GoogleFonts.cinzel(
            color: _onDeep,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _shareButton(
              icon: Icons.chat_bubble_rounded,
              platform: 'WhatsApp',
              backgroundColor: const Color(0xFF25D366),
            ),
            const SizedBox(width: 18),
            _shareButton(
              icon: Icons.camera_alt_rounded,
              platform: 'Instagram',
              backgroundColor: const Color(0xFFE95B70),
            ),
            const SizedBox(width: 18),
            _shareButton(
              icon: Icons.facebook_rounded,
              platform: 'Facebook',
              backgroundColor: const Color(0xFF1877F2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shareButton({
    required IconData icon,
    required String platform,
    required Color backgroundColor,
  }) {
    return InkWell(
      onTap: () => _shareQuote(platform),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  Widget _buildSharedConfirmation(String platform) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _gold,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.check_rounded, color: _goldInk, size: 23),
        ),
        const SizedBox(height: 7),
        Text(
          'COMPARTIDO',
          style: GoogleFonts.cinzel(
            color: _onDeep,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'en $platform',
          style: GoogleFonts.inter(
            color: _onDeep.withValues(alpha: 0.82),
            fontSize: 7,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _shareQuote(String platform) async {
    final quote = quotes[currentQuote];

    final text =
        '“${quote['text']}”\n'
        '— ${quote['author']}'
        '${quote['work']!.isEmpty ? '' : ' · ${quote['work']}'}\n\n'
        '📚 Compartido desde Capítulo 0';

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) {
      return;
    }

    setState(() {
      showQuoteShare = true;
      quoteSharedOn = platform;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1350));

    if (!mounted) {
      return;
    }

    setState(() {
      showQuoteShare = false;
      quoteSharedOn = null;
    });
  }

  Widget _buildContinueReading() {
    final book = widget.continueReadingBook;

    if (book == null) {
      return const SizedBox.shrink();
    }

    final progress = widget.continueReadingProgress.clamp(0, 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      child: Column(
        children: [
          _sectionTitle('Continuar Leyendo'),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Container(
              key: ValueKey('${book.id}-$progress'),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _gold.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  _networkCover(
                    book.cover,
                    width: 64,
                    height: 88,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            color: _textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _textSecondary,
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Progreso',
                                style: GoogleFonts.inter(
                                  color: _textSecondary,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                            Text(
                              '$progress%',
                              style: GoogleFonts.inter(
                                color: _accent,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 5,
                            backgroundColor: _surfaceSoft,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_accent),
                          ),
                        ),
                        const SizedBox(height: 9),
                        if (progress < 100)
                          Row(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  if (widget.isGuest) {
                                    _guestMessage('biblioteca');
                                    return;
                                  }

                                  widget.onOpenLibrary();
                                },
                                style: _accentButtonStyle(),
                                child: Text(
                                  'Continuar →',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                onPressed: () =>
                                    _advanceSharedReading(book, progress),
                                style: _outlineButtonStyle(),
                                child: Text(
                                  '+ Avanzar',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7EE),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: const Color(0xFF78935F)
                                    .withValues(alpha: 0.68),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF708A56),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Libro finalizado correctamente',
                                    style: GoogleFonts.merriweather(
                                      color: const Color(0xFF3F4F33),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.auto_stories_rounded,
                                  color: _gold.withValues(alpha: 0.78),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _advanceSharedReading(
    LibraryBook book,
    int currentProgress,
  ) {
    if (widget.isGuest) {
      _guestMessage('progreso de lectura');
      return;
    }

    final nextProgress =
        (currentProgress + 10).clamp(0, 100).toInt();

    widget.onContinueReadingProgressChanged(
      book.id,
      nextProgress,
    );

  }

  Widget _buildRecommendedBooks() {
    final maxOffset = max(0, books.length - 3);
    final visible = books.skip(carouselOffset).take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _sectionTitle('Lecturas Recomendadas')),
                _carouselButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: carouselOffset > 0,
                  onTap: () {
                    setState(() {
                      carouselOffset = max(0, carouselOffset - 1);
                    });
                  },
                ),
                const SizedBox(width: 6),
                _carouselButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: carouselOffset < maxOffset,
                  onTap: () {
                    setState(() {
                      carouselOffset = min(maxOffset, carouselOffset + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(visible.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < visible.length - 1 ? 7 : 0,
                    ),
                    child: SizedBox(
                      height: 226,
                      child: _recommendedBookCard(visible[index]),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carouselButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.35,
        duration: const Duration(milliseconds: 180),
        child: Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? _deepSurface : _surface,
            border: Border.all(color: _gold),
          ),
          child: Icon(icon, color: _gold, size: 16),
        ),
      ),
    );
  }

  Widget _recommendedBookCard(Map<String, dynamic> book) {
    final author = book['author'] as String;
    final isUserAuthor = author.startsWith('@');

    return InkWell(
      onTap: () => _showBookDetails(book),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _gold.withValues(alpha: 0.72),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 122,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _networkCover(
                    book['cover'] as String,
                    width: double.infinity,
                    height: 122,
                    radius: 0,
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.03),
                              Colors.black.withValues(alpha: 0.20),
                            ],
                            stops: const [0.45, 0.72, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.merriweather(
                        color: _textPrimary,
                        fontSize: 8.4,
                        fontWeight: FontWeight.w700,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isUserAuthor ? _accent : _gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color:
                                  isUserAuthor ? _accent : _textSecondary,
                              fontSize: 6.8,
                              fontWeight: isUserAuthor
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E793E).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF2E793E).withValues(alpha: 0.34),
                        ),
                      ),
                      child: Text(
                        'GRATIS',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2E793E),
                          fontSize: 5.6,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: _gold,
                            size: 10.5,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${book['rating']}',
                            style: GoogleFonts.inter(
                              color: _textPrimary,
                              fontSize: 6.7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildReadingClubs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('Clubes de Lectura Activos')),
              TextButton(
                onPressed: _showAllClubs,
                style: TextButton.styleFrom(
                  foregroundColor: _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.inter(
                    color: _accent,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          _clubCard(widget.clubs[0]),
          const SizedBox(height: 8),
          _clubCard(widget.clubs[1]),
        ],
      ),
    );
  }

  Widget _clubCard(ReadingClub club) {
    final id = club.id;
    final joined = widget.joinedClubIds.contains(id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club.name,
            style: GoogleFonts.merriweather(
              color: _textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Leyendo: ${club.book}',
            style: GoogleFonts.inter(color: _textSecondary, fontSize: 8),
          ),
          const SizedBox(height: 4),
          Text(
            '📅 Debate: ${club.date} · ${club.members} lectores',
            style: GoogleFonts.inter(color: _accent, fontSize: 7),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showClubDetails(club),
                  style: _outlineButtonStyle(),
                  child: Text(
                    'Ver',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => _toggleClub(id),
                  style: FilledButton.styleFrom(
                    backgroundColor: joined ? _surfaceSoft : _accent,
                    foregroundColor: joined ? _textPrimary : _onAccent,
                    minimumSize: const Size(0, 31),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    joined ? 'Unido ✓' : 'Unirme',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
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

  void _toggleClub(int id) {
    if (widget.isGuest) {
      _guestMessage('clubes de lectura');
      return;
    }

    widget.onToggleClub(id);
  }

  Widget _buildCommunityStories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('Historias de la Comunidad')),
              TextButton(
                onPressed: () {
                  if (widget.isGuest) {
                    _guestMessage('escribir');
                    return;
                  }
                  widget.onOpenWriter();
                },
                style: TextButton.styleFrom(
                  foregroundColor: _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  '✦ Escribir',
                  style: GoogleFonts.inter(
                    color: _accent,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ...stories.map(_storyCard),
        ],
      ),
    );
  }

  Widget _storyCard(Map<String, String> story) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story['title']!,
            style: GoogleFonts.merriweather(
              color: _textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InkWell(
                onTap: () => _showAuthorProfile(story),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    story['author']!,
                    style: GoogleFonts.inter(
                      color: _accent,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: _accent,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _deepSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Autor Independiente',
                  style: GoogleFonts.inter(
                    color: _gold,
                    fontSize: 6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            story['extract']!,
            style: GoogleFonts.merriweather(
              color: _textPrimary,
              fontSize: 8,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _showStory(story),
            style: _accentButtonStyle(height: 30),
            child: Text(
              'Leer historia completa',
              style: GoogleFonts.inter(
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyReadingPoint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          _sectionTitle('Puntos Lectores Cercanos ☕'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _deepSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                _networkCover(
                  'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=300&h=300&fit=crop',
                  width: 75,
                  height: 75,
                  radius: 10,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CAFÉ LITERARIO PARQUE BALMACEDA',
                        style: GoogleFonts.cinzel(
                          color: _gold,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Providencia · A 1.2 km de ti',
                        style: GoogleFonts.inter(color: _onDeep, fontSize: 7),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: [
                          _placeTag('WiFi libre', accent: true),
                          _placeTag('Silencio'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                FilledButton(
                  onPressed: widget.onOpenPoints,
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _goldInk,
                    minimumSize: const Size(54, 35),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Ver mapa',
                    style: GoogleFonts.inter(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
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

  Widget _placeTag(String text, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: accent ? _accent : _gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: accent ? _accent : _gold.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: accent ? _onAccent : _gold,
          fontSize: 6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    final dividerColor = _textSecondary.withValues(alpha: 0.34);

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: GoogleFonts.cinzel(
              color: _textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: dividerColor,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 8,
                  color: dividerColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkCover(
    String url, {
    required double width,
    required double height,
    double radius = 8,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: _deepSurface,
              alignment: Alignment.center,
              child: Icon(Icons.menu_book_rounded, color: _gold),
            );
          },
        ),
      ),
    );
  }

  void _showBookDetails(Map<String, dynamic> book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeBookDetailScreen(
          book: book,
          currentUsername: widget.currentUsername,
          initialReview: widget.reviews[book['id'] as int],
          onReviewSaved: widget.onReviewSaved,
          initiallyFavorite:
              widget.favoriteBookIds.contains(book['id'] as int),
          onToggleFavorite: () {
            widget.onToggleFavoriteBook(book['id'] as int);
          },
          onOpenOwnProfile: () {
            Navigator.of(context).pop();
            widget.onOpenProfile();
          },
          onAddToLibrary: () {
            if (widget.isGuest) {
              _guestMessage('biblioteca');
              return;
            }

            Navigator.of(context).pop();
            widget.onOpenLibrary();
          },
        ),
      ),
    );
  }

  void showIsbnScanner() {
    isbnController.clear();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF120C0A),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 28,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _gold.withValues(alpha: 0.55)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: _gold, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Escáner ISBN',
                        style: GoogleFonts.cinzel(
                          color: _onDeep,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold, width: 1.5),
                    color: Colors.black,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _ScannerFramePainter()),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            color: _gold,
                            size: 44,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Apunta la cámara al código de barras\ndel libro impreso',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 10,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: isbnController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: _textPrimary, fontSize: 11),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _surface,
                    hintText: 'O escribe un ISBN',
                    hintStyle: GoogleFonts.inter(
                      color: _textSecondary,
                      fontSize: 10,
                    ),
                    prefixIcon: Icon(
                      Icons.numbers_rounded,
                      color: _gold,
                      size: 18,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _gold),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _gold, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _openBookFromIsbn(isbnController.text);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _gold,
                          side: BorderSide(color: _gold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Buscar ISBN'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _showBookDetails(books.first);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Simular lectura'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openBookFromIsbn(String rawIsbn) {
    final normalized = rawIsbn.replaceAll(RegExp(r'[^0-9Xx]'), '');

    if (normalized.isEmpty) {
      _showMessage('Escribe un ISBN para buscarlo.');
      return;
    }

    Map<String, dynamic>? found;
    for (final book in books) {
      final bookIsbn = book['isbn'].toString().replaceAll(
        RegExp(r'[^0-9Xx]'),
        '',
      );
      if (bookIsbn == normalized) {
        found = book;
        break;
      }
    }

    if (found == null) {
      _showMessage('No encontramos ese ISBN en la colección de demostración.');
      return;
    }

    _showBookDetails(found);
  }

  void showGeminiAssistant() {
    geminiController.clear();

    final messages = <Map<String, String>>[
      {
        'role': 'assistant',
        'text': 'Hola ✦ Soy tu asistente literario. Puedo recomendarte lecturas, ayudarte a elegir tu próxima historia o conversar sobre géneros y autores.',
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void sendMessage() {
              final prompt = geminiController.text.trim();
              if (prompt.isEmpty) {
                return;
              }

              setSheetState(() {
                messages.add({'role': 'user', 'text': prompt});
                messages.add({
                  'role': 'assistant',
                  'text': _geminiDemoAnswer(prompt),
                });
                geminiController.clear();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.72,
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: _gold, width: 1.5)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(17, 14, 10, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _deepAltSurface,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: _gold,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gemini AI Literario',
                                  style: GoogleFonts.cinzel(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Asistente de Capítulo 0',
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
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isUser = message['role'] == 'user';

                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 280),
                              margin: const EdgeInsets.only(bottom: 9),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isUser ? _accent : _surface,
                                borderRadius: BorderRadius.circular(10),
                                border: isUser
                                    ? null
                                    : Border.all(
                                        color: _gold.withValues(alpha: 0.4),
                                      ),
                              ),
                              child: Text(
                                message['text']!,
                                style: GoogleFonts.inter(
                                  color: isUser ? _onAccent : _textPrimary,
                                  fontSize: 10,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: geminiController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => sendMessage(),
                              style: GoogleFonts.inter(
                                color: _textPrimary,
                                fontSize: 10,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _surface,
                                hintText: 'Pregúntale a Gemini...',
                                hintStyle: GoogleFonts.inter(
                                  color: _textSecondary,
                                  fontSize: 9,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: BorderSide(
                                    color: _gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: BorderSide(color: _gold),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          SizedBox(
                            width: 42,
                            height: 42,
                            child: FilledButton(
                              onPressed: sendMessage,
                              style: FilledButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: _onAccent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: const Icon(Icons.send_rounded, size: 17),
                            ),
                          ),
                        ],
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

  String _geminiDemoAnswer(String prompt) {
    final q = prompt.toLowerCase();

    if (q.contains('gótic') || q.contains('terror')) {
      return 'Para un ambiente gótico te recomiendo “Rebecca” de Daphne du Maurier, “El retrato de Dorian Gray” de Oscar Wilde y, si quieres algo más intenso, continuar con “Frankenstein”.';
    }

    if (q.contains('romance')) {
      return 'Si buscas romance clásico, empieza por “Orgullo y Prejuicio”. Si prefieres una atmósfera más intensa y oscura, “Jane Eyre” puede gustarte mucho.';
    }

    if (q.contains('recom') || q.contains('leer')) {
      return 'Por tus lecturas actuales, probaría con “Jane Eyre”. Mantiene el tono clásico y emocional, pero agrega misterio y una protagonista con mucha personalidad.';
    }

    return 'Puedo ayudarte con recomendaciones, autores, géneros o con tu próxima lectura. Cuéntame qué tipo de historia tienes ganas de leer hoy.';
  }

  void _showAuthorProfile(Map<String, String> story) {
    final isOwnProfile = story['user'] == '@constanza.lectora';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Perfil literario',
                        style: GoogleFonts.cinzel(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _gold.withValues(alpha: 0.55)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: _surfaceSoft,
                            child: Text(
                              _initials(story['author']!),
                              style: GoogleFonts.cinzel(
                                color: _textPrimary,
                                fontSize: 15,
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
                                  story['author']!,
                                  style: GoogleFonts.merriweather(
                                    color: _textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  story['user']!,
                                  style: GoogleFonts.inter(
                                    color: _accent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Miembro desde ${story['memberSince']}',
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
                      const SizedBox(height: 12),
                      Text(
                        story['bio']!,
                        style: GoogleFonts.merriweather(
                          color: _textPrimary,
                          fontSize: 9,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _profileStat('24', 'Leídos'),
                          _profileStat(
                            isOwnProfile ? '142' : '86',
                            'Seguidores',
                          ),
                          _profileStat(isOwnProfile ? '89' : '51', 'Siguiendo'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OBRA DESTACADA',
                        style: GoogleFonts.cinzel(
                          color: _textPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story['title']!,
                        style: GoogleFonts.merriweather(
                          color: _textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story['extract']!,
                        style: GoogleFonts.merriweather(
                          color: _textPrimary,
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _showStory(story);
                        },
                        style: _accentButtonStyle(),
                        child: const Text('Leer historia'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cinzel(
              color: _accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(color: _textSecondary, fontSize: 7),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final clean = name.replaceAll('@', '').trim();
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, String> _clubExtraData(ReadingClub club) {
    switch (club.id) {
      case 1:
        return {
          'author': '@mariaPaz200',
          'instagram': '@adictosclasicos',
          'facebook': 'Adictos a los Clásicos',
          'x': '@adictosclasicos_x',
        };
      case 2:
        return {
          'author': '@valencruz',
          'instagram': '@mansiongotica',
          'facebook': 'Mansión Gótica',
          'x': '@mansiongotica_club',
        };
      case 3:
        return {
          'author': '@marcoibanez17',
          'instagram': '@plumasdelsur',
          'facebook': 'Plumas del Sur',
          'x': '@plumasdelsur',
        };
      default:
        return {
          'author': '@capitulo0',
          'instagram': '@capitulo0',
          'facebook': 'Capítulo 0',
          'x': '@capitulo0',
        };
    }
  }

  void _showClubDetails(ReadingClub club) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final id = club.id;
        final extra = _clubExtraData(club);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final joined = widget.joinedClubIds.contains(id);

            ReadingClub currentClub = club;
            for (final candidate in widget.clubs) {
              if (candidate.id == id) {
                currentClub = candidate;
                break;
              }
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.58,
              minChildSize: 0.38,
              maxChildSize: 0.84,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DETALLE DEL CLUB',
                              style: GoogleFonts.cinzel(
                                color: _textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.25,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: _gold,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentClub.name,
                                    style: GoogleFonts.merriweather(
                                      color: _textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentClub.description,
                                    style: GoogleFonts.inter(
                                      color: _textPrimary,
                                      fontSize: 9.2,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Autor/a del club: ',
                                        style: GoogleFonts.inter(
                                          color: _textSecondary,
                                          fontSize: 8,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          extra['author']!,
                                          style: GoogleFonts.inter(
                                            color: _accent,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: _accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        color: _accent,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Debate: ${currentClub.date}',
                                          style: GoogleFonts.inter(
                                            color: _textSecondary,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.groups_2_outlined,
                                        color: _deepSurface,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${currentClub.members} lectores',
                                        style: GoogleFonts.inter(
                                          color: _textSecondary,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        currentClub.modality.toLowerCase() ==
                                                'online'
                                            ? Icons.language_rounded
                                            : Icons.location_on_outlined,
                                        color: _deepSurface,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Modalidad: ${currentClub.modality}',
                                        style: GoogleFonts.inter(
                                          color: _textSecondary,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 11),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                13,
                                12,
                                13,
                                8,
                              ),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: _gold.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'REDES SOCIALES',
                                    style: GoogleFonts.cinzel(
                                      color: _textPrimary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _clubSocialRow(
                                    icon: Icons.photo_camera_outlined,
                                    label: 'Instagram:',
                                    value: extra['instagram']!,
                                  ),
                                  _clubSocialDivider(),
                                  _clubSocialRow(
                                    icon: Icons.facebook_outlined,
                                    label: 'Facebook:',
                                    value: extra['facebook']!,
                                  ),
                                  _clubSocialDivider(),
                                  _clubSocialRow(
                                    icon: Icons.close_rounded,
                                    label: 'X:',
                                    value: extra['x']!,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      decoration: BoxDecoration(
                        color: _background,
                        border: Border(
                          top: BorderSide(
                            color: _gold.withValues(alpha: 0.16),
                          ),
                        ),
                      ),
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: () {
                            if (widget.isGuest) {
                              Navigator.of(sheetContext).pop();
                              _guestMessage('clubes de lectura');
                              return;
                            }

                            widget.onToggleClub(id);
                            setSheetState(() {});
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                joined ? _surfaceSoft : _accent,
                            foregroundColor:
                                joined ? _textPrimary : _onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: joined
                                ? BorderSide(
                                    color: _gold.withValues(alpha: 0.55),
                                  )
                                : BorderSide.none,
                          ),
                          child: Text(
                            joined ? 'Salir del club' : 'Unirme al club',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _clubSocialRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: _textSecondary,
            size: 13,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 8,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _accent,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clubSocialDivider() {
    return Divider(
      height: 1,
      color: _gold.withValues(alpha: 0.14),
    );
  }

  void _showAllClubs() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.52,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: _gold.withValues(alpha: 0.34),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 9),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _deepSurface,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _gold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _gold.withValues(alpha: 0.26),
                                ),
                              ),
                              child: Icon(
                                Icons.groups_2_outlined,
                                color: _gold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CLUBES DE LECTURA',
                                    style: GoogleFonts.cinzel(
                                      color: _textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${widget.clubs.length} clubes disponibles para descubrir',
                                    style: GoogleFonts.inter(
                                      color: _textSecondary,
                                      fontSize: 8,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(),
                              splashRadius: 18,
                              icon: Icon(
                                Icons.close_rounded,
                                color: _textPrimary,
                                size: 21,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: _gold.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                          itemCount: widget.clubs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 11),
                          itemBuilder: (context, index) {
                            final club = widget.clubs[index];
                            final id = club.id;
                            final joined =
                                widget.joinedClubIds.contains(id);
                            final isOnline =
                                club.modality.toLowerCase() == 'online';

                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.96, end: 1),
                              duration: Duration(
                                milliseconds: 220 + (index * 45),
                              ),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: ((value - 0.96) / 0.04)
                                      .clamp(0.0, 1.0),
                                  child: Transform.scale(
                                    scale: value,
                                    alignment: Alignment.topCenter,
                                    child: child,
                                  ),
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: joined
                                      ? _gold.withValues(alpha: 0.08)
                                      : _surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: joined
                                        ? _gold.withValues(alpha: 0.72)
                                        : _gold.withValues(alpha: 0.32),
                                    width: joined ? 1.15 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.035,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _deepSurface,
                                            borderRadius:
                                                BorderRadius.circular(11),
                                            border: Border.all(
                                              color: _gold.withValues(
                                                alpha: 0.28,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.auto_stories_outlined,
                                            color: _gold,
                                            size: 19,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      club.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.merriweather(
                                                        color: _textPrimary,
                                                        fontSize: 10.8,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  if (joined)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 7,
                                                        vertical: 3,
                                                      ),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: _gold.withValues(
                                                          alpha: 0.16,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(99),
                                                      ),
                                                      child: Text(
                                                        'UNIDO',
                                                        style:
                                                            GoogleFonts.inter(
                                                          color: _deepSurface,
                                                          fontSize: 6.5,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: 0.45,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Leyendo: ${club.book}',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
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
                                    const SizedBox(height: 11),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _allClubsInfoChip(
                                          icon: Icons.calendar_month_outlined,
                                          text: club.date,
                                        ),
                                        _allClubsInfoChip(
                                          icon: Icons.people_outline_rounded,
                                          text: '${club.members} lectores',
                                        ),
                                        _allClubsInfoChip(
                                          icon: isOnline
                                              ? Icons.language_rounded
                                              : Icons.location_on_outlined,
                                          text: club.modality,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 36,
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                Navigator.of(sheetContext)
                                                    .pop();
                                                _showClubDetails(club);
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: _textPrimary,
                                                side: BorderSide(
                                                  color: _gold.withValues(
                                                    alpha: 0.72,
                                                  ),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                              ),
                                              icon: Icon(
                                                Icons.visibility_outlined,
                                                size: 14,
                                                color: _gold,
                                              ),
                                              label: Text(
                                                'Ver detalles',
                                                style: GoogleFonts.inter(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SizedBox(
                                            height: 36,
                                            child: FilledButton(
                                              onPressed: () {
                                                if (widget.isGuest) {
                                                  Navigator.of(sheetContext)
                                                      .pop();
                                                  _guestMessage(
                                                    'clubes de lectura',
                                                  );
                                                  return;
                                                }

                                                widget.onToggleClub(id);
                                                setSheetState(() {});
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor: joined
                                                    ? _surfaceSoft
                                                    : _accent,
                                                foregroundColor: joined
                                                    ? _textPrimary
                                                    : _onAccent,
                                                side: joined
                                                    ? BorderSide(
                                                        color: _gold.withValues(
                                                          alpha: 0.50,
                                                        ),
                                                      )
                                                    : BorderSide.none,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                              ),
                                              child: AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                child: Text(
                                                  joined
                                                      ? 'Unido ✓'
                                                      : 'Unirme',
                                                  key: ValueKey(joined),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
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
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _allClubsInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: _gold.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: _gold,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showStory(Map<String, String> story) {
    final publishedStory = _communityStoryToWriterStory(story);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublishedStoryScreen(
          story: publishedStory,
          currentUsername: widget.currentUsername,
          authorUsername: story['user'],
          initiallyFavorite:
              widget.favoriteCommunityStoryIds.contains(publishedStory.id),
          onToggleFavorite: () {
            widget.onToggleCommunityStoryFavorite(publishedStory);
          },
        ),
      ),
    );
  }

  WriterStory _communityStoryToWriterStory(
    Map<String, String> story,
  ) {
    final title = story['title']?.trim() ?? '';
    final synopsis = story['extract']?.trim() ?? '';
    final fullText = story['full']?.trim() ?? '';
    final author = story['user']?.trim() ?? '@autor';

    final storyId =
        'community_${_stableCommunityId('$author|$title')}';

    final now = DateTime.now();

    return WriterStory(
      id: storyId,
      title: title,
      synopsis: synopsis,
      genre: 'Ficción',
      coverPath: 'preset:classic',
      status: WriterStoryStatus.published,
      chapters: _communityStoryChapters(
        storyId: storyId,
        fullText: fullText,
        now: now,
      ),
      createdAt: now,
      updatedAt: now,
      followers: 0,
      rating: 0,
    );
  }

  List<WriterChapter> _communityStoryChapters({
    required String storyId,
    required String fullText,
    required DateTime now,
  }) {
    if (fullText.trim().isEmpty) {
      return [
        WriterChapter(
          id: '$storyId-chapter-1',
          title: 'Historia completa',
          content: 'Esta historia todavía no tiene contenido disponible.',
          order: 1,
          isPublished: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }

    final headingPattern = RegExp(
      r'Capítulo\s+(\d+)\s*:\s*([^\n]+)',
      caseSensitive: false,
    );

    final matches = headingPattern.allMatches(fullText).toList();

    if (matches.isEmpty) {
      return [
        WriterChapter(
          id: '$storyId-chapter-1',
          title: 'Historia completa',
          content: fullText,
          order: 1,
          isPublished: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }

    final chapters = <WriterChapter>[];

    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      final nextStart = index + 1 < matches.length
          ? matches[index + 1].start
          : fullText.length;

      var content = fullText
          .substring(match.end, nextStart)
          .trim();

      if (content.isEmpty) {
        content = 'Capítulo sin contenido.';
      }

      final number =
          int.tryParse(match.group(1) ?? '') ?? index + 1;
      final chapterTitle =
          match.group(2)?.trim().isNotEmpty == true
              ? match.group(2)!.trim()
              : 'Capítulo $number';

      chapters.add(
        WriterChapter(
          id: '$storyId-chapter-$number',
          title: chapterTitle,
          content: content,
          order: number,
          isPublished: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    chapters.sort((a, b) => a.order.compareTo(b.order));
    return chapters;
  }

  int _stableCommunityId(String value) {
    var hash = 0x811C9DC5;

    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }

    return hash;
  }

  void _guestMessage(String feature) {
    _showMessage('Inicia sesión para acceder a $feature.');
  }

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
      );
  }
}


class HomeBookDetailScreen extends StatefulWidget {
  const HomeBookDetailScreen({
    super.key,
    required this.book,
    required this.currentUsername,
    required this.initialReview,
    required this.onReviewSaved,
    required this.initiallyFavorite,
    required this.onToggleFavorite,
    required this.onOpenOwnProfile,
    required this.onAddToLibrary,
  });

  final Map<String, dynamic> book;
  final String currentUsername;
  final BookReview? initialReview;
  final void Function(int bookId, BookReview review) onReviewSaved;
  final bool initiallyFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenOwnProfile;
  final VoidCallback onAddToLibrary;

  @override
  State<HomeBookDetailScreen> createState() => _HomeBookDetailScreenState();
}

class _HomeBookDetailScreenState extends State<HomeBookDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  late final List<TextEditingController> _replyControllers;
  final TextEditingController _reviewController = TextEditingController();

  bool _compactHeader = false;
  bool _favorite = false;

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

  String get _title => widget.book['title']?.toString() ?? '';
  String get _author => widget.book['authorReal']?.toString() ?? '';
  String get _authorHandle => widget.book['author']?.toString() ?? '';
  String get _genre => widget.book['genre']?.toString() ?? '';
  String get _cover => widget.book['cover']?.toString() ?? '';
  String get _synopsis => widget.book['synopsis']?.toString() ?? '';
  String get _isbn => widget.book['isbn']?.toString() ?? '';
  int get _year => widget.book['year'] as int? ?? 0;
  double get _bookRating => widget.book['rating'] as double? ?? 0;
  bool get _isFree => widget.book['availability']?.toString() == 'GRATIS';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _replyControllers = List.generate(
      _comments.length,
      (_) => TextEditingController(),
    );

    final bookId = widget.book['id'] as int;
    for (var index = 0; index < _comments.length; index++) {
      _comments[index]['replies'] =
          BookInteractionStore.repliesFor(bookId, index);
    }

    _favorite = widget.initiallyFavorite;

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
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              onPressed: widget.onAddToLibrary,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                'Añadir a mi biblioteca',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
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
                                      widget.book['id'] as int,
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

    widget.onReviewSaved(
      widget.book['id'] as int,
      review,
    );

    setState(() {
      _rating = review.rating;
      _reviewIsPublic = review.isPublic;
      _reviewText = review.text;
      _hasReview = true;
      _reviewEditorOpen = false;
    });
  }



}

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    const corner = 26.0;
    final rect = Rect.fromLTWH(22, 22, size.width - 44, size.height - 44);

    final path = Path()
      ..moveTo(rect.left, rect.top + corner)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + corner, rect.top)
      ..moveTo(rect.right - corner, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + corner)
      ..moveTo(rect.left, rect.bottom - corner)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left + corner, rect.bottom)
      ..moveTo(rect.right - corner, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.bottom - corner);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
