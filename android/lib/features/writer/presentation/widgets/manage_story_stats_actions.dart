part of '../screens/manage_story_screen.dart';

extension _ManageStoryStatsActions on _ManageStoryScreenState {
  Widget _buildStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.22),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _inlineStat(
            icon: Icons.star_rounded,
            value:
                _story.rating > 0 ? _story.rating.toStringAsFixed(1) : '—',
          ),
          _statDot(),
          _inlineStat(
            icon: Icons.public_rounded,
            value: '${_story.publishedChapterCount} publicados',
          ),
          _statDot(),
          _inlineStat(
            icon: Icons.people_outline_rounded,
            value: '${_story.followers} seguidores',
          ),
        ],
      ),
    );
  }

  Widget _inlineStat({
    required IconData icon,
    required String value,
  }) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.gold),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 6.7,
                color: _textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Text(
        '·',
        style: GoogleFonts.inter(
          fontSize: 8,
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openNewChapter,
            icon: const Icon(Icons.add_rounded, size: 15),
            label: Text(
              'Nuevo capítulo',
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : (_story.isPublished
                    ? _openPublishedView
                    : _toggleStoryPublication),
            icon: _isPublishingStory
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                    ),
                  )
                : Icon(
                    _story.isPublished
                        ? Icons.visibility_outlined
                        : Icons.upload_rounded,
                    size: 13,
                  ),
            label: Text(
              _isPublishingStory
                  ? 'Publicando...'
                  : (_story.isPublished
                      ? 'Vista publicada'
                      : 'Publicar historia'),
              style: GoogleFonts.inter(
                fontSize: 7.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _headingColor,
              side: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.45),
              ),
              padding: const EdgeInsets.symmetric(vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
