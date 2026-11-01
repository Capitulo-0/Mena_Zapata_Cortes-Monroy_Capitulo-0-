import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MapsHeader extends StatelessWidget {
  const MapsHeader({
    super.key,
    required this.currentName,
  });

  final String currentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PUNTOS LECTORES',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Bibliotecas, cafeterías, ferias y eventos literarios cerca de ti,',
            style: GoogleFonts.merriweather(
              fontSize: 8,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.78,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${currentName.trim().toUpperCase()} ✦',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cinzel(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
