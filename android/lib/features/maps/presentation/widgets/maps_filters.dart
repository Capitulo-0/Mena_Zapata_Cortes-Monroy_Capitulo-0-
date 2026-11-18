import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/map_point_type.dart';

class MapsFilters extends StatelessWidget {
  const MapsFilters({
    super.key,
    required this.scrollController,
    required this.hasJoinedClubs,
    required this.showJoinedClubs,
    required this.selectedFilter,
    required this.onJoinedClubsTap,
    required this.onFilterTap,
  });

  final ScrollController scrollController;
  final bool hasJoinedClubs;
  final bool showJoinedClubs;
  final MapPointType? selectedFilter;
  final VoidCallback onJoinedClubsTap;
  final ValueChanged<MapPointType?> onFilterTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 5, 14, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clubes literarios del usuario.
            if (hasJoinedClubs) ...[
              _FilterChip(
                label: 'Mis clubes',
                emoji: '👥',
                selected: showJoinedClubs,
                onTap: onJoinedClubsTap,
              ),
              const SizedBox(width: 6),
            ],

            // Todos los lugares disponibles.
            _FilterChip(
              label: 'Todos',
              emoji: '🌍',
              selected: !showJoinedClubs && selectedFilter == null,
              onTap: () => onFilterTap(null),
            ),

            const SizedBox(width: 6),

            // Bibliotecas.
            _FilterChip(
              label: 'Bibliotecas',
              emoji: '📚',
              selected:
                  !showJoinedClubs && selectedFilter == MapPointType.library,
              onTap: () => onFilterTap(MapPointType.library),
            ),

            const SizedBox(width: 6),

            // Cafeterias.
            _FilterChip(
              label: 'Cafés',
              emoji: '☕',
              selected: !showJoinedClubs && selectedFilter == MapPointType.cafe,
              onTap: () => onFilterTap(MapPointType.cafe),
            ),

            const SizedBox(width: 6),

            // Librerias.
            _FilterChip(
              label: 'Librerías',
              emoji: '📖',
              selected:
                  !showJoinedClubs && selectedFilter == MapPointType.bookstore,
              onTap: () => onFilterTap(MapPointType.bookstore),
            ),

            const SizedBox(width: 6),

            // Museos.
            _FilterChip(
              label: 'Museos',
              emoji: '🏛️',
              selected:
                  !showJoinedClubs && selectedFilter == MapPointType.museum,
              onTap: () => onFilterTap(MapPointType.museum),
            ),

            const SizedBox(width: 6),

            // Centros culturales.
            _FilterChip(
              label: 'Cultura',
              emoji: '🎭',
              selected:
                  !showJoinedClubs &&
                  selectedFilter == MapPointType.culturalCenter,
              onTap: () => onFilterTap(MapPointType.culturalCenter),
            ),

            const SizedBox(width: 6),

            // Parques.
            _FilterChip(
              label: 'Parques',
              emoji: '🌳',
              selected: !showJoinedClubs && selectedFilter == MapPointType.park,
              onTap: () => onFilterTap(MapPointType.park),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),

      // Emoji a color, independiente del tema visual.
      avatar: SizedBox(
        width: 18,
        height: 20,
        child: Center(
          child: Text(
            emoji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.2),
          ),
        ),
      ),

      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: selected
              ? AppColors.deepOf(context)
              : AppColors.textPrimaryOf(context),
        ),
      ),

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      selectedColor: AppColors.goldOf(context),
      backgroundColor: AppColors.surfaceOf(context),

      side: BorderSide(
        color: selected
            ? AppColors.goldOf(context)
            : AppColors.goldOf(context).withValues(alpha: 0.28),
      ),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
