import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../writer/models/writer_publication.dart';
import 'home_section_title.dart';

class CommunityStoriesSection extends StatelessWidget {
  const CommunityStoriesSection({
    super.key,
    required this.stories,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onCommunity,
    this.openingPublicationId,
    required this.onAuthorTap,
    required this.onStoryTap,
  });

  final List<WriterPublication> stories;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onCommunity;
  final String? openingPublicationId;
  final ValueChanged<WriterPublication> onAuthorTap;
  final ValueChanged<WriterPublication> onStoryTap;

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
                onPressed: onCommunity,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  '✦ Comunidad',
                  style: GoogleFonts.inter(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          if (loading && stories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null && stories.isEmpty)
            Column(
              children: [
                Text(error!),
                TextButton(onPressed: onRetry, child: const Text('Reintentar')),
              ],
            )
          else if (stories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aún no hay historias publicadas en la comunidad.'),
            )
          else
            ...stories.map(
              (story) => CommunityStoryCard(
                story: story,
                onAuthorTap: () => onAuthorTap(story),
                onStoryTap: () => onStoryTap(story),
                loading: openingPublicationId == story.id,
              ),
            ),
        ],
      ),
    );
  }
}

class CommunityStoryCard extends StatelessWidget {
  const CommunityStoryCard({
    super.key,
    required this.story,
    required this.onAuthorTap,
    required this.onStoryTap,
    this.loading = false,
  });

  final WriterPublication story;
  final bool loading;
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
        border: Border.all(color: gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.title,
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
                    story.author,
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
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
            story.synopsis.trim().isEmpty
                ? 'Sin sinopsis disponible.'
                : story.synopsis,
            style: GoogleFonts.merriweather(
              color: textPrimary,
              fontSize: 8,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: loading ? null : onStoryTap,
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
