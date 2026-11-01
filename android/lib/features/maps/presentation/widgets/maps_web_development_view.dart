import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class MapsWebDevelopmentView extends StatelessWidget {
  const MapsWebDevelopmentView({
    super.key,
    required this.resultText,
    required this.onOpenMap,
  });

  final String resultText;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = AppColors.goldOf(context);
    final deep = AppColors.deepOf(context);

    final messageCard = Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 390),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gold.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gold.withValues(alpha: 0.24),
              ),
            ),
            child: Icon(
              Icons.map_outlined,
              size: 32,
              color: gold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'MAPA LISTO PARA TU DISPOSITIVO',
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.25,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para visualizar el mapa y utilizar sus diferentes funciones, '
            'deberás permitir el acceso a tu ubicación en Android o iOS.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: onOpenMap,
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: deep,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(
                Icons.map_rounded,
                size: 17,
              ),
              label: Text(
                'Abrir mapa',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: gold.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resultText,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Disponibles para visualizar en el mapa',
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.phone_android_rounded,
                  size: 18,
                  color: deep.withValues(alpha: 0.78),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceContainerLow,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Align(
                alignment: const Alignment(0, -0.18),
                child: messageCard,
              ),
            ),
          ),
        );
      },
    );
  }
}
