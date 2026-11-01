import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

Future<String?> showCustomGenderSheet(
  BuildContext context, {
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final canSave = controller.text.trim().isNotEmpty;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Cuál es tu género?',
                                style: GoogleFonts.cinzel(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                initialValue == null
                                    ? 'Escribe cómo quieres identificarte en la aplicación.'
                                    : 'Edita cómo quieres identificarte en la aplicación.',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 8.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => Navigator.of(sheetContext).pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                              size: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLength: 50,
                      maxLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setSheetState(() {}),
                      onSubmitted: (_) {
                        if (controller.text.trim().isNotEmpty) {
                          Navigator.of(sheetContext)
                              .pop(controller.text.trim());
                        }
                      },
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ej. No binario',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.70),
                          fontSize: 10,
                        ),
                        counterStyle: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 7,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 13,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.44),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(11)),
                          borderSide: BorderSide(
                            color: AppColors.gold,
                            width: 1.25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 36,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 140),
                          opacity: canSave ? 1 : 0.42,
                          child: SizedBox(
                            width: 92,
                            height: 36,
                            child: FilledButton(
                              onPressed: canSave
                                  ? () {
                                      Navigator.of(sheetContext)
                                          .pop(controller.text.trim());
                                    }
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.background,
                                disabledBackgroundColor:
                                    AppColors.accent.withValues(alpha: 0.30),
                                disabledForegroundColor:
                                    AppColors.background.withValues(alpha: 0.75),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Listo',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  await Future<void>.delayed(const Duration(milliseconds: 280));
  controller.dispose();

  return result;
}

Future<DateTime?> showBirthDateSheet(
  BuildContext context, {
  required String existingValue,
}) async {
  final now = DateTime.now();
  var selectedDate = DateTime(2000, 1, 1);

  if (existingValue.isNotEmpty) {
    final parts = existingValue.split('-');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        selectedDate = DateTime(year, month, day);
      }
    }
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    builder: (sheetContext) {
      var draftDate = selectedDate;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.36),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.cake_outlined,
                          color: AppColors.gold,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FECHA DE NACIMIENTO',
                              style: GoogleFonts.cinzel(
                                color: AppColors.deep,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Selecciona tu fecha de nacimiento.',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 8.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          '${draftDate.day.toString().padLeft(2, '0')} / '
                          '${draftDate.month.toString().padLeft(2, '0')} / '
                          '${draftDate.year}',
                          style: GoogleFonts.merriweather(
                            color: AppColors.deep,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CalendarDatePicker(
                    initialDate: draftDate,
                    firstDate: DateTime(1900),
                    lastDate: now,
                    onDateChanged: (date) {
                      setSheetState(() {
                        draftDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 15,
                            ),
                            label: Text(
                              'Cancelar',
                              style: GoogleFonts.inter(
                                fontSize: 8.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              backgroundColor: AppColors.background,
                              side: BorderSide(
                                color:
                                    AppColors.gold.withValues(alpha: 0.38),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 44,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop(draftDate);
                            },
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                            ),
                            label: Text(
                              'Confirmar fecha',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.deep,
                              foregroundColor: AppColors.gold,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                                side: BorderSide(
                                  color: AppColors.gold
                                      .withValues(alpha: 0.48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
