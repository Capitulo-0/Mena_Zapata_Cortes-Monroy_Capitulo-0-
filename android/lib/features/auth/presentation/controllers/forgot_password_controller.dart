import 'package:flutter/material.dart';

import '../../domain/auth_repository.dart';

enum RecoveryStep { email, success }

class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController(this.auth);
  final AuthRepository auth;
  RecoveryStep currentStep = RecoveryStep.email;
  final emailController = TextEditingController();
  bool busy = false;
  bool _disposed = false;
  int get stepNumber => currentStep == RecoveryStep.email ? 1 : 2;

  Future<String?> sendResetEmail() async {
    if (busy) return null;
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      return 'Ingresa un correo electrónico válido.';
    }
    busy = true;
    notifyListeners();
    try {
      await auth.sendPasswordResetEmail(email);
      if (!_disposed) currentStep = RecoveryStep.success;
      return null;
    } on AuthFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return 'No pudimos enviar el enlace. Inténtalo nuevamente.';
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    emailController.dispose();
    super.dispose();
  }
}
