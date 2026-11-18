import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Mirrors LibraryHeader dimensions and typography without changing Biblioteca.
class WriterHeader extends StatelessWidget {
  const WriterHeader({
    super.key,
    required this.onCreate,
    required this.onLegacy,
    required this.onRefresh,
    required this.onDiagnostics,
  });
  final VoidCallback onCreate, onLegacy, onRefresh, onDiagnostics;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: FittedBox(
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
          ),
          const SizedBox(width: 4),
          IconButton(
            key: const ValueKey('writer-create-story'),
            tooltip: 'Crear historia',
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 23),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.deep,
              foregroundColor: AppColors.gold,
              minimumSize: const Size(48, 48),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              border: Border.all(color: AppColors.gold.withValues(alpha: .55)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              key: const ValueKey('writer-options'),
              tooltip: 'Opciones de Writer',
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 290),
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: AppColors.textPrimaryOf(context),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'legacy':
                    onLegacy();
                  case 'refresh':
                    onRefresh();
                  case 'covers':
                    onDiagnostics();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'legacy',
                  child: Text('Consultar borradores locales anteriores'),
                ),
                PopupMenuItem(
                  value: 'refresh',
                  child: Text('Actualizar historias'),
                ),
                PopupMenuItem(
                  value: 'covers',
                  child: Text('Comprobar portadas y versión'),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Escribe, guarda y comparte tus historias.',
        style: GoogleFonts.merriweather(
          color: AppColors.textSecondaryOf(context),
          fontSize: 9.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
  );
}
