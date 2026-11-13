import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'core/network/api_client.dart';
import 'features/library/data/library_repository.dart';
import 'core/session/local_account_scope.dart';
import 'features/auth/presentation/controllers/session_controller.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/session_preparation_screen.dart';
import 'features/home/presentation/screens/main_shell_screen.dart';
import 'features/library/presentation/widgets/book_interaction_store.dart';
import 'features/profile/presentation/widgets/profile_privacy_store.dart';
import 'features/profile/presentation/widgets/profile_gender_preference.dart';
import 'features/profile/presentation/widgets/profile_blocked_users_store.dart';

enum AppStage { splash, auth, preparing, main }

class CapituloCeroApp extends StatefulWidget {
  const CapituloCeroApp({
    super.key,
    required this.session,
    this.libraryRepositoryFactory,
  });
  final LibraryRepository Function(String uid)? libraryRepositoryFactory;
  final SessionController session;
  @override
  State<CapituloCeroApp> createState() => _CapituloCeroAppState();
}

class _CapituloCeroAppState extends State<CapituloCeroApp> {
  bool _splashFinished = false;
  bool isDarkMode = false;
  bool _authStartsInLogin = true;
  String? _lastScope;
  LibraryRepository? _libraryRepository;
  String? _libraryOwner;
  LibraryRepository _repositoryFor(String uid) {
    if (_libraryRepository == null || _libraryOwner != uid) {
      _libraryOwner = uid;
      _libraryRepository =
          widget.libraryRepositoryFactory?.call(uid) ??
          ApiLibraryRepository(
            ApiClient(auth: widget.session.auth),
            ownerUid: uid,
          );
    }
    return _libraryRepository!;
  }

  late final _catalogApi = ApiClient(auth: widget.session.auth);
  late final _catalog = ApiCatalogRepository(_catalogApi);
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_sessionChanged);
    widget.session.start();
  }

  void _sessionChanged() {
    if (!mounted) return;
    final scope = widget.session.phase == SessionPhase.ready
        ? widget.session.uid
        : widget.session.phase == SessionPhase.guest
        ? 'guest'
        : null;
    if (scope != _lastScope) {
      _lastScope = scope;
      _libraryRepository = null;
      _libraryOwner = null;
      // Dispose account-specific routes as well as the shell, without deleting local files.
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      BookInteractionStore.clear();
      ProfilePrivacyStore.isPrivate.value = false;
      ProfileGenderStore.value = ProfileGender.preferNotToSay;
      ProfileGenderStore.customGender = null;
      ProfileBlockedUsersStore.blockedUsers.value = [];
    }
    setState(() {});
  }

  @override
  void dispose() {
    _catalogApi.close();
    widget.session.removeListener(_sessionChanged);
    super.dispose();
  }

  void _openAuth({required bool login}) {
    _authStartsInLogin = login;
    widget.session.leaveGuest();
  }

  Future<void> _logout() async {
    await widget.session.logout();
    if (!mounted || widget.session.message == null) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(widget.session.message!)),
    );
  }

  AppStage get stage {
    if (!_splashFinished) return AppStage.splash;
    return switch (widget.session.phase) {
      SessionPhase.ready || SessionPhase.guest => AppStage.main,
      SessionPhase.signedOut => AppStage.auth,
      _ => AppStage.preparing,
    };
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    scaffoldMessengerKey: _messengerKey,
    title: 'Capítulo 0',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => LocalAccountScope(
      uid: widget.session.phase == SessionPhase.ready
          ? widget.session.uid!
          : widget.session.phase == SessionPhase.guest
          ? 'guest'
          : 'signed-out',
      child: child!,
    ),
    home: _buildCurrentStage(),
  );
  Widget _buildCurrentStage() {
    switch (stage) {
      case AppStage.splash:
        return SplashScreen(
          onFinished: () {
            if (mounted) setState(() => _splashFinished = true);
          },
        );
      case AppStage.auth:
        return AuthScreen(
          session: widget.session,
          initialLogin: _authStartsInLogin,
          onAuthenticated: (guest) {
            if (guest) widget.session.enterGuest();
          },
        );
      case AppStage.preparing:
        return SessionPreparationScreen(session: widget.session);
      case AppStage.main:
        final guest = widget.session.phase == SessionPhase.guest;
        final scope = guest ? 'guest' : widget.session.uid!;
        return LocalAccountScope(
          key: ValueKey(scope),
          uid: scope,
          child: MainShellScreen(
            isGuest: guest,
            profileUser: widget.session.user,
            catalogRepository: _catalog,
            libraryRepository: guest ? null : _repositoryFor(scope),
            onLogout: _logout,
            onGuestLoginRequested: () => _openAuth(login: true),
            onGuestRegisterRequested: () => _openAuth(login: false),
            isDarkMode: isDarkMode,
            onDarkModeChanged: (value) => setState(() => isDarkMode = value),
            profileDisplayName:
                widget.session.user?.displayName ?? widget.session.user?.email,
          ),
        );
    }
  }
}
