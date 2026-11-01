import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/home/presentation/screens/main_shell_screen.dart';

enum AppStage { splash, auth, main }

class CapituloCeroApp extends StatefulWidget {
  const CapituloCeroApp({super.key});

  @override
  State<CapituloCeroApp> createState() => _CapituloCeroAppState();
}

class _CapituloCeroAppState extends State<CapituloCeroApp> {
  AppStage stage = AppStage.splash;

  bool isGuest = false;
  bool isDarkMode = false;
  bool _authStartsInLogin = true;

  void _finishSplash() {
    setState(() {
      stage = AppStage.auth;
      _authStartsInLogin = true;
    });
  }

  void _enterApp(bool guest) {
    setState(() {
      isGuest = guest;
      stage = AppStage.main;
    });
  }

  void _openAuth({required bool login}) {
    setState(() {
      isGuest = false;
      _authStartsInLogin = login;
      stage = AppStage.auth;
    });
  }

  void _logout() {
    _openAuth(login: true);
  }

  void _changeDarkMode(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capítulo 0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _buildCurrentStage(),
    );
  }

  Widget _buildCurrentStage() {
    switch (stage) {
      case AppStage.splash:
        return SplashScreen(onFinished: _finishSplash);

      case AppStage.auth:
        return AuthScreen(
          initialLogin: _authStartsInLogin,
          onAuthenticated: _enterApp,
        );

      case AppStage.main:
        return MainShellScreen(
          isGuest: isGuest,
          onLogout: _logout,
          onGuestLoginRequested: () => _openAuth(login: true),
          onGuestRegisterRequested: () => _openAuth(login: false),
          isDarkMode: isDarkMode,
          onDarkModeChanged: _changeDarkMode,
        );
    }
  }
}
