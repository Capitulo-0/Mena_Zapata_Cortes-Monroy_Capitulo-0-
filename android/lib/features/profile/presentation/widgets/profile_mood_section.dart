part of '../screens/profile_screen.dart';

extension _ProfileMoodSection on _ProfileScreenState {
  Widget _buildReaderMoodCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADO LECTOR',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Visible en tu perfil',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _showCustomMoodEditor,
                icon: const Icon(Icons.edit_outlined, size: 13),
                label: const Text('Personalizar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  textStyle: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.985, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<String>(
                '${_currentMood['emoji']}-${_currentMood['label']}-$_moodIndex',
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _currentMood['emoji']!,
                    style: const TextStyle(fontSize: 21),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentMood['label']!,
                          style: GoogleFonts.merriweather(
                            color: _textPrimaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentMood['detail']!,
                          style: GoogleFonts.inter(
                            color: _textSecondaryColor,
                            fontSize: 7.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          _buildMoodCarousel(),
        ],
      ),
    );
  }

  Widget _buildMoodCarousel() {
    final nextIndex = (_moodIndex + 1) % _moods.length;

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.center,
              children: [
                ...previousChildren,
                ?currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0.055, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slide,
                child: child,
              ),
            );
          },
          child: Row(
            key: ValueKey<int>(_moodIndex),
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _moodArrow(Icons.chevron_left_rounded, -1),
              const SizedBox(width: 7),
              Expanded(
                flex: 10,
                child: _moodOption(_moodIndex, selectedOverride: true),
              ),
              const SizedBox(width: 7),
              Expanded(
                flex: 9,
                child: _moodOption(nextIndex, selectedOverride: false),
              ),
              const SizedBox(width: 7),
              _moodArrow(Icons.chevron_right_rounded, 1),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_moods.length, (index) {
            final selected = index == _moodIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 7 : 5,
              height: selected ? 7 : 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? _deepSurfaceColor
                    : AppColors.gold.withValues(alpha: 0.34),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _moodArrow(IconData icon, int direction) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _changeMood(direction),
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _deepSurfaceColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDarkMode ? 0.16 : 0.07),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.gold, size: 18),
        ),
      ),
    );
  }

  Widget _moodOption(int index, {bool? selectedOverride}) {
    final mood = _moods[index];
    final selected = selectedOverride ?? index == _moodIndex;

    return InkWell(
      onTap: () => _selectMood(index),
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _deepSurfaceColor : _backgroundColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.88)
                : AppColors.gold.withValues(alpha: 0.30),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isDarkMode ? 0.14 : 0.055,
                    ),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(mood['emoji']!, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                mood['label']!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: selected ? AppColors.background : _textPrimaryColor,
                  fontSize: 7.3,
                  height: 1.28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeMood(int direction) {
    final next = (_moodIndex + direction + _moods.length) % _moods.length;
    _selectMood(next);
  }

  void _selectMood(int index) {
    if (index == _moodIndex) return;
    _updateState(() => _moodIndex = index);
  }

  Future<void> _showCustomMoodEditor() async {
    final emojiController = TextEditingController(text: _customMoodEmoji);
    final labelController = TextEditingController(text: _customMoodLabel);
    final detailController = TextEditingController(text: _customMoodDetail);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        var isSaving = false;
        var savingDots = 1;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final previewEmoji = emojiController.text.trim().isEmpty
                ? '✨'
                : emojiController.text.trim();
            final previewLabel = labelController.text.trim().isEmpty
                ? 'Mi propio estado'
                : labelController.text.trim();
            final previewDetail = detailController.text.trim().isEmpty
                ? 'Una lectura a mi manera'
                : detailController.text.trim();

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _goldColor.withValues(alpha: 0.38),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isDarkMode ? 0.34 : 0.18,
                      ),
                      blurRadius: 32,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color:
                                  _textSecondaryColor.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _goldColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color:
                                      _goldColor.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: _goldColor,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ESTADO PERSONALIZADO',
                                    style: GoogleFonts.cinzel(
                                      color: _headingColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.25,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Define cómo quieres aparecer ante otros lectores.',
                                    style: GoogleFonts.inter(
                                      color: _textSecondaryColor,
                                      fontSize: 8.3,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Cerrar',
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: _headingColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'VISTA PREVIA',
                          style: GoogleFonts.inter(
                            color: _textSecondaryColor,
                            fontSize: 7.4,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _goldColor.withValues(alpha: 0.36),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _goldColor.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  previewEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      previewLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.merriweather(
                                        color: _headingColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      previewDetail,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: _textSecondaryColor,
                                        fontSize: 7.8,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PERSONALIZACIÓN',
                          style: GoogleFonts.inter(
                            color: _textSecondaryColor,
                            fontSize: 7.4,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 86,
                              child: _customMoodField(
                                controller: emojiController,
                                label: 'Emoji',
                                hintText: '✨',
                                maxLength: 2,
                                enabled: !isSaving,
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _customMoodField(
                                controller: labelController,
                                label: 'Estado',
                                hintText: 'Mi propio estado',
                                enabled: !isSaving,
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        _customMoodField(
                          controller: detailController,
                          label: 'Detalle',
                          hintText: 'Una lectura a mi manera',
                          maxLines: 2,
                          enabled: !isSaving,
                          onChanged: (_) => setModalState(() {}),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final label =
                                        labelController.text.trim();
                                    if (label.isEmpty) return;

                                    setModalState(() {
                                      isSaving = true;
                                      savingDots = 1;
                                    });

                                    for (var step = 0;
                                        step < 4;
                                        step++) {
                                      await Future<void>.delayed(
                                        const Duration(milliseconds: 250),
                                      );

                                      if (!sheetContext.mounted) return;

                                      setModalState(() {
                                        savingDots = (savingDots % 3) + 1;
                                      });
                                    }

                                    if (!mounted ||
                                        !sheetContext.mounted) {
                                      return;
                                    }

                                    _updateState(() {
                                      _customMoodEmoji =
                                          emojiController.text.trim().isEmpty
                                              ? '✨'
                                              : emojiController.text.trim();
                                      _customMoodLabel = label;
                                      _customMoodDetail =
                                          detailController.text.trim().isEmpty
                                              ? 'Estado lector personalizado'
                                              : detailController.text.trim();
                                      _moodIndex = _moods.length - 1;
                                    });

                                    Navigator.of(sheetContext).pop();
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: isSaving
                                  ? _accentColor.withValues(alpha: 0.58)
                                  : _accentColor,
                              disabledBackgroundColor:
                                  _accentColor.withValues(alpha: 0.58),
                              foregroundColor: AppColors.background,
                              disabledForegroundColor:
                                  AppColors.background.withValues(alpha: 0.82),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              isSaving
                                  ? 'Guardando${'.' * savingDots}'
                                  : 'Guardar estado',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));
    emojiController.dispose();
    labelController.dispose();
    detailController.dispose();
  }


  Widget _customMoodField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    final isMultiline = maxLines > 1;

    final field = TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      maxLines: isMultiline ? null : 1,
      minLines: isMultiline ? null : 1,
      expands: isMultiline,
      textAlignVertical: TextAlignVertical.center,
      maxLength: maxLength,
      style: GoogleFonts.inter(
        color: _textPrimaryColor,
        fontSize: 10.5,
        height: 1.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        counterText: '',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: GoogleFonts.inter(
          color: _textSecondaryColor,
          fontSize: 8.5,
        ),
        hintStyle: GoogleFonts.inter(
          color: _textSecondaryColor.withValues(alpha: 0.72),
          fontSize: 9.5,
        ),
        filled: true,
        fillColor: _backgroundColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isMultiline ? 0 : 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _goldColor.withValues(alpha: 0.48),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _goldColor.withValues(alpha: 0.95),
            width: 1.25,
          ),
        ),
      ),
    );

    if (!isMultiline) return field;

    return SizedBox(
      height: 58,
      child: field,
    );
  }


}
