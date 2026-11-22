import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../clubs/data/reading_club_repository.dart'
    show ReadingClubRepository;
import '../../../clubs/presentation/widgets/create_reading_club_form.dart';
import '../../../verification/data/organizer_verification_repository.dart';
import '../../../auth/domain/domain_user.dart';
import '../../../../core/network/api_client.dart';
import '../widgets/profile_gender_preference.dart';
import '../widgets/profile_privacy_store.dart';
import '../widgets/profile_blocked_users_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/account_repository.dart';

part '../widgets/settings_home_section.dart';
part '../widgets/settings_privacy_section.dart';
part '../widgets/settings_blocked_users_section.dart';
part '../widgets/settings_appearance_section.dart';
part '../widgets/settings_common_widgets.dart';
part '../widgets/settings_edit_profile_sheet.dart';
part '../widgets/settings_feedback_and_session.dart';
part '../widgets/settings_verification_section.dart';

typedef ProfileSavedCallback = void Function(
  String name,
  String username,
  String biography,
  String readingFormat,
  int annualGoal,
);

enum SettingsView {
  home,
  privacy,
  blocked,
  appearance,
  verification,
  createClub,
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.onProfileSaved,
    this.onProfileUpdated,
    this.accountRepository,
    this.initialName = 'Constanza Mena',
    this.initialUsername = '@constanza.lectora',
    this.initialBiography =
        'Amante de las novelas góticas victorianas y los clásicos de siempre 🌹 '
        'Estudiante de Ingeniería en Informática.',
    this.initialReadingFormat = 'Ambos',
    this.initialAnnualGoal = 25,
    this.verificationRepository,
    this.readingClubRepository,
  });

  final VoidCallback onBack;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  final ProfileSavedCallback onProfileSaved;
  final ValueChanged<DomainUser>? onProfileUpdated;
  final AccountRepository? accountRepository;

  final String initialName;
  final String initialUsername;
  final String initialBiography;
  final String initialReadingFormat;
  final int initialAnnualGoal;

  final OrganizerVerificationRepository? verificationRepository;
  final ReadingClubRepository? readingClubRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _updateState(VoidCallback callback) {
    setState(callback);
  }

  SettingsView _currentView = SettingsView.home;

  OrganizerVerificationStatus? _clubCreationStatus;
  bool _clubCreationLoading = true;
  String? _clubCreationError;

  bool get _canCreateClubs =>
      _clubCreationStatus == OrganizerVerificationStatus.approved &&
      !_clubCreationLoading &&
      _clubCreationError == null;

  late String _name;
  late String _username;
  late String _biography;
  late String _readingFormat;
  late int _annualGoal;

  bool get _privateAccount => ProfilePrivacyStore.isPrivate.value;

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

  Future<void> _loadClubCreationPermission() async {
    final repository = widget.verificationRepository;

    if (repository == null) {
      if (!mounted) return;

      setState(() {
        _clubCreationStatus = null;
        _clubCreationLoading = false;
        _clubCreationError = null;
      });
      return;
    }

    setState(() {
      _clubCreationLoading = true;
      _clubCreationError = null;
      _clubCreationStatus = null;
    });

    try {
      final verification = await repository.myStatus();

      if (!mounted) return;

      setState(() {
        _clubCreationStatus = verification?.status;
        _clubCreationLoading = false;
        _clubCreationError = null;
      });
    } on ApiFailure catch (error) {
      if (!mounted) return;

      setState(() {
        _clubCreationStatus = null;
        _clubCreationLoading = false;
        _clubCreationError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _clubCreationStatus = null;
        _clubCreationLoading = false;
        _clubCreationError =
            'No pudimos comprobar tu verificación. Inténtalo nuevamente.';
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _name = widget.initialName;
    _username = widget.initialUsername;
    _biography = widget.initialBiography;
    _readingFormat = widget.initialReadingFormat;
    _annualGoal = widget.initialAnnualGoal;
    _loadClubCreationPermission();
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
                final returningFromVerification =
                    _currentView == SettingsView.verification;

                setState(() {
                  _currentView = SettingsView.home;
                });

                if (returningFromVerification) {
                  _loadClubCreationPermission();
                }
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

      case SettingsView.verification:
        return 'Verificación de organizador';

      case SettingsView.createClub:
        return 'Crear club de lectura';

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

      case SettingsView.verification:
        return _buildVerificationSettings();

      case SettingsView.createClub:
        final repository = widget.readingClubRepository;

        if (repository == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Inicia sesión para crear clubes de lectura.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: _textSecondary, fontSize: 12),
              ),
            ),
          );
        }

        return CreateReadingClubForm(
          repository: repository,
          onCreated: (club) {
            if (!mounted) return;

            setState(() {
              _currentView = SettingsView.home;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡El club "${club.name}" se creó correctamente!'),
              ),
            );
          },
        );

      case SettingsView.privacy:
        return _buildPrivacySettings();

      case SettingsView.blocked:
        return _buildBlockedUsers();

      case SettingsView.appearance:
        return _buildAppearanceSettings();
    }
  }
}
