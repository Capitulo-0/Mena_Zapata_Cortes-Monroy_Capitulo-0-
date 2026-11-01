part of '../screens/settings_screen.dart';

extension _SettingsAppearanceSection on _SettingsScreenState {
  Widget _buildAppearanceSettings() {
    return ListView(
      key: const ValueKey('appearance-settings'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        _settingsCard(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _gold.withValues(alpha: 0.35)),
                  ),
                  child: Icon(
                    widget.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: _gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo oscuro',
                        style: GoogleFonts.inter(
                          color: _textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Aplica el tema nocturno en toda la aplicación',
                        style: GoogleFonts.inter(
                          color: _textSecondary,
                          fontSize: 8,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.isDarkMode,
                  activeThumbColor: _gold,
                  activeTrackColor: _accent,
                  onChanged: widget.onDarkModeChanged,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _themePreview(),
      ],
    );
  }

  Widget _themePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VISTA PREVIA',
            style: GoogleFonts.cinzel(
              color: _gold,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Capítulo 0',
                  style: GoogleFonts.cinzel(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.isDarkMode
                      ? 'Así se verá el modo oscuro.'
                      : 'Así se verá el modo claro.',
                  style: GoogleFonts.merriweather(
                    color: _textSecondary,
                    fontSize: 9,
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
