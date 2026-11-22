import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../data/admin_verification_repository.dart';

class AdminVerificationsScreen extends StatefulWidget {
  const AdminVerificationsScreen({
    super.key,
    required this.repository,
    required this.onLogout,
  });

  final AdminVerificationRepository repository;
  final VoidCallback onLogout;

  @override
  State<AdminVerificationsScreen> createState() =>
      _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen> {
  static const _gold = Color(0xFFC6A76B);
  static const _background = Color(0xFF151311);
  static const _surface = Color(0xFF211D19);
  static const _textPrimary = Color(0xFFF5EFE6);
  static const _textSecondary = Color(0xFFBDB0A0);

  bool _loading = true;
  bool _authorized = false;
  String? _error;

  final Set<int> _processingIds = {};
  List<AdminVerification> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _requests = [];
    });

    try {
      final authorized = await widget.repository.isAdmin();

      if (!mounted) return;

      if (!authorized) {
        setState(() {
          _authorized = false;
          _loading = false;
        });
        return;
      }

      final requests = await widget.repository.pendingRequests();

      if (!mounted) return;

      setState(() {
        _authorized = true;
        _requests = requests;
        _loading = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) return;

      setState(() {
        _authorized = false;
        _requests = [];
        _loading = false;
        _error = error.statusCode == 401 || error.statusCode == 403
            ? 'Tu sesión no tiene autorización para consultar este panel.'
            : error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _authorized = false;
        _requests = [];
        _loading = false;
        _error =
            'No pudimos conectar con el servidor. '
            'Comprueba tu conexión e inténtalo nuevamente.';
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approve(AdminVerification request) async {
    if (_processingIds.contains(request.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          title: Text(
            'Confirmar aprobación',
            style: GoogleFonts.cinzel(color: _textPrimary, fontSize: 17),
          ),
          content: Text(
            '¿Confirmas que revisaste la información de '
            '${request.organizationName} y verificaste '
            'que corresponde aprobar esta organización?\n\n'
            'Esta decisión quedará registrada y se enviará '
            'una notificación al solicitante.',
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 12,
              height: 1.7,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: const Text('Confirmar aprobación'),
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _background,
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    await _processDecision(
      request,
      () => widget.repository.approve(request.id),
      'Organización aprobada correctamente.',
    );
  }

  Future<void> _reject(AdminVerification request) async {
    if (_processingIds.contains(request.id)) return;

    final controller = TextEditingController();

    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final formKey = GlobalKey<FormState>();

          return AlertDialog(
            backgroundColor: _surface,
            title: Text(
              'Rechazar solicitud',
              style: GoogleFonts.cinzel(color: _textPrimary, fontSize: 17),
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organización: ${request.organizationName}',
                      style: GoogleFonts.inter(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Indica el motivo de rechazo. '
                      'El solicitante podrá consultarlo '
                      'desde Configuración.',
                      style: GoogleFonts.inter(
                        color: _textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: controller,
                      maxLength: 1000,
                      maxLines: 4,
                      minLines: 3,
                      style: GoogleFonts.inter(
                        color: _textPrimary,
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Motivo obligatorio',
                        labelStyle: const TextStyle(color: _textSecondary),
                        hintText:
                            'Explica qué información '
                            'no pudo verificarse...',
                        hintStyle: TextStyle(
                          color: _textSecondary.withValues(alpha: 0.75),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _gold.withValues(alpha: 0.4),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: _gold),
                        ),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return 'Debes explicar el motivo';
                        }

                        if (text.length > 1000) {
                          return 'Máximo 1000 caracteres';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, controller.text.trim());
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _background,
                ),
                child: const Text('Confirmar rechazo'),
              ),
            ],
          );
        },
      );

      if (!mounted || reason == null) return;

      await _processDecision(
        request,
        () => widget.repository.reject(request.id, reason: reason),
        'Solicitud rechazada. El motivo quedó registrado.',
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _processDecision(
    AdminVerification request,
    Future<AdminVerification> Function() action,
    String successMessage,
  ) async {
    if (_processingIds.contains(request.id)) return;

    setState(() => _processingIds.add(request.id));

    try {
      await action();

      if (!mounted) return;

      setState(() {
        _requests.removeWhere((item) => item.id == request.id);
      });

      _showMessage(successMessage);
    } on ApiFailure catch (error) {
      if (!mounted) return;

      _showMessage('No pudimos completar la decisión: ${error.message}');

      if (error.statusCode == 409) {
        await _load();
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'No pudimos confirmar el resultado. '
        'Actualiza las solicitudes antes de intentarlo nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(request.id));
      }
    }
  }

  Widget _panelCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(22),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.admin_panel_settings_outlined,
            color: _gold,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAPÍTULO 0',
                style: GoogleFonts.cinzel(
                  color: _textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Panel de administración',
                style: GoogleFonts.inter(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loading || _processingIds.isNotEmpty ? null : _load,
          tooltip: 'Actualizar solicitudes',
          icon: const Icon(Icons.refresh_rounded, color: _gold),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _processingIds.isNotEmpty ? null : widget.onLogout,
          icon: const Icon(Icons.logout_rounded, size: 17),
          label: const Text('Salir'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _gold,
            side: BorderSide(color: _gold.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _message(String title, String description, IconData icon) {
    return _panelCard(
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 38),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 12,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime date) {
    final local = date.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Widget _requestCard(AdminVerification request) {
    final processing = _processingIds.contains(request.id);

    return _panelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                request.organizationName,
                style: GoogleFonts.cinzel(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  processing ? 'PROCESANDO' : 'PENDIENTE',
                  style: GoogleFonts.inter(
                    color: _gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Representante: ${request.representativeName}',
            style: GoogleFonts.inter(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Ciudad: ${request.city}',
            style: GoogleFonts.inter(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Recibida: ${_date(request.createdAt)}',
            style: GoogleFonts.inter(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: processing ? null : () => _showDetails(request),
              icon: processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.visibility_outlined, size: 18),
              label: Text(processing ? 'Procesando...' : 'Revisar solicitud'),
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _background,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    final cleanValue = value?.trim();

    if (cleanValue == null || cleanValue.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              color: _gold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          SelectableText(
            cleanValue,
            style: GoogleFonts.inter(
              color: _textPrimary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(AdminVerification request) {
    if (_processingIds.contains(request.id)) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _gold.withValues(alpha: 0.35)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Revisión de organización',
                          style: GoogleFonts.cinzel(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('ID de solicitud', request.id.toString()),
                          _detailRow(
                            'ID de usuario',
                            request.userId.toString(),
                          ),
                          _detailRow(
                            'Nombre de la organización',
                            request.organizationName,
                          ),
                          _detailRow(
                            'Nombre del representante',
                            request.representativeName,
                          ),
                          _detailRow('RUT', request.organizationRut),
                          _detailRow('Ciudad', request.city),
                          _detailRow(
                            'Dirección pública',
                            request.publicAddress,
                          ),
                          _detailRow(
                            'Correo de contacto',
                            request.contactEmail,
                          ),
                          _detailRow(
                            'Teléfono de contacto',
                            request.contactPhone,
                          ),
                          _detailRow(
                            'Sitio web o red social',
                            request.socialUrl,
                          ),
                          _detailRow(
                            'Propuesta de organización',
                            request.organizationDescription,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Aprueba únicamente después de comprobar '
                    'la identidad y los datos de la organización. '
                    'Cada decisión quedará registrada en Neon.',
                    style: GoogleFonts.inter(
                      color: _textSecondary,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _reject(request);
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Rechazar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textPrimary,
                          side: BorderSide(color: _gold.withValues(alpha: 0.5)),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _approve(request);
                        },
                        icon: const Icon(Icons.verified_rounded, size: 18),
                        label: const Text('Aprobar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: _background,
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
  }

  Widget _content() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(color: _gold),
        ),
      );
    }

    if (_error != null) {
      return _message(
        'No pudimos cargar el panel',
        _error!,
        Icons.error_outline_rounded,
      );
    }

    if (!_authorized) {
      return _message(
        'Acceso restringido',
        'Tu cuenta no tiene permisos administrativos '
            'para acceder a esta sección.',
        Icons.lock_outline_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelCard(
          child: Row(
            children: [
              const Icon(Icons.pending_actions_rounded, color: _gold, size: 34),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_requests.length}',
                      style: GoogleFonts.cinzel(
                        color: _textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Solicitudes pendientes',
                      style: GoogleFonts.inter(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'SOLICITUDES POR REVISAR',
          style: GoogleFonts.inter(
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        if (_requests.isEmpty)
          _message(
            'Todo está al día',
            'No hay solicitudes pendientes de revisión.',
            Icons.task_alt_rounded,
          )
        else
          ..._requests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _requestCard(request),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1060),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 38),
                  Text(
                    'Verificación de organizadores',
                    style: GoogleFonts.cinzel(
                      color: _textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Revisa las organizaciones que desean crear '
                    'clubes de lectura en nuestra comunidad.',
                    style: GoogleFonts.inter(
                      color: _textSecondary,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _content(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
