import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/profile_gender_preference.dart';
import '../widgets/profile_privacy_store.dart';
import '../widgets/profile_blocked_users_store.dart';


import '../../../../core/theme/app_colors.dart';


part '../widgets/settings_home_section.dart';
part '../widgets/settings_privacy_section.dart';
part '../widgets/settings_blocked_users_section.dart';
part '../widgets/settings_appearance_section.dart';
part '../widgets/settings_common_widgets.dart';
part '../widgets/settings_edit_profile_sheet.dart';
part '../widgets/settings_feedback_and_session.dart';

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
  void _updateState(VoidCallback callback) {
    setState(callback);
  }

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

  List<Map<String, String>> get _blockedUsers =>
      ProfileBlockedUsersStore.blockedUsers.value;

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

}
