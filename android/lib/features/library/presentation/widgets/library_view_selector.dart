import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class LibraryViewSelector extends StatelessWidget {
  const LibraryViewSelector({
    super.key,
    required this.view,
    required this.onChanged,
  });

  final String view;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isBooks = view == 'libros';

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.55),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment:
                    isBooks ? Alignment.centerLeft : Alignment.centerRight,
                child: SizedBox(
                  width: constraints.maxWidth / 2,
                  height: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.deepOf(context),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepOf(context)
                              .withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ViewButton(
                      active: isBooks,
                      label: '📚 Libros',
                      onTap: () => onChanged('libros'),
                    ),
                  ),
                  Expanded(
                    child: _ViewButton(
                      active: !isBooks,
                      label: '☷ Mis listas',
                      onTap: () => onChanged('listas'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.active,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 210),
        curve: Curves.easeOutCubic,
        style: GoogleFonts.inter(
          color: active
              ? AppColors.gold
              : AppColors.textPrimaryOf(context),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
        child: SizedBox(
          height: 36,
          child: Center(child: Text(label)),
        ),
      ),
    );
  }
}
