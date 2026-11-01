import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onAuthenticated,
  });

  final ValueChanged<bool> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final ScrollController _scrollController = ScrollController();

  bool isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isGenderMenuOpen = false;
  bool isLoggingIn = false;
  bool isRegistering = false;
  int loginDots = 1;

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  final registerNameController = TextEditingController();
  final registerBirthDateController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerConfirmPasswordController = TextEditingController();

  String? selectedGender;
  String? customGender;

  bool get _passwordHasMinLength =>
      registerPasswordController.text.length >= 8;

  bool get _passwordHasUppercase =>
      RegExp(r'[A-Z]').hasMatch(registerPasswordController.text);

  bool get _passwordHasLowercase =>
      RegExp(r'[a-z]').hasMatch(registerPasswordController.text);

  bool get _passwordHasNumber =>
      RegExp(r'[0-9]').hasMatch(registerPasswordController.text);

  bool get _passwordHasSpecial =>
      RegExp(r'[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>/?`~]')
          .hasMatch(registerPasswordController.text);

  bool get _passwordIsValid =>
      _passwordHasMinLength &&
      _passwordHasUppercase &&
      _passwordHasLowercase &&
      _passwordHasNumber &&
      _passwordHasSpecial;

  @override
  void dispose() {
    _scrollController.dispose();

    loginEmailController.dispose();
    loginPasswordController.dispose();

    registerNameController.dispose();
    registerBirthDateController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();

    super.dispose();
  }

  void showTemporaryMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _changeTab(bool login) {
    if (isLogin == login) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    setState(() {
      isLogin = login;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // En login el header parte grande y se compacta al hacer scroll.
          // En registro parte compacto desde el inicio y NO cambia de tamaño:
          // simplemente sube con el resto del contenido, igual que el mockup.
          if (isLogin)
            SliverPersistentHeader(
              pinned: true,
              delegate: _AuthHeaderDelegate(
                topPadding: topPadding,
              ),
            )
          else
            SliverToBoxAdapter(
              child: _AuthHeaderVisual(
                compact: true,
                topPadding: topPadding,
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _buildTabs(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: isLogin
                    ? _buildLoginForm()
                    : _buildRegisterForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Iniciar sesión',
              selected: isLogin,
              onTap: () => _changeTab(true),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Registrarse',
              selected: !isLogin,
              onTap: () => _changeTab(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.deep : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: selected ? AppColors.gold : AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
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
        _buildLabel('Correo electrónico'),
        const SizedBox(height: 7),
        TextField(
          controller: loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            hintText: 'tucorreo@example.com',
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: loginPasswordController,
          obscureText: obscurePassword,
          decoration: _inputDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
              iconSize: 50,
              splashRadius: 18,
              icon: Icon(
                obscurePassword
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
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 8,
              ),
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
        _buildPrimaryButton(
          text: isLoggingIn
              ? 'Entrando${'.' * loginDots}'
              : 'Iniciar sesión',
          loading: isLoggingIn,
          onPressed: isLoggingIn
              ? null
              : () async {
                  if (loginEmailController.text.trim().isEmpty ||
                      loginPasswordController.text.isEmpty) {
                    showTemporaryMessage(
                      'Completa el correo y la contraseña.',
                    );
                    return;
                  }

                  setState(() {
                    isLoggingIn = true;
                    loginDots = 1;
                  });

                  for (var step = 0; step < 4; step++) {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 250),
                    );

                    if (!mounted) return;

                    setState(() {
                      loginDots = (loginDots % 3) + 1;
                    });
                  }

                  if (!mounted) return;

                  widget.onAuthenticated(false);
                },
        ),
        const SizedBox(height: 12),
        _buildGuestOutlinedButton(),
        const SizedBox(height: 18),
        _buildDivider('o continúa con'),
        const SizedBox(height: 16),
        _buildGoogleButton(),
        const SizedBox(height: 16),
        _buildBottomSwitch(
          text: '¿Aún no tienes cuenta?',
          actionText: 'Regístrate',
          onPressed: () => _changeTab(false),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
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
        _buildLabel('Nombre y apellido'),
        const SizedBox(height: 7),
        TextField(
          controller: registerNameController,
          decoration: _inputDecoration(
            hintText: 'Ej: Juan Perez',
            prefixIcon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Fecha de nacimiento'),
        const SizedBox(height: 7),
        TextField(
          controller: registerBirthDateController,
          readOnly: true,
          onTap: _selectBirthDate,
          decoration: _inputDecoration(
            hintText: 'dd-mm-aaaa',
            prefixIcon: Icons.calendar_today_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Género'),
        const SizedBox(height: 7),
        _buildGenderSelector(),
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
        _buildLabel('Correo electrónico'),
        const SizedBox(height: 7),
        TextField(
          controller: registerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            hintText: 'tucorreo@example.com',
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: registerPasswordController,
          obscureText: obscurePassword,
          onChanged: (_) {
            setState(() {});
          },
          decoration: _inputDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
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
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REQUISITOS DE CONTRASEÑA',
                style: GoogleFonts.cinzel(
                  color: AppColors.deep,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                ),
              ),
              const SizedBox(height: 7),
              _passwordRequirement(
                label: '8 caracteres mínimo',
                fulfilled: _passwordHasMinLength,
              ),
              const SizedBox(height: 5),
              _passwordRequirement(
                label: 'Una letra mayúscula',
                fulfilled: _passwordHasUppercase,
              ),
              const SizedBox(height: 5),
              _passwordRequirement(
                label: 'Una letra minúscula',
                fulfilled: _passwordHasLowercase,
              ),
              const SizedBox(height: 5),
              _passwordRequirement(
                label: 'Un número',
                fulfilled: _passwordHasNumber,
              ),
              const SizedBox(height: 5),
              _passwordRequirement(
                label: 'Un carácter especial (@, -, _, !, etc.)',
                fulfilled: _passwordHasSpecial,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Confirmar contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: registerConfirmPasswordController,
          obscureText: obscureConfirmPassword,
          onChanged: (_) {
            setState(() {});
          },
          decoration: _inputDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  obscureConfirmPassword =
                      !obscureConfirmPassword;
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
        const SizedBox(height: 8),
        if (registerConfirmPasswordController.text.isNotEmpty)
          _passwordConfirmationStatus(),
        const SizedBox(height: 22),
        _buildPrimaryButton(
          text: isRegistering ? 'Creando cuenta...' : 'Crear cuenta',
          loading: isRegistering,
          onPressed: isRegistering ? null : _register,
        ),
        const SizedBox(height: 18),
        _buildDivider('o continúa con'),
        const SizedBox(height: 16),
        _buildGoogleButton(),
        const SizedBox(height: 16),
        _buildBottomSwitch(
          text: '¿Ya tienes cuenta?',
          actionText: 'Inicia sesión',
          onPressed: () => _changeTab(true),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    final options = <String>[
      'Mujer',
      'Hombre',
      'Prefiero no decirlo',
      'Prefiero decirlo yo',
    ];

    final displayGender =
        selectedGender == 'Prefiero decirlo yo' &&
                customGender != null &&
                customGender!.trim().isNotEmpty
            ? customGender!.trim()
            : selectedGender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              isGenderMenuOpen = !isGenderMenuOpen;
            });
          },
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isGenderMenuOpen
                    ? AppColors.gold
                    : AppColors.gold.withValues(alpha: 0.55),
                width: isGenderMenuOpen ? 1.35 : 1,
              ),
              boxShadow: isGenderMenuOpen
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayGender ?? 'Selecciona una opción',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: displayGender == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isGenderMenuOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.gold,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: isGenderMenuOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.62),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(options.length, (index) {
                          final option = options[index];
                          final selected = selectedGender == option;
                          final alternate = index.isOdd;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () async {
                                  if (option == 'Prefiero decirlo yo') {
                                    setState(() {
                                      isGenderMenuOpen = false;
                                    });

                                    final value =
                                        await _openCustomGenderEditor();

                                    if (!mounted || value == null) return;

                                    setState(() {
                                      customGender = value;
                                      selectedGender = 'Prefiero decirlo yo';
                                    });
                                    return;
                                  }

                                  setState(() {
                                    selectedGender = option;
                                    isGenderMenuOpen = false;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 12,
                                  ),
                                  color: selected
                                      ? AppColors.accent
                                          .withValues(alpha: 0.08)
                                      : alternate
                                          ? AppColors.surfaceSoft
                                              .withValues(alpha: 0.34)
                                          : AppColors.surface,
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? AppColors.gold
                                                  .withValues(alpha: 0.16)
                                              : AppColors.background,
                                          border: Border.all(
                                            color: selected
                                                ? AppColors.gold
                                                : AppColors.gold
                                                    .withValues(alpha: 0.22),
                                          ),
                                        ),
                                        child: Icon(
                                          selected
                                              ? Icons.check_rounded
                                              : Icons.person_outline_rounded,
                                          size: 13,
                                          color: selected
                                              ? AppColors.gold
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: GoogleFonts.inter(
                                            color: selected
                                                ? AppColors.accent
                                                : AppColors.textPrimary,
                                            fontSize: 10,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (selected)
                                        Text(
                                          'ACTUAL',
                                          style: GoogleFonts.inter(
                                            color: AppColors.gold,
                                            fontSize: 6,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.7,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (index < options.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.gold
                                      .withValues(alpha: 0.12),
                                ),
                            ],
                          );
                        }),
                        if (customGender != null &&
                            customGender!.trim().isNotEmpty) ...[
                          Divider(
                            height: 1,
                            thickness: 1,
                            color:
                                AppColors.gold.withValues(alpha: 0.12),
                          ),
                          InkWell(
                            onTap: () async {
                              setState(() {
                                isGenderMenuOpen = false;
                              });

                              final value = await _openCustomGenderEditor(
                                initialValue: customGender,
                              );

                              if (!mounted || value == null) return;

                              setState(() {
                                customGender = value;
                                selectedGender = 'Prefiero decirlo yo';
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 11,
                              ),
                              color: selectedGender == 'Prefiero decirlo yo'
                                  ? AppColors.accent
                                      .withValues(alpha: 0.08)
                                  : AppColors.surfaceSoft
                                      .withValues(alpha: 0.18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          AppColors.gold.withValues(alpha: 0.16),
                                      border: Border.all(
                                        color: AppColors.gold,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      customGender!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: AppColors.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 12,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Editar',
                                    style: GoogleFonts.inter(
                                      color: AppColors.accent,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<String?> _openCustomGenderEditor({
    String? initialValue,
  }) async {
    final controller = TextEditingController(
      text: initialValue ?? '',
    );

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canSave = controller.text.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.42),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Cuál es tu género?',
                                  style: GoogleFonts.cinzel(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  initialValue == null
                                      ? 'Escribe cómo quieres identificarte en la aplicación.'
                                      : 'Edita cómo quieres identificarte en la aplicación.',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 8.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () =>
                                Navigator.of(sheetContext).pop(),
                            borderRadius: BorderRadius.circular(999),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondary,
                                size: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        maxLength: 50,
                        maxLines: 1,
                        textCapitalization:
                            TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setSheetState(() {}),
                        onSubmitted: (_) {
                          if (controller.text.trim().isNotEmpty) {
                            Navigator.of(sheetContext)
                                .pop(controller.text.trim());
                          }
                        },
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ej. No binario',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.70),
                            fontSize: 10,
                          ),
                          counterStyle: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 7,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 13,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide(
                              color: AppColors.gold
                                  .withValues(alpha: 0.44),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(11)),
                            borderSide: BorderSide(
                              color: AppColors.gold,
                              width: 1.25,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 36,
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    AppColors.textSecondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedOpacity(
                            duration:
                                const Duration(milliseconds: 140),
                            opacity: canSave ? 1 : 0.42,
                            child: SizedBox(
                              width: 92,
                              height: 36,
                              child: FilledButton(
                                onPressed: canSave
                                    ? () {
                                        Navigator.of(sheetContext).pop(
                                          controller.text.trim(),
                                        );
                                      }
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor:
                                      AppColors.background,
                                  disabledBackgroundColor:
                                      AppColors.accent
                                          .withValues(alpha: 0.30),
                                  disabledForegroundColor:
                                      AppColors.background
                                          .withValues(alpha: 0.75),
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Listo',
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 280),
    );
    controller.dispose();

    return result;
  }

  Widget _passwordConfirmationStatus() {
    final matches = registerPasswordController.text.isNotEmpty &&
        registerConfirmPasswordController.text ==
            registerPasswordController.text;

    final color = matches
        ? const Color(0xFF6F8F57)
        : const Color(0xFFB75A52);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(
              matches
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              size: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              matches
                  ? 'Las contraseñas coinciden'
                  : 'Las contraseñas no son iguales',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordRequirement({
    required String label,
    required bool fulfilled,
  }) {
    final color = fulfilled
        ? const Color(0xFF6F8F57)
        : AppColors.textSecondary.withValues(alpha: 0.82);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fulfilled
                ? const Color(0xFF6F8F57).withValues(alpha: 0.13)
                : Colors.transparent,
            border: Border.all(
              color: fulfilled
                  ? const Color(0xFF6F8F57).withValues(alpha: 0.72)
                  : AppColors.gold.withValues(alpha: 0.24),
            ),
          ),
          child: Icon(
            fulfilled
                ? Icons.check_rounded
                : Icons.circle_outlined,
            size: fulfilled ? 11 : 7,
            color: color,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: GoogleFonts.inter(
              color: color,
              fontSize: 7.8,
              fontWeight:
                  fulfilled ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        prefixIcon,
        size: 18,
        color: AppColors.textSecondary.withValues(alpha: 0.68),
      ),
      prefixIconColor:
          AppColors.textSecondary.withValues(alpha: 0.72),
      suffixIcon: suffix,
      suffixIconColor:
          AppColors.textSecondary.withValues(alpha: 0.72),
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
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
        color: AppColors.textSecondary.withValues(alpha: 0.82),
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      height: 48,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          boxShadow: loading
              ? const []
              : [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: loading
                ? const Color(0xFF747474)
                : AppColors.accent,
            disabledBackgroundColor: const Color(0xFF747474),
            foregroundColor: AppColors.background,
            disabledForegroundColor:
                AppColors.background.withValues(alpha: 0.92),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            child: Text(
              text,
              key: ValueKey(text),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(
          Icons.g_mobiledata_rounded,
          size: 22,
        ),
        label: Text(
          'Continuar con Google',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deep,
          disabledForegroundColor: AppColors.deep,
          backgroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.surface,
          side: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.55),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestOutlinedButton() {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: () {
          widget.onAuthenticated(true);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.42),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Text(
          'Iniciar como invitado',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.gold.withValues(alpha: 0.30),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.gold.withValues(alpha: 0.30),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSwitch({
    required String text,
    required String actionText,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            actionText,
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    DateTime selectedDate = DateTime(2000, 1, 1);

    final existing = registerBirthDateController.text.trim();
    if (existing.isNotEmpty) {
      final parts = existing.split('-');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          selectedDate = DateTime(year, month, day);
        }
      }
    }

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (sheetContext) {
        var draftDate = selectedDate;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.cake_outlined,
                            color: AppColors.gold,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FECHA DE NACIMIENTO',
                                style: GoogleFonts.cinzel(
                                  color: AppColors.deep,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Selecciona tu fecha de nacimiento.',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 8.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            '${draftDate.day.toString().padLeft(2, '0')} / '
                            '${draftDate.month.toString().padLeft(2, '0')} / '
                            '${draftDate.year}',
                            style: GoogleFonts.merriweather(
                              color: AppColors.deep,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    CalendarDatePicker(
                      initialDate: draftDate,
                      firstDate: DateTime(1900),
                      lastDate: now,
                      onDateChanged: (date) {
                        setSheetState(() {
                          draftDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 15,
                              ),
                              label: Text(
                                'Cancelar',
                                style: GoogleFonts.inter(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                backgroundColor: AppColors.background,
                                side: BorderSide(
                                  color: AppColors.gold.withValues(alpha: 0.38),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop(draftDate);
                              },
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                              ),
                              label: Text(
                                'Confirmar fecha',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.deep,
                                foregroundColor: AppColors.gold,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                  side: BorderSide(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.48),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    registerBirthDateController.text =
        '${result.day.toString().padLeft(2, '0')}-'
        '${result.month.toString().padLeft(2, '0')}-'
        '${result.year}';
  }

  void _showAuthErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          duration: const Duration(milliseconds: 2200),
          padding: EdgeInsets.zero,
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFB75A52)
                    .withValues(alpha: 0.68),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB75A52),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.merriweather(
                      color: const Color(0xFF7A3732),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.gold.withValues(alpha: 0.72),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
  }

  Future<void> _register() async {
    if (registerNameController.text.trim().isEmpty ||
        registerBirthDateController.text.trim().isEmpty ||
        selectedGender == null ||
        registerEmailController.text.trim().isEmpty ||
        registerPasswordController.text.isEmpty ||
        registerConfirmPasswordController.text.isEmpty) {
      _showAuthErrorMessage(
        'Completa todos los campos',
      );
      return;
    }

    if (!_passwordIsValid) {
      _showAuthErrorMessage(
        'La contraseña no cumple los requisitos',
      );
      return;
    }

    if (registerPasswordController.text !=
        registerConfirmPasswordController.text) {
      _showAuthErrorMessage(
        'Las contraseñas no son iguales',
      );
      return;
    }

    setState(() {
      isRegistering = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 2500),
    );

    if (!mounted) return;

    setState(() {
      isRegistering = false;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          duration: const Duration(milliseconds: 1500),
          padding: EdgeInsets.zero,
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF78935F)
                    .withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFF708A56),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Cuenta creada correctamente',
                    style: GoogleFonts.merriweather(
                      color: const Color(0xFF3F4F33),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.gold.withValues(alpha: 0.76),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );

    await Future<void>.delayed(
      const Duration(milliseconds: 1500),
    );

    if (!mounted) return;

    registerNameController.clear();
    registerBirthDateController.clear();
    registerEmailController.clear();
    registerPasswordController.clear();
    registerConfirmPasswordController.clear();

    setState(() {
      selectedGender = null;
      customGender = null;
      isGenderMenuOpen = false;
      obscurePassword = true;
      obscureConfirmPassword = true;
    });

    _changeTab(true);
  }

}

class _AuthHeaderDelegate extends SliverPersistentHeaderDelegate {
  _AuthHeaderDelegate({
    required this.topPadding,
  });

  final double topPadding;

  @override
  double get minExtent => topPadding + 118;

  @override
  double get maxExtent => topPadding + 218;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final available = maxExtent - minExtent;

    final progress = available <= 0
        ? 1.0
        : (shrinkOffset / available).clamp(0.0, 1.0);

    return _AuthHeaderVisual(
      compact: progress >= 0.70,
      progress: progress,
      topPadding: 0,
      showShadow: overlapsContent || progress > 0.05,
    );
  }

  @override
  bool shouldRebuild(covariant _AuthHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding;
  }
}

class _AuthHeaderVisual extends StatelessWidget {
  const _AuthHeaderVisual({
    required this.compact,
    required this.topPadding,
    this.progress,
    this.showShadow = false,
  });

  final bool compact;
  final double topPadding;
  final double? progress;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final t = progress ?? (compact ? 1.0 : 0.0);

    final logoSize = 92 - (34 * t);
    final titleSize = 22 - (6 * t);
    final headerTop = 22 - (13 * t);
    final headerBottom = 20 - (10 * t);
    final logoRadius = 22 - (5 * t);
    final logoMargin = 12 - (5 * t);
    final lineWidth = 50 - (16 * t);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        topPadding + headerTop,
        24,
        headerBottom,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deep,
            AppColors.deepAlt,
            Color(0xFF2E1510),
          ],
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 4,
            child: Opacity(
              opacity: 0.50,
              child: Text(
                '✦',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12 - (3 * t),
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 34 - (9 * t),
            child: Opacity(
              opacity: 0.30,
              child: Text(
                '✦',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 8 - (1 * t),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(logoRadius),
                    color: Colors.white.withValues(alpha: 0.025),
                    border: Border.all(
                      color: AppColors.gold.withValues(
                        alpha: 0.36 + (0.04 * (1 - t)),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.28 + (0.10 * (1 - t)),
                        ),
                        blurRadius: 14 + (8 * (1 - t)),
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      logoRadius - 1,
                    ),
                    child: Image.asset(
                      'assets/images/logo_capitulo0.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: logoMargin),
                Text(
                  'CAPÍTULO 0',
                  style: GoogleFonts.cinzel(
                    color: AppColors.gold,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.1 + (0.9 * (1 - t)),
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 4 + (2 * (1 - t))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: lineWidth,
                      height: 1,
                      color: AppColors.gold.withValues(
                        alpha: compact ? 0.50 : 0.72,
                      ),
                    ),
                    SizedBox(width: compact ? 5 : 8),
                    Text(
                      '✦',
                      style: TextStyle(
                        color: AppColors.gold.withValues(
                          alpha: compact ? 0.50 : 0.82,
                        ),
                        fontSize: 7,
                      ),
                    ),
                    SizedBox(width: compact ? 5 : 8),
                    Container(
                      width: lineWidth,
                      height: 1,
                      color: AppColors.gold.withValues(
                        alpha: compact ? 0.50 : 0.72,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
