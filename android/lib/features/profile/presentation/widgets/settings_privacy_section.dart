part of '../screens/settings_screen.dart';

extension _SettingsPrivacySection on _SettingsScreenState {
  Widget _buildPrivacySettings() {
    return ListView(
      key: const ValueKey('privacy-settings'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        _settingsCard(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          children: [
            _privacySwitch(
              title: 'Cuenta privada',
              subtitle: 'Solo las personas aprobadas podrán ver tu actividad completa',
              value: _privateAccount,
              enabled: !_privacyUpdating,
              onChanged: _confirmPrivacyChange,
            ),
            _divider(),
            _privacySwitch(
              title: 'Compartir actividad lectora',
              subtitle: 'Muestra géneros, reto, favoritos y reseñas en tu perfil público',
              value: _shareReadingActivity,
              enabled: !_privacyUpdating,
              onChanged: (value) {
                _updateState(() {
                  _shareReadingActivity = value;
                });
              },
            ),
            _divider(),
            _privacySwitch(
              title: 'Mostrar estado lector',
              subtitle: 'Hace visible tu emoji y estado actual en el perfil',
              value: _showReadingStatus,
              enabled: !_privacyUpdating,
              onChanged: (value) {
                _updateState(() {
                  _showReadingStatus = value;
                });
              },
            ),
            _divider(),
            _privacySwitch(
              title: 'Mostrar clubes',
              subtitle: 'Permite que otros vean los clubes de lectura a los que perteneces',
              value: _showClubs,
              enabled: !_privacyUpdating,
              onChanged: (value) {
                _updateState(() {
                  _showClubs = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _informationCard(
          icon: Icons.shield_outlined,
          title: 'Control de privacidad',
          text:
              'Estas opciones controlarán qué información puede mostrarse '
              'en tu perfil público cuando conectemos el backend.',
        ),
      ],
    );
  }

  Future<void> _confirmPrivacyChange(bool makePrivate) async {
    if (_privacyUpdating || makePrivate == _privateAccount) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final title = makePrivate
            ? 'Hacer cuenta privada'
            : 'Hacer cuenta pública';

        final description = makePrivate
            ? 'Tu cuenta será privada. Solo las personas que apruebes podrán '
                'ver tu actividad completa y el contenido que decidas compartir.'
            : 'Tu cuenta será pública. Otras personas podrán ver la información '
                'y actividad que tengas habilitada como visible en tu perfil.';

        final icon = makePrivate
            ? Icons.lock_outline_rounded
            : Icons.public_rounded;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _gold.withValues(alpha: 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold.withValues(alpha: 0.12),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.38),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: _gold,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _textSecondary,
                    fontSize: 9,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textPrimary,
                            side: BorderSide(
                              color: _gold.withValues(alpha: 0.38),
                            ),
                            backgroundColor:
                                _surface.withValues(alpha: 0.48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Confirmar',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    ProfilePrivacyStore.isPrivate.value = makePrivate;

    _updateState(() {
      _privacyUpdating = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    _updateState(() {
      _privacyUpdating = false;
    });
  }
}
