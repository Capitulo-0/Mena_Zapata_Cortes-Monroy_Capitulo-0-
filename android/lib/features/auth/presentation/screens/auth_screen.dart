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

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  final registerNameController = TextEditingController();
  final registerBirthDateController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerConfirmPasswordController = TextEditingController();

  String? selectedGender;

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
          'BIENVENIDO DE NUEVO',
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
            hintText: 'tu@correo.com',
            prefixIcon: Icons.email_outlined,
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
            prefixIcon: Icons.lock_outline,
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
          text: 'Iniciar sesión',
          onPressed: () {
            if (loginEmailController.text.trim().isEmpty ||
                loginPasswordController.text.isEmpty) {
              showTemporaryMessage(
                'Completa el correo y la contraseña.',
              );
              return;
            }

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
        _buildLabel('Nombre completo'),
        const SizedBox(height: 7),
        TextField(
          controller: registerNameController,
          decoration: _inputDecoration(
            hintText: 'Ej: Constanza Mena',
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
            hintText: 'tu@correo.com',
            prefixIcon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: registerPasswordController,
          obscureText: obscurePassword,
          decoration: _inputDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline,
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
        const SizedBox(height: 16),
        _buildLabel('Confirmar contraseña'),
        const SizedBox(height: 7),
        TextField(
          controller: registerConfirmPasswordController,
          obscureText: obscureConfirmPassword,
          decoration: _inputDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline,
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
        const SizedBox(height: 22),
        _buildPrimaryButton(
          text: 'Crear cuenta',
          onPressed: _register,
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
      'No binario',
      'Prefiero no decirlo',
    ];

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              isGenderMenuOpen = !isGenderMenuOpen;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isGenderMenuOpen
                    ? AppColors.gold
                    : AppColors.gold.withValues(alpha: 0.55),
                width: isGenderMenuOpen ? 1.15 : 1,
              ),
              boxShadow: isGenderMenuOpen
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 20,
                  color: AppColors.deep,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedGender ?? 'Selecciona una opción',
                    style: GoogleFonts.inter(
                      color: selectedGender == null
                          ? AppColors.textSecondary
                          : AppColors.deep,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isGenderMenuOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isGenderMenuOpen
                        ? AppColors.gold
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: isGenderMenuOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.96, end: 1),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        alignment: Alignment.topCenter,
                        child: child,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: options.map((option) {
                          final selected = selectedGender == option;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedGender = option;
                                isGenderMenuOpen = false;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              color: selected
                                  ? AppColors.gold.withValues(alpha: 0.10)
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: GoogleFonts.inter(
                                        color: selected
                                            ? AppColors.deep
                                            : AppColors.textPrimary,
                                        fontSize: 11.5,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: AppColors.gold,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
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
        size: 20,
      ),
      suffixIcon: suffix,
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
        color: AppColors.deep,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: () {
          showTemporaryMessage(
            'Inicio con Google simulado.',
          );
        },
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
          backgroundColor: AppColors.surface,
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
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    registerBirthDateController.text =
        '${selectedDate.day.toString().padLeft(2, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.year}';
  }

  void _register() {
    if (registerNameController.text.trim().isEmpty ||
        registerBirthDateController.text.trim().isEmpty ||
        selectedGender == null ||
        registerEmailController.text.trim().isEmpty ||
        registerPasswordController.text.isEmpty ||
        registerConfirmPasswordController.text.isEmpty) {
      showTemporaryMessage(
        'Completa todos los campos.',
      );
      return;
    }

    if (registerPasswordController.text !=
        registerConfirmPasswordController.text) {
      showTemporaryMessage(
        'Las contraseñas no coinciden.',
      );
      return;
    }

    showTemporaryMessage(
      'Registro simulado correctamente.',
    );
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
