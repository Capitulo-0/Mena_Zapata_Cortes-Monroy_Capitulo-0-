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
          style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _headingColor,
          disabledForegroundColor: _textSecondaryColor.withValues(alpha: 0.45),
          side: BorderSide(
            color: _canPublish
                ? AppColors.gold.withValues(alpha: 0.45)
                : AppColors.gold.withValues(alpha: 0.16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildActions() => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      key: const ValueKey('writer-save-chapter-draft'),
      onPressed: _isSaving || _restoring || _draftConflict
          ? null
          : _saveChapter,
      icon: _isSaving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined),
      label: Text(
        widget.story.isPublished
            ? 'Guardar cambios publicados'
            : 'Guardar capítulo',
      ),
    ),
  );
}
