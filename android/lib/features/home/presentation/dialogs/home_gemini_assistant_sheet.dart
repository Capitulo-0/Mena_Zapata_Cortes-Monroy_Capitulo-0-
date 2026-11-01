import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

Future<void> showHomeGeminiAssistantSheet({
  required BuildContext context,
}) async {
  final geminiController = TextEditingController();

  final messages = <Map<String, String>>[
    {
      'role': 'assistant',
      'text':
          'Hola ✦ Soy tu asistente literario. Puedo recomendarte lecturas, ayudarte a elegir tu próxima historia o conversar sobre géneros y autores.',
    },
  ];

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final background = AppColors.backgroundOf(context);
            final surface = AppColors.surfaceOf(context);
            final deepAlt = AppColors.deepAltOf(context);
            final textPrimary = AppColors.textPrimaryOf(context);
            final textSecondary = AppColors.textSecondaryOf(context);
            final gold = AppColors.goldOf(context);
            final accent = AppColors.accentOf(context);
            final onAccent = AppColors.isDark(context)
                ? AppColors.darkTextPrimary
                : AppColors.background;

            void sendMessage() {
              final prompt = geminiController.text.trim();
              if (prompt.isEmpty) {
                return;
              }

              setSheetState(() {
                messages.add({'role': 'user', 'text': prompt});
                messages.add({
                  'role': 'assistant',
                  'text': _geminiDemoAnswer(prompt),
                });
                geminiController.clear();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.72,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: gold, width: 1.5),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(17, 14, 10, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: deepAlt,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: gold.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: gold,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gemini AI Literario',
                                  style: GoogleFonts.cinzel(
                                    color: textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Asistente de Capítulo 0',
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isUser = message['role'] == 'user';

                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints:
                                  const BoxConstraints(maxWidth: 280),
                              margin: const EdgeInsets.only(bottom: 9),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isUser ? accent : surface,
                                borderRadius: BorderRadius.circular(10),
                                border: isUser
                                    ? null
                                    : Border.all(
                                        color:
                                            gold.withValues(alpha: 0.4),
                                      ),
                              ),
                              child: Text(
                                message['text']!,
                                style: GoogleFonts.inter(
                                  color:
                                      isUser ? onAccent : textPrimary,
                                  fontSize: 10,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: geminiController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => sendMessage(),
                              style: GoogleFonts.inter(
                                color: textPrimary,
                                fontSize: 10,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: surface,
                                hintText: 'Pregúntale a Gemini...',
                                hintStyle: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 9,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(9),
                                  borderSide: BorderSide(
                                    color:
                                        gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(9),
                                  borderSide: BorderSide(color: gold),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          SizedBox(
                            width: 42,
                            height: 42,
                            child: FilledButton(
                              onPressed: sendMessage,
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: onAccent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(9),
                                ),
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                size: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    geminiController.dispose();
  }
}

String _geminiDemoAnswer(String prompt) {
  final q = prompt.toLowerCase();

  if (q.contains('gótic') || q.contains('terror')) {
    return 'Para un ambiente gótico te recomiendo “Rebecca” de Daphne du Maurier, “El retrato de Dorian Gray” de Oscar Wilde y, si quieres algo más intenso, continuar con “Frankenstein”.';
  }

  if (q.contains('romance')) {
    return 'Si buscas romance clásico, empieza por “Orgullo y Prejuicio”. Si prefieres una atmósfera más intensa y oscura, “Jane Eyre” puede gustarte mucho.';
  }

  if (q.contains('recom') || q.contains('leer')) {
    return 'Por tus lecturas actuales, probaría con “Jane Eyre”. Mantiene el tono clásico y emocional, pero agrega misterio y una protagonista con mucha personalidad.';
  }

  return 'Puedo ayudarte con recomendaciones, autores, géneros o con tu próxima lectura. Cuéntame qué tipo de historia tienes ganas de leer hoy.';
}
