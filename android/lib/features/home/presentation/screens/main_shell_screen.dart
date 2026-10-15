import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/settings_screen.dart';
import 'home_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.isGuest,
    required this.onLogout,
  });

  final bool isGuest;
  final VoidCallback onLogout;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int selectedIndex = 0;

  bool showSettings = false;
  bool isDarkMode = false;

  void _selectTab(int index) {
    if (widget.isGuest && (index == 1 || index == 2 || index == 4)) {
      _showGuestAccessDialog(index);
      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  void _showGuestAccessDialog(int index) {
    String title;
    String message;

    switch (index) {
      case 1:
        title = 'Tu biblioteca te está esperando';
        message = 'Inicia sesión para guardar tus lecturas, organizar tu estantería y llevar tu progreso.';
        break;

      case 2:
        title = 'Convierte tus ideas en historias';
        message = 'Para crear, guardar y publicar tus propias historias necesitas una cuenta de Capítulo 0.';
        break;

      case 4:
        title = 'Haz tu experiencia más personal';
        message = 'Inicia sesión para acceder a tu perfil, seguidores, reseñas y preferencias literarias.';
        break;

      default:
        title = 'Inicia sesión';
        message = 'Esta función requiere una cuenta.';
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_stories_outlined,
                color: AppColors.gold,
                size: 42,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  color: AppColors.deep,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onLogout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Iniciar sesión',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Seguir como invitado',
                  style: GoogleFonts.inter(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _currentScreen() {
    switch (selectedIndex) {
      case 0:
        return HomeScreen(
          isGuest: widget.isGuest,
          onOpenLibrary: () {
            _selectTab(1);
          },
          onOpenWriter: () {
            _selectTab(2);
          },
          onOpenPoints: () {
            _selectTab(3);
          },
        );

      case 1:
        return _buildPlaceholder(
          icon: Icons.menu_book_outlined,
          title: 'Mi Biblioteca',
          description:
              'Aquí construiremos tu estantería, progreso de lectura y listas.',
        );

      case 2:
        return _buildPlaceholder(
          icon: Icons.edit_outlined,
          title: 'Escribir',
          description:
              'Aquí construiremos la creación y publicación de historias.',
        );

      case 3:
        return _buildPlaceholder(
          icon: Icons.location_on_outlined,
          title: 'Puntos Lectores',
          description: 'Aquí mostraremos cafeterías, bibliotecas y espacios para lectores.',
        );

      case 4:
        return ProfileScreen(
          onOpenSettings: () {
            setState(() {
              showSettings = true;
            });
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 130),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 54, color: AppColors.gold),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: AppColors.deep,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showSettings) {
      return SettingsScreen(
        onBack: () {
          setState(() {
            showSettings = false;
          });
        },
        onLogout: widget.onLogout,
        onDeleteAccount: widget.onLogout,
        isDarkMode: isDarkMode,
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
        onProfileSaved: (name, username, biography, readingFormat, annualGoal) {
          // En el próximo paso conectaremos
          // estos datos directamente con ProfileScreen.
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentScreen(),
      extendBody: true,
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: SizedBox(
        height: 76,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                height: 62,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.deep,
                  borderRadius: BorderRadius.circular(31),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _navItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Inicio',
                      ),
                    ),
                    Expanded(
                      child: _navItem(
                        index: 1,
                        icon: Icons.menu_book_outlined,
                        activeIcon: Icons.menu_book_rounded,
                        label: 'Biblioteca',
                      ),
                    ),
                    Expanded(
                      child: _navItem(
                        index: 3,
                        icon: Icons.location_on_outlined,
                        activeIcon: Icons.location_on_rounded,
                        label: 'Puntos',
                      ),
                    ),
                    Expanded(
                      child: _navItem(
                        index: 4,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person_rounded,
                        label: 'Perfil',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () {
                _selectTab(2);
              },
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedIndex == 2
                      ? const Color(0xFFB58B3D)
                      : AppColors.gold,
                  border: Border.all(
                    color: AppColors.deep,
                    width: selectedIndex == 2 ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(
                  selectedIndex == 2 ? Icons.edit_outlined : Icons.add_rounded,
                  color: AppColors.deep,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final active = selectedIndex == index;

    return InkWell(
      onTap: () {
        _selectTab(index);
      },
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 50,
        decoration: BoxDecoration(
          color: active ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active
                  ? AppColors.deep
                  : AppColors.background.withValues(alpha: 0.68),
              size: 23,
            ),
            if (active) ...[
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.deep,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
