part of '../screens/chapter_editor_screen.dart';

extension _ChapterEditorFieldsSection on _ChapterEditorScreenState {
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAPÍTULO ${_chapterOrder.toString().padLeft(2, '0')} · TÍTULO',
          style: _fieldLabelStyle(),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _titleController,
          maxLength: 100,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.merriweather(
            fontSize: 10.5,
            color: _textPrimaryColor,
          ),
          decoration: _inputDecoration(
            hintText: 'Ej: La última carta',
            counterText: '${_titleController.text.length} / 100',
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTENIDO',
          style: _fieldLabelStyle(),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _contentController,
          minLines: 16,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.merriweather(
            fontSize: 10.5,
            height: 1.65,
            color: _textPrimaryColor,
          ),
          decoration: _inputDecoration(
            hintText: 'Comienza a escribir tu capítulo...',
            counterText: '',
          ).copyWith(
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
          ),
        ),
      ],
    );
  }

  TextStyle _fieldLabelStyle() {
    return GoogleFonts.inter(
      fontSize: 8,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.45,
      color: _textSecondaryColor,
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required String counterText,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: counterText,
      filled: true,
      fillColor: _surfaceColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      hintStyle: GoogleFonts.merriweather(
        fontSize: 9.5,
        color: _textSecondaryColor,
      ),
      counterStyle: GoogleFonts.inter(
        fontSize: 6.5,
        color: _textSecondaryColor,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.gold.withValues(alpha: 0.42),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.gold,
          width: 1.1,
        ),
      ),
    );
  }
}
