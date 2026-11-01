import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import 'auth_common_widgets.dart';
import 'auth_gender_selector.dart';
import 'password_requirements.dart';

class AuthRegisterForm extends StatelessWidget {
  const AuthRegisterForm({
    super.key,
    required this.controller,
    required this.onBirthDateRequested,
    required this.onCustomGenderRequested,
    required this.onRegister,
    required this.onLoginRequested,
  });

  final AuthController controller;
  final Future<void> Function() onBirthDateRequested;
  final Future<void> Function({String? initialValue}) onCustomGenderRequested;
  final Future<void> Function() onRegister;
  final VoidCallback onLoginRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('register-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CREA TU CUENTA',
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 21,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Únete a la comunidad de lectores y autores.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 22),
        const AuthFieldLabel('Nombre y apellido'),
        const SizedBox(height: 7),
        TextField(
          controller: controller.registerNameController,
          decoration: authInputDecoration(
            hintText: 'Ej: Juan Perez',
            prefixIcon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 16),
        const AuthFieldLabel('Fecha de nacimiento'),
        const SizedBox(height: 7),
        TextField(
          controller: controller.registerBirthDateController,
          readOnly: true,
          onTap: onBirthDateRequested,
          decoration: authInputDecoration(
            hintText: 'dd-mm-aaaa',
            prefixIcon: Icons.calendar_today_outlined,
          ),
        ),
        const SizedBox(height: 16),
        const AuthFieldLabel('Género'),
        const SizedBox(height: 7),
        AuthGenderSelector(
          selectedGender: controller.selectedGender,
          customGender: controller.customGender,
          isOpen: controller.isGenderMenuOpen,
          onToggle: controller.toggleGenderMenu,
          onSelect: controller.selectGender,
          onCustomGenderRequested: onCustomGenderRequested,
        ),
        const SizedBox(height: 5),
        Text(
          'Puedes elegir “Prefiero no decirlo” si no deseas compartir esta información.',
          style: GoogleFonts.inter(
            fontSize: 7,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        const AuthFieldLabel('Correo electrónico'),
        const SizedBox(height: 7),
        TextField(
          controller: controller.registerEmailController,
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
          controller: controller.registerPasswordController,
          obscureText: controller.obscurePassword,
          onChanged: (_) => controller.refreshPasswordState(),
          decoration: authInputDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: controller.togglePasswordVisibility,
              icon: Icon(
                controller.obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        PasswordRequirements(
          hasMinLength: controller.passwordHasMinLength,
          hasUppercase: controller.passwordHasUppercase,
          hasLowercase: controller.passwordHasLowercase,
          hasNumber: controller.passwordHasNumber,
          hasSpecial: controller.passwordHasSpecial,
        ),
        const SizedBox(height: 16),
        const AuthFieldLabel('Confirmar contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: controller.registerConfirmPasswordController,
          obscureText: controller.obscureConfirmPassword,
          onChanged: (_) => controller.refreshPasswordState(),
          decoration: authInputDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: controller.toggleConfirmPasswordVisibility,
              icon: Icon(
                controller.obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (controller.registerConfirmPasswordController.text.isNotEmpty)
          PasswordConfirmationStatus(
            matches: controller.passwordsMatch,
          ),
        const SizedBox(height: 22),
        AuthPrimaryButton(
          text:
              controller.isRegistering ? 'Creando cuenta...' : 'Crear cuenta',
          loading: controller.isRegistering,
          onPressed: controller.isRegistering ? null : onRegister,
        ),
        const SizedBox(height: 18),
        const AuthDivider('o continúa con'),
        const SizedBox(height: 16),
        const AuthGoogleButton(),
        const SizedBox(height: 16),
        AuthBottomSwitch(
          text: '¿Ya tienes cuenta?',
          actionText: 'Inicia sesión',
          onPressed: onLoginRequested,
        ),
      ],
    );
  }
}
