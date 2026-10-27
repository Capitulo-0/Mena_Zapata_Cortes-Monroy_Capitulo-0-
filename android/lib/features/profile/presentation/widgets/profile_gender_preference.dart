import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// Más adelante estos valores pueden venir directamente desde backend.
/// No se muestran en el perfil público: se utilizan para personalizar la
/// experiencia dentro de la aplicación.
class ProfileGenderStore {
  ProfileGenderStore._();

  static final ValueNotifier<ProfileGender> notifier =
      ValueNotifier<ProfileGender>(ProfileGender.woman);

  /// Género personalizado guardado por el usuario.
  static final ValueNotifier<String?> customGenderNotifier =
      ValueNotifier<String?>(null);

  static ProfileGender get value => notifier.value;

  static set value(ProfileGender gender) {
    notifier.value = gender;
  }

  static String? get customGender {
    final value = customGenderNotifier.value?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static set customGender(String? value) {
    final normalized = value?.trim();
    customGenderNotifier.value =
        normalized == null || normalized.isEmpty ? null : normalized;
  }

  static bool get hasCustomGender => customGender != null;

  static String get selectedLabel {
    if (value == ProfileGender.selfDescribe && hasCustomGender) {
      return customGender!;
    }

    return value.label;
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
                        onSelected: _handleGenderSelected,
                        onEditCustom: _handleEditCustomGender,
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

  Future<void> _handleGenderSelected(ProfileGender gender) async {
    if (gender == ProfileGender.selfDescribe) {
      // Si ya existe un género personalizado, "Prefiero decirlo yo" vuelve
      // simplemente a esa opción guardada. Para modificarla se usa Editar.
      if (ProfileGenderStore.hasCustomGender) {
        ProfileGenderStore.value = ProfileGender.selfDescribe;
        _overlayEntry?.markNeedsBuild();

        if (mounted) {
          setState(() {});
        }

        await _closeMenu();
        return;
      }

      await _closeMenu();

      if (!mounted) return;

      await _openCustomGenderEditor(
        selectAfterSave: true,
        isEditing: false,
      );
      return;
    }

    ProfileGenderStore.value = gender;
    _overlayEntry?.markNeedsBuild();

    if (mounted) {
      setState(() {});
    }

    await _closeMenu();
  }

  Future<void> _handleEditCustomGender() async {
    await _closeMenu();

    if (!mounted) return;

    await _openCustomGenderEditor(
      selectAfterSave: false,
      isEditing: true,
    );
  }

  Future<void> _openCustomGenderEditor({
    required bool selectAfterSave,
    required bool isEditing,
  }) async {
    final controller = TextEditingController(
      text: isEditing ? (ProfileGenderStore.customGender ?? '') : '',
    );

    final savedGender = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (sheetContext) {
        return _CustomGenderSheet(
          controller: controller,
          initialValue: controller.text,
          isEditing: isEditing,
        );
      },
    );

    // Dejamos terminar por completo la animación inversa del bottom sheet
    // antes de liberar el controller.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    controller.dispose();

    if (!mounted || savedGender == null) return;

    ProfileGenderStore.customGender = savedGender;

    if (selectAfterSave || ProfileGenderStore.value == ProfileGender.selfDescribe) {
      ProfileGenderStore.value = ProfileGender.selfDescribe;
    }

    setState(() {});
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
        return ValueListenableBuilder<String?>(
          valueListenable: ProfileGenderStore.customGenderNotifier,
          builder: (context, customGender, _) {
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
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              layoutBuilder: (
                                Widget? currentChild,
                                List<Widget> previousChildren,
                              ) {
                                return Stack(
                                  alignment: Alignment.centerLeft,
                                  children: <Widget>[
                                    ...previousChildren,
                                    ?currentChild,
                                  ],
                                );
                              },
                              child: Align(
                                key: ValueKey(
                                  '${selectedGender.name}-${customGender ?? ''}',
                                ),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  ProfileGenderStore.selectedLabel,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
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
      },
    );
  }
}

class _GenderDropdownMenu extends StatelessWidget {
  const _GenderDropdownMenu({
    required this.onSelected,
    required this.onEditCustom,
  });

  final ValueChanged<ProfileGender> onSelected;
  final VoidCallback onEditCustom;

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
    final customGender = ProfileGenderStore.customGender;

    final entries = <Widget>[
      _genderOption(
        context: context,
        gender: ProfileGender.woman,
        label: ProfileGender.woman.label,
        selected: selectedGender == ProfileGender.woman,
        index: 0,
        background: background,
        surface: surface,
        surfaceSoft: surfaceSoft,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        gold: gold,
        accent: accent,
      ),
      _divider(gold),
      _genderOption(
        context: context,
        gender: ProfileGender.man,
        label: ProfileGender.man.label,
        selected: selectedGender == ProfileGender.man,
        index: 1,
        background: background,
        surface: surface,
        surfaceSoft: surfaceSoft,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        gold: gold,
        accent: accent,
      ),
    ];

    if (customGender != null) {
      entries.add(_divider(gold));
      entries.add(
        _customGenderOption(
          context: context,
          label: customGender,
          selected: selectedGender == ProfileGender.selfDescribe,
          background: background,
          surfaceSoft: surfaceSoft,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          gold: gold,
          accent: accent,
        ),
      );
    }

    entries.addAll([
      _divider(gold),
      _genderOption(
        context: context,
        gender: ProfileGender.preferNotToSay,
        label: ProfileGender.preferNotToSay.label,
        selected: selectedGender == ProfileGender.preferNotToSay,
        index: 2,
        background: background,
        surface: surface,
        surfaceSoft: surfaceSoft,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        gold: gold,
        accent: accent,
      ),
      _divider(gold),
      _genderOption(
        context: context,
        gender: ProfileGender.selfDescribe,
        label: ProfileGender.selfDescribe.label,
        // Cuando existe género personalizado, la fila guardada de arriba es
        // la que representa visualmente la selección actual.
        selected: selectedGender == ProfileGender.selfDescribe &&
            customGender == null,
        index: 3,
        background: background,
        surface: surface,
        surfaceSoft: surfaceSoft,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        gold: gold,
        accent: accent,
      ),
    ]);

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
        children: entries,
      ),
    );
  }

  Widget _genderOption({
    required BuildContext context,
    required ProfileGender gender,
    required String label,
    required bool selected,
    required int index,
    required Color background,
    required Color surface,
    required Color surfaceSoft,
    required Color textPrimary,
    required Color textSecondary,
    required Color gold,
    required Color accent,
  }) {
    return InkWell(
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
            _optionIcon(
              selected: selected,
              background: background,
              textSecondary: textSecondary,
              gold: gold,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? accent : textPrimary,
                  fontSize: 10,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected) _currentBadge(gold),
          ],
        ),
      ),
    );
  }

  Widget _customGenderOption({
    required BuildContext context,
    required String label,
    required bool selected,
    required Color background,
    required Color surfaceSoft,
    required Color textPrimary,
    required Color textSecondary,
    required Color gold,
    required Color accent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      color: selected
          ? accent.withValues(alpha: 0.08)
          : surfaceSoft.withValues(alpha: 0.18),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onSelected(ProfileGender.selfDescribe),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 10, 4, 10),
                child: Row(
                  children: [
                    _optionIcon(
                      selected: selected,
                      background: background,
                      textSecondary: textSecondary,
                      gold: gold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: selected ? accent : textPrimary,
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      _currentBadge(gold),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: onEditCustom,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 11,
                      color: accent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Editar',
                      style: GoogleFonts.inter(
                        color: accent,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionIcon({
    required bool selected,
    required Color background,
    required Color textSecondary,
    required Color gold,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? gold.withValues(alpha: 0.16) : background,
        border: Border.all(
          color: selected ? gold : gold.withValues(alpha: 0.22),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Icon(
          selected ? Icons.check_rounded : Icons.person_outline_rounded,
          key: ValueKey(selected),
          size: 13,
          color: selected ? gold : textSecondary,
        ),
      ),
    );
  }

  Widget _currentBadge(Color gold) {
    return Text(
      'ACTUAL',
      style: GoogleFonts.inter(
        color: gold,
        fontSize: 6,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    );
  }

  Widget _divider(Color gold) {
    return Divider(
      height: 1,
      thickness: 1,
      color: gold.withValues(alpha: 0.12),
    );
  }
}

class _CustomGenderSheet extends StatefulWidget {
  const _CustomGenderSheet({
    required this.controller,
    required this.initialValue,
    required this.isEditing,
  });

  final TextEditingController controller;
  final String initialValue;
  final bool isEditing;

  @override
  State<_CustomGenderSheet> createState() => _CustomGenderSheetState();
}

class _CustomGenderSheetState extends State<_CustomGenderSheet> {
  static const int _maxLength = 50;

  bool get _canSave => widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  void _save() {
    final value = widget.controller.text.trim();
    if (value.isEmpty) return;

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final background = AppColors.backgroundOf(context);
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final gold = AppColors.goldOf(context);
    final accent = AppColors.accentOf(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: gold.withValues(alpha: 0.42),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Cuál es tu género?',
                          style: GoogleFonts.cinzel(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isEditing
                              ? 'Edita cómo quieres identificarte en la aplicación.'
                              : 'Escribe cómo quieres identificarte en la aplicación.',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 8.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        Icons.close_rounded,
                        color: textSecondary,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                controller: widget.controller,
                autofocus: true,
                maxLength: _maxLength,
                maxLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_maxLength),
                ],
                onSubmitted: (_) {
                  if (_canSave) _save();
                },
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontSize: 11,
                ),
                decoration: InputDecoration(
                  hintText: 'Ej. No binario',
                  hintStyle: GoogleFonts.inter(
                    color: textSecondary.withValues(alpha: 0.70),
                    fontSize: 10,
                  ),
                  counterStyle: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: 7,
                  ),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 13,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(
                      color: gold.withValues(alpha: 0.44),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(
                      color: gold,
                      width: 1.25,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 36,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: _canSave ? 1 : 0.42,
                    child: SizedBox(
                      width: 92,
                      height: 36,
                      child: FilledButton(
                        onPressed: _canSave ? _save : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: background,
                          disabledBackgroundColor:
                              accent.withValues(alpha: 0.30),
                          disabledForegroundColor:
                              background.withValues(alpha: 0.75),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Listo',
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
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
  }
}
