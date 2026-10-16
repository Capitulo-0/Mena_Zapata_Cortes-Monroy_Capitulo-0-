import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isGuest,
    required this.onOpenLibrary,
    required this.onOpenWriter,
    required this.onOpenPoints,
  });

  final bool isGuest;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenWriter;
  final VoidCallback onOpenPoints;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController geminiController = TextEditingController();
  final TextEditingController isbnController = TextEditingController();
  final Random random = Random();

  Timer? quoteTimer;

  String searchQuery = '';
  String searchFilter = 'titulo';

  bool searchSubmitted = false;
  bool showFilters = false;
  bool showQuoteShare = false;
  String? quoteSharedOn;

  int currentQuote = 0;
  int carouselOffset = 0;

  int currentChapter = 4;
  int currentProgress = 65;

  final Set<int> joinedClubs = {};

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
      'cover':
      'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400&h=560&fit=crop&auto=format',
      'synopsis':
      'Elizabeth Bennet y el enigmático señor Darcy se encuentran envueltos en un juego de prejuicios, primeras impresiones y sentimientos inesperados.',
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
      'cover':
      'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=560&fit=crop&auto=format',
      'synopsis':
      'En los páramos de Yorkshire, el amor tortuoso entre Heathcliff y Catherine trasciende el tiempo en una historia oscura y apasionada.',
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
      'cover':
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400&h=560&fit=crop&auto=format',
      'synopsis':
      'Huérfana y sin fortuna, Jane Eyre descubre en Thornfield Hall secretos oscuros y un amor prohibido.',
    },
    {
      'id': 4,
      'title': 'Sentido y Sensibilidad',
      'author': 'Jane Austen',
      'authorReal': 'Jane Austen',
      'rating': 4.6,
      'year': 1811,
      'genre': 'Drama Clásico',
      'availability': 'GRATIS',
      'isbn': '978-84-9105-028-5',
      'cover':
      'https://images.unsplash.com/photo-1495640388908-05fa85288e61?w=400&h=560&fit=crop&auto=format',
      'synopsis':
      'Las hermanas Dashwood experimentan las dificultades del amor, la decepción y el matrimonio en la sociedad inglesa.',
    },
    {
      'id': 5,
      'title': 'Frankenstein',
      'author': 'Mary Shelley',
      'authorReal': 'Mary Shelley',
      'rating': 4.8,
      'year': 1818,
      'genre': 'Terror Gótico',
      'availability': 'GRATIS',
      'isbn': '978-84-670-4965-7',
      'cover':
      'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=400&h=560&fit=crop&auto=format',
      'synopsis':
      'Un científico obsesionado desafía las leyes naturales creando una criatura que deberá enfrentarse al rechazo del mundo.',
    },
  ];

  final List<Map<String, dynamic>> clubs = [
    {
      'id': 1,
      'name': 'Adictos a los Clásicos ☕',
      'members': 342,
      'book': 'Cumbres Borrascosas',
      'date': 'Viernes 20:00',
      'description':
      'Un espacio para quienes aman los grandes clásicos de la literatura universal. Cada semana conversamos sobre capítulos, personajes y contexto histórico.',
    },
    {
      'id': 2,
      'name': 'Mansión Gótica 🕯️',
      'members': 189,
      'book': 'Jane Eyre',
      'date': 'Sábado 18:30',
      'description':
      'Para amantes de la literatura gótica y victoriana. Misterio, romanticismo oscuro y personajes inolvidables.',
    },
    {
      'id': 3,
      'name': 'Plumas del Sur ✍️',
      'members': 98,
      'book': 'El Jardín de los Recuerdos',
      'date': 'Miércoles 19:00',
      'description':
      'Club dedicado a literatura latinoamericana contemporánea y autores independientes.',
    },
  ];

  final List<Map<String, String>> stories = [
    {
      'title': 'El Jardín de los Recuerdos',
      'author': 'Valentina Cruz',
      'user': '@valentinacruz',
      'bio':
      'Escritora independiente. Historias de memoria, naturaleza y pequeños lugares que guardan grandes recuerdos.',
      'memberSince': 'Enero 2025',
      'extract':
      '“Las flores que plantamos en silencio son las que más fragantes florecen cuando nadie las mira...”',
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
      'bio':
      'Autor independiente de relatos melancólicos, mar, distancia y personajes que escriben para no olvidar.',
      'memberSince': 'Agosto 2024',
      'extract':
      '“Cada noche enciendo la luz para los barcos perdidos, sin saber que yo mismo soy el más perdido de todos...”',
      'full':
      'El faro despertaba cada tarde antes que el sol desapareciera detrás del horizonte.\n\n'
          'Yo encendía su luz sin saber si alguien realmente la estaba esperando. '
          'Las cartas seguían llegando, aunque ninguna llevaba remitente.',
    },
    {
      'title': 'Sombras bajo la lluvia',
      'author': '@constanza.lectora',
      'user': '@constanza.lectora',
      'bio':
      'Amante de las novelas góticas victorianas y los clásicos de siempre 🌹 Estudiante de Ingeniería en Informática.',
      'memberSince': 'Marzo 2024',
      'extract':
      'Una estudiante encuentra cartas anónimas escondidas entre los libros de una vieja biblioteca y descubre que todas parecen dirigidas a ella.',
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
      if (searchFilter == 'autor') {
        result = result.where((book) {
          return book['authorReal'].toString().toLowerCase().contains(query);
        }).toList();
      } else {
        result = result.where((book) {
          final title = book['title'].toString().toLowerCase();
          final author = book['authorReal'].toString().toLowerCase();
          return title.contains(query) || author.contains(query);
        }).toList();
      }
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
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.background,
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }

  ButtonStyle _outlineButtonStyle({double height = 31}) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.deep,
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: const BorderSide(color: AppColors.gold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            _buildTopHeader(),
            _buildWelcome(),
            _buildSearch(),
            if (searchSubmitted)
              _buildSearchResults()
            else ...[
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

  Widget _buildTopHeader() {
    return Container(
      color: AppColors.deep,
      padding: const EdgeInsets.fromLTRB(15, 10, 13, 10),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_capitulo0.png',
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'CAPÍTULO 0',
              style: GoogleFonts.cinzel(
                color: AppColors.gold,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.7,
              ),
            ),
          ),
          if (widget.isGuest)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                'Invitado',
                style: GoogleFonts.inter(
                  color: AppColors.gold,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          _headerButton(
            icon: Icons.qr_code_scanner_rounded,
            tooltip: 'Escanear ISBN',
            onTap: _showIsbnScanner,
          ),
          const SizedBox(width: 6),
          _headerButton(
            icon: Icons.auto_awesome_rounded,
            tooltip: 'Asistente Gemini',
            onTap: _showGeminiAssistant,
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.28),
            ),
            color: AppColors.deepAlt,
          ),
          child: Icon(icon, size: 18, color: AppColors.gold),
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
          Text(
            widget.isGuest
                ? 'Bienvenida a Capítulo 0 ✦'
                : 'Bienvenida, Constanza Mena ✦',
            style: GoogleFonts.cinzel(
              color: AppColors.deep,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué historia quieres descubrir hoy?',
            style: GoogleFonts.merriweather(
              color: AppColors.textSecondary,
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
          Container(
            height: 42,
            padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.gold,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Buscar libros...',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    onSubmitted: (_) {
                      setState(() {
                        searchSubmitted = true;
                        showFilters = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  height: 27,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        showFilters = !showFilters;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.deep,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 27),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Filtrar',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  height: 27,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        searchSubmitted = true;
                        showFilters = false;
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      minimumSize: const Size(0, 27),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
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
          if (showFilters) ...[
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.45),
                ),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _filterChip('Título', 'titulo'),
                  _filterChip('Autor', 'autor'),
                  _filterChip('Recientes', 'recientes'),
                  _filterChip('Mejor calificados', 'calificados'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = searchFilter == value;

    return InkWell(
      onTap: () {
        setState(() {
          searchFilter = value;
        });
      },
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.deep : AppColors.background,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.gold),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? AppColors.gold : AppColors.deep,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = filteredBooks;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resultados',
                  style: GoogleFonts.cinzel(
                    color: AppColors.deep,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  searchController.clear();
                  setState(() {
                    searchQuery = '';
                    searchSubmitted = false;
                    showFilters = false;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 15),
                label: const Text('Volver'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${results.length} obra(s)',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 10),
          if (results.isEmpty)
            _emptySearch()
          else
            ...results.map(_buildSearchBook),
        ],
      ),
    );
  }

  Widget _emptySearch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            color: AppColors.gold,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            'No encontramos libros con esa búsqueda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBook(Map<String, dynamic> book) {
    return InkWell(
      onTap: () => _showBookDetails(book),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.42),
          ),
        ),
        child: Row(
          children: [
            _networkCover(book['cover'] as String, width: 49, height: 69),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'] as String,
                    style: GoogleFonts.merriweather(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book['authorReal'] as String,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold,
                        size: 13,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${book['rating']}',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(width: 7),
                      _availabilityBadge(),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
          ],
        ),
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.deep, Color(0xFF63252D), Color(0xFF3A1D17)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deep.withValues(alpha: 0.12),
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
                  color: AppColors.gold.withValues(alpha: 0.09),
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
                  color: AppColors.gold.withValues(alpha: 0.06),
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
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'CITA DEL DÍA',
                          style: GoogleFonts.cinzel(
                            color: AppColors.gold,
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
                              color: AppColors.gold.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            showQuoteShare ? 'Cerrar' : 'Compartir',
                            style: GoogleFonts.inter(
                              color: AppColors.gold,
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
                        color: AppColors.gold,
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
            color: AppColors.background,
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
            color: AppColors.gold,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.deep,
            size: 23,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'COMPARTIDO',
          style: GoogleFonts.cinzel(
            color: AppColors.background,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'en $platform',
          style: GoogleFonts.inter(
            color: AppColors.background.withValues(alpha: 0.82),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      child: Column(
        children: [
          _sectionTitle('Continuar Leyendo'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                _networkCover(
                  books[1]['cover'] as String,
                  width: 64,
                  height: 88,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cumbres Borrascosas',
                        style: GoogleFonts.merriweather(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Capítulo $currentChapter de 12',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
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
                                color: AppColors.textSecondary,
                                fontSize: 8,
                              ),
                            ),
                          ),
                          Text(
                            '$currentProgress%',
                            style: GoogleFonts.inter(
                              color: AppColors.accent,
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
                          value: currentProgress / 100,
                          minHeight: 5,
                          backgroundColor: AppColors.surfaceSoft,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      if (currentProgress < 100)
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
                              onPressed: _advanceReading,
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
                        FilledButton.icon(
                          onPressed: () {
                            _showMessage(
                              'Cumbres Borrascosas quedó marcado como leído.',
                            );
                          },
                          icon: const Icon(Icons.check_rounded, size: 15),
                          label: const Text('Marcar como leído'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.deep,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _advanceReading() {
    if (widget.isGuest) {
      _guestMessage('progreso de lectura');
      return;
    }

    setState(() {
      currentProgress = (currentProgress + 8).clamp(0, 100).toInt();
      if (currentChapter < 12) {
        currentChapter++;
      }
    });

    _showMessage(
      currentProgress >= 100
          ? '¡Terminaste el libro!'
          : 'Progreso actualizado a $currentProgress%.',
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
                      height: 204,
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
            color: enabled ? AppColors.deep : AppColors.surface,
            border: Border.all(color: AppColors.gold),
          ),
          child: Icon(icon, color: AppColors.gold, size: 16),
        ),
      ),
    );
  }

  Widget _recommendedBookCard(Map<String, dynamic> book) {
    return InkWell(
      onTap: () => _showBookDetails(book),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.gold),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _networkCover(
                  book['cover'] as String,
                  width: double.infinity,
                  height: 128,
                  radius: 0,
                ),
                Positioned(right: 5, top: 5, child: _availabilityBadge()),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      child: Text(
                        book['title'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.merriweather(
                          color: AppColors.textPrimary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 13,
                      child: Text(
                        book['author'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: (book['author'] as String).startsWith('@')
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          fontSize: 7,
                          fontWeight: (book['author'] as String).startsWith('@')
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 11,
                        ),
                        Text(
                          ' ${book['rating']}',
                          style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
                  foregroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.inter(
                    color: AppColors.accent,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          _clubCard(clubs[0]),
          const SizedBox(height: 8),
          _clubCard(clubs[1]),
        ],
      ),
    );
  }

  Widget _clubCard(Map<String, dynamic> club) {
    final id = club['id'] as int;
    final joined = joinedClubs.contains(id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club['name'] as String,
            style: GoogleFonts.merriweather(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Leyendo: ${club['book']}',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '📅 Debate: ${club['date']} · ${club['members']} lectores',
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontSize: 7,
            ),
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
                    backgroundColor:
                    joined ? AppColors.surfaceSoft : AppColors.accent,
                    foregroundColor:
                    joined ? AppColors.deep : AppColors.background,
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

    setState(() {
      if (joinedClubs.contains(id)) {
        joinedClubs.remove(id);
      } else {
        joinedClubs.add(id);
      }
    });
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
                  foregroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  '✦ Escribir',
                  style: GoogleFonts.inter(
                    color: AppColors.accent,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story['title']!,
            style: GoogleFonts.merriweather(
              color: AppColors.textPrimary,
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
                      color: AppColors.accent,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.accent,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.deep,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Autor Independiente',
                  style: GoogleFonts.inter(
                    color: AppColors.gold,
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
              color: AppColors.textPrimary,
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
              color: AppColors.deep,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.45),
              ),
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
                          color: AppColors.gold,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Providencia · A 1.2 km de ti',
                        style: GoogleFonts.inter(
                          color: AppColors.background,
                          fontSize: 7,
                        ),
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
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.deep,
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
        color: accent
            ? AppColors.accent
            : AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: accent
              ? AppColors.accent
              : AppColors.gold.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: accent ? AppColors.background : AppColors.gold,
          fontSize: 6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cinzel(
                color: AppColors.deep,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
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
              color: AppColors.deep,
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.gold,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showBookDetails(Map<String, dynamic> book) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 25),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle del libro',
                        style: GoogleFonts.cinzel(
                          color: AppColors.deep,
                          fontSize: 16,
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
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _networkCover(
                      book['cover'] as String,
                      width: 95,
                      height: 135,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title'] as String,
                            style: GoogleFonts.merriweather(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            book['authorReal'] as String,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '★ ${book['rating']}',
                            style: GoogleFonts.inter(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${book['genre']} · ${book['year']}',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'ISBN: ${book['isbn']}',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Sinopsis',
                  style: GoogleFonts.cinzel(
                    color: AppColors.deep,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  book['synopsis'] as String,
                  style: GoogleFonts.merriweather(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      if (widget.isGuest) {
                        _guestMessage('biblioteca');
                        return;
                      }
                      widget.onOpenLibrary();
                    },
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('Ver en Mi Biblioteca'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
  }

  void _showIsbnScanner() {
    isbnController.clear();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF120C0A),
          insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Escáner ISBN',
                        style: GoogleFonts.cinzel(
                          color: AppColors.background,
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
                    border: Border.all(
                      color: AppColors.gold,
                      width: 1.5,
                    ),
                    color: Colors.black,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ScannerFramePainter(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.document_scanner_outlined,
                            color: AppColors.gold,
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
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    hintText: 'O escribe un ISBN',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    prefixIcon: const Icon(
                      Icons.numbers_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.gold,
                        width: 1.5,
                      ),
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
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold),
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
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
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
      final bookIsbn = book['isbn'].toString().replaceAll(RegExp(r'[^0-9Xx]'), '');
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

  void _showGeminiAssistant() {
    geminiController.clear();

    final messages = <Map<String, String>>[
      {
        'role': 'assistant',
        'text':
        'Hola ✦ Soy tu asistente literario. Puedo recomendarte lecturas, ayudarte a elegir tu próxima historia o conversar sobre géneros y autores.',
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
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: AppColors.gold, width: 1.5),
                  ),
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
                              color: AppColors.deepAlt,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.45),
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.gold,
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
                                    color: AppColors.deep,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Asistente de Capítulo 0',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
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
                                color: isUser
                                    ? AppColors.accent
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: isUser
                                    ? null
                                    : Border.all(
                                  color: AppColors.gold.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                message['text']!,
                                style: GoogleFonts.inter(
                                  color: isUser
                                      ? AppColors.background
                                      : AppColors.textPrimary,
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
                                color: AppColors.textPrimary,
                                fontSize: 10,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface,
                                hintText: 'Pregúntale a Gemini...',
                                hintStyle: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: BorderSide(
                                    color: AppColors.gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: const BorderSide(
                                    color: AppColors.gold,
                                  ),
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
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.background,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                size: 17,
                              ),
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
      backgroundColor: AppColors.background,
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
                          color: AppColors.deep,
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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.surfaceSoft,
                            child: Text(
                              _initials(story['author']!),
                              style: GoogleFonts.cinzel(
                                color: AppColors.deep,
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
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  story['user']!,
                                  style: GoogleFonts.inter(
                                    color: AppColors.accent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Miembro desde ${story['memberSince']}',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
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
                          color: AppColors.textPrimary,
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
                          _profileStat(
                            isOwnProfile ? '89' : '51',
                            'Siguiendo',
                          ),
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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OBRA DESTACADA',
                        style: GoogleFonts.cinzel(
                          color: AppColors.deep,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story['title']!,
                        style: GoogleFonts.merriweather(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story['extract']!,
                        style: GoogleFonts.merriweather(
                          color: AppColors.textPrimary,
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
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 7,
            ),
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

  void _showClubDetails(Map<String, dynamic> club) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final id = club['id'] as int;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final joined = joinedClubs.contains(id);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club['name'] as String,
                    style: GoogleFonts.cinzel(
                      color: AppColors.deep,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Leyendo: ${club['book']}',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '📅 ${club['date']} · ${club['members']} lectores',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    club['description'] as String,
                    style: GoogleFonts.merriweather(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (widget.isGuest) {
                          Navigator.of(sheetContext).pop();
                          _guestMessage('clubes de lectura');
                          return;
                        }

                        setState(() {
                          if (joinedClubs.contains(id)) {
                            joinedClubs.remove(id);
                          } else {
                            joinedClubs.add(id);
                          }
                        });
                        setSheetState(() {});
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: joined
                            ? AppColors.surfaceSoft
                            : AppColors.accent,
                        foregroundColor: joined
                            ? AppColors.deep
                            : AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        joined ? 'Salir del club' : 'Unirme al club',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAllClubs() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(17, 18, 17, 25),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Clubes de Lectura',
                          style: GoogleFonts.cinzel(
                            color: AppColors.deep,
                            fontSize: 17,
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
                  Expanded(
                    child: ListView.separated(
                      itemCount: clubs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final club = clubs[index];
                        final id = club['id'] as int;
                        final joined = joinedClubs.contains(id);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                club['name'] as String,
                                style: GoogleFonts.merriweather(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Leyendo: ${club['book']}',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(sheetContext).pop();
                                        _showClubDetails(club);
                                      },
                                      style: _outlineButtonStyle(),
                                      child: const Text('Ver'),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    flex: 2,
                                    child: FilledButton(
                                      onPressed: () {
                                        if (widget.isGuest) {
                                          Navigator.of(sheetContext).pop();
                                          _guestMessage('clubes de lectura');
                                          return;
                                        }

                                        setState(() {
                                          if (joinedClubs.contains(id)) {
                                            joinedClubs.remove(id);
                                          } else {
                                            joinedClubs.add(id);
                                          }
                                        });
                                        setSheetState(() {});
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: joined
                                            ? AppColors.surfaceSoft
                                            : AppColors.accent,
                                        foregroundColor: joined
                                            ? AppColors.deep
                                            : AppColors.background,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                      ),
                                      child: Text(
                                        joined ? 'Unido ✓' : 'Unirme',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
  }

  void _showStory(Map<String, String> story) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(19, 20, 19, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        story['title']!,
                        style: GoogleFonts.cinzel(
                          color: AppColors.deep,
                          fontSize: 17,
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
                InkWell(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showAuthorProfile(story);
                  },
                  child: Text(
                    '${story['author']} · Autor Independiente',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  story['full']!,
                  style: GoogleFonts.merriweather(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );
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
