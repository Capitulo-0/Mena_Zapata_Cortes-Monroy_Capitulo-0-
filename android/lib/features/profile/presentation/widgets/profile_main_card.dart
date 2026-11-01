import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileMainCard extends StatelessWidget {
  const ProfileMainCard({
    super.key,
    required this.name,
    required this.username,
    required this.biography,
    required this.moodEmoji,
    required this.readBooksCount,
    required this.followerCount,
    required this.followingCount,
    required this.onFollowersTap,
    required this.onFollowingTap,
  });

  final String name;
  final String username;
  final String biography;
  final String moodEmoji;
  final int readBooksCount;
  final int followerCount;
  final int followingCount;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.surface;
    final textPrimaryColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final headingColor =
        isDark ? AppColors.darkTextPrimary : AppColors.deep;
    final deepSurfaceColor =
        isDark ? AppColors.darkDeep : AppColors.deep;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 1.3),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return Container(
                            color: deepSurfaceColor,
                            alignment: Alignment.center,
                            child: Text(
                              name.trim().isEmpty
                                  ? '?'
                                  : name.trim()[0].toUpperCase(),
                              style: GoogleFonts.cinzel(
                                color: AppColors.gold,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        moodEmoji,
                        style: const TextStyle(fontSize: 14),
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
                      name,
                      style: GoogleFonts.merriweather(
                        color: textPrimaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Miembro desde: Marzo 2024',
                      style: GoogleFonts.inter(
                        color: textSecondaryColor,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              biography,
              style: GoogleFonts.merriweather(
                color: textPrimaryColor,
                fontSize: 10,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.28),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    value: '$readBooksCount',
                    label: 'Total Leídos',
                    headingColor: headingColor,
                    textSecondaryColor: textSecondaryColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    value: '$followerCount',
                    label: 'Seguidores',
                    headingColor: headingColor,
                    textSecondaryColor: textSecondaryColor,
                    highlighted: true,
                    onTap: onFollowersTap,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    value: '$followingCount',
                    label: 'Siguiendo',
                    headingColor: headingColor,
                    textSecondaryColor: textSecondaryColor,
                    highlighted: true,
                    onTap: onFollowingTap,
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

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.headingColor,
    required this.textSecondaryColor,
    this.highlighted = false,
    this.onTap,
  });

  final String value;
  final String label;
  final Color headingColor;
  final Color textSecondaryColor;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: highlighted
                    ? AppColors.accent
                    : headingColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: textSecondaryColor,
                fontSize: 7,
                decoration:
                    highlighted ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
