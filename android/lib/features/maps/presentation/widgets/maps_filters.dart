
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/map_point_type.dart';

class MapsFilters extends StatelessWidget {
  const MapsFilters({
    super.key,
    required this.scrollController,
    required this.selectedFilter,
    required this.onFilterTap,
  });

  final ScrollController scrollController;
  final MapPointType? selectedFilter;
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
            _FilterChip(
              label: 'Todos',
              emoji: '🌍',
              selected: selectedFilter == null,
              onTap: () => onFilterTap(null),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Bibliotecas',
              emoji: '📚',
              selected: selectedFilter == MapPointType.library,
              onTap: () => onFilterTap(MapPointType.library),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Cafés',
              emoji: '☕',
              selected: selectedFilter == MapPointType.cafe,
              onTap: () => onFilterTap(MapPointType.cafe),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Librerías',
              emoji: '📖',
              selected: selectedFilter == MapPointType.bookstore,
              onTap: () => onFilterTap(MapPointType.bookstore),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Museos',
              emoji: '🏛️',
              selected: selectedFilter == MapPointType.museum,
              onTap: () => onFilterTap(MapPointType.museum),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Cultura',
              emoji: '🎭',
              selected: selectedFilter == MapPointType.culturalCenter,
              onTap: () => onFilterTap(MapPointType.culturalCenter),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Parques',
              emoji: '🌳',
              selected: selectedFilter == MapPointType.park,
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
    final borderRadius = BorderRadius.circular(18);
    final borderColor = selected
        ? AppColors.goldOf(context)
        : AppColors.goldOf(context).withValues(alpha: 0.28);

    return Material(
      color: selected
          ? AppColors.goldOf(context)
          : AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.deepOf(context)
                      : AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
