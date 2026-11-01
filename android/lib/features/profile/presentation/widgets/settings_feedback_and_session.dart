part of '../screens/settings_screen.dart';

extension _SettingsFeedbackAndSession on _SettingsScreenState {
  void _showSettingsSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          duration: const Duration(milliseconds: 2500),
          padding: EdgeInsets.zero,
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? const Color(0xFF283125)
                  : const Color(0xFFF4F7EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF78935F).withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFF708A56),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.merriweather(
                      color: widget.isDarkMode
                          ? const Color(0xFFE7EEDC)
                          : const Color(0xFF3F4F33),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.person_outline_rounded,
                  color: _gold.withValues(alpha: 0.76),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
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
