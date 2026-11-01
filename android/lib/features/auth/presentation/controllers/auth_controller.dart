import 'package:flutter/material.dart';

enum RegisterValidationResult {
  valid,
  missingFields,
  invalidPassword,
  passwordMismatch,
}

class AuthController extends ChangeNotifier {
  AuthController({bool initialLogin = true}) : isLogin = initialLogin;

  final ScrollController scrollController = ScrollController();

  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();

  final TextEditingController registerNameController = TextEditingController();
  final TextEditingController registerBirthDateController = TextEditingController();
  final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController registerPasswordController = TextEditingController();
  final TextEditingController registerConfirmPasswordController = TextEditingController();

  bool isLogin;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isGenderMenuOpen = false;
  bool isLoggingIn = false;
  bool isRegistering = false;
  bool isGuestLoading = false;
  int loginDots = 1;

  String? selectedGender;
  String? customGender;

  bool get passwordHasMinLength =>
      registerPasswordController.text.length >= 8;

  bool get passwordHasUppercase =>
      RegExp(r'[A-Z]').hasMatch(registerPasswordController.text);

  bool get passwordHasLowercase =>
      RegExp(r'[a-z]').hasMatch(registerPasswordController.text);

  bool get passwordHasNumber =>
      RegExp(r'[0-9]').hasMatch(registerPasswordController.text);

  bool get passwordHasSpecial =>
      RegExp(r'[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>/?`~]')
          .hasMatch(registerPasswordController.text);

  bool get passwordIsValid =>
      passwordHasMinLength &&
      passwordHasUppercase &&
      passwordHasLowercase &&
      passwordHasNumber &&
      passwordHasSpecial;

  bool get passwordsMatch =>
      registerPasswordController.text.isNotEmpty &&
      registerConfirmPasswordController.text ==
          registerPasswordController.text;

  void setLoginTab(bool login) {
    if (isLogin == login) {
      _scrollToTop();
      return;
    }

    isLogin = login;
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  void toggleGenderMenu() {
    isGenderMenuOpen = !isGenderMenuOpen;
    notifyListeners();
  }

  void closeGenderMenu() {
    if (!isGenderMenuOpen) return;
    isGenderMenuOpen = false;
    notifyListeners();
  }

  void selectGender(String value) {
    selectedGender = value;
    isGenderMenuOpen = false;
    notifyListeners();
  }

  void setCustomGender(String value) {
    customGender = value.trim();
    selectedGender = 'Prefiero decirlo yo';
    isGenderMenuOpen = false;
    notifyListeners();
  }

  void setBirthDate(DateTime date) {
    registerBirthDateController.text =
        '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
    notifyListeners();
  }

  void refreshPasswordState() {
    notifyListeners();
  }

  bool get loginFieldsAreValid =>
      loginEmailController.text.trim().isNotEmpty &&
      loginPasswordController.text.isNotEmpty;

  Future<void> simulateLogin() async {
    isLoggingIn = true;
    loginDots = 1;
    notifyListeners();

    for (var step = 0; step < 4; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      loginDots = (loginDots % 3) + 1;
      notifyListeners();
    }
  }

  Future<void> simulateGuestLogin() async {
    isGuestLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 2500));
  }

  RegisterValidationResult validateRegister() {
    if (registerNameController.text.trim().isEmpty ||
        registerBirthDateController.text.trim().isEmpty ||
        selectedGender == null ||
        registerEmailController.text.trim().isEmpty ||
        registerPasswordController.text.isEmpty ||
        registerConfirmPasswordController.text.isEmpty) {
      return RegisterValidationResult.missingFields;
    }

    if (!passwordIsValid) {
      return RegisterValidationResult.invalidPassword;
    }

    if (!passwordsMatch) {
      return RegisterValidationResult.passwordMismatch;
    }

    return RegisterValidationResult.valid;
  }

  Future<void> simulateRegister() async {
    isRegistering = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 2500));

    isRegistering = false;
    notifyListeners();
  }

  void resetRegisterForm() {
    registerNameController.clear();
    registerBirthDateController.clear();
    registerEmailController.clear();
    registerPasswordController.clear();
    registerConfirmPasswordController.clear();

    selectedGender = null;
    customGender = null;
    isGenderMenuOpen = false;
    obscurePassword = true;
    obscureConfirmPassword = true;

    notifyListeners();
  }

  void _scrollToTop() {
    if (!scrollController.hasClients) return;

    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    registerNameController.dispose();
    registerBirthDateController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
    super.dispose();
  }
}
