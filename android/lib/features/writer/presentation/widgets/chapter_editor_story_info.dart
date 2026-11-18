part of '../screens/chapter_editor_screen.dart';

extension _ChapterEditorStoryInfo on _ChapterEditorScreenState {
  Widget _buildStoryInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.10 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          WriterCover(
            storyId: widget.story.id,
            coverPath: widget.story.coverPath,
            title: widget.story.title,
            width: 48,
            height: 64,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.story.title.isEmpty
                      ? 'Historia sin título'
                      : widget.story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.story.genre.isEmpty
                      ? 'Sin género'
                      : widget.story.genre,
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '${widget.story.chapterCount} capítulos',
                      style: GoogleFonts.inter(
                        fontSize: 6.5,
                        color: _textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '·',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Capítulo ${_chapterOrder.toString().padLeft(2, '0')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 6.5,
                          color: _textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
