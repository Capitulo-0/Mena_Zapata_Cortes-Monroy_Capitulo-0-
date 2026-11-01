part of '../screens/create_story_screen.dart';

extension _CreateStoryCoverSection on _CreateStoryScreenState {
  Future<void> _chooseCover() async {
    final selectedCover = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surfaceColor,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ELIGE UNA PORTADA',
                  style: GoogleFonts.cinzel(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _headingColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Por ahora puedes elegir una portada base. Más adelante conectaremos la carga de imágenes.',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    height: 1.45,
                    color: _textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildCoverOption(
                        bottomSheetContext,
                        id: 'preset:classic',
                        label: 'Clásica',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCoverOption(
                        bottomSheetContext,
                        id: 'preset:gold',
                        label: 'Dorada',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCoverOption(
                        bottomSheetContext,
                        id: 'preset:forest',
                        label: 'Bosque',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCoverOption(
                        bottomSheetContext,
                        id: 'preset:night',
                        label: 'Noche',
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

    if (selectedCover == null || !mounted) return;

    _updateState(() {
      _selectedCover = selectedCover;
    });
  }

  Widget _buildCoverOption(
    BuildContext context, {
    required String id,
    required String label,
  }) {
    final colors = _coverColors(id);

    return InkWell(
      onTap: () => Navigator.of(context).pop(id),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: _textPrimaryColor,
            ),
          ),
        ],
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

  bool get _hasUnsavedChanges {
    return _titleController.text != _initialTitle ||
        _synopsisController.text != _initialSynopsis ||
        _selectedGenre != _initialGenre ||
        _selectedCover != _initialCover;
  }

  Widget _buildCoverSection() {
    return Column(
      children: [
        Center(child: _buildLargeCoverPreview()),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _chooseCover,
          icon: const Icon(Icons.auto_awesome_rounded, size: 14),
          label: Text(
            _hasCover ? 'Cambiar portada' : 'Elegir portada',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _headingColor,
            side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.55),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Añade una imagen mediante URL',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 6.8,
            color: _textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLargeCoverPreview() {
    return Container(
      width: 96,
      height: 136,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasCover
          ? _buildPresetCover()
          : Container(
              color: _surfaceColor,
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '✦',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'TU HISTORIA',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      color: _textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 28,
                    height: 1,
                    color: AppColors.gold.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPresetCover() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _coverColors(_selectedCover),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(height: 10),
          Text(
            _hasTitle ? _titleController.text.trim().toUpperCase() : 'TU HISTORIA',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 7,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
