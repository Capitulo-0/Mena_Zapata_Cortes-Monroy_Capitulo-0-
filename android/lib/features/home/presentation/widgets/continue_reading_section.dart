import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../library/presentation/screens/library_screen.dart';
import 'home_network_cover.dart';
import 'home_section_title.dart';

class ContinueReadingSection extends StatelessWidget {
  const ContinueReadingSection({
    super.key,
    required this.book,
    required this.progress,
    required this.isGuest,
    required this.onContinue,
    required this.onAdvance,
    required this.onGuestRestricted,
  });

  final LibraryBook book;
  final int progress;
  final bool isGuest;
  final VoidCallback onContinue;
  final VoidCallback onAdvance;
  final VoidCallback onGuestRestricted;

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

    final safeProgress = progress.clamp(0, 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      child: Column(
        children: [
          const HomeSectionTitle('Continuar Leyendo'),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Container(
              key: ValueKey('${book.id}-$safeProgress'),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: gold.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  HomeNetworkCover(
                    url: book.cover,
                    width: 64,
                    height: 88,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            color: textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Progreso',
                                style: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                            Text(
                              '$safeProgress%',
                              style: GoogleFonts.inter(
                                color: accent,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: safeProgress / 100,
                            minHeight: 5,
                            backgroundColor: surfaceSoft,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                        const SizedBox(height: 9),
                        if (safeProgress < 100)
                          Row(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  if (isGuest) {
                                    onGuestRestricted();
                                    return;
                                  }
                                  onContinue();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: onAccent,
                                  minimumSize: const Size(0, 31),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                child: Text(
                                  'Continuar →',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                onPressed: onAdvance,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  minimumSize: const Size(0, 31),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  side: BorderSide(color: gold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                child: Text(
                                  '+ Avanzar',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7EE),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: const Color(0xFF78935F)
                                    .withValues(alpha: 0.68),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF708A56),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Libro finalizado correctamente',
                                    style: GoogleFonts.merriweather(
                                      color: const Color(0xFF3F4F33),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.auto_stories_rounded,
                                  color: gold.withValues(alpha: 0.78),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
