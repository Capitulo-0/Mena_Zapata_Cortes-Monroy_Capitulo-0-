import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/config/firebase_configuration.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/data/admin_verification_repository.dart';
import 'features/admin/presentation/screens/admin_verifications_screen.dart';
import 'features/auth/data/account_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/presentation/controllers/session_controller.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/session_preparation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final options = FirebaseWebConfiguration.optionsForPlatform(isWeb: kIsWeb);
    await Firebase.initializeApp(options: options);

    final auth = FirebaseAuthRepository();
    final api = ApiClient(auth: auth);
    final session = SessionController(
      auth: auth,
      accounts: ApiAccountRepository(api),
    );

    runApp(CapituloCeroAdminApp(session: session, api: api));
  } on FirebaseConfigurationException catch (error) {
    runApp(_AdminStartupFailure(message: error.message));
  } catch (_) {
    runApp(
      const _AdminStartupFailure(
        message: 'No pudimos iniciar el panel administrativo.',
      ),
    );
  }
}

class CapituloCeroAdminApp extends StatefulWidget {
  const CapituloCeroAdminApp({
    super.key,
    required this.session,
    required this.api,
  });

  final SessionController session;
  final ApiClient api;

  @override
  State<CapituloCeroAdminApp> createState() => _CapituloCeroAdminAppState();
}

class _CapituloCeroAdminAppState extends State<CapituloCeroAdminApp> {
  late final AdminVerificationRepository _repository =
      ApiAdminVerificationRepository(widget.api);

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_sessionChanged);
    widget.session.start();
  }

  void _sessionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_sessionChanged);
    widget.api.close();
    super.dispose();
  }

  Future<void> _logout() async {
    await widget.session.logout();
  }

  Widget _buildScreen() {
    switch (widget.session.phase) {
      case SessionPhase.ready:
        return AdminVerificationsScreen(
          key: ValueKey(widget.session.uid),
          repository: _repository,
          onLogout: () {
            _logout();
          },
        );

      case SessionPhase.signedOut:
        return AuthScreen(
          session: widget.session,
          initialLogin: true,
          onAuthenticated: (guest) {
            if (guest) {
              widget.session.enterGuest();
            }
          },
        );

      case SessionPhase.guest:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 52),
                const SizedBox(height: 16),
                const Text('El panel administrativo requiere iniciar sesión.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: widget.session.leaveGuest,
                  child: const Text('Iniciar sesión'),
                ),
              ],
            ),
          ),
        );

      case SessionPhase.preparing:
      case SessionPhase.verificationRequired:
      case SessionPhase.backendFailure:
        return SessionPreparationScreen(session: widget.session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capítulo 0 | Administración',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: _buildScreen(),
    );
  }
}

class _AdminStartupFailure extends StatelessWidget {
  const _AdminStartupFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
