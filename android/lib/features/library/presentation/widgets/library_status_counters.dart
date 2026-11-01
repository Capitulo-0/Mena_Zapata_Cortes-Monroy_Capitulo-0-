import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class LibraryStatusCounters extends StatelessWidget {
  const LibraryStatusCounters({
    super.key,
    required this.filter,
    required this.readingCount,
    required this.pendingCount,
    required this.readCount,
    required this.onChanged,
  });

  final String filter;
  final int readingCount;
  final int pendingCount;
  final int readCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusCounterCard(
            active: filter == 'leyendo',
            label: 'Leyendo',
            count: readingCount,
            activeColor: AppColors.accentOf(context),
            activeForeground: AppColors.backgroundOf(context),
            onTap: () => onChanged('leyendo'),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _StatusCounterCard(
            active: filter == 'porLeer',
            label: 'Por leer',
            count: pendingCount,
            activeColor: AppColors.goldOf(context),
            activeForeground: AppColors.deepOf(context),
            onTap: () => onChanged('porLeer'),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _StatusCounterCard(
            active: filter == 'leidos',
            label: 'Leídos',
            count: readCount,
            activeColor: AppColors.deepOf(context),
            activeForeground: AppColors.goldOf(context),
            onTap: () => onChanged('leidos'),
          ),
        ),
      ],
    );
  }
}

class _StatusCounterCard extends StatelessWidget {
  const _StatusCounterCard({
    required this.active,
    required this.label,
    required this.count,
    required this.activeColor,
    required this.activeForeground,
    required this.onTap,
  });

  final bool active;
  final String label;
  final int count;
  final Color activeColor;
  final Color activeForeground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: active ? activeColor : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: active
                ? activeColor
                : activeColor.withValues(alpha: 0.72),
            width: active ? 1.4 : 1.05,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              scale: active ? 1.08 : 1,
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  color: active ? activeForeground : activeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: active
                    ? activeForeground
                    : AppColors.textSecondaryOf(context),
                fontSize: 7.5,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
