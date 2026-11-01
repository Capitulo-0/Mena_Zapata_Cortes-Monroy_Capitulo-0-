import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import 'home_network_cover.dart';
import 'home_section_title.dart';

class NearbyReadingPointSection extends StatelessWidget {
  const NearbyReadingPointSection({
    super.key,
    required this.onOpenPoints,
  });

  final VoidCallback onOpenPoints;

  @override
  Widget build(BuildContext context) {
    final deep = AppColors.deepOf(context);
    final gold = AppColors.goldOf(context);
    final accent = AppColors.accentOf(context);
    final goldInk = AppColors.deep;
    final onDeep = AppColors.isDark(context)
        ? AppColors.darkTextPrimary
        : AppColors.background;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          const HomeSectionTitle('Puntos Lectores Cercanos ☕'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: deep,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: gold.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                const HomeNetworkCover(
                  url:
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
                          color: gold,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Providencia · A 1.2 km de ti',
                        style: GoogleFonts.inter(
                          color: onDeep,
                          fontSize: 7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: [
                          _PlaceTag(
                            text: 'WiFi libre',
                            accent: true,
                            gold: gold,
                            accentColor: accent,
                            onAccent: AppColors.isDark(context)
                                ? AppColors.darkTextPrimary
                                : AppColors.background,
                          ),
                          _PlaceTag(
                            text: 'Silencio',
                            gold: gold,
                            accentColor: accent,
                            onAccent: AppColors.isDark(context)
                                ? AppColors.darkTextPrimary
                                : AppColors.background,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                FilledButton(
                  onPressed: onOpenPoints,
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: goldInk,
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
}

class _PlaceTag extends StatelessWidget {
  const _PlaceTag({
    required this.text,
    required this.gold,
    required this.accentColor,
    required this.onAccent,
    this.accent = false,
  });

  final String text;
  final bool accent;
  final Color gold;
  final Color accentColor;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: accent ? accentColor : gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: accent ? accentColor : gold.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: accent ? onAccent : gold,
          fontSize: 6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
