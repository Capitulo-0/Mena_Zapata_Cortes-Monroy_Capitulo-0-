import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

enum RecoveryStep { email, code, newPassword, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
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

    setState(() {
      currentStep = RecoveryStep.code;
    });
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

    setState(() {
      currentStep = RecoveryStep.newPassword;
    });
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

    setState(() {
      currentStep = RecoveryStep.success;
    });
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
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deep, AppColors.deepAlt],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: goBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.background,
              ),
              const Spacer(),
              Text(
                'Recuperar contraseña',
                style: GoogleFonts.cinzel(
                  color: AppColors.background,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/logo_capitulo0.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'CAPÍTULO 0',
            style: GoogleFonts.cinzel(
              color: AppColors.gold,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
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
                  child: Container(
                    height: 2,
                    color: index < stepNumber
                        ? AppColors.gold
                        : AppColors.surfaceSoft,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Paso $stepNumber de 4',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int index) {
    final completed = index <= stepNumber;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? AppColors.accent : AppColors.surfaceSoft,
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: GoogleFonts.inter(
          color: completed ? AppColors.background : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
        const SizedBox(height: 34),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 54,
          color: AppColors.gold,
        ),
        const SizedBox(height: 18),
        Text(
          '¿Olvidaste tu contraseña?',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ingresa el correo asociado a tu cuenta y te enviaremos un código de recuperación.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        _buildLabel('Correo electrónico'),
        const SizedBox(height: 7),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'correo@ejemplo.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 26),
        _buildPrimaryButton(text: 'Enviar código', onPressed: goToCode),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Volver al inicio de sesión',
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
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
        const SizedBox(height: 34),
        const Icon(Icons.password_rounded, size: 54, color: AppColors.gold),
        const SizedBox(height: 18),
        Text(
          'Verifica tu correo',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enviamos un código de 6 dígitos a ${emailController.text.trim()}.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
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
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 10,
          ),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '000000',
          ),
        ),
        const SizedBox(height: 26),
        _buildPrimaryButton(text: 'Verificar código', onPressed: verifyCode),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () {
            showMessage('Código reenviado de forma simulada.');
          },
          child: Text(
            'Reenviar código',
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
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
        const SizedBox(height: 34),
        const Icon(Icons.lock_reset_rounded, size: 56, color: AppColors.gold),
        const SizedBox(height: 18),
        Text(
          'Crea una nueva contraseña',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tu nueva contraseña debe tener al menos 6 caracteres.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        _buildLabel('Nueva contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: newPasswordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: 'Ingresa tu nueva contraseña',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _buildLabel('Confirmar contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Repite tu nueva contraseña',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  obscureConfirmPassword = !obscureConfirmPassword;
                });
              },
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
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
        const SizedBox(height: 42),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold.withValues(alpha: 0.16),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 62,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Contraseña actualizada',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tu contraseña fue modificada correctamente. Ya puedes iniciar sesión con tus nuevas credenciales.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 34),
        _buildPrimaryButton(
          text: 'Volver al inicio de sesión',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.deep,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
