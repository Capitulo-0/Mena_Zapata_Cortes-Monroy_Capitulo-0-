part of '../screens/manage_story_screen.dart';

extension _ManageStoryProgressSection on _ManageStoryScreenState {
  Widget _buildProgress() {
    final progress = _story.publicationProgress;
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_story.publishedChapterCount} de '
                '${_story.chapterCount} capítulos publicados',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  color: _textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: GoogleFonts.inter(
                fontSize: 7.5,
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.gold.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      ],
    );
  }
}
