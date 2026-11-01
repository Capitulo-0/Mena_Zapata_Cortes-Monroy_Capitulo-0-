import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class AuthGenderSelector extends StatelessWidget {
  const AuthGenderSelector({
    super.key,
    required this.selectedGender,
    required this.customGender,
    required this.isOpen,
    required this.onToggle,
    required this.onSelect,
    required this.onCustomGenderRequested,
  });

  final String? selectedGender;
  final String? customGender;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;
  final Future<void> Function({String? initialValue}) onCustomGenderRequested;

  static const _options = <String>[
    'Mujer',
    'Hombre',
    'Prefiero no decirlo',
    'Prefiero decirlo yo',
  ];

  String? get _displayGender {
    if (selectedGender == 'Prefiero decirlo yo' &&
        customGender != null &&
        customGender!.trim().isNotEmpty) {
      return customGender!.trim();
    }
    return selectedGender;
  }

  @override
  Widget build(BuildContext context) {
    final displayGender = _displayGender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isOpen
                    ? AppColors.gold
                    : AppColors.gold.withValues(alpha: 0.55),
                width: isOpen ? 1.35 : 1,
              ),
              boxShadow: isOpen
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayGender ?? 'Selecciona una opción',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: displayGender == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.gold,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: isOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.62),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(_options.length, (index) {
                          final option = _options[index];
                          final selected = selectedGender == option;
                          final alternate = index.isOdd;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () async {
                                  if (option == 'Prefiero decirlo yo') {
                                    await onCustomGenderRequested();
                                    return;
                                  }
                                  onSelect(option);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 12,
                                  ),
                                  color: selected
                                      ? AppColors.accent.withValues(alpha: 0.08)
                                      : alternate
                                          ? AppColors.surfaceSoft
                                              .withValues(alpha: 0.34)
                                          : AppColors.surface,
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? AppColors.gold
                                                  .withValues(alpha: 0.16)
                                              : AppColors.background,
                                          border: Border.all(
                                            color: selected
                                                ? AppColors.gold
                                                : AppColors.gold
                                                    .withValues(alpha: 0.22),
                                          ),
                                        ),
                                        child: Icon(
                                          selected
                                              ? Icons.check_rounded
                                              : Icons.person_outline_rounded,
                                          size: 13,
                                          color: selected
                                              ? AppColors.gold
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: GoogleFonts.inter(
                                            color: selected
                                                ? AppColors.accent
                                                : AppColors.textPrimary,
                                            fontSize: 10,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (selected)
                                        Text(
                                          'ACTUAL',
                                          style: GoogleFonts.inter(
                                            color: AppColors.gold,
                                            fontSize: 6,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.7,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (index < _options.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color:
                                      AppColors.gold.withValues(alpha: 0.12),
                                ),
                            ],
                          );
                        }),
                        if (customGender != null &&
                            customGender!.trim().isNotEmpty) ...[
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.gold.withValues(alpha: 0.12),
                          ),
                          InkWell(
                            onTap: () => onCustomGenderRequested(
                              initialValue: customGender,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 11,
                              ),
                              color: selectedGender == 'Prefiero decirlo yo'
                                  ? AppColors.accent.withValues(alpha: 0.08)
                                  : AppColors.surfaceSoft
                                      .withValues(alpha: 0.18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.gold
                                          .withValues(alpha: 0.16),
                                      border: Border.all(
                                        color: AppColors.gold,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      customGender!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: AppColors.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 12,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Editar',
                                    style: GoogleFonts.inter(
                                      color: AppColors.accent,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
