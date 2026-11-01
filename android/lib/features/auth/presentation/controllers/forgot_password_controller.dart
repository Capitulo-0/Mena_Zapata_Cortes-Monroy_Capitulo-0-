import 'package:flutter/material.dart';

enum RecoveryStep { email, code, newPassword, success }

class ForgotPasswordController extends ChangeNotifier {
  RecoveryStep currentStep = RecoveryStep.email;

  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

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

  String? validateEmailStep() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }

    if (!email.contains('@')) {
      return 'Ingresa un correo electrónico válido.';
    }

    currentStep = RecoveryStep.code;
    notifyListeners();
    return null;
  }

  String? validateCodeStep() {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      return 'Ingresa el código de verificación.';
    }

    if (code.length != 6) {
      return 'El código debe tener 6 dígitos.';
    }

    currentStep = RecoveryStep.newPassword;
    notifyListeners();
    return null;
  }

  String? validatePasswordStep() {
    final password = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      return 'Completa ambas contraseñas.';
    }

    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }

    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden.';
    }

    currentStep = RecoveryStep.success;
    notifyListeners();
    return null;
  }

  bool moveBack() {
    if (currentStep == RecoveryStep.email) {
      return false;
    }

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

    notifyListeners();
    return true;
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
