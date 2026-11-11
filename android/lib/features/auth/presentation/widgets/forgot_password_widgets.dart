import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/forgot_password_controller.dart';

class RecoveryHeader extends StatelessWidget {
  const RecoveryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.deep, AppColors.deepAlt],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Image.asset(
                'assets/images/logo_capitulo0.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'CAPÍTULO 0',
            style: GoogleFonts.cinzel(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 39,
                height: 1,
                color: AppColors.gold.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 8),
              Text(
                '✦',
                style: TextStyle(
                  color: AppColors.gold.withValues(alpha: 0.88),
                  fontSize: 8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 39,
                height: 1,
                color: AppColors.gold.withValues(alpha: 0.72),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecoveryStepIndicator extends StatelessWidget {
  const RecoveryStepIndicator({
    super.key,
    required this.stepNumber,
  });

  final int stepNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (int index = 1; index <= 2; index++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index <= stepNumber
                      ? AppColors.accent
                      : AppColors.surfaceSoft,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: GoogleFonts.inter(
                    color: index <= stepNumber
                        ? AppColors.background
                        : AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (index < 2)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 2,
                    color: index < stepNumber
                        ? AppColors.gold
                        : AppColors.surfaceSoft,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Paso $stepNumber de 2',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

InputDecoration recoveryInputDecoration({
  required String hintText,
  IconData? prefixIcon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.surface,
    hintStyle: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 12,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.gold.withValues(alpha: 0.55),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.gold,
        width: 1.2,
      ),
    ),
  );
}

class RecoveryLabel extends StatelessWidget {
  const RecoveryLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.deep,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class RecoveryPrimaryButton extends StatelessWidget {
  const RecoveryPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          elevation: 4,
          shadowColor: AppColors.accent.withValues(alpha: 0.24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class RecoveryStepContent extends StatelessWidget {
  const RecoveryStepContent({
    super.key,
    required this.controller,
    required this.onEmailContinue,
    required this.onBackToLogin,
  });

  final ForgotPasswordController controller;
  final VoidCallback onEmailContinue;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    switch (controller.currentStep) {
      case RecoveryStep.email:
        return _emailStep();
      case RecoveryStep.success:
        return _successStep();
    }
  }

  Widget _emailStep() {
    return Column(
      key: const ValueKey('email-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecoveryStepIndicator(stepNumber: controller.stepNumber),
        const SizedBox(height: 28),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 48,
          color: AppColors.gold,
        ),
        const SizedBox(height: 16),
        Text(
          '¿OLVIDASTE TU CONTRASEÑA?',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa el correo asociado a tu cuenta y te enviaremos un enlace de recuperación.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const RecoveryLabel('Correo electrónico'),
        const SizedBox(height: 7),
        TextField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: recoveryInputDecoration(
            hintText: 'correo@ejemplo.com',
            prefixIcon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 22),
        RecoveryPrimaryButton(
          text: controller.busy ? 'Enviando...' : 'Enviar enlace',
          onPressed: controller.busy ? null : onEmailContinue,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onBackToLogin,
          child: Text(
            'Volver al inicio de sesión',
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _successStep() {
    return Column(
      key: const ValueKey('success-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecoveryStepIndicator(stepNumber: controller.stepNumber),
        const SizedBox(height: 34),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: AppColors.gold,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'ENLACE ENVIADO',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Si existe una cuenta con ese correo, recibirás un enlace de Firebase para cambiar tu contraseña. Abre el enlace y luego vuelve para iniciar sesión.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        RecoveryPrimaryButton(
          text: 'Volver al inicio de sesión',
          onPressed: onBackToLogin,
        ),
      ],
    );
  }
}
