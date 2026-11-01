import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_login_form.dart';
import '../widgets/auth_register_form.dart';
import '../widgets/auth_sheets.dart';
import '../widgets/auth_tabs.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onAuthenticated,
    this.initialLogin = true,
  });

  final ValueChanged<bool> onAuthenticated;
  final bool initialLogin;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController(initialLogin: widget.initialLogin)
      ..addListener(_refresh);
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

  Future<void> _login() async {
    if (!_controller.loginFieldsAreValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el correo y la contraseña.'),
        ),
      );
      return;
    }

    await _controller.simulateLogin();

    if (!mounted) return;
    widget.onAuthenticated(false);
  }

  Future<void> _guestLogin() async {
    await _controller.simulateGuestLogin();

    if (!mounted) return;
    widget.onAuthenticated(true);
  }

  Future<void> _register() async {
    final validation = _controller.validateRegister();

    switch (validation) {
      case RegisterValidationResult.missingFields:
        showAuthErrorMessage(context, 'Completa todos los campos');
        return;
      case RegisterValidationResult.invalidPassword:
        showAuthErrorMessage(
          context,
          'La contraseña no cumple los requisitos',
        );
        return;
      case RegisterValidationResult.passwordMismatch:
        showAuthErrorMessage(
          context,
          'Las contraseñas no son iguales',
        );
        return;
      case RegisterValidationResult.valid:
        break;
    }

    await _controller.simulateRegister();

    if (!mounted) return;

    showAccountCreatedMessage(context);

    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    _controller.resetRegisterForm();
    _controller.setLoginTab(true);
  }

  Future<void> _selectBirthDate() async {
    final result = await showBirthDateSheet(
      context,
      existingValue: _controller.registerBirthDateController.text.trim(),
    );

    if (!mounted || result == null) return;

    _controller.setBirthDate(result);
  }

  Future<void> _selectCustomGender({String? initialValue}) async {
    _controller.closeGenderMenu();

    final value = await showCustomGenderSheet(
      context,
      initialValue: initialValue,
    );

    if (!mounted || value == null) return;

    _controller.setCustomGender(value);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _controller.scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          if (_controller.isLogin)
            SliverPersistentHeader(
              pinned: true,
              delegate: AuthHeaderDelegate(
                topPadding: topPadding,
              ),
            )
          else
            SliverToBoxAdapter(
              child: AuthHeaderVisual(
                compact: true,
                topPadding: topPadding,
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(
              child: AuthTabs(
                isLogin: _controller.isLogin,
                onLoginTap: () => _controller.setLoginTab(true),
                onRegisterTap: () => _controller.setLoginTab(false),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _controller.isLogin
                    ? AuthLoginForm(
                        controller: _controller,
                        onLogin: _login,
                        onGuestLogin: _guestLogin,
                        onRegisterRequested: () =>
                            _controller.setLoginTab(false),
                      )
                    : AuthRegisterForm(
                        controller: _controller,
                        onBirthDateRequested: _selectBirthDate,
                        onCustomGenderRequested: _selectCustomGender,
                        onRegister: _register,
                        onLoginRequested: () =>
                            _controller.setLoginTab(true),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
