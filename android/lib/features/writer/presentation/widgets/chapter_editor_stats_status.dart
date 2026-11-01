part of '../screens/chapter_editor_screen.dart';

extension _ChapterEditorStatsStatus on _ChapterEditorScreenState {
  Widget _buildCompactStats() {
    return Row(
      children: [
        _compactStat(
          icon: Icons.notes_rounded,
          value: '$_wordCount palabras',
        ),
        _compactDot(),
        _compactStat(
          icon: Icons.text_fields_rounded,
          value: '$_characterCount caracteres',
        ),
        _compactDot(),
        _compactStat(
          icon: Icons.schedule_rounded,
          value: '$_readingMinutes min de lectura',
        ),
      ],
    );
  }

  Widget _compactStat({
    required IconData icon,
    required String value,
  }) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 9,
            color: AppColors.gold,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 6.2,
                color: _textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        '·',
        style: GoogleFonts.inter(
          fontSize: 7,
          color: AppColors.gold,
        ),
      ),
    );
  }

  Widget _buildPendingStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: _titleController.text.trim().isEmpty &&
                      _contentController.text.trim().isEmpty
                  ? AppColors.gold.withValues(alpha: 0.30)
                  : AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _titleController.text.trim().isEmpty &&
                    _contentController.text.trim().isEmpty
                ? 'Sin cambios pendientes'
                : 'Cambios pendientes',
            style: GoogleFonts.inter(
              fontSize: 6.8,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
