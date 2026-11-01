part of '../screens/create_story_screen.dart';

extension _CreateStoryHeaderSection on _CreateStoryScreenState {
  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: _goBack,
      icon: const Icon(Icons.arrow_back_rounded, size: 16),
      label: Text(
        _isEditing ? 'Volver' : 'Volver',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? 'EDICIÓN DE OBRA' : 'CREAR HISTORIA',
          style: GoogleFonts.cinzel(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _isEditing ? 'EDITAR HISTORIA' : 'DA FORMA A UNA NUEVA OBRA.',
                style: GoogleFonts.merriweather(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: _headingColor,
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(width: 8),
              _buildStatusPill(widget.story!.isPublished),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _isEditing
              ? 'Actualiza la identidad y presentación de tu obra.'
              : 'Empieza por su identidad, género y la idea que quieres contar.',
          style: GoogleFonts.inter(
            fontSize: 9.5,
            height: 1.45,
            color: _textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 9.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.65,
            color: _headingColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.55),
                  AppColors.gold.withValues(alpha: 0.06),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '◆',
          style: TextStyle(
            color: AppColors.gold.withValues(alpha: 0.75),
            fontSize: 7,
          ),
        ),
      ],
    );
  }
}
