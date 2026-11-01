import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../screens/forgot_password_screen.dart';
import 'auth_common_widgets.dart';

class AuthLoginForm extends StatelessWidget {
  const AuthLoginForm({
    super.key,
    required this.controller,
    required this.onLogin,
    required this.onGuestLogin,
    required this.onRegisterRequested,
  });

  final AuthController controller;
  final Future<void> Function() onLogin;
  final Future<void> Function() onGuestLogin;
  final VoidCallback onRegisterRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('login-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¡Qué gusto verte!',
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 21,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Ingresa a tu cuenta para continuar tu historia.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 22),
        const AuthFieldLabel('Correo electrónico'),
        const SizedBox(height: 7),
        TextField(
          controller: controller.loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: authInputDecoration(
            hintText: 'tucorreo@example.com',
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        const AuthFieldLabel('Contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: controller.loginPasswordController,
          obscureText: controller.obscurePassword,
          decoration: authInputDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: controller.togglePasswordVisibility,
              iconSize: 50,
              splashRadius: 18,
              icon: Icon(
                controller.obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary.withValues(alpha: 0.35),
                size: 23,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
            ),
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        AuthPrimaryButton(
          text: controller.isLoggingIn
              ? 'Entrando${'.' * controller.loginDots}'
              : 'Iniciar sesión',
          loading: controller.isLoggingIn,
          onPressed: controller.isLoggingIn ? null : onLogin,
        ),
        const SizedBox(height: 12),
        _GuestButton(
          loading: controller.isGuestLoading,
          onPressed: controller.isGuestLoading ? null : onGuestLogin,
        ),
        const SizedBox(height: 18),
        const AuthDivider('o continúa con'),
        const SizedBox(height: 16),
        const AuthGoogleButton(),
        const SizedBox(height: 16),
        AuthBottomSwitch(
          text: '¿Aún no tienes cuenta?',
          actionText: 'Regístrate',
          onPressed: onRegisterRequested,
        ),
      ],
    );
  }
}

class _GuestButton extends StatelessWidget {
  const _GuestButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          disabledForegroundColor: AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.surface,
          side: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.42),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              loading
                  ? 'Iniciando como invitado...'
                  : 'Iniciar como invitado',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
