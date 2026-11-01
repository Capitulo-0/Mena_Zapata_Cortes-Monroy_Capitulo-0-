part of '../screens/published_story_screen.dart';

extension _PublishedStoryMenus on _PublishedStoryScreenState {
  Future<void> _showCommentMenu(
    BuildContext context,
    WriterChapter chapter,
    _MockChapterComment comment,
    Offset tapPosition,
  ) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Opciones del comentario',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final size = MediaQuery.of(dialogContext).size;
        const menuWidth = 160.0;
        const menuHeight = 88.0;

        final left = (tapPosition.dx - menuWidth)
            .clamp(12.0, size.width - menuWidth - 12.0);
        final top = (tapPosition.dy + 5)
            .clamp(12.0, size.height - menuHeight - 24.0);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.of(dialogContext).pop(),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: _surfaceColor(dialogContext),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.13),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _commentMenuOption(
                        dialogContext,
                        icon: Icons.flag_rounded,
                        label: 'Reportar',
                        color: _headingColor(dialogContext),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _showCommentReportDialog(context, comment);
                        },
                      ),
                      Divider(
                        height: 1,
                        color: AppColors.gold.withValues(alpha: 0.14),
                      ),
                      _commentMenuOption(
                        dialogContext,
                        icon: Icons.visibility_off_outlined,
                        label: 'Ocultar comentario',
                        color: AppColors.accent,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _showHideCommentDialog(
                            context,
                            chapter,
                            comment,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            alignment: Alignment.topRight,
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  Widget _commentMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 7.2,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCommentReportDialog(
    BuildContext context,
    _MockChapterComment comment,
  ) async {
    final reasons = <String>[
      'Spam o contenido repetitivo',
      'Acoso o ataques personales',
      'Contenido ofensivo o inapropiado',
      'Discurso de odio',
      'Spoiler sin advertencia',
      'Otro',
    ];

    String? selectedReason;
    final detailController = TextEditingController();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reportar comentario',
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Container(
                    width: MediaQuery.of(dialogContext).size.width * 0.80,
                    constraints: const BoxConstraints(maxWidth: 370),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                    decoration: BoxDecoration(
                      color: _surfaceColor(dialogContext),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.27),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⚑ REPORTAR COMENTARIO',
                                      style: GoogleFonts.cinzel(
                                        fontSize: 7.2,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.55,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '¿Qué ocurre con este comentario?',
                                      style: GoogleFonts.merriweather(
                                        fontSize: 13.5,
                                        height: 1.25,
                                        fontWeight: FontWeight.w700,
                                        color: _headingColor(dialogContext),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.of(dialogContext).pop(),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.gold.withValues(alpha: 0.36),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: _textSecondaryColor(dialogContext),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _backgroundColor(dialogContext),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.username,
                                  style: GoogleFonts.inter(
                                    fontSize: 6.6,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '“${comment.text}”',
                                  style: GoogleFonts.merriweather(
                                    fontSize: 7,
                                    height: 1.4,
                                    color: _textPrimaryColor(dialogContext),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...reasons.map((reason) {
                            final selected = selectedReason == reason;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedReason = reason;
                                  });
                                },
                                borderRadius: BorderRadius.circular(9),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.accent.withValues(alpha: 0.07)
                                        : _backgroundColor(dialogContext),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.accent.withValues(alpha: 0.40)
                                          : AppColors.gold.withValues(alpha: 0.20),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          reason,
                                          style: GoogleFonts.inter(
                                            fontSize: 7.2,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: _textPrimaryColor(dialogContext),
                                          ),
                                        ),
                                      ),
                                      if (selected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: AppColors.accent,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 5),
                          TextField(
                            controller: detailController,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: 300,
                            style: GoogleFonts.inter(
                              fontSize: 7.2,
                              color: _textPrimaryColor(dialogContext),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Añade un detalle opcional...',
                              counterText: '',
                              filled: true,
                              fillColor: _backgroundColor(dialogContext),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 7,
                                color: _textSecondaryColor(dialogContext),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 10,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide(
                                  color: AppColors.gold.withValues(alpha: 0.28),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: const BorderSide(
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: selectedReason == null
                                  ? null
                                  : () {
                                      Navigator.of(dialogContext).pop();

                                      if (!mounted) return;
                                      _showModerationSuccess(
                                        this.context,
                                        title: 'Comentario reportado',
                                        eyebrow: 'MODERACIÓN',
                                        message:
                                            'Gracias. El reporte fue registrado para revisión de moderación.',
                                      );
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                disabledBackgroundColor:
                                    AppColors.accent.withValues(alpha: 0.32),
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: Text(
                                'Enviar reporte',
                                style: GoogleFonts.inter(
                                  fontSize: 7.4,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
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

    detailController.dispose();
  }

  Future<void> _showHideCommentDialog(
    BuildContext context,
    WriterChapter chapter,
    _MockChapterComment comment,
  ) async {
    final shouldHide = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Ocultar comentario',
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.78,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                decoration: BoxDecoration(
                  color: _surfaceColor(dialogContext),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.27),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '● OCULTAR COMENTARIO',
                                style: GoogleFonts.cinzel(
                                  fontSize: 7.2,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.55,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '¿Estás seguro de que quieres ocultar este comentario?',
                                style: GoogleFonts.merriweather(
                                  fontSize: 13.5,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                  color: _headingColor(dialogContext),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              Navigator.of(dialogContext).pop(false),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.36),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: _textSecondaryColor(dialogContext),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _backgroundColor(dialogContext),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.username,
                            style: GoogleFonts.inter(
                              fontSize: 6.6,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '“${comment.text}”',
                            style: GoogleFonts.merriweather(
                              fontSize: 7,
                              height: 1.4,
                              color: _textPrimaryColor(dialogContext),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      'Como autor puedes ocultarlo de tu publicación. '
                      'El comentario no se elimina de forma permanente; '
                      'más adelante esta acción se conectará con la moderación del backend.',
                      style: GoogleFonts.inter(
                        fontSize: 6.7,
                        height: 1.5,
                        color: _textSecondaryColor(dialogContext),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _headingColor(dialogContext),
                              side: BorderSide(
                                color: AppColors.gold.withValues(alpha: 0.34),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.inter(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.background,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              'Ocultar comentario',
                              style: GoogleFonts.inter(
                                fontSize: 6.8,
                                fontWeight: FontWeight.w800,
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

    if (shouldHide == true) {
      if (!mounted) return;

      _updateState(() {
        comment.hidden = true;
      });

      _showModerationSuccess(
        this.context,
        title: 'Comentario ocultado',
        eyebrow: 'MODERACIÓN DE TU OBRA',
        message:
            'Este comentario ya no se muestra en la vista pública de tu obra.',
      );
    }
  }

  Future<void> _showModerationSuccess(
    BuildContext context, {
    required String title,
    required String eyebrow,
    required String message,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.76,
                constraints: const BoxConstraints(maxWidth: 350),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: _surfaceColor(dialogContext),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 47,
                      height: 47,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.42),
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 25,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      eyebrow,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 6.9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.62,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.merriweather(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _headingColor(dialogContext),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 7.2,
                        height: 1.45,
                        color: _textSecondaryColor(dialogContext),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Entendido',
                          style: GoogleFonts.inter(
                            fontSize: 7.3,
                            fontWeight: FontWeight.w800,
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
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.88,
              end: 1,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildEmptyChapters(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 31,
            color: AppColors.gold,
          ),
          const SizedBox(height: 9),
          Text(
            'Aún no hay capítulos publicados',
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _textPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportMenu(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Opciones de publicación',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(dialogContext);
        final top = media.padding.top + 54;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: top,
              right: 18,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 170,
                  decoration: BoxDecoration(
                    color: _surfaceColor(dialogContext),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _showReportDialog(context);
                    },
                    borderRadius: BorderRadius.circular(13),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            size: 15,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Reportar publicación',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
            alignment: Alignment.topRight,
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

  Future<void> _showReportDialog(BuildContext context) async {
    final reasons = <String>[
      'Contenido inapropiado',
      'Spam o contenido engañoso',
      'Acoso o lenguaje ofensivo',
      'Otro motivo',
    ];

    final detailController = TextEditingController();
    String? selectedReason;
    var isSending = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSending,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
                decoration: BoxDecoration(
                  color: _surfaceColor(dialogContext),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AbsorbPointer(
                  absorbing: isSending,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.accent
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accent
                                    .withValues(alpha: 0.20),
                              ),
                            ),
                            child: const Icon(
                              Icons.flag_rounded,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MODERACIÓN',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 7.2,
                                    fontWeight:
                                        FontWeight.w700,
                                    letterSpacing: 0.65,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reportar publicación',
                                  style:
                                      GoogleFonts.merriweather(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: _headingColor(
                                      dialogContext,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Selecciona el motivo que mejor describe el problema.',
                                  style: GoogleFonts.inter(
                                    fontSize: 7.5,
                                    height: 1.4,
                                    color:
                                        _textSecondaryColor(
                                      dialogContext,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                Navigator.of(dialogContext)
                                    .pop(),
                            customBorder:
                                const CircleBorder(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold
                                      .withValues(
                                    alpha: 0.34,
                                  ),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color:
                                    _textSecondaryColor(
                                  dialogContext,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...reasons.map((reason) {
                        final selected =
                            selectedReason == reason;

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 7,
                          ),
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedReason = reason;
                              });
                            },
                            borderRadius:
                                BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(
                                milliseconds: 170,
                              ),
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accent
                                        .withValues(
                                          alpha: 0.08,
                                        )
                                    : _backgroundColor(
                                        dialogContext,
                                      ),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.accent
                                          .withValues(
                                            alpha: 0.42,
                                          )
                                      : AppColors.gold
                                          .withValues(
                                            alpha: 0.22,
                                          ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons
                                            .radio_button_checked_rounded
                                        : Icons
                                            .radio_button_unchecked_rounded,
                                    size: 15,
                                    color: selected
                                        ? AppColors.accent
                                        : _textSecondaryColor(
                                            dialogContext,
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style:
                                          GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: selected
                                            ? FontWeight
                                                .w700
                                            : FontWeight
                                                .w500,
                                        color:
                                            _textPrimaryColor(
                                          dialogContext,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 5),
                      Text(
                        'DETALLE ADICIONAL · OPCIONAL',
                        style: GoogleFonts.cinzel(
                          fontSize: 6.7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.45,
                          color: _textSecondaryColor(
                            dialogContext,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: detailController,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 300,
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          color: _textPrimaryColor(
                            dialogContext,
                          ),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Cuéntanos brevemente qué ocurrió...',
                          counterText: '',
                          filled: true,
                          fillColor:
                              _backgroundColor(dialogContext),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 7.2,
                            color: _textSecondaryColor(
                              dialogContext,
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 10,
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.gold
                                  .withValues(alpha: 0.28),
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: FilledButton(
                          onPressed: selectedReason == null
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isSending = true;
                                  });

                                  await Future<void>.delayed(
                                    const Duration(
                                      milliseconds: 1000,
                                    ),
                                  );

                                  if (!dialogContext.mounted) {
                                    return;
                                  }

                                  Navigator.of(dialogContext)
                                      .pop();

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Reporte enviado para revisión.',
                                      ),
                                    ),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppColors.accent,
                            disabledBackgroundColor:
                                isSending
                                    ? Colors.grey.shade600
                                    : AppColors.accent
                                        .withValues(
                                          alpha: 0.30,
                                        ),
                            foregroundColor:
                                AppColors.background,
                            disabledForegroundColor:
                                isSending
                                    ? Colors.white
                                    : AppColors.background
                                        .withValues(
                                          alpha: 0.72,
                                        ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                          child: isSending
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'Enviando reporte...',
                                      style:
                                          GoogleFonts.inter(
                                        fontSize: 7.8,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Enviar reporte',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                        ),
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

    detailController.dispose();
  }

  Future<void> _showShareDialog(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Compartir obra',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.76,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: _surfaceColor(dialogContext),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.28),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COMPARTIR OBRA',
                                style: GoogleFonts.cinzel(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.65,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '¿Dónde deseas compartir?',
                                style: GoogleFonts.merriweather(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _headingColor(dialogContext),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(dialogContext).pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.38),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: _textSecondaryColor(dialogContext),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _shareOption(
                            dialogContext,
                            label: 'W · WhatsApp',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _shareOption(
                            dialogContext,
                            label: 'I · Instagram',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _shareOption(
                            dialogContext,
                            label: 'X · X',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _shareOption(
                            dialogContext,
                            label: '↗ · Enlace',
                          ),
                        ),
                      ],
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

  Widget _shareOption(
    BuildContext context, {
    required String label,
  }) {
    return InkWell(
      onTap: null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: _backgroundColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.34),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 7.4,
            fontWeight: FontWeight.w700,
            color: _textPrimaryColor(context),
          ),
        ),
      ),
    );
  }


  List<Color> _coverColors(String? cover) {
    switch (cover) {
      case 'preset:gold':
        return const [Color(0xFF9A6D2F), Color(0xFF3B2414)];
      case 'preset:forest':
        return const [Color(0xFF405A49), Color(0xFF18241E)];
      case 'preset:night':
        return const [Color(0xFF34354A), Color(0xFF171821)];
      case 'preset:classic':
      default:
        return const [Color(0xFF7D2430), Color(0xFF35130F)];
    }
  }
}
