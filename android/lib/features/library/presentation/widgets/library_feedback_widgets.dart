import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.libraryEmpty,
  });

  final bool libraryEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            color: AppColors.gold,
            size: 34,
          ),
          const SizedBox(height: 9),
          Text(
            libraryEmpty
                ? 'Todavía no tienes libros en tu biblioteca.'
                : 'No encontramos libros con este filtro.',
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              color: AppColors.textSecondaryOf(context),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryFinishSuccessMessage extends StatelessWidget {
  const LibraryFinishSuccessMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF283125)
            : const Color(0xFFF4F7EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF78935F).withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF708A56),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Libro finalizado correctamente',
              style: GoogleFonts.merriweather(
                color: isDark
                    ? const Color(0xFFE7EEDC)
                    : const Color(0xFF3F4F33),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.auto_stories_rounded,
            color: AppColors.gold.withValues(alpha: 0.76),
            size: 20,
          ),
        ],
      ),
    );
  }
}
