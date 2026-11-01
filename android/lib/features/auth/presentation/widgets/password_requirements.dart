import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({
    super.key,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecial,
  });

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REQUISITOS DE CONTRASEÑA',
            style: GoogleFonts.cinzel(
              color: AppColors.deep,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 7),
          _Requirement(label: '8 caracteres mínimo', fulfilled: hasMinLength),
          const SizedBox(height: 5),
          _Requirement(label: 'Una letra mayúscula', fulfilled: hasUppercase),
          const SizedBox(height: 5),
          _Requirement(label: 'Una letra minúscula', fulfilled: hasLowercase),
          const SizedBox(height: 5),
          _Requirement(label: 'Un número', fulfilled: hasNumber),
          const SizedBox(height: 5),
          _Requirement(
            label: 'Un carácter especial (@, -, _, !, etc.)',
            fulfilled: hasSpecial,
          ),
        ],
      ),
    );
  }
}

class PasswordConfirmationStatus extends StatelessWidget {
  const PasswordConfirmationStatus({
    super.key,
    required this.matches,
  });

  final bool matches;

  @override
  Widget build(BuildContext context) {
    final color = matches
        ? const Color(0xFF6F8F57)
        : const Color(0xFFB75A52);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(
              matches ? Icons.check_rounded : Icons.close_rounded,
              size: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              matches
                  ? 'Las contraseñas coinciden'
                  : 'Las contraseñas no son iguales',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({
    required this.label,
    required this.fulfilled,
  });

  final String label;
  final bool fulfilled;

  @override
  Widget build(BuildContext context) {
    final color = fulfilled
        ? const Color(0xFF6F8F57)
        : AppColors.textSecondary.withValues(alpha: 0.82);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fulfilled
                ? const Color(0xFF6F8F57).withValues(alpha: 0.13)
                : Colors.transparent,
            border: Border.all(
              color: fulfilled
                  ? const Color(0xFF6F8F57).withValues(alpha: 0.72)
                  : AppColors.gold.withValues(alpha: 0.24),
            ),
          ),
          child: Icon(
            fulfilled ? Icons.check_rounded : Icons.circle_outlined,
            size: fulfilled ? 11 : 7,
            color: color,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: GoogleFonts.inter(
              color: color,
              fontSize: 7.8,
              fontWeight:
                  fulfilled ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
