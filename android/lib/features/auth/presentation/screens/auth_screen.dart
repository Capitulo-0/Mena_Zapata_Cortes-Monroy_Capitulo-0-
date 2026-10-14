import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});

  final ValueChanged<bool> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
                child: Column(
                  children: [
                    _buildTabs(),
                    const SizedBox(height: 26),
                    if (isLogin) _buildLoginForm() else _buildRegisterForm(),
                  ],
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deep, AppColors.deepAlt],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.55),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
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
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tu historia comienza aquí',
            style: GoogleFonts.inter(color: AppColors.background, fontSize: 12),
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
              onTap: () {
                setState(() {
                  isLogin = true;
                });
              },
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Registrarse',
              selected: !isLogin,
              onTap: () {
                setState(() {
                  isLogin = false;
                });
              },
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
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
            color: selected ? AppColors.deep : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bienvenido de nuevo',
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa a tu cuenta para continuar tu historia.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),

        _buildLabel('Correo electrónico'),

        const SizedBox(height: 7),

        TextField(
          controller: loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'correo@ejemplo.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),

        const SizedBox(height: 18),

        _buildLabel('Contraseña'),

        const SizedBox(height: 7),

        TextField(
          controller: loginPasswordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: 'Ingresa tu contraseña',
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

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ForgotPasswordScreen(),
                ),
              );
            },
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: GoogleFonts.inter(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        _buildPrimaryButton(
          text: 'Iniciar sesión',
          onPressed: () {
            if (loginEmailController.text.trim().isEmpty ||
                loginPasswordController.text.isEmpty) {
              showTemporaryMessage('Completa el correo y la contraseña.');
              return;
            }

            widget.onAuthenticated(false);
          },
        ),

        const SizedBox(height: 18),

        _buildDivider(),

        const SizedBox(height: 18),

        _buildGoogleButton(),

        const SizedBox(height: 14),

        _buildGuestButton(),

        const SizedBox(height: 24),

        _buildBottomSwitch(
          text: '¿No tienes cuenta?',
          actionText: 'Regístrate',
          onPressed: () {
            setState(() {
              isLogin = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Crea tu cuenta',
          style: GoogleFonts.cinzel(
            color: AppColors.deep,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Únete a la comunidad de lectores y autores.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),

        _buildLabel('Nombre completo'),

        const SizedBox(height: 7),

        TextField(
          controller: registerNameController,
          decoration: const InputDecoration(
            hintText: 'Tu nombre',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),

        const SizedBox(height: 18),

        _buildLabel('Fecha de nacimiento'),

        const SizedBox(height: 7),

        TextField(
          controller: registerBirthDateController,
          readOnly: true,
          onTap: _selectBirthDate,
          decoration: const InputDecoration(
            hintText: 'Seleccionar fecha',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),

        const SizedBox(height: 18),

        _buildLabel('Género'),

        const SizedBox(height: 7),

        DropdownButtonFormField<String>(
          initialValue: selectedGender,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.people_outline),
          ),
          hint: const Text('Selecciona una opción'),
          items: const [
            DropdownMenuItem(value: 'Mujer', child: Text('Mujer')),
            DropdownMenuItem(value: 'Hombre', child: Text('Hombre')),
            DropdownMenuItem(value: 'No binario', child: Text('No binario')),
            DropdownMenuItem(
              value: 'Prefiero no decirlo',
              child: Text('Prefiero no decirlo'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              selectedGender = value;
            });
          },
        ),

        const SizedBox(height: 18),

        _buildLabel('Correo electrónico'),

        const SizedBox(height: 7),

        TextField(
          controller: registerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'correo@ejemplo.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),

        const SizedBox(height: 18),

        _buildLabel('Contraseña'),

        const SizedBox(height: 7),

        TextField(
          controller: registerPasswordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: 'Crea una contraseña',
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
          controller: registerConfirmPasswordController,
          obscureText: obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Repite tu contraseña',
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

        const SizedBox(height: 24),

        _buildPrimaryButton(text: 'Crear cuenta', onPressed: _register),

        const SizedBox(height: 18),

        _buildDivider(),

        const SizedBox(height: 18),

        _buildGoogleButton(),

        const SizedBox(height: 24),

        _buildBottomSwitch(
          text: '¿Ya tienes cuenta?',
          actionText: 'Inicia sesión',
          onPressed: () {
            setState(() {
              isLogin = true;
            });
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          showTemporaryMessage('Inicio con Google simulado.');
        },
        icon: const Icon(Icons.g_mobiledata_rounded),
        label: Text(
          'Continuar con Google',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deep,
          side: const BorderSide(color: AppColors.gold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      height: 50,
      child: TextButton(
        onPressed: () {
          widget.onAuthenticated(true);
        },
        child: Text(
          'Iniciar como invitado',
          style: GoogleFonts.inter(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.surfaceSoft)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.surfaceSoft)),
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
              fontSize: 12,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            actionText,
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
  }

  void _register() {
    if (registerNameController.text.trim().isEmpty ||
        registerBirthDateController.text.trim().isEmpty ||
        selectedGender == null ||
        registerEmailController.text.trim().isEmpty ||
        registerPasswordController.text.isEmpty ||
        registerConfirmPasswordController.text.isEmpty) {
      showTemporaryMessage('Completa todos los campos.');
      return;
    }

    if (registerPasswordController.text !=
        registerConfirmPasswordController.text) {
      showTemporaryMessage('Las contraseñas no coinciden.');
      return;
    }

    showTemporaryMessage('Registro simulado correctamente.');
  }
}
