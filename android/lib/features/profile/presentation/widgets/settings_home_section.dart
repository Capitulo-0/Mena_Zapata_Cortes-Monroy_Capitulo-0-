part of '../screens/settings_screen.dart';

extension _SettingsHomeSection on _SettingsScreenState {
  Widget _buildHomeSettings() {
    return ListView(
      key: const ValueKey('settings-home'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        _sectionTitle('TU CUENTA'),
        _settingsCard(
          children: [
            _settingsItem(
              icon: Icons.person_outline_rounded,
              title: 'Editar perfil',
              subtitle: 'Nombre, foto, biografía y meta anual',
              onTap: _openEditProfile,
            ),
            _divider(),
            _settingsItem(
              icon: Icons.lock_outline_rounded,
              title: 'Privacidad y visibilidad',
              subtitle: _privateAccount ? 'Cuenta privada' : 'Cuenta pública',
              onTap: () {
                _updateState(() {
                  _currentView = SettingsView.privacy;
                });
              },
            ),
            // Crear clubes: disponible solo con verificacion aprobada.
            Opacity(
              opacity: _canCreateClubs ? 1.0 : 0.55,
              child: AbsorbPointer(
                absorbing: !_canCreateClubs,
                child: _settingsItem(
                  icon: Icons.auto_stories_rounded,
                  title: 'Crear clubes',
                  subtitle: _clubCreationLoading
                      ? 'Comprobando tu verificación...'
                      : _clubCreationError != null
                      ? 'No pudimos comprobar tu permiso'
                      : _canCreateClubs
                      ? 'Organizador verificado · Crear un club'
                      : _clubCreationStatus ==
                            OrganizerVerificationStatus.pending
                      ? 'Tu verificación está pendiente'
                      : _clubCreationStatus ==
                            OrganizerVerificationStatus.rejected
                      ? 'Tu solicitud fue rechazada'
                      : 'Primero debes verificar tu organización',
                  showArrow: _canCreateClubs,
                  onTap: () {
                    if (!_canCreateClubs) return;

                    _updateState(() {
                      _currentView = SettingsView.createClub;
                    });
                  },
                ),
              ),
            ),
            if (_clubCreationError != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _clubCreationLoading
                        ? null
                        : _loadClubCreationPermission,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reintentar verificación'),
                  ),
                ),
              ),
            ],
            _divider(),
            _settingsItem(
              icon: Icons.verified_user_outlined,
              title: 'Verificación de organizador',
              subtitle: 'Solicita permiso para crear clubes de lectura',
              onTap: () {
                _updateState(() {
                  _currentView = SettingsView.verification;
                });
              },
            ),
            _divider(),
            _settingsItem(
              icon: Icons.block_outlined,
              title: 'Usuarios bloqueados',
              subtitle:
                  '${_blockedUsers.length} bloqueado${_blockedUsers.length == 1 ? '' : 's'}',
              onTap: () {
                _updateState(() {
                  _currentView = SettingsView.blocked;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle('PREFERENCIAS'),
        _settingsCard(
          children: [
            _settingsItem(
              icon: widget.isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              title: 'Apariencia',
              subtitle: widget.isDarkMode ? 'Modo oscuro' : 'Modo claro',
              onTap: () {
                _updateState(() {
                  _currentView = SettingsView.appearance;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle('SESIÓN'),
        _settingsCard(
          children: [
            _settingsItem(
              icon: Icons.logout_rounded,
              title: 'Cerrar sesión',
              subtitle: 'Volver a la pantalla de inicio de sesión',
              onTap: () {
                _confirmSessionAction(deleteAccount: false);
              },
            ),
            _divider(),
            _settingsItem(
              icon: Icons.delete_outline_rounded,
              title: 'Eliminar cuenta',
              subtitle: 'Eliminar tu cuenta de Capítulo 0',
              danger: true,
              showArrow: false,
              onTap: () {
                _confirmSessionAction(deleteAccount: true);
              },
            ),
          ],
        ),
      ],
    );
  }
}
