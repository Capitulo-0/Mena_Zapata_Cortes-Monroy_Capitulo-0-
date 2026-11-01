part of '../screens/published_story_screen.dart';

extension _PublishedStoryHeaderHero on _PublishedStoryScreenState {
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 9),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 15),
            label: Text(
              'Volver atrás',
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
          ),
          const Spacer(),
          InkWell(
            onTap: () => _showReportMenu(context),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: _surfaceColor(context),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.42),
                ),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: 17,
                color: _headingColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final cover = widget.story.coverPath?.trim() ?? '';
    final hasNetworkCover =
        cover.startsWith('http://') || cover.startsWith('https://');

    return SizedBox(
      width: double.infinity,
      height: 225,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasNetworkCover)
            Image.network(
              cover,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPresetHeroBackground(),
            )
          else
            _buildPresetHeroBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 16,
            child: _buildFavoriteChip(),
          ),
          Positioned(
            top: 13,
            right: 16,
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 1,
                  color: AppColors.gold.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 5),
                Text(
                  'CREADA · ${_formatDate(widget.story.createdAt)}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 5.6,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildGenrePill(),
                          const SizedBox(width: 6),
                          _buildPublishedPill(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.story.title.isEmpty
                            ? 'Historia sin título'
                            : widget.story.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.merriweather(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'por ',
                            style: GoogleFonts.inter(
                              color: AppColors.gold,
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.displayedAuthorUsername,
                            style: GoogleFonts.inter(
                              color: AppColors.gold,
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _showShareDialog(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.75),
                      ),
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 17,
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

  Widget _buildPresetHeroBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _coverColors(widget.story.coverPath),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: 74,
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
    );
  }

  Widget _buildFavoriteChip() {
    return InkWell(
      onTap: () {
        if (_guardGuestAction()) return;

        widget.onToggleFavorite?.call();

        _updateState(() {
          _isFavorite = !_isFavorite;
        });
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: _isFavorite
              ? AppColors.accent.withValues(alpha: 0.92)
              : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _isFavorite
                ? AppColors.gold.withValues(alpha: 0.60)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: Colors.white,
              size: 11,
            ),
            const SizedBox(width: 4),
            Text(
              'Favoritos',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 6.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenrePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        widget.story.genre.isEmpty
            ? 'SIN GÉNERO'
            : widget.story.genre.toUpperCase(),
        style: GoogleFonts.inter(
          color: AppColors.deep,
          fontSize: 5.6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPublishedPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'PUBLICADA',
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontSize: 5.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
