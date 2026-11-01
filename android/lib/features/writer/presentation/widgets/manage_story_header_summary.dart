part of '../screens/manage_story_screen.dart';

extension _ManageStoryHeaderSummary on _ManageStoryScreenState {
  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pop(_story),
      icon: const Icon(Icons.arrow_back_rounded, size: 15),
      label: Text(
        'Mis historias',
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'ADMINISTRAR HISTORIA',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.55,
                  color: _headingColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Organiza capítulos y controla la publicación de tu obra.',
          style: GoogleFonts.inter(
            fontSize: 8.5,
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
            fontSize: 8.8,
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

  Widget _buildStatusBadge() {
    final published = _story.isPublished;

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
              : AppColors.gold.withValues(alpha: 0.38),
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
            published ? 'PUBLICADA' : 'BORRADOR',
            style: GoogleFonts.inter(
              fontSize: 5.6,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.25,
              color: published ? AppColors.accent : AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.12 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCover(),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _story.title.isEmpty ? 'Historia sin título' : _story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: _textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _story.genre.isEmpty ? 'Sin género' : _story.genre,
                  style: GoogleFonts.inter(
                    fontSize: 7.5,
                    color: _textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.gold,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_story.chapterCount} '
                      '${_story.chapterCount == 1 ? 'capítulo' : 'capítulos'}',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        color: _textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.gold,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Última edición · ${_formatDate(_story.updatedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 6.8,
                          color: _textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _editStory,
                  icon: const Icon(Icons.edit_outlined, size: 12),
                  label: Text(
                    'Editar historia',
                    style: GoogleFonts.inter(
                      fontSize: 7.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _headingColor,
                    side: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.55),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    return Container(
      width: 76,
      height: 106,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _coverColors(_story.coverPath),
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 23,
          ),
          const SizedBox(height: 8),
          Text(
            _story.title.isEmpty ? 'MI HISTORIA' : _story.title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cinzel(
              fontSize: 6.4,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
}
