part of '../screens/settings_screen.dart';

extension _SettingsVerificationSection on _SettingsScreenState {
  Widget _buildVerificationSettings() {
    return _OrganizerVerificationPanel(
      key: const ValueKey('settings-verification'),
      repository: widget.verificationRepository,
      surface: _surface,
      surfaceSoft: _surfaceSoft,
      textPrimary: _textPrimary,
      textSecondary: _textSecondary,
      gold: _gold,
      accent: _accent,
    );
  }
}

class _OrganizerVerificationPanel extends StatefulWidget {
  const _OrganizerVerificationPanel({
    super.key,
    required this.repository,
    required this.surface,
    required this.surfaceSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.gold,
    required this.accent,
  });

  final OrganizerVerificationRepository? repository;
  final Color surface;
  final Color surfaceSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color gold;
  final Color accent;

  @override
  State<_OrganizerVerificationPanel> createState() =>
      _OrganizerVerificationPanelState();
}

class _OrganizerVerificationPanelState
    extends State<_OrganizerVerificationPanel> {
  final _formKey = GlobalKey<FormState>();

  OrganizerVerification? _verification;

  bool _loading = true;
  bool _submitting = false;
  bool _showForm = false;
  String? _error;

  String _representativeName = '';
  String _organizationName = '';
  String _organizationRut = '';
  String _city = '';
  String _publicAddress = '';
  String _contactEmail = '';
  String _contactPhone = '';
  String _socialUrl = '';
  String _organizationDescription = '';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final repository = widget.repository;

    if (repository == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await repository.myStatus();

      if (!mounted) return;

      setState(() {
        _verification = result;
        _loading = false;
      });
    } on ApiFailure catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'No pudimos consultar tu verificación. '
            'Inténtalo nuevamente.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting || widget.repository == null) return;

    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await widget.repository!.submit(
        OrganizerVerificationForm(
          representativeName: _representativeName.trim(),
          organizationName: _organizationName.trim(),
          organizationRut: _optional(_organizationRut),
          city: _city.trim(),
          publicAddress: _optional(_publicAddress),
          contactEmail: _contactEmail.trim(),
          contactPhone: _contactPhone.trim(),
          socialUrl: _optional(_socialUrl),
          organizationDescription: _organizationDescription.trim(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _verification = result;
        _showForm = false;
        _submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Solicitud enviada! Te avisaremos cuando sea revisada.',
          ),
        ),
      );
    } on ApiFailure catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _submitting = false;
      });

      if (error.statusCode == 409) {
        setState(() {
          _showForm = false;
        });
        await _loadStatus();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'No pudimos enviar la solicitud. '
            'Revisa tu conexión e inténtalo nuevamente.';
        _submitting = false;
      });
    }
  }

  String? _optional(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _required(String? value, int maxLength) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Este campo es obligatorio';
    }

    if (text.length > maxLength) {
      return 'Máximo $maxLength caracteres';
    }

    return null;
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: widget.textSecondary.withValues(alpha: 0.75),
        fontSize: 11,
      ),
      prefixIcon: Icon(icon, color: widget.gold, size: 19),
      filled: true,
      fillColor: widget.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.gold.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.gold.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.gold, width: 1.5),
      ),
    );
  }

  Widget _field({
    required String title,
    required String hint,
    required IconData icon,
    required int maxLength,
    required ValueChanged<String> onSaved,
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            required ? '$title *' : title,
            style: GoogleFonts.inter(
              color: widget.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            maxLength: maxLength,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(color: widget.textPrimary, fontSize: 12),
            decoration: _decoration(hint, icon),
            validator:
                validator ??
                (value) {
                  if (required) {
                    return _required(value, maxLength);
                  }
                  if ((value?.trim().length ?? 0) > maxLength) {
                    return 'Máximo $maxLength caracteres';
                  }
                  return null;
                },
            onSaved: (value) => onSaved(value ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: widget.gold, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cinzel(
                    color: widget.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: widget.textSecondary,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.gold.withValues(alpha: 0.30)),
      ),
      child: child,
    );
  }

  Widget _message(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: widget.gold, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: widget.textSecondary,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _intro() {
    return _card(
      Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: widget.gold.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(color: widget.gold.withValues(alpha: 0.35)),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: widget.gold,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Crea encuentros alrededor de los libros',
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              color: widget.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            '¿Tienes una cafetería, librería, biblioteca, '
            'emprendimiento o espacio cultural? '
            'Verifica tu organización para conectar lectores, '
            'organizar encuentros y crear clubes de lectura '
            'en Capítulo 0.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: widget.textSecondary,
              fontSize: 11,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final verification = _verification;

    if (verification == null) {
      return _message(
        'Aún no tienes solicitudes de verificación.',
        Icons.info_outline_rounded,
      );
    }

    final title = switch (verification.status) {
      OrganizerVerificationStatus.pending => 'Solicitud pendiente de revisión',
      OrganizerVerificationStatus.approved => '¡Organización verificada!',
      OrganizerVerificationStatus.rejected => 'Tu solicitud fue rechazada',
    };

    final description = switch (verification.status) {
      OrganizerVerificationStatus.pending =>
        'Recibimos tu solicitud para ${verification.organizationName}. '
            'Nuestro equipo revisará la información y '
            'te avisará en Notificaciones.',
      OrganizerVerificationStatus.approved =>
        'Tu organización ${verification.organizationName} '
            'ha sido aprobada. Ya tienes autorización '
            'para crear clubes de lectura.',
      OrganizerVerificationStatus.rejected =>
        'La solicitud de ${verification.organizationName} '
            'no fue aprobada. Puedes revisar el motivo '
            'y enviar una nueva solicitud.',
    };

    final icon = switch (verification.status) {
      OrganizerVerificationStatus.pending => Icons.hourglass_top_rounded,
      OrganizerVerificationStatus.approved => Icons.verified_rounded,
      OrganizerVerificationStatus.rejected => Icons.info_outline_rounded,
    };

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: widget.gold, size: 27),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cinzel(
                    color: widget.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: GoogleFonts.inter(
              color: widget.textSecondary,
              fontSize: 11,
              height: 1.6,
            ),
          ),
          if (verification.status == OrganizerVerificationStatus.rejected &&
              verification.reviewReason != null &&
              verification.reviewReason!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _message(
              'Motivo: ${verification.reviewReason}',
              Icons.assignment_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading(
                  'Sobre ti',
                  'Cuéntanos quién representa a la organización.',
                  Icons.person_outline_rounded,
                ),
                _field(
                  title: 'Nombre del representante',
                  hint: 'Nombre y apellido',
                  icon: Icons.badge_outlined,
                  maxLength: 150,
                  onSaved: (value) => _representativeName = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading(
                  'Tu organización',
                  'Queremos conocer el espacio donde '
                      'se reunirá nuestra comunidad.',
                  Icons.storefront_outlined,
                ),
                _field(
                  title: 'Nombre de la organización',
                  hint: 'Ej. Café Entre Páginas',
                  icon: Icons.store_outlined,
                  maxLength: 200,
                  onSaved: (value) => _organizationName = value,
                ),
                _field(
                  title: 'RUT de la organización',
                  hint: 'Opcional, si corresponde',
                  icon: Icons.assignment_outlined,
                  maxLength: 20,
                  required: false,
                  onSaved: (value) => _organizationRut = value,
                ),
                _field(
                  title: 'Ciudad',
                  hint: 'Ej. Santiago',
                  icon: Icons.location_city_outlined,
                  maxLength: 120,
                  onSaved: (value) => _city = value,
                ),
                _field(
                  title: 'Dirección pública',
                  hint: 'Opcional, solo dirección comercial',
                  icon: Icons.place_outlined,
                  maxLength: 300,
                  required: false,
                  onSaved: (value) => _publicAddress = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading(
                  'Contacto',
                  'Usaremos estos datos para comunicarnos '
                      'y revisar tu solicitud.',
                  Icons.contact_mail_outlined,
                ),
                _field(
                  title: 'Correo de contacto',
                  hint: 'contacto@organizacion.cl',
                  icon: Icons.email_outlined,
                  maxLength: 320,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final requiredError = _required(value, 320);
                    if (requiredError != null) return requiredError;

                    final email = value!.trim();
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                  onSaved: (value) => _contactEmail = value,
                ),
                _field(
                  title: 'Teléfono de contacto',
                  hint: 'Ej. +56 9 1234 5678',
                  icon: Icons.phone_outlined,
                  maxLength: 40,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final requiredError = _required(value, 40);
                    if (requiredError != null) return requiredError;

                    if (value!.trim().length < 7) {
                      return 'Ingresa un teléfono válido';
                    }
                    return null;
                  },
                  onSaved: (value) => _contactPhone = value,
                ),
                _field(
                  title: 'Sitio web o red social',
                  hint: 'https://...',
                  icon: Icons.language_rounded,
                  maxLength: 2048,
                  required: false,
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;

                    if (text.length > 2048) {
                      return 'Máximo 2048 caracteres';
                    }

                    final uri = Uri.tryParse(text);
                    if (uri == null ||
                        !uri.hasAuthority ||
                        (uri.scheme != 'https' && uri.scheme != 'http')) {
                      return 'Ingresa un enlace http o https válido';
                    }
                    return null;
                  },
                  onSaved: (value) => _socialUrl = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading(
                  'Tu propuesta lectora',
                  'Cuéntanos qué tipo de encuentros '
                      'te gustaría organizar.',
                  Icons.menu_book_rounded,
                ),
                _field(
                  title: 'Descripción de tu propuesta',
                  hint:
                      'Describe tu organización, '
                      'la comunidad que quieres reunir '
                      'y tus ideas para los clubes...',
                  icon: Icons.edit_note_rounded,
                  maxLength: 2000,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  onSaved: (value) => _organizationDescription = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _message(
            'Nuestro equipo revisará personalmente tu '
            'solicitud. La verificación confirma una revisión '
            'de la organización, pero no garantiza la seguridad '
            'de todos los encuentros.',
            Icons.shield_outlined,
          ),
          const SizedBox(height: 22),
          if (_error != null) ...[
            _message(_error!, Icons.error_outline_rounded),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 19),
              label: Text(
                _submitting ? 'Enviando solicitud...' : 'Enviar solicitud',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _submitting
                ? null
                : () {
                    setState(() {
                      _showForm = false;
                      _error = null;
                    });
                  },
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        if (!_showForm) ...[
          _intro(),
          const SizedBox(height: 18),
          _message(
            'Nuestro equipo comprobará la información '
            'antes de habilitar la creación de clubes.',
            Icons.shield_outlined,
          ),
          const SizedBox(height: 20),
          Text(
            'ESTADO DE VERIFICACIÓN',
            style: GoogleFonts.inter(
              color: widget.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (widget.repository == null)
            _message(
              'Inicia sesión para solicitar la verificación '
              'de tu organización.',
              Icons.login_rounded,
            )
          else ...[
            if (_error != null) ...[
              _message(_error!, Icons.error_outline_rounded),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadStatus,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ] else ...[
              _statusCard(),
              const SizedBox(height: 18),
              if (_verification == null ||
                  _verification!.status == OrganizerVerificationStatus.rejected)
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _showForm = true;
                      });
                    },
                    icon: const Icon(Icons.verified_outlined, size: 19),
                    label: Text(
                      _verification == null
                          ? 'Solicitar verificación'
                          : 'Volver a solicitar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ] else ...[
          _sectionHeading(
            'Solicitar verificación',
            'Completa los datos de tu organización. '
                'Los campos marcados con * son obligatorios.',
            Icons.verified_user_outlined,
          ),
          _form(),
        ],
      ],
    );
  }
}
