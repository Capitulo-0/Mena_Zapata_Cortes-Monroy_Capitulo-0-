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
            if (hasJoinedClubs) ...[
              _FilterChip(
                label: 'Mis clubes',
                icon: Icons.groups_2_outlined,
                selected: showJoinedClubs,
                onTap: onJoinedClubsTap,
              ),
              const SizedBox(width: 6),
            ],
            _FilterChip(
              label: 'Todos',
              icon: Icons.public,
              selected: !showJoinedClubs && selectedFilter == null,
              onTap: () => onFilterTap(null),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Bibliotecas',
              icon: Icons.local_library_outlined,
              selected:
                  !showJoinedClubs && selectedFilter == MapPointType.library,
              onTap: () => onFilterTap(MapPointType.library),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Cafés',
              icon: Icons.local_cafe_outlined,
              selected:
                  !showJoinedClubs && selectedFilter == MapPointType.cafe,
              onTap: () => onFilterTap(MapPointType.cafe),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Ferias',
              icon: Icons.menu_book_outlined,
              selected:
                  !showJoinedClubs && selectedFilter == MapPointType.bookFair,
              onTap: () => onFilterTap(MapPointType.bookFair),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Eventos',
              icon: Icons.auto_stories_outlined,
              selected: !showJoinedClubs &&
                  selectedFilter == MapPointType.literaryEvent,
              onTap: () => onFilterTap(MapPointType.literaryEvent),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Cultura',
              icon: Icons.account_balance_outlined,
              selected: !showJoinedClubs &&
                  selectedFilter == MapPointType.culturalCenter,
              onTap: () => onFilterTap(MapPointType.culturalCenter),
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
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      avatar: Icon(
        icon,
        size: 16,
        color: selected
            ? AppColors.deepOf(context)
            : AppColors.goldOf(context),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
