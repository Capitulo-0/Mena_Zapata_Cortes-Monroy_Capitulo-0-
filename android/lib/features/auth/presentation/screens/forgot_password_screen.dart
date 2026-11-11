import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/auth_repository.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/forgot_password_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.auth});
  final AuthRepository auth;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final ForgotPasswordController _controller;
  @override
  void initState() {
    super.initState();
    _controller = ForgotPasswordController(widget.auth)..addListener(_refresh);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _continueEmail() async {
    final error = await _controller.sendResetEmail();
    if (mounted && error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  onBackToLogin: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
