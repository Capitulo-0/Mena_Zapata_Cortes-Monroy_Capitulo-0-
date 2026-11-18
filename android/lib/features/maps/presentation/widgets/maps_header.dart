import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MapsHeader extends StatelessWidget {
  const MapsHeader({super.key, required this.currentName});

  final String currentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = currentName.trim().toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titulo principal.
          Text(
            'PUNTOS LECTORES',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 5),

          // Descripcion y nombre del usuario en un solo bloque.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      'Bibliotecas, cafeterías, ferias y eventos '
                      'literarios cerca de ti, ',
                  style: GoogleFonts.merriweather(
                    fontSize: 9.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.85,
                    ),
                  ),
                ),
                TextSpan(
                  text: '$userName ✦',
                  style: GoogleFonts.cinzel(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    height: 1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
