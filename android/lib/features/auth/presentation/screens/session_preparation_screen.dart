import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/session_controller.dart';
import '../widgets/forgot_password_widgets.dart';

class SessionPreparationScreen extends StatelessWidget {
  const SessionPreparationScreen({super.key, required this.session});
  final SessionController session;
  @override
  Widget build(BuildContext context) {
    final verification = session.phase == SessionPhase.verificationRequired;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const RecoveryHeader(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      verification
                          ? 'Verifica tu correo'
                          : session.busy
                          ? 'Preparando tu cuenta'
                          : 'Falta preparar tu cuenta',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      verification
                          ? 'Tu cuenta Firebase está creada. Abre el enlace de verificación enviado a tu correo para continuar.'
                          : 'Tu autenticación Firebase está activa. Confirmaremos tu usuario interno antes de entrar.',
                    ),
                    if (session.message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        session.message!,
                        key: const ValueKey('session-message'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (session.busy)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      FilledButton(
                        onPressed: session.retry,
                        child: Text(
                          verification
                              ? 'Ya verifiqué mi correo'
                              : 'Reintentar',
                        ),
                      ),
                      if (verification)
                        TextButton(
                          onPressed: session.resendVerification,
                          child: const Text('Reenviar enlace de verificación'),
                        ),
                      TextButton(
                        onPressed: session.logout,
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
