import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import 'home_section_title.dart';

class CommunityStoriesSection extends StatelessWidget {
  const CommunityStoriesSection({
    super.key,
    required this.stories,
    required this.isGuest,
    required this.onWrite,
    required this.onGuestRestricted,
    required this.onAuthorTap,
    required this.onStoryTap,
  });

  final List<Map<String, String>> stories;
  final bool isGuest;
  final VoidCallback onWrite;
  final VoidCallback onGuestRestricted;
  final ValueChanged<Map<String, String>> onAuthorTap;
  final ValueChanged<Map<String, String>> onStoryTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: HomeSectionTitle('Historias de la Comunidad'),
              ),
              TextButton(
                onPressed: () {
                  if (isGuest) {
                    onGuestRestricted();
                    return;
                  }
                  onWrite();
                },
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  '✦ Escribir',
                  style: GoogleFonts.inter(
                    color: accent,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ...stories.map(
            (story) => _StoryCard(
              story: story,
              onAuthorTap: () => onAuthorTap(story),
              onStoryTap: () => onStoryTap(story),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.onAuthorTap,
    required this.onStoryTap,
  });

  final Map<String, String> story;
  final VoidCallback onAuthorTap;
  final VoidCallback onStoryTap;

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final gold = AppColors.goldOf(context);
    final accent = AppColors.accentOf(context);
    final deep = AppColors.deepOf(context);
    final onAccent = AppColors.isDark(context)
        ? AppColors.darkTextPrimary
        : AppColors.background;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
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
            story['title']!,
            style: GoogleFonts.merriweather(
              color: textPrimary,
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
                onTap: onAuthorTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    story['author']!,
                    style: GoogleFonts.inter(
                      color: accent,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: accent,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: deep,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Autor Independiente',
                  style: GoogleFonts.inter(
                    color: gold,
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
              color: textPrimary,
              fontSize: 8,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onStoryTap,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: onAccent,
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
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
}
