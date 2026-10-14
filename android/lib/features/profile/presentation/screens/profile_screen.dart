import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String selectedTab = 'favoritos';
  int quoteIndex = 0;

  final List<Map<String, String>> favoriteQuotes = [
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
  ];

  final List<Map<String, dynamic>> favoriteBooks = [
    {
      'title': 'Orgullo y prejuicio',
      'author': 'Jane Austen',
      'rating': 4.9,
      'color': AppColors.accent,
    },
    {
      'title': 'Cumbres Borrascosas',
      'author': 'Emily Brontë',
      'rating': 4.8,
      'color': AppColors.deep,
    },
    {
      'title': 'Frankenstein',
      'author': 'Mary Shelley',
      'rating': 4.8,
      'color': AppColors.deepAlt,
    },
    {
      'title': 'Jane Eyre',
      'author': 'Charlotte Brontë',
      'rating': 4.7,
      'color': AppColors.gold,
    },
  ];

  final List<Map<String, dynamic>> reviews = [
    {
      'title': 'Cumbres Borrascosas',
      'rating': 5,
      'text': 'Una obra maestra sombría que no envejece jamás. La intensidad emocional de sus personajes se queda contigo mucho después de cerrar el libro.',
    },
    {
      'title': 'Orgullo y prejuicio',
      'rating': 5,
      'text': 'Ingeniosa, elegante y profundamente humana. Elizabeth Bennet sigue siendo una de mis protagonistas favoritas.',
    },
    {
      'title': 'Frankenstein',
      'rating': 4,
      'text': 'Más melancólica y filosófica de lo que recordaba. Una lectura gótica preciosa para conversar durante horas.',
    },
  ];

  final List<Map<String, dynamic>> reads = [
    {
      'title': 'Orgullo y prejuicio',
      'author': 'Jane Austen',
      'rating': 5,
      'status': 'Leído',
    },
    {
      'title': 'Cumbres Borrascosas',
      'author': 'Emily Brontë',
      'rating': 5,
      'status': 'Leído',
    },
    {
      'title': 'Frankenstein',
      'author': 'Mary Shelley',
      'rating': 4,
      'status': 'Leído',
    },
  ];

  final List<Map<String, String>> works = [
    {
      'title': 'Sombras bajo la lluvia',
      'genre': 'Misterio',
      'status': 'Publicada',
    },
  ];

  final List<String> badges = [
    '📚 Lectora constante',
    '🔥 Racha de 14 días',
    '🌙 Amante del gótico',
    '⭐ 10 reseñas publicadas',
  ];

  final List<Map<String, String>> followers = [
    {'name': 'Valentina Cruz', 'user': '@valencruz', 'initial': 'V'},
    {'name': 'Marco Ibáñez', 'user': '@MarcoIbanez17', 'initial': 'M'},
    {'name': 'María Paz Rojas', 'user': '@mariaPaz200', 'initial': 'M'},
  ];

  final List<Map<String, String>> following = [
    {'name': 'Jane Austen', 'user': '@JaneAusten1', 'initial': 'J'},
    {'name': 'Valentina Cruz', 'user': '@valencruz', 'initial': 'V'},
  ];

  final List<Map<String, String>> blockedUsers = [];

  int get followerCount => 142 - blockedUsers.length;

  int get followingCount => 89;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _buildMainProfileCard(),
            const SizedBox(height: 14),
            _buildClubsCard(),
            const SizedBox(height: 14),
            _buildFavoriteQuote(),
            const SizedBox(height: 14),
            _buildBookDna(),
            const SizedBox(height: 14),
            _buildReadingChallenge(),
            const SizedBox(height: 18),
            _buildTabs(),
            const SizedBox(height: 12),
            _buildSelectedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perfil Literario',
                style: GoogleFonts.cinzel(
                  color: AppColors.deep,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tu espacio dentro de Capítulo 0',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: widget.onOpenSettings,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.deep,
              size: 21,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold, width: 1.4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.deep,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        'C',
                        style: GoogleFonts.cinzel(
                          color: AppColors.gold,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -3,
                    child: Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                      child: const Center(
                        child: Text('☕', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Constanza Mena',
                      style: GoogleFonts.merriweather(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@constanza.lectora',
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Miembro desde: Marzo 2024',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Amante de las novelas góticas victorianas y los clásicos de siempre 🌹 '
              'Estudiante de Ingeniería en Informática.',
              style: GoogleFonts.merriweather(
                color: AppColors.textPrimary,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.30),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _statItem(value: '42', label: 'Total Leídos'),
                ),
                Expanded(
                  child: _statItem(
                    value: '$followerCount',
                    label: 'Seguidores',
                    highlighted: true,
                    onTap: () {
                      _showSocialList(title: 'Seguidores', users: followers);
                    },
                  ),
                ),
                Expanded(
                  child: _statItem(
                    value: '$followingCount',
                    label: 'Siguiendo',
                    highlighted: true,
                    onTap: () {
                      _showSocialList(title: 'Siguiendo', users: following);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _smallInfoCard(
                  icon: Icons.auto_stories_outlined,
                  label: 'Formato',
                  value: 'Ambos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _smallInfoCard(
                  icon: Icons.menu_book_outlined,
                  label: 'Páginas',
                  value: '12.480',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _smallInfoCard(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Racha',
                  value: '14 días',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Text('☕', style: TextStyle(fontSize: 19)),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado lector',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Leyendo con cafecito',
                        style: GoogleFonts.merriweather(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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

  Widget _statItem({
    required String value,
    required String label,
    bool highlighted = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: highlighted ? AppColors.accent : AppColors.deep,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.deep,
              fontSize: 10,
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

  Widget _buildClubsCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MIS CLUBES DE LECTURA',
                  style: GoogleFonts.cinzel(
                    color: AppColors.deep,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '2 miembros',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _clubRow(
            icon: '☕',
            title: 'Adictos a los Clásicos',
            subtitle: 'Leyendo Cumbres Borrascosas',
          ),
          const SizedBox(height: 8),
          _clubRow(
            icon: '🕯️',
            title: 'Mansión Gótica',
            subtitle: 'Leyendo Jane Eyre',
          ),
        ],
      ),
    );
  }

  Widget _clubRow({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () {
        _showMessage(
          'El detalle del club se conectará con la pantalla de clubes.',
        );
      },
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 21)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.merriweather(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.gold,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteQuote() {
    final quote = favoriteQuotes[quoteIndex];
    final work = quote['work'] ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'CITA FAVORITA ANCLADA',
                        style: GoogleFonts.cinzel(
                          color: AppColors.deep,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          quoteIndex = (quoteIndex + 1) % favoriteQuotes.length;
                        });
                      },
                      child: Text(
                        'Cambiar',
                        style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '“${quote['text']}”',
                  style: GoogleFonts.merriweather(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '— ${quote['author']}${work.isEmpty ? '' : ' · $work'}',
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
    );
  }

  Widget _buildBookDna() {
    final genres = [
      {'name': 'Ficción Gótica', 'value': 0.55},
      {'name': 'Romance Clásico', 'value': 0.30},
      {'name': 'Poesía', 'value': 0.15},
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Géneros más leídos 📚',
                  style: GoogleFonts.cinzel(
                    color: AppColors.deep,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Tus lecturas por género',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...genres.map((genre) {
            final value = genre['value'] as double;

            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          genre['name'] as String,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      Text(
                        '${(value * 100).round()}%',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor: AppColors.surfaceSoft,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReadingChallenge() {
    const read = 18;
    const goal = 25;
    const progress = read / goal;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reto de Lectura Anual 🎯',
                  style: GoogleFonts.cinzel(
                    color: AppColors.deep,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$read de $goal',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: AppColors.surfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${(progress * 100).round()}% completado',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'id': 'favoritos', 'label': 'Favoritos (${favoriteBooks.length})'},
      {'id': 'resenas', 'label': 'Mis Reseñas (${reviews.length})'},
      {'id': 'lecturas', 'label': 'Mis Lecturas'},
      {'id': 'obras', 'label': 'Mis obras (${works.length})'},
      {'id': 'insignias', 'label': 'Insignias (${badges.length})'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final active = selectedTab == tab['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedTab = tab['id']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.only(bottom: 7),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab['label']!,
                  style: GoogleFonts.inter(
                    color: active ? AppColors.accent : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (selectedTab) {
      case 'favoritos':
        return _buildFavorites();

      case 'resenas':
        return _buildReviews();

      case 'lecturas':
        return _buildReads();

      case 'obras':
        return _buildWorks();

      case 'insignias':
        return _buildBadges();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFavorites() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favoriteBooks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final book = favoriteBooks[index];

        return InkWell(
          onTap: () {
            _showMessage(
              'Detalle de ${book['title']} se conectará con la vista de libro.',
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.38)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: book['color'] as Color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(13),
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          book['title'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            color: AppColors.background,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['author'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '★ ${book['rating']}',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
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
  }

  Widget _buildReviews() {
    return Column(
      children: reviews.map((review) {
        final rating = review['rating'] as int;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review['title'] as String,
                      style: GoogleFonts.merriweather(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.gold,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '“${review['text']}”',
                style: GoogleFonts.merriweather(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  height: 1.55,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReads() {
    return Column(
      children: reads.map((book) {
        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.deep,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'] as String,
                      style: GoogleFonts.merriweather(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book['author'] as String,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '★ ${book['rating']} · ${book['status']}',
                      style: GoogleFonts.inter(
                        color: AppColors.gold,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorks() {
    return Column(
      children: works.map((work) {
        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.deepAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work['title']!,
                      style: GoogleFonts.merriweather(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      work['genre']!,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        work['status']!,
                        style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 8,
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
      }).toList(),
    );
  }

  Widget _buildBadges() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
          ),
          child: Center(
            child: Text(
              badges[index],
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.deep,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.38)),
      ),
      child: child,
    );
  }

  void _showSocialList({
    required String title,
    required List<Map<String, String>> users,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.cinzel(
                              color: AppColors.deep,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(bottomSheetContext).pop();
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.deep,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (users.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        child: Text(
                          'No hay usuarios en esta lista.',
                          style: GoogleFonts.merriweather(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      ...users.map((user) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.deep,
                                child: Text(
                                  user['initial'] ?? '?',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'] ?? '',
                                      style: GoogleFonts.merriweather(
                                        color: AppColors.textPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user['user'] ?? '',
                                      style: GoogleFonts.inter(
                                        color: AppColors.accent,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                onSelected: (value) {
                                  final userName = user['name'] ?? 'Usuario';

                                  if (value == 'remove') {
                                    setState(() {
                                      users.remove(user);
                                    });

                                    setModalState(() {});

                                    _showMessage(
                                      '$userName fue eliminado de la lista.',
                                    );
                                  }

                                  if (value == 'block') {
                                    setState(() {
                                      if (!blockedUsers.any(
                                        (blocked) =>
                                            blocked['user'] == user['user'],
                                      )) {
                                        blockedUsers.add(
                                          Map<String, String>.from(user),
                                        );
                                      }

                                      followers.removeWhere(
                                        (item) => item['user'] == user['user'],
                                      );

                                      following.removeWhere(
                                        (item) => item['user'] == user['user'],
                                      );
                                    });

                                    setModalState(() {});

                                    _showMessage('$userName fue bloqueado.');
                                  }
                                },
                                itemBuilder: (context) {
                                  return const [
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_remove_outlined,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Eliminar'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'block',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.block_outlined,
                                            color: AppColors.accent,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Bloquear',
                                            style: TextStyle(
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ],
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
