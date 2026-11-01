part of '../screens/chapter_editor_screen.dart';

extension _ChapterEditorHeaderSection on _ChapterEditorScreenState {
  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: _goBack,
      icon: const Icon(Icons.arrow_back_rounded, size: 15),
      label: Text(
        'Administrar capítulos',
        style: GoogleFonts.inter(
          fontSize: 8.5,
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 8.8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.65,
            color: AppColors.accent,
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

  Widget _buildHeader() {
    final isPublished = widget.chapter?.isPublished == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _isEditing
                    ? 'CAPÍTULO ${_chapterOrder.toString().padLeft(2, '0')}'
                    : 'CAPÍTULO ${_chapterOrder.toString().padLeft(2, '0')}',
                style: GoogleFonts.merriweather(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _headingColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusPill(isPublished),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          _isEditing
              ? 'Continúa desarrollando esta parte de tu historia.'
              : 'Comienza una nueva parte de tu historia.',
          style: GoogleFonts.inter(
            fontSize: 8.5,
            height: 1.45,
            color: _textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(bool published) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: published
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: published
              ? AppColors.accent.withValues(alpha: 0.30)
              : AppColors.gold.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: published ? AppColors.accent : AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            published ? 'PUBLICADO' : 'BORRADOR',
            style: GoogleFonts.inter(
              fontSize: 5.7,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.25,
              color: published ? AppColors.accent : AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
