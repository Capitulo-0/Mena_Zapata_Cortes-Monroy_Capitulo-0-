part of '../screens/published_story_screen.dart';

extension _PublishedStoryOverview on _PublishedStoryScreenState {
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 8.8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.65,
            color: _headingColor(context),
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

  Widget _buildSynopsis(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 11),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.70),
            width: 2,
          ),
        ),
      ),
      child: Text(
        widget.story.synopsis.isEmpty
            ? 'Esta obra todavía no tiene una sinopsis.'
            : widget.story.synopsis,
        style: GoogleFonts.merriweather(
          fontSize: 10.8,
          height: 1.65,
          color: _textPrimaryColor(context),
        ),
      ),
    );
  }

  Widget _buildMetrics(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _metric(
            context,
            icon: Icons.star_rounded,
            text: widget.story.rating > 0
                ? widget.story.rating.toStringAsFixed(1)
                : '—',
          ),
          _dot(),
          _metric(
            context,
            icon: Icons.menu_book_outlined,
            text:
                '${widget.story.publishedChapterCount} ${widget.story.publishedChapterCount == 1 ? 'capítulo' : 'capítulos'}',
          ),
          _dot(),
          _metric(
            context,
            icon: Icons.people_outline_rounded,
            text: '${widget.story.followers} seguidores',
          ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.gold),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 6.8,
                color: _textSecondaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Text(
        '·',
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
