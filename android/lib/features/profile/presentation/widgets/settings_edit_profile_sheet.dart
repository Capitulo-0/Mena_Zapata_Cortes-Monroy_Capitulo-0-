part of '../screens/settings_screen.dart';

extension _SettingsEditProfileSheet on _SettingsScreenState {
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
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: isSaving
                            ? null
                            : () async {
                                final selected =
                                    await _showReadingFormatPicker(
                                  bottomSheetContext,
                                  tempReadingFormat,
                                );

                                if (selected == null ||
                                    !bottomSheetContext.mounted) {
                                  return;
                                }

                                setModalState(() {
                                  tempReadingFormat = selected;
                                });
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 31,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: _gold.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(
                                  tempReadingFormat == 'Físico'
                                      ? Icons.menu_book_rounded
                                      : tempReadingFormat == 'Digital'
                                          ? Icons.tablet_mac_rounded
                                          : Icons.auto_stories_rounded,
                                  color: _gold,
                                  size: 17,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tempReadingFormat,
                                  style: GoogleFonts.inter(
                                    color: _textPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
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

                                        _updateState(() {
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

                                          _showSettingsSuccessMessage(
                                            'Perfil actualizado correctamente',
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

  Future<String?> _showReadingFormatPicker(
    BuildContext parentContext,
    String currentValue,
  ) {
    final options = <Map<String, Object>>[
      {
        'value': 'Físico',
        'icon': Icons.menu_book_rounded,
        'description': 'Prefiero leer libros impresos.',
      },
      {
        'value': 'Digital',
        'icon': Icons.tablet_mac_rounded,
        'description': 'Prefiero leer desde dispositivos digitales.',
      },
      {
        'value': 'Ambos',
        'icon': Icons.auto_stories_rounded,
        'description': 'Alterno entre formato físico y digital.',
      },
    ];

    return showModalBottomSheet<String>(
      context: parentContext,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (pickerContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _gold.withValues(alpha: 0.30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _textSecondary.withValues(alpha: 0.26),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.chrome_reader_mode_outlined,
                        color: _gold,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FORMATO DE LECTURA',
                            style: GoogleFonts.cinzel(
                              color: _textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Selecciona tu formato preferido.',
                            style: GoogleFonts.inter(
                              color: _textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...options.map((option) {
                  final value = option['value']! as String;
                  final icon = option['icon']! as IconData;
                  final description = option['description']! as String;
                  final selected = currentValue == value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(pickerContext).pop(value),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: selected
                                ? _accent.withValues(alpha: 0.08)
                                : _surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? _accent.withValues(alpha: 0.45)
                                  : _gold.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _accent.withValues(alpha: 0.12)
                                      : _gold.withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  icon,
                                  color: selected ? _accent : _gold,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      value,
                                      style: GoogleFonts.inter(
                                        color: _textPrimary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      description,
                                      style: GoogleFonts.inter(
                                        color: _textSecondary,
                                        fontSize: 7.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _accent,
                                  size: 19,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
