import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Mirrors LibraryHeader dimensions and typography without changing Biblioteca.
class WriterHeader extends StatelessWidget {
  const WriterHeader({
    super.key,
    required this.onCreate,
    required this.displayName,
  });

  final VoidCallback onCreate;
  final String displayName;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MIS HISTORIAS',
                    style: GoogleFonts.cinzel(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Escribe, guarda y comparte tus historias, $displayName ✦',
                  style: GoogleFonts.merriweather(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 9.8,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            key: const ValueKey('writer-create-story'),
            tooltip: 'Crear historia',
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 21),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.deep,
              foregroundColor: AppColors.gold,
              minimumSize: const Size(44, 44),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    ],
  );
}
