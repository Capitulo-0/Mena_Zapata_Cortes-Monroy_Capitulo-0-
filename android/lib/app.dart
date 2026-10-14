import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

class CapituloCeroApp extends StatefulWidget {
  const CapituloCeroApp({super.key});

  @override
  State<CapituloCeroApp> createState() => _CapituloCeroAppState();
}

class _CapituloCeroAppState extends State<CapituloCeroApp> {
  bool _showSplash = true;

  void _finishSplash() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capítulo 0',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,

      home: _showSplash
          ? SplashScreen(onFinished: _finishSplash)
          : const AuthScreen(),
    );
  }
}
