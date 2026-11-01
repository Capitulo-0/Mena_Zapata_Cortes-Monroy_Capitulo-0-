import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
    super.key,
    required this.currentName,
    required this.onOptionsTap,
  });

  final String currentName;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    final displayName = currentName.trim().isEmpty
        ? 'LECTOR/A'
        : currentName.trim().toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MI BIBLIOTECA',
                style: GoogleFonts.cinzel(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Tus libros, progreso y estados en un solo lugar, ',
                      style: GoogleFonts.merriweather(
                        color: AppColors.textSecondaryOf(context),
                        fontSize: 9.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(
                      text: '$displayName ✦',
                      style: GoogleFonts.cinzel(
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 9.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onOptionsTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.55),
              ),
            ),
            child: Icon(
              Icons.more_vert_rounded,
              size: 19,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ),
      ],
    );
  }
}
