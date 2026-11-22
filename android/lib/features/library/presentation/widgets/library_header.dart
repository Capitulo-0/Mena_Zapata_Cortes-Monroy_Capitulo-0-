import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
    super.key,
    required this.currentName,
    required this.onOptionsTap,
    this.onAddTap,
  });
  final String currentName;
  final VoidCallback onOptionsTap;
  // Compatibilidad con integraciones y pruebas anteriores.
  // El acceso visual de registro está ahora dentro del menú de opciones.
  final VoidCallback? onAddTap;
  @override
  Widget build(BuildContext context) {
    final displayName = currentName.trim().isEmpty
        ? 'LECTOR/A'
        : currentName.trim().toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'MI BIBLIOTECA',
                  style: GoogleFonts.cinzel(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              key: const ValueKey('library-options'),
              tooltip: 'Opciones de biblioteca',
              onPressed: onOptionsTap,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceOf(context),
                foregroundColor: AppColors.textPrimaryOf(context),
                side: BorderSide(color: AppColors.gold.withValues(alpha: .55)),
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.more_vert_rounded, size: 20),
            ),
          ],
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
                  letterSpacing: .35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
