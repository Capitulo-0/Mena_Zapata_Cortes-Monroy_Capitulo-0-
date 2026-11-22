import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/session_controller.dart';
import '../widgets/forgot_password_widgets.dart';
import '../widgets/auth_legal_documents.dart';

class SessionPreparationScreen extends StatefulWidget {
  const SessionPreparationScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<SessionPreparationScreen> createState() =>
      _SessionPreparationScreenState();
}

class _SessionPreparationScreenState extends State<SessionPreparationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final verification = session.phase == SessionPhase.verificationRequired;

    final background = AppColors.background;
    final surface = AppColors.surface;
    final gold = AppColors.gold;
    final deep = AppColors.deep;
    final accent = AppColors.accent;
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            children: [
              const RecoveryHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: gold.withValues(alpha: 0.38)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: gold.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Icon(
                            verification
                                ? Icons.mark_email_read_outlined
                                : session.busy
                                ? Icons.sync_rounded
                                : Icons.person_outline_rounded,
                            size: 34,
                            color: deep,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: gold.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Text(
                            verification
                                ? 'VERIFICACIÓN PENDIENTE'
                                : session.busy
                                ? 'PREPARANDO SESIÓN'
                                : 'CONFIGURACIÓN PENDIENTE',
                            style: GoogleFonts.inter(
                              color: deep,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        verification
                            ? 'Verifica tu correo'
                            : session.busy
                            ? 'Preparando tu cuenta'
                            : 'Falta preparar tu cuenta',
                        textAlign: TextAlign.left,
                        style: GoogleFonts.inter(
                          color: textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        verification
                            ? 'Tu cuenta ya fue creada correctamente. Solo falta confirmar tu correo electrónico para que puedas entrar a Capítulo 0.'
                            : 'Tu autenticación con Firebase ya está activa. Confirmaremos tu usuario interno antes de entrar a la app.',
                        style: GoogleFonts.inter(
                          color: textSecondary,
                          fontSize: 13.5,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (verification) ...[
                        _InfoPanel(
                          icon: Icons.info_outline_rounded,
                          title: '¿Qué debes hacer ahora?',
                          description: 'Abre el correo que te enviamos, pulsa el enlace de verificación y luego vuelve aquí para continuar.',
                        ),
                        const SizedBox(height: 14),
                        _StepRow(
                          number: '1',
                          text: 'Revisa tu bandeja de entrada.',
                        ),
                        const SizedBox(height: 10),
                        _StepRow(
                          number: '2',
                          text: 'Abre el enlace de verificación.',
                        ),
                        const SizedBox(height: 10),
                        _StepRow(
                          number: '3',
                          text: 'Regresa a la app y pulsa “Ya verifiqué mi correo”.',
                        ),
                      ],
                      if (!verification && session.usernameRequired) ...[
                        const SizedBox(height: 6),
                        _InfoPanel(
                          icon: Icons.alternate_email_rounded,
                          title: 'Falta tu nombre de usuario',
                          description: 'Antes de entrar, necesitamos que elijas cómo se verá tu usuario dentro de la app.',
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Nombre de usuario',
                          style: GoogleFonts.inter(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameController,
                          onChanged: (_) => setState(() {}),
                          maxLength: 30,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          style: GoogleFonts.inter(
                            color: textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ej: edu_lector',
                            hintStyle: GoogleFonts.inter(
                              color: textSecondary.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              color: deep,
                            ),
                            filled: true,
                            fillColor: background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: gold.withValues(alpha: 0.25),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: gold.withValues(alpha: 0.28),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: accent, width: 1.4),
                            ),
                          ),
                        ),
                      ],
                      if (!verification && session.legalConsentRequired) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Antes de crear tu usuario en Capítulo 0, debes aceptar ambos documentos.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AuthLegalConsentCheckbox(
                          value: _termsAccepted,
                          title: 'Términos y condiciones',
                          document: LegalDocument.terms,
                          onChanged: (value) =>
                              setState(() => _termsAccepted = value),
                        ),
                        AuthLegalConsentCheckbox(
                          value: _privacyAccepted,
                          title: 'Política de privacidad',
                          document: LegalDocument.privacy,
                          onChanged: (value) =>
                              setState(() => _privacyAccepted = value),
                        ),
                      ],
                      if (session.message != null) ...[
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: accent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  session.message!,
                                  key: const ValueKey('session-message'),
                                  style: GoogleFonts.inter(
                                    color: textPrimary,
                                    fontSize: 12.5,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      if (session.busy)
                        Column(
                          children: [
                            const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              verification
                                  ? 'Esperando confirmación de tu cuenta...'
                                  : 'Preparando acceso...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        if (!verification && session.legalConsentRequired)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  _termsAccepted &&
                                      _privacyAccepted &&
                                      (!session.usernameRequired ||
                                          _usernameController.text
                                              .trim()
                                              .isNotEmpty)
                                  ? () => session.submitLegalConsent(
                                      username: session.usernameRequired
                                          ? _usernameController.text
                                          : null,
                                    )
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: const Text('Aceptar y continuar'),
                            ),
                          )
                        else if (!verification && session.usernameRequired)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => session.submitUsername(
                                _usernameController.text,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Guardar nombre de usuario',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: session.retry,
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                verification
                                    ? 'Ya verifiqué mi correo'
                                    : 'Reintentar',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        if (verification) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: session.resendVerification,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                minimumSize: const Size.fromHeight(50),
                                side: BorderSide(
                                  color: gold.withValues(alpha: 0.50),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Reenviar enlace de verificación',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: session.logout,
                            child: Text(
                              'Cerrar sesión',
                              style: GoogleFonts.inter(
                                color: accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.deep, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12.2,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.deep,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 12.8,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
