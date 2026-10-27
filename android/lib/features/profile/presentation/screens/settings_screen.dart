import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/profile_gender_preference.dart';
import '../widgets/profile_privacy_store.dart';


import '../../../../core/theme/app_colors.dart';

typedef ProfileSavedCallback = void Function(
  String name,
  String username,
  String biography,
  String readingFormat,
  int annualGoal,
);

enum SettingsView { home, privacy, blocked, appearance }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.onProfileSaved,
    this.initialName = 'Constanza Mena',
    this.initialUsername = '@constanza.lectora',
    this.initialBiography =
        'Amante de las novelas góticas victorianas y los clásicos de siempre 🌹 '
        'Estudiante de Ingeniería en Informática.',
    this.initialReadingFormat = 'Ambos',
    this.initialAnnualGoal = 25,
  });

  final VoidCallback onBack;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  final ProfileSavedCallback onProfileSaved;

  final String initialName;
  final String initialUsername;
  final String initialBiography;
  final String initialReadingFormat;
  final int initialAnnualGoal;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsView _currentView = SettingsView.home;

  late String _name;
  late String _username;
  late String _biography;
  late String _readingFormat;
  late int _annualGoal;

  bool get _privateAccount => ProfilePrivacyStore.isPrivate.value;
  bool _shareReadingActivity = true;
  bool _showReadingStatus = true;
  bool _showClubs = true;
  bool _privacyUpdating = false;

  final List<Map<String, String>> _blockedUsers = [];

  Color get _background =>
      widget.isDarkMode ? AppColors.darkBackground : AppColors.background;

  Color get _surface =>
      widget.isDarkMode ? AppColors.darkSurface : AppColors.surface;

  Color get _surfaceSoft =>
      widget.isDarkMode ? AppColors.darkSurfaceSoft : AppColors.surfaceSoft;

  Color get _deep => widget.isDarkMode ? AppColors.darkDeep : AppColors.deep;

  Color get _textPrimary =>
      widget.isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get _textSecondary =>
      widget.isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get _gold => widget.isDarkMode ? AppColors.darkGold : AppColors.gold;

  Color get _accent =>
      widget.isDarkMode ? AppColors.darkAccent : AppColors.accent;

  @override
  void initState() {
    super.initState();

    _name = widget.initialName;
    _username = widget.initialUsername;
    _biography = widget.initialBiography;
    _readingFormat = widget.initialReadingFormat;
    _annualGoal = widget.initialAnnualGoal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildCurrentView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isHome = _currentView == SettingsView.home;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: _background,
        border: Border(
          bottom: BorderSide(color: _gold.withValues(alpha: 0.20)),
        ),
      ),
      child: Row(
        children: [
          if (!isHome) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _currentView = SettingsView.home;
                });
              },
              icon: Icon(Icons.arrow_back_rounded, color: _accent),
            ),
            const SizedBox(width: 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleForCurrentView(),
                  style: GoogleFonts.cinzel(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHome ? 'Cuenta · privacidad · preferencias' : 'Capítulo 0',
                  style: GoogleFonts.inter(color: _textSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
          if (isHome)
            IconButton(
              onPressed: widget.onBack,
              icon: Icon(Icons.close_rounded, color: _textPrimary),
            ),
        ],
      ),
    );
  }

  String _titleForCurrentView() {
    switch (_currentView) {
      case SettingsView.home:
        return 'Configuración y privacidad';

      case SettingsView.privacy:
        return 'Privacidad y visibilidad';

      case SettingsView.blocked:
        return 'Usuarios bloqueados';

      case SettingsView.appearance:
        return 'Apariencia';
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case SettingsView.home:
        return _buildHomeSettings();

      case SettingsView.privacy:
        return _buildPrivacySettings();

      case SettingsView.blocked:
        return _buildBlockedUsers();

      case SettingsView.appearance:
        return _buildAppearanceSettings();
    }
  }

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
                setState(() {
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
                setState(() {
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
                setState(() {
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
                setState(() {
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
                setState(() {
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
                setState(() {
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

  Widget _buildBlockedUsers() {
    return ListView(
      key: const ValueKey('blocked-users'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        _settingsCard(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
          children: [
            if (_blockedUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 12,
                ),
                child: Column(
                  children: [
                    Icon(Icons.block_rounded, color: _gold, size: 34),
                    const SizedBox(height: 12),
                    Text(
                      'No tienes usuarios bloqueados.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_blockedUsers.length, (index) {
                final user = _blockedUsers[index];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _deep,
                            child: Text(
                              _firstLetter(user['name'] ?? ''),
                              style: GoogleFonts.cinzel(
                                color: _gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'] ?? '',
                                  style: GoogleFonts.inter(
                                    color: _textPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user['username'] ?? '',
                                  style: GoogleFonts.inter(
                                    color: _textSecondary,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _blockedUsers.removeAt(index);
                              });

                              _showMessage('Usuario desbloqueado.');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textPrimary,
                              side: BorderSide(color: _gold),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                            ),
                            child: Text(
                              'Desbloquear',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < _blockedUsers.length - 1) _divider(),
                  ],
                );
              }),
          ],
        ),
      ],
    );
  }

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

  Widget _privacySwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final loading = _privacyUpdating;

    final thumbColor = loading
        ? Colors.grey.shade600
        : _gold;

    final activeTrackColor = loading
        ? Colors.grey.shade300
        : _accent;

    final inactiveTrackColor = loading
        ? Colors.grey.shade300
        : _textSecondary.withValues(alpha: 0.28);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: loading ? 0.92 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: _textPrimary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: _textSecondary,
                      fontSize: 8,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              activeThumbColor: thumbColor,
              activeTrackColor: activeTrackColor,
              inactiveThumbColor: thumbColor,
              inactiveTrackColor: inactiveTrackColor,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: danger
                      ? _accent.withValues(alpha: 0.35)
                      : _gold.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(icon, size: 18, color: danger ? _accent : _gold),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: danger ? _accent : _textPrimary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: _textSecondary,
                      fontSize: 8,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: _textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard({
    required List<Widget> children,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _gold.withValues(alpha: 0.30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: _gold.withValues(alpha: 0.14),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 7),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: _textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _informationCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: _textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    color: _textSecondary,
                    fontSize: 8,
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

    setState(() {
      _privacyUpdating = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    setState(() {
      _privacyUpdating = false;
    });
  }

  Future<void> _openEditProfile() async {
    final nameController = TextEditingController(text: _name);

    final usernameController = TextEditingController(text: _username);

    final biographyController = TextEditingController(text: _biography);

    final goalController = TextEditingController(text: '$_annualGoal');

    String tempReadingFormat = _readingFormat;
    bool isSaving = false;
    int savingDots = 1;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(context).viewInsets.bottom + 22,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Editar Perfil',
                            style: GoogleFonts.cinzel(
                              color: _textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(bottomSheetContext).pop();
                          },
                          icon: Icon(Icons.close_rounded, color: _textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _gold,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.10),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) {
                                      return Container(
                                        color: _deep,
                                        alignment: Alignment.center,
                                        child: Text(
                                          _firstLetter(nameController.text),
                                          style: GoogleFonts.cinzel(
                                            color: _gold,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: _surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _gold,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.photo_camera_outlined,
                                    color: _gold,
                                    size: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () {
                                    _showMessage(
                                      'El selector de imagen se conectará '
                                      'con la galería en el siguiente paso.',
                                    );
                                  },
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              size: 16,
                            ),
                            label: const Text('Cambiar imagen'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _gold,
                              disabledForegroundColor:
                                  _gold.withValues(alpha: 0.45),
                              side: BorderSide(
                                color: _gold.withValues(alpha: 0.72),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _fieldLabel('Nombre'),
                    _editTextField(controller: nameController, hint: 'Nombre'),
                    const SizedBox(height: 12),
                    _fieldLabel('Nombre de usuario'),
                    _editTextField(
                      controller: usernameController,
                      hint: '@usuario',
                      onChanged: (value) {
                        final cleaned = value.replaceAll(' ', '');

                        if (cleaned != value) {
                          usernameController.value = usernameController.value
                              .copyWith(
                                text: cleaned,
                                selection: TextSelection.collapsed(
                                  offset: cleaned.length,
                                ),
                              );
                        }
                      },
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'El nombre de usuario no puede contener espacios.',
                      style: GoogleFonts.inter(
                        color: _textSecondary,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Preferencia privada: solo personaliza el saludo de Home.
                    // No se muestra en el perfil público.
                    const ProfileGenderPreferenceField(),

                    const SizedBox(height: 12),
                    _fieldLabel('Biografía'),
                    _editTextField(
                      controller: biographyController,
                      hint: 'Cuéntanos sobre ti...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('Formato de lectura'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.55),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempReadingFormat,
                          isExpanded: true,
                          dropdownColor: _surface,
                          style: GoogleFonts.inter(
                            color: _textPrimary,
                            fontSize: 11,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Físico',
                              child: Text('Físico'),
                            ),
                            DropdownMenuItem(
                              value: 'Digital',
                              child: Text('Digital'),
                            ),
                            DropdownMenuItem(
                              value: 'Ambos',
                              child: Text('Ambos'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setModalState(() {
                              tempReadingFormat = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('Meta anual de lectura'),
                    _editTextField(
                      controller: goalController,
                      hint: '25',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      Navigator.of(bottomSheetContext).pop();
                                    },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 15,
                              ),
                              label: const Text('Cancelar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _textPrimary,
                                disabledForegroundColor:
                                    _textSecondary.withValues(alpha: 0.45),
                                side: BorderSide(
                                  color: _gold.withValues(alpha: 0.42),
                                ),
                                backgroundColor:
                                    _surface.withValues(alpha: 0.55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                textStyle: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: isSaving
                                    ? const []
                                    : [
                                        BoxShadow(
                                          color: _accent.withValues(alpha: 0.18),
                                          blurRadius: 12,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                              ),
                              child: FilledButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final cleanName =
                                            nameController.text.trim();

                                        var cleanUsername = usernameController
                                            .text
                                            .replaceAll(' ', '')
                                            .trim();

                                        if (cleanName.isEmpty ||
                                            cleanUsername.isEmpty ||
                                            cleanUsername == '@') {
                                          _showMessage(
                                            'Completa nombre y usuario.',
                                          );
                                          return;
                                        }

                                        if (!cleanUsername.startsWith('@')) {
                                          cleanUsername = '@$cleanUsername';
                                        }

                                        final parsedGoal = int.tryParse(
                                              goalController.text.trim(),
                                            ) ??
                                            _annualGoal;

                                        setModalState(() {
                                          isSaving = true;
                                          savingDots = 1;
                                        });

                                        // Simulación visual de guardado en backend:
                                        // Guardando. -> Guardando.. -> Guardando...
                                        for (var step = 0; step < 4; step++) {
                                          await Future<void>.delayed(
                                            const Duration(milliseconds: 250),
                                          );

                                          if (!bottomSheetContext.mounted) {
                                            return;
                                          }

                                          setModalState(() {
                                            savingDots =
                                                (savingDots % 3) + 1;
                                          });
                                        }

                                        if (!mounted ||
                                            !bottomSheetContext.mounted) {
                                          return;
                                        }

                                        setState(() {
                                          _name = cleanName;
                                          _username = cleanUsername;
                                          _biography =
                                              biographyController.text.trim();
                                          _readingFormat = tempReadingFormat;
                                          _annualGoal =
                                              parsedGoal.clamp(1, 365);
                                        });

                                        widget.onProfileSaved(
                                          _name,
                                          _username,
                                          _biography,
                                          _readingFormat,
                                          _annualGoal,
                                        );

                                        Navigator.of(
                                          bottomSheetContext,
                                        ).pop();

                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (!mounted) return;

                                          _showMessage(
                                            'Perfil actualizado correctamente.',
                                          );
                                        });
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: isSaving
                                      ? _accent.withValues(alpha: 0.58)
                                      : _accent,
                                  disabledBackgroundColor:
                                      _accent.withValues(alpha: 0.58),
                                  foregroundColor: AppColors.background,
                                  disabledForegroundColor:
                                      AppColors.background.withValues(
                                        alpha: 0.82,
                                      ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  textStyle: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 120),
                                  opacity: 1,
                                  child: Text(
                                    isSaving
                                        ? 'Guardando${'.' * savingDots}'
                                        : 'Guardar',
                                  ),
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
      },
    );

    // showModalBottomSheet completa su Future antes de que termine por completo
    // la animación de salida. Si liberamos los controllers inmediatamente,
    // los TextField todavía pueden intentar leerlos durante ese último frame.
    await Future<void>.delayed(const Duration(milliseconds: 350));

    nameController.dispose();
    usernameController.dispose();
    biographyController.dispose();
    goalController.dispose();
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: _textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _editTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: _textPrimary, fontSize: 11),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: _textSecondary, fontSize: 10),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: _gold.withValues(alpha: 0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: _gold, width: 1.4),
        ),
      ),
    );
  }

  Future<void> _confirmSessionAction({
    required bool deleteAccount,
  }) async {
    var processing = false;
    var dots = 1;

    await showDialog<void>(
      context: context,
      barrierDismissible: !processing,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final title = deleteAccount
                ? 'Eliminar cuenta'
                : 'Cerrar sesión';

            final description = deleteAccount
                ? 'Esta acción eliminará tu cuenta de Capítulo 0. '
                    'En esta demo volverás a la pantalla de autenticación.'
                : 'Tu sesión actual se cerrará y volverás a la '
                    'pantalla de autenticación.';

            return PopScope(
              canPop: !processing,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 28,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 390),
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: deleteAccount
                          ? _accent.withValues(alpha: 0.50)
                          : _gold.withValues(alpha: 0.42),
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
                          color: deleteAccount
                              ? _accent.withValues(alpha: 0.10)
                              : _gold.withValues(alpha: 0.12),
                          border: Border.all(
                            color: deleteAccount
                                ? _accent.withValues(alpha: 0.35)
                                : _gold.withValues(alpha: 0.38),
                          ),
                        ),
                        child: Icon(
                          deleteAccount
                              ? Icons.delete_outline_rounded
                              : Icons.logout_rounded,
                          color: deleteAccount ? _accent : _gold,
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
                                onPressed: processing
                                    ? null
                                    : () {
                                        Navigator.of(
                                          dialogContext,
                                        ).pop();
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _textPrimary,
                                  disabledForegroundColor:
                                      _textSecondary.withValues(
                                    alpha: 0.40,
                                  ),
                                  side: BorderSide(
                                    color: _gold.withValues(
                                      alpha: 0.38,
                                    ),
                                  ),
                                  backgroundColor:
                                      _surface.withValues(alpha: 0.48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
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
                                onPressed: processing
                                    ? null
                                    : () async {
                                        if (deleteAccount) {
                                          Navigator.of(
                                            dialogContext,
                                          ).pop();

                                          if (mounted) {
                                            widget.onDeleteAccount();
                                          }
                                          return;
                                        }

                                        setDialogState(() {
                                          processing = true;
                                          dots = 1;
                                        });

                                        for (
                                          var step = 0;
                                          step < 4;
                                          step++
                                        ) {
                                          await Future<void>.delayed(
                                            const Duration(
                                              milliseconds: 250,
                                            ),
                                          );

                                          if (!dialogContext.mounted) {
                                            return;
                                          }

                                          setDialogState(() {
                                            dots = (dots % 3) + 1;
                                          });
                                        }

                                        if (!dialogContext.mounted) {
                                          return;
                                        }

                                        Navigator.of(
                                          dialogContext,
                                        ).pop();

                                        if (!mounted) return;

                                        widget.onLogout();
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: processing
                                      ? _accent.withValues(alpha: 0.62)
                                      : _accent,
                                  disabledBackgroundColor:
                                      _accent.withValues(alpha: 0.62),
                                  foregroundColor:
                                      AppColors.background,
                                  disabledForegroundColor:
                                      AppColors.background.withValues(
                                    alpha: 0.90,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 120),
                                  child: Text(
                                    processing
                                        ? 'Cerrando${'.' * dots}'
                                        : deleteAccount
                                            ? 'Eliminar cuenta'
                                            : 'Cerrar sesión',
                                    key: ValueKey(
                                      '$processing-$dots-$deleteAccount',
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
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
              ),
            );
          },
        );
      },
    );
  }

  String _firstLetter(String text) {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return '?';
    }

    return cleanText.substring(0, 1).toUpperCase();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
