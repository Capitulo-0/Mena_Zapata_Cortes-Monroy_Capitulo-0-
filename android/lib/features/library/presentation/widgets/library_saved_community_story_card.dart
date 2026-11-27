import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../writer/models/writer_publication.dart';
import '../../../writer/presentation/widgets/writer_cover.dart';

/// Tarjeta visualmente compatible con LibraryBookCard, sin mezclar historias
/// comunitarias con el catálogo ni con el seguimiento de lecturas de libros.
class LibrarySavedCommunityStoryCard extends StatelessWidget {
  const LibrarySavedCommunityStoryCard({
    super.key,
    required this.story,
    required this.onRead,
    this.onAuthorTap,
    this.loading = false,
  });

  final WriterPublication story;
  final VoidCallback onRead;
  final VoidCallback? onAuthorTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    return InkWell(
      onTap: loading ? null : onRead,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.42)),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepOf(context).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WriterCover(
              coverPath: story.coverPath,
              title: story.title,
              storyId: story.id,
              author: story.author,
              width: 62,
              height: 88,
              radius: 8,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            color: textPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.7),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'POR LEER',
                          style: GoogleFonts.inter(
                            color: AppColors.goldOf(context),
                            fontSize: 6.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  InkWell(
                    onTap: onAuthorTap,
                    child: Text(
                      story.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 8,
                      ),
                    ),
                  ),
                  Text(
                    'Historia de la comunidad',
                    style: TextStyle(fontSize: 10, color: textSecondary),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 30,
                    child: FilledButton(
                      onPressed: loading ? null : onRead,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text(
                        loading ? 'Abriendo...' : 'Leer historia',
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                        ),
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
  }
}
