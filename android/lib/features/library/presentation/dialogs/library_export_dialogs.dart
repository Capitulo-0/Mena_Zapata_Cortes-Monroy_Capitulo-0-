import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/personal_library_list.dart';

class LibraryExportDialogs {
  const LibraryExportDialogs._();

  static Future<void> showLibraryShareDialog({
    required BuildContext context,
    required String barrierLabel,
    required String eyebrow,
    required String title,
    required String summaryTitle,
    required String summaryMain,
    required String summaryDetail,
    required String linkText,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.80,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.goldOf(context)
                        .withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                eyebrow,
                                style: GoogleFonts.cinzel(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.65,
                                  color: AppColors.accentOf(context),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                title,
                                style: GoogleFonts.merriweather(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppColors.textPrimaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _closeButton(
                          context,
                          dialogContext,
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: AppColors.goldOf(context)
                              .withValues(alpha: 0.28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summaryTitle,
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.textSecondaryOf(context),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summaryMain,
                            style: GoogleFonts.merriweather(
                              color:
                                  AppColors.textPrimaryOf(context),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            summaryDetail,
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.textSecondaryOf(context),
                              fontSize: 7.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _shareGrid(
                      context: context,
                      dialogContext: dialogContext,
                      linkText: linkText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static Future<int?> showListSelector({
    required BuildContext context,
    required List<PersonalLibraryList> lists,
  }) async {
    if (lists.isEmpty) {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Sin listas personales',
        barrierColor: Colors.black.withValues(alpha: 0.62),
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return SafeArea(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(dialogContext).size.width * 0.80,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: AppColors.goldOf(context)
                          .withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.playlist_add_rounded,
                        color: AppColors.goldOf(context),
                        size: 28,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'NO HAY LISTAS PARA EXPORTAR',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          color: AppColors.textPrimaryOf(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Crea una lista personal y luego podrás compartirla desde aquí.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondaryOf(context),
                          fontSize: 8,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppColors.deepOf(context),
                            foregroundColor:
                                AppColors.backgroundOf(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Entendido',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
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
      return null;
    }

    int? selectedIndex;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Exportar lista',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  final selected = selectedIndex == null
                      ? null
                      : lists[selectedIndex!];

                  return Container(
                    width:
                        MediaQuery.of(dialogContext).size.width * 0.84,
                    constraints: BoxConstraints(
                      maxWidth: 380,
                      maxHeight:
                          MediaQuery.of(dialogContext).size.height * 0.78,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: AppColors.goldOf(context)
                            .withValues(alpha: 0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'EXPORTAR MI LISTA',
                                      style: GoogleFonts.cinzel(
                                        color:
                                            AppColors.accentOf(context),
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.65,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '¿Qué lista deseas exportar?',
                                      style: GoogleFonts.merriweather(
                                        color:
                                            AppColors.textPrimaryOf(context),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _closeButton(
                                context,
                                dialogContext,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...List.generate(
                            lists.length,
                            (index) {
                              final list = lists[index];
                              final active = selectedIndex == index;

                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedIndex = index;
                                    });
                                  },
                                  borderRadius:
                                      BorderRadius.circular(11),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.goldOf(context)
                                              .withValues(alpha: 0.18)
                                          : AppColors.backgroundOf(context),
                                      borderRadius:
                                          BorderRadius.circular(11),
                                      border: Border.all(
                                        color: active
                                            ? AppColors.goldOf(context)
                                            : AppColors.goldOf(context)
                                                .withValues(alpha: 0.30),
                                        width: active ? 1.3 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: active
                                                ? AppColors.deepOf(context)
                                                : AppColors.goldOf(context)
                                                    .withValues(alpha: 0.10),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            list.emoji,
                                            style: const TextStyle(
                                              fontSize: 19,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                list.name,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    GoogleFonts.merriweather(
                                                  color: AppColors
                                                      .textPrimaryOf(
                                                    context,
                                                  ),
                                                  fontSize: 9.5,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${list.bookIds.length} ${list.bookIds.length == 1 ? 'libro' : 'libros'}',
                                                style: GoogleFonts.inter(
                                                  color: AppColors
                                                      .textSecondaryOf(
                                                    context,
                                                  ),
                                                  fontSize: 7.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 160,
                                          ),
                                          child: active
                                              ? Icon(
                                                  Icons
                                                      .check_circle_rounded,
                                                  key: const ValueKey(
                                                    'selected',
                                                  ),
                                                  color: AppColors
                                                      .goldOf(context),
                                                  size: 19,
                                                )
                                              : Icon(
                                                  Icons.circle_outlined,
                                                  key: const ValueKey(
                                                    'unselected',
                                                  ),
                                                  color: AppColors
                                                      .textSecondaryOf(
                                                    context,
                                                  ),
                                                  size: 18,
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (selected != null) ...[
                            const SizedBox(height: 7),
                            Divider(
                              color: AppColors.goldOf(context)
                                  .withValues(alpha: 0.24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'LISTA SELECCIONADA',
                              style: GoogleFonts.cinzel(
                                color: AppColors.accentOf(context),
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.55,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${selected.emoji} ${selected.name}',
                              style: GoogleFonts.merriweather(
                                color: AppColors.textPrimaryOf(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${selected.bookIds.length} ${selected.bookIds.length == 1 ? 'libro agregado' : 'libros agregados'}',
                              style: GoogleFonts.inter(
                                color:
                                    AppColors.textSecondaryOf(context),
                                fontSize: 7.5,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Text(
                              '¿Dónde deseas compartir?',
                              style: GoogleFonts.merriweather(
                                color: AppColors.textPrimaryOf(context),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            _shareGrid(
                              context: context,
                              dialogContext: dialogContext,
                              linkText:
                                  'Capítulo 0 · Lista ${selected.name} · ${selected.bookIds.length} libros',
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    return selectedIndex;
  }

  static Widget _closeButton(
    BuildContext context,
    BuildContext dialogContext,
  ) {
    return InkWell(
      onTap: () => Navigator.of(dialogContext).pop(),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.goldOf(context).withValues(alpha: 0.38),
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 15,
          color: AppColors.textSecondaryOf(context),
        ),
      ),
    );
  }

  static Widget _shareGrid({
    required BuildContext context,
    required BuildContext dialogContext,
    required String linkText,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _shareOption(context, 'W · WhatsApp')),
            const SizedBox(width: 8),
            Expanded(child: _shareOption(context, 'I · Instagram')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _shareOption(context, 'X · X')),
            const SizedBox(width: 8),
            Expanded(child: _shareOption(context, '↗ · Enlace')),
          ],
        ),
      ],
    );
  }

  static Widget _shareOption(
    BuildContext context,
    String label,
  ) {
    return InkWell(
      onTap: null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                AppColors.goldOf(context).withValues(alpha: 0.34),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 7.4,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ),
    );
  }
}
