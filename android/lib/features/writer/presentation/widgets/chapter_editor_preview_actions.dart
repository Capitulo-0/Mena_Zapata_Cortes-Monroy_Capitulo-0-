part of '../screens/chapter_editor_screen.dart';

extension _ChapterEditorPreviewActions on _ChapterEditorScreenState {
  Future<void> _openChapterPreview() async {
    if (!_canPublish) return;

    FocusScope.of(context).unfocus();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChapterPreviewScreen(
          storyTitle: widget.story.title,
          chapterNumber: _chapterOrder,
          chapterTitle: _titleController.text.trim(),
          content: _contentController.text.trim(),
          readingMinutes: _readingMinutes,
          wordCount: _wordCount,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }

  Widget _buildPreviewButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _canPublish ? _openChapterPreview : null,
        icon: const Icon(Icons.visibility_outlined, size: 12),
        label: Text(
          'Vista previa',
          style: GoogleFonts.inter(
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _headingColor,
          disabledForegroundColor:
              _textSecondaryColor.withValues(alpha: 0.45),
          side: BorderSide(
            color: _canPublish
                ? AppColors.gold.withValues(alpha: 0.45)
                : AppColors.gold.withValues(alpha: 0.16),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSaving || !_canPublish
                ? null
                : () {
                    _saveChapter(publish: true);
                  },
            icon: _isSaving
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_upward_rounded, size: 13),
            label: Text(
              'Publicar capítulo',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor:
                  AppColors.accent.withValues(alpha: 0.23),
              foregroundColor: AppColors.background,
              disabledForegroundColor:
                  AppColors.background.withValues(alpha: 0.90),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        OutlinedButton.icon(
          onPressed: _isSaving
              ? null
              : () {
                  _saveChapter(publish: false);
                },
          icon: const Icon(Icons.save_outlined, size: 12),
          label: Text(
            'Guardar como borrador',
            style: GoogleFonts.inter(
              fontSize: 7.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _textSecondaryColor,
            side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
