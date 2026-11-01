part of '../screens/settings_screen.dart';

extension _SettingsBlockedUsersSection on _SettingsScreenState {
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
                            onPressed: () async {
                              final confirmed =
                                  await _confirmUnblockUser(user);

                              if (confirmed != true || !mounted) {
                                return;
                              }

                              final username = user['username'] ?? '';
                              ProfileBlockedUsersStore.unblock(username);
                              _updateState(() {});

                              _showSettingsSuccessMessage(
                                'Se desbloqueó $username',
                              );
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

  Future<bool?> _confirmUnblockUser(Map<String, String> user) {
    final username = user['username'] ?? '@usuario';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var isUnblocking = false;
        var unblockingDots = 1;

        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    color: _gold.withValues(alpha: 0.48),
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
                        color: _gold.withValues(alpha: 0.11),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Icon(
                        Icons.lock_open_rounded,
                        color: _gold,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      '¿Desbloquear a $username?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Este usuario podrá volver a ver tu perfil y el contenido relacionado a ti.',
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
                              onPressed: isUnblocking
                                  ? null
                                  : () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _textPrimary,
                                disabledForegroundColor:
                                    _textSecondary.withValues(alpha: 0.55),
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
                              onPressed: isUnblocking
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isUnblocking = true;
                                        unblockingDots = 1;
                                      });

                                      for (var step = 0;
                                          step < 4;
                                          step++) {
                                        await Future<void>.delayed(
                                          const Duration(milliseconds: 250),
                                        );

                                        if (!dialogContext.mounted) return;

                                        setDialogState(() {
                                          unblockingDots =
                                              (unblockingDots % 3) + 1;
                                        });
                                      }

                                      if (!dialogContext.mounted) return;
                                      Navigator.of(dialogContext).pop(true);
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: isUnblocking
                                    ? _accent.withValues(alpha: 0.58)
                                    : _accent,
                                disabledBackgroundColor:
                                    _accent.withValues(alpha: 0.58),
                                foregroundColor: AppColors.background,
                                disabledForegroundColor:
                                    AppColors.background.withValues(alpha: 0.82),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isUnblocking
                                    ? 'Desbloqueando${'.' * unblockingDots}'
                                    : 'Desbloquear',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
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
            );
          },
        );
      },
    );
  }
}
