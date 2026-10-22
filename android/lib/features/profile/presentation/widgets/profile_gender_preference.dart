import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

enum ProfileGender {
  woman,
  man,
  preferNotToSay,
  selfDescribe,
}

extension ProfileGenderLabel on ProfileGender {
  String get label {
    switch (this) {
      case ProfileGender.woman:
        return 'Mujer';
      case ProfileGender.man:
        return 'Hombre';
      case ProfileGender.preferNotToSay:
        return 'Prefiero no decirlo';
      case ProfileGender.selfDescribe:
        return 'Prefiero decirlo yo';
    }
  }
}

/// Estado temporal compartido de la preferencia de género.
///
/// Más adelante este estado puede venir directamente desde backend.
/// No se muestra en el perfil público: se usa para personalizar el saludo
/// del Home.
class ProfileGenderStore {
  ProfileGenderStore._();

  static final ValueNotifier<ProfileGender> notifier =
      ValueNotifier<ProfileGender>(ProfileGender.woman);

  static ProfileGender get value => notifier.value;

  static set value(ProfileGender gender) {
    notifier.value = gender;
  }
}

class ProfileGenderPreferenceField extends StatefulWidget {
  const ProfileGenderPreferenceField({
    super.key,
    this.label = 'Género',
  });

  final String label;

  @override
  State<ProfileGenderPreferenceField> createState() =>
      _ProfileGenderPreferenceFieldState();
}

class _ProfileGenderPreferenceFieldState
    extends State<ProfileGenderPreferenceField>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay(immediate: true);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleMenu() async {
    if (_isOpen) {
      await _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final fieldSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 7),
              showWhenUnlinked: false,
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    alignment: Alignment.topCenter,
                    scale: _scaleAnimation,
                    child: SizedBox(
                      width: fieldSize.width,
                      child: _GenderDropdownMenu(
                        onSelected: (gender) async {
                          ProfileGenderStore.value = gender;

                          if (mounted) {
                            setState(() {});
                          }

                          await _closeMenu();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);

    setState(() {
      _isOpen = true;
    });

    _animationController.forward(from: 0);
  }

  Future<void> _closeMenu() async {
    if (_overlayEntry == null) return;

    await _animationController.reverse();

    if (!mounted) return;

    _removeOverlay();
  }

  void _removeOverlay({bool immediate = false}) {
    if (immediate) {
      _animationController.stop();
    }

    _overlayEntry?.remove();
    _overlayEntry = null;

    if (mounted && _isOpen) {
      setState(() {
        _isOpen = false;
      });
    } else {
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final gold = AppColors.goldOf(context);

    return ValueListenableBuilder<ProfileGender>(
      valueListenable: ProfileGenderStore.notifier,
      builder: (context, selectedGender, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                key: _fieldKey,
                onTap: _toggleMenu,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: _isOpen
                          ? gold
                          : gold.withValues(alpha: 0.55),
                      width: _isOpen ? 1.35 : 1,
                    ),
                    boxShadow: _isOpen
                        ? [
                            BoxShadow(
                              color: gold.withValues(alpha: 0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedGender.label,
                          style: GoogleFonts.inter(
                            color: textPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: gold,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Esta información no se mostrará en tu perfil público.',
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 8,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GenderDropdownMenu extends StatelessWidget {
  const _GenderDropdownMenu({
    required this.onSelected,
  });

  final ValueChanged<ProfileGender> onSelected;

  @override
  Widget build(BuildContext context) {
    final background = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final surfaceSoft = AppColors.surfaceSoftOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final gold = AppColors.goldOf(context);
    final accent = AppColors.accentOf(context);

    final selectedGender = ProfileGenderStore.value;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: gold.withValues(alpha: 0.62),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          ProfileGender.values.length,
          (index) {
            final gender = ProfileGender.values[index];
            final selected = gender == selectedGender;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => onSelected(gender),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    color: selected
                        ? accent.withValues(alpha: 0.08)
                        : index.isEven
                            ? surface
                            : surfaceSoft.withValues(alpha: 0.34),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? gold.withValues(alpha: 0.16)
                                : background,
                            border: Border.all(
                              color: selected
                                  ? gold
                                  : gold.withValues(alpha: 0.22),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              selected
                                  ? Icons.check_rounded
                                  : Icons.person_outline_rounded,
                              key: ValueKey(selected),
                              size: 13,
                              color: selected ? gold : textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            gender.label,
                            style: GoogleFonts.inter(
                              color: selected ? accent : textPrimary,
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selected)
                          Text(
                            'ACTUAL',
                            style: GoogleFonts.inter(
                              color: gold,
                              fontSize: 6,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (index < ProfileGender.values.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: gold.withValues(alpha: 0.12),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
