part of '../screens/profile_screen.dart';

extension _ProfileClubsSection on _ProfileScreenState {
  Widget _buildClubsCard() {
    final joinedClubs = _joinedClubs;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MIS CLUBES DE LECTURA',
                  style: GoogleFonts.cinzel(
                    color: _headingColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${joinedClubs.length} ${joinedClubs.length == 1 ? 'club' : 'clubes'}',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (joinedClubs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'Aún no te has unido a un club desde Inicio.',
                style: GoogleFonts.merriweather(
                  color: _textSecondaryColor,
                  fontSize: 8.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...joinedClubs.map((club) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            club.name,
                            style: GoogleFonts.merriweather(
                              color: _textPrimaryColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _showClubDetails(club),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.gold,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                minimumSize: const Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: GoogleFonts.inter(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Ver'),
                            ),
                            TextButton(
                              onPressed: () => widget.onToggleClub(club.id),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: GoogleFonts.inter(
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                              child: const Text('Salir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Leyendo: ${club.book}',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '📅 ${club.date} · ${club.members} lectores',
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Modalidad: ${club.modality}',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Map<String, String> _clubExtraData(ReadingClub club) {
    switch (club.id) {
      case 1:
        return {
          'author': '@mariaPaz200',
          'instagram': '@adictosclasicos',
          'facebook': 'Adictos a los Clásicos',
          'x': '@adictosclasicos_x',
        };
      case 2:
        return {
          'author': '@valencruz',
          'instagram': '@mansiongotica',
          'facebook': 'Mansión Gótica',
          'x': '@mansiongotica_club',
        };
      case 3:
        return {
          'author': '@marcoibanez17',
          'instagram': '@plumasdelsur',
          'facebook': 'Plumas del Sur',
          'x': '@plumasdelsur',
        };
      default:
        return {
          'author': '@capitulo0',
          'instagram': '@capitulo0',
          'facebook': 'Capítulo 0',
          'x': '@capitulo0',
        };
    }
  }

  void _showClubDetails(ReadingClub club) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _backgroundColor,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final id = club.id;
        final extra = _clubExtraData(club);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final joined = widget.joinedClubIds.contains(id);

            ReadingClub currentClub = club;
            for (final candidate in widget.clubs) {
              if (candidate.id == id) {
                currentClub = candidate;
                break;
              }
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.58,
              minChildSize: 0.38,
              maxChildSize: 0.84,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DETALLE DEL CLUB',
                              style: GoogleFonts.cinzel(
                                color: _textPrimaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.25,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: _surfaceColor,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: AppColors.gold,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentClub.name,
                                    style: GoogleFonts.merriweather(
                                      color: _textPrimaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentClub.description,
                                    style: GoogleFonts.inter(
                                      color: _textPrimaryColor,
                                      fontSize: 9.2,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Autor/a del club: ',
                                        style: GoogleFonts.inter(
                                          color: _textSecondaryColor,
                                          fontSize: 8,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          extra['author']!,
                                          style: GoogleFonts.inter(
                                            color: AppColors.accent,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppColors.accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        color: AppColors.accent,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Debate: ${currentClub.date}',
                                          style: GoogleFonts.inter(
                                            color: _textSecondaryColor,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.groups_2_outlined,
                                        color: _deepSurfaceColor,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${currentClub.members} lectores',
                                        style: GoogleFonts.inter(
                                          color: _textSecondaryColor,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        currentClub.modality.toLowerCase() ==
                                                'online'
                                            ? Icons.language_rounded
                                            : Icons.location_on_outlined,
                                        color: _deepSurfaceColor,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Modalidad: ${currentClub.modality}',
                                        style: GoogleFonts.inter(
                                          color: _textSecondaryColor,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 11),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                13,
                                12,
                                13,
                                8,
                              ),
                              decoration: BoxDecoration(
                                color: _surfaceColor,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'REDES SOCIALES',
                                    style: GoogleFonts.cinzel(
                                      color: _textPrimaryColor,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _clubSocialRow(
                                    icon: Icons.photo_camera_outlined,
                                    label: 'Instagram:',
                                    value: extra['instagram']!,
                                  ),
                                  _clubSocialDivider(),
                                  _clubSocialRow(
                                    icon: Icons.facebook_outlined,
                                    label: 'Facebook:',
                                    value: extra['facebook']!,
                                  ),
                                  _clubSocialDivider(),
                                  _clubSocialRow(
                                    icon: Icons.close_rounded,
                                    label: 'X:',
                                    value: extra['x']!,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.16),
                          ),
                        ),
                      ),
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: () {
                            widget.onToggleClub(id);
                            setSheetState(() {});
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: joined
                                ? AppColors.surfaceSoftOf(context)
                                : AppColors.accent,
                            foregroundColor: joined
                                ? _textPrimaryColor
                                : AppColors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: joined
                                ? BorderSide(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.55),
                                  )
                                : BorderSide.none,
                          ),
                          child: Text(
                            joined ? 'Salir del club' : 'Unirme al club',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _clubSocialRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: _textSecondaryColor,
            size: 13,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _textSecondaryColor,
              fontSize: 8,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.accent,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clubSocialDivider() {
    return Divider(
      height: 1,
      color: AppColors.gold.withValues(alpha: 0.14),
    );
  }

}
