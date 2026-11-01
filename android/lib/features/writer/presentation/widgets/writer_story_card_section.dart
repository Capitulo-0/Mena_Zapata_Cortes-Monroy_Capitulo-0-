part of '../screens/writer_screen.dart';

extension _WriterStoryCardSection on _WriterScreenState {
  Widget _buildStoryCard(WriterStory story) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _isDarkMode ? 0.14 : 0.055,
            ),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(story),
              const SizedBox(width: 11),
              Expanded(child: _buildStoryInformation(story)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 89),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: FilledButton(
                    onPressed: () => _openManageStory(story),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      'Administrar',
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildStoryMenu(story),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCover(WriterStory story) {
    final cover = story.coverPath?.trim() ?? '';
    final hasNetworkCover =
        cover.startsWith('http://') || cover.startsWith('https://');

    return Container(
      width: 78,
      height: 108,
      decoration: BoxDecoration(
        color: _deepColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasNetworkCover
          ? Image.network(
              cover,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildCoverPlaceholder(story),
            )
          : _buildCoverPlaceholder(story),
    );
  }

  Widget _buildCoverPlaceholder(WriterStory story) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _deepColor,
            _deepColor.withValues(alpha: 0.76),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: AppColors.gold,
            size: 24,
          ),
          const SizedBox(height: 7),
          Text(
            story.title.trim().isEmpty
                ? 'TU HISTORIA'
                : story.title.toUpperCase(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              color: AppColors.background,
              fontSize: 6.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryInformation(WriterStory story) {
    return SizedBox(
      height: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  story.title.trim().isEmpty
                      ? 'Historia sin título'
                      : story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    color: _textPrimaryColor,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildStatusBadge(story),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            story.genre.trim().isEmpty ? 'Sin género' : story.genre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: _textSecondaryColor,
              fontSize: 7.5,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _microMeta('${story.chapterCount} capítulos'),
              _dotSeparator(),
              _microMeta('${story.totalWordCount} palabras'),
              _dotSeparator(),
              _microMeta('${story.followers} seguidores'),
            ],
          ),
          const Spacer(),
          if (story.isPublished)
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.gold,
                  size: 12,
                ),
                const SizedBox(width: 3),
                Text(
                  story.rating > 0
                      ? story.rating.toStringAsFixed(1)
                      : 'Sin valoración',
                  style: GoogleFonts.inter(
                    color: story.rating > 0
                        ? AppColors.gold
                        : _textSecondaryColor,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            Text(
              '★ Sin valoración',
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontSize: 7.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: _textSecondaryColor,
                size: 10,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Última edición: ${_formatUpdatedDate(story.updatedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _textSecondaryColor,
                    fontSize: 6.8,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _microMeta(String text) {
    return Flexible(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: _textSecondaryColor,
          fontSize: 6.6,
        ),
      ),
    );
  }

  Widget _dotSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildStatusBadge(WriterStory story) {
    final published = story.isPublished;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: published
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: published
              ? AppColors.accent.withValues(alpha: 0.34)
              : AppColors.gold.withValues(alpha: 0.46),
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
              color: published ? AppColors.accent : AppColors.gold,
              fontSize: 5.8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryMenu(WriterStory story) {
    return SizedBox(
      width: 34,
      height: 32,
      child: InkWell(
        onTapDown: (details) {
          _showStoryMenu(
            story,
            details.globalPosition,
          );
        },
        borderRadius: BorderRadius.circular(9),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.55),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.more_horiz_rounded,
            color: _headingColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _showStoryMenu(
    WriterStory story,
    Offset tapPosition,
  ) async {
    if (_blockGuestAction()) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Opciones de historia',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final size = MediaQuery.of(dialogContext).size;
        const menuWidth = 165.0;
        final menuHeight = story.isPublished ? 94.0 : 52.0;

        final left = (tapPosition.dx - menuWidth)
            .clamp(12.0, size.width - menuWidth - 12.0);
        final top = (tapPosition.dy + 6)
            .clamp(12.0, size.height - menuHeight - 24.0);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.of(dialogContext).pop(),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _storyMenuOption(
                        icon: Icons.edit_outlined,
                        label: 'Editar historia',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _openEditStory(story);
                        },
                      ),
                      if (story.isPublished) ...[
                        Divider(
                          height: 1,
                          color: AppColors.gold.withValues(alpha: 0.16),
                        ),
                        _storyMenuOption(
                          icon: Icons.visibility_outlined,
                          label: 'Ver publicada',
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            _openPublishedStory(story);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  Widget _storyMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: AppColors.gold,
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8.3,
                fontWeight: FontWeight.w600,
                color: _textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
