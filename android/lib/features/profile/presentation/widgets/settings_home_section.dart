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
