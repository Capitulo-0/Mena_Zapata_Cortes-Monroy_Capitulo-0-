import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../home_recommendation_controller.dart';

/// A selection workflow, not a conversational assistant. Opening it never calls a provider.
class HomeGeminiSelectionDialog extends StatelessWidget {
  const HomeGeminiSelectionDialog({
    super.key,
    required this.controller,
    required this.isCurrent,
  });
  final HomeRecommendationController controller;
  final bool Function() isCurrent;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final current = isCurrent();
      final data = controller.data;
      final busy = controller.loading || controller.enriching;
      final selected = data?.aiStatus == 'ENRICHED';
      final available =
          current &&
          controller.repository.supportsGemini &&
          data?.geminiAvailable == true &&
          data?.personalized == true &&
          data!.items.isNotEmpty;
      return AlertDialog(
        key: const ValueKey('gemini-selection-dialog'),
        scrollable: true,
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.goldOf(context).withValues(alpha: .6),
          ),
        ),
        title: Text(
          'Selección con Gemini',
          style: GoogleFonts.merriweather(
            fontSize: 18,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!current)
                const Text(
                  'Tus lecturas cambiaron. Cierra esta ventana y abre Gemini de nuevo.',
                )
              else if (busy) ...[
                const LinearProgressIndicator(
                  key: ValueKey('gemini-dialog-loading'),
                ),
                const SizedBox(height: 12),
                Text(
                  controller.enriching
                      ? 'Gemini está seleccionando entre tus libros candidatos.'
                      : 'Estamos preparando tus recomendaciones.',
                ),
              ] else if (selected)
                const Text('La selección está aplicada a tus recomendaciones.')
              else if (!available)
                const Text(
                  'Por ahora Gemini no está disponible. Puedes seguir explorando las recomendaciones de tu Biblioteca.',
                  key: ValueKey('gemini-unavailable'),
                )
              else ...[
                const Text(
                  'Gemini puede seleccionar entre recomendaciones reales relacionadas con tu Biblioteca.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Al solicitar la selección se compartirán títulos, autores, categorías y estados de lectura. No se envían datos de tu cuenta.',
                  key: ValueKey('gemini-consent'),
                ),
                if (controller.aiMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.aiMessage!,
                    key: const ValueKey('gemini-dialog-message'),
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('gemini-close'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (available && !selected)
            FilledButton(
              key: const ValueKey('gemini-request'),
              onPressed: busy
                  ? null
                  : () {
                      if (isCurrent()) controller.enrich();
                    },
              child: const Text('Solicitar selección'),
            ),
        ],
      );
    },
  );
}
