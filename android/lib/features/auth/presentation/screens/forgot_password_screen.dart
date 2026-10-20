import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

enum RecoveryStep { email, code, newPassword, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  RecoveryStep currentStep = RecoveryStep.email;

  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void goToCode() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage('Ingresa tu correo electrónico.');
      return;
    }

    if (!email.contains('@')) {
      showMessage('Ingresa un correo electrónico válido.');
      return;
    }

    setState(() => currentStep = RecoveryStep.code);
  }

  void verifyCode() {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      showMessage('Ingresa el código de verificación.');
      return;
    }

    if (code.length != 6) {
      showMessage('El código debe tener 6 dígitos.');
      return;
    }

    setState(() => currentStep = RecoveryStep.newPassword);
  }

  void changePassword() {
    final password = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      showMessage('Completa ambas contraseñas.');
      return;
    }

    if (password.length < 6) {
      showMessage('La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Las contraseñas no coinciden.');
      return;
    }

    setState(() => currentStep = RecoveryStep.success);
  }

  void goBack() {
    if (currentStep == RecoveryStep.email) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      switch (currentStep) {
        case RecoveryStep.email:
          break;
        case RecoveryStep.code:
          currentStep = RecoveryStep.email;
          break;
        case RecoveryStep.newPassword:
          currentStep = RecoveryStep.code;
          break;
        case RecoveryStep.success:
          currentStep = RecoveryStep.newPassword;
          break;
      }
    });
  }

  int get stepNumber {
    switch (currentStep) {
      case RecoveryStep.email:
        return 1;
      case RecoveryStep.code:
        return 2;
      case RecoveryStep.newPassword:
        return 3;
      case RecoveryStep.success:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case RecoveryStep.email:
        return _buildEmailStep();
      case RecoveryStep.code:
        return _buildCodeStep();
      case RecoveryStep.newPassword:
        return _buildPasswordStep();
      case RecoveryStep.success:
        return _buildSuccessStep();
    }
  }

  Widget _buildStepIndicator() {
    return Column(
      children: [
        Row(
          children: [
            for (int index = 1; index <= 4; index++) ...[
              _buildStepCircle(index),
              if (index < 4)
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
          'Paso $stepNumber de 4',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int index) {
    final active = index <= stepNumber;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.accent : AppColors.surfaceSoft,
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: GoogleFonts.inter(
          color: active ? AppColors.background : AppColors.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey('email-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(),
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
          'Ingresa el correo asociado a tu cuenta y te enviaremos un código de recuperación.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Correo electrónico'),
        const SizedBox(height: 7),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            hintText: 'correo@ejemplo.com',
            prefixIcon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 22),
        _buildPrimaryButton(
          text: 'Enviar código',
          onPressed: goToCode,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildCodeStep() {
    return Column(
      key: const ValueKey('code-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 28),
        const Icon(
          Icons.password_rounded,
          size: 48,
          color: AppColors.gold,
        ),
        const SizedBox(height: 16),
        Text(
          'VERIFICA TU CORREO',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enviamos un código de 6 dígitos a ${emailController.text.trim()}.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Código de verificación'),
        const SizedBox(height: 7),
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.inter(
            color: AppColors.deep,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
          ),
          decoration: _inputDecoration(
            hintText: '0 0 0 0 0 0',
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: 22),
        _buildPrimaryButton(
          text: 'Verificar código',
          onPressed: verifyCode,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            showMessage('Código reenviado de forma simulada.');
          },
          child: Text(
            'Reenviar código',
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

  Widget _buildPasswordStep() {
    return Column(
      key: const ValueKey('password-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 28),
        const Icon(
          Icons.lock_reset_rounded,
          size: 50,
          color: AppColors.gold,
        ),
        const SizedBox(height: 16),
        Text(
          'CREA UNA NUEVA CONTRASEÑA',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu nueva contraseña debe tener al menos 6 caracteres.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Nueva contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: newPasswordController,
          obscureText: obscurePassword,
          decoration: _inputDecoration(
            hintText: 'Ingresa tu nueva contraseña',
            prefixIcon: Icons.lock_outline,
            suffix: IconButton(
              onPressed: () {
                setState(() => obscurePassword = !obscurePassword);
              },
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Confirmar contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          decoration: _inputDecoration(
            hintText: 'Repite tu nueva contraseña',
            prefixIcon: Icons.lock_outline,
            suffix: IconButton(
              onPressed: () {
                setState(
                  () => obscureConfirmPassword = !obscureConfirmPassword,
                );
              },
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _buildPrimaryButton(
          text: 'Cambiar contraseña',
          onPressed: changePassword,
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      key: const ValueKey('success-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(),
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
          'CONTRASEÑA ACTUALIZADA',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tu contraseña fue modificada correctamente. Ya puedes iniciar sesión con tus nuevas credenciales.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        _buildPrimaryButton(
          text: 'Volver al inicio de sesión',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon:
          prefixIcon == null ? null : Icon(prefixIcon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.deep,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
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
