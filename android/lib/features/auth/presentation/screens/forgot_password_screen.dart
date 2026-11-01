import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/forgot_password_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final ForgotPasswordController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ForgotPasswordController()..addListener(_refresh);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _continueEmail() {
    final error = _controller.validateEmailStep();
    if (error != null) _showMessage(error);
  }

  void _continueCode() {
    final error = _controller.validateCodeStep();
    if (error != null) _showMessage(error);
  }

  void _continuePassword() {
    final error = _controller.validatePasswordStep();
    if (error != null) _showMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const RecoveryHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: RecoveryStepContent(
                    controller: _controller,
                    onEmailContinue: _continueEmail,
                    onCodeContinue: _continueCode,
                    onPasswordContinue: _continuePassword,
                    onBackToLogin: () => Navigator.of(context).pop(),
                    onResendCode: () {
                      _showMessage('Código reenviado de forma simulada.');
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
