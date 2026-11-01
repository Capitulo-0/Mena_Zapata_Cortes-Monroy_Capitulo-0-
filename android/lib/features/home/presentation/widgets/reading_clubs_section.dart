import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../clubs/models/reading_club.dart';
import 'home_section_title.dart';

class ReadingClubsSection extends StatelessWidget {
  const ReadingClubsSection({
    super.key,
    required this.clubs,
    required this.joinedClubIds,
    required this.onShowAll,
    required this.onShowDetails,
    required this.onToggleClub,
  });

  final List<ReadingClub> clubs;
  final Set<int> joinedClubIds;
  final VoidCallback onShowAll;
  final ValueChanged<ReadingClub> onShowDetails;
  final ValueChanged<int> onToggleClub;

  @override
  Widget build(BuildContext context) {
    final visible = clubs.take(2).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: HomeSectionTitle('Clubes de Lectura Activos'),
              ),
              TextButton(
                onPressed: onShowAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentOf(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.inter(
                    color: AppColors.accentOf(context),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          for (var index = 0; index < visible.length; index++) ...[
            _ClubCard(
              club: visible[index],
              joined: joinedClubIds.contains(visible[index].id),
              onShowDetails: () => onShowDetails(visible[index]),
              onToggle: () => onToggleClub(visible[index].id),
            ),
            if (index < visible.length - 1)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({
    required this.club,
    required this.joined,
    required this.onShowDetails,
    required this.onToggle,
  });

  final ReadingClub club;
  final bool joined;
  final VoidCallback onShowDetails;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surfaceOf(context);
    final surfaceSoft = AppColors.surfaceSoftOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final gold = AppColors.goldOf(context);
    final accent = AppColors.accentOf(context);
    final onAccent = AppColors.isDark(context)
        ? AppColors.darkTextPrimary
        : AppColors.background;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: gold.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club.name,
            style: GoogleFonts.merriweather(
              color: textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Leyendo: ${club.book}',
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '📅 Debate: ${club.date} · ${club.members} lectores',
            style: GoogleFonts.inter(
              color: accent,
              fontSize: 7,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onShowDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    minimumSize: const Size(0, 31),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: gold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
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
                  onPressed: onToggle,
                  style: FilledButton.styleFrom(
                    backgroundColor: joined ? surfaceSoft : accent,
                    foregroundColor: joined ? textPrimary : onAccent,
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
}
