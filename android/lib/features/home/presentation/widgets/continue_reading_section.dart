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
    required this.onFinish,
    required this.onGuestRestricted,
    this.finishedReadingTitle,
    this.onOpenLibrary,
  });
  final LibraryBook? book;
  final int progress;
  final bool isGuest;
  final VoidCallback onContinue;
  final VoidCallback onFinish;
  final VoidCallback onGuestRestricted;
  final VoidCallback? onOpenLibrary;
  final String? finishedReadingTitle;

  void _guard(VoidCallback action) {
    if (isGuest) {
      onGuestRestricted();
    } else {
      action();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = book;
    final secondary = AppColors.textSecondaryOf(context);
    final accent = AppColors.accentOf(context);
    final safeProgress = progress.clamp(0, 100);
    final Widget content;
    if (finishedReadingTitle != null) {
      content = Row(
        key: const ValueKey('reading-finished'),
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.goldOf(context),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lectura finalizada',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '«$finishedReadingTitle» · Leído',
                  style: GoogleFonts.inter(fontSize: 10, color: secondary),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (current == null) {
      content = Column(
        key: const ValueKey('reading-empty'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comienza una nueva lectura',
            style: GoogleFonts.merriweather(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige un libro de tu Biblioteca y márcalo como Leyendo.',
            style: GoogleFonts.inter(
              fontSize: 10,
              height: 1.5,
              color: secondary,
            ),
          ),
          if (onOpenLibrary != null)
            TextButton(
              onPressed: () => _guard(onOpenLibrary!),
              child: const Text(
                'Ir a Biblioteca',
                style: TextStyle(fontSize: 10),
              ),
            ),
        ],
      );
    } else {
      content = Row(
        key: ValueKey('reading-${current.id}'),
        children: [
          HomeNetworkCover(url: current.cover, width: 64, height: 88),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  current.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 8, color: secondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Progreso',
                        style: GoogleFonts.inter(fontSize: 8, color: secondary),
                      ),
                    ),
                    Text(
                      '$safeProgress%',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: accent,
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
                    color: accent,
                    backgroundColor: AppColors.surfaceSoftOf(context),
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilledButton(
                      onPressed: () => _guard(onContinue),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary,
                        minimumSize: const Size(0, 31),
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text(
                        current.isFree
                            ? BookStatus.leyendo.readingActionLabel
                            : 'Registrar lectura',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _guard(onFinish),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimaryOf(context),
                        minimumSize: const Size(0, 31),
                        side: BorderSide(color: AppColors.goldOf(context)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text(
                        'Finalizar',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      child: Column(
        children: [
          const HomeSectionTitle('Tu lectura'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.goldOf(context).withValues(alpha: .6),
                width: 1.2,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}
