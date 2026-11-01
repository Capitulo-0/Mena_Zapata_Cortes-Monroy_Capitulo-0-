part of '../screens/published_story_screen.dart';

extension _PublishedStoryChapters on _PublishedStoryScreenState {
  Widget _buildChapterCard(
    BuildContext context,
    WriterChapter chapter,
  ) {
    final expanded = _expandedChapterIds.contains(chapter.id);
    final comments = _visibleComments(chapter);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _isDarkMode(context) ? 0.10 : 0.035,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  chapter.order.toString().padLeft(2, '0'),
                  style: GoogleFonts.cinzel(
                    fontSize: 6.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title.isEmpty
                          ? 'Capítulo sin título'
                          : chapter.title,
                      style: GoogleFonts.merriweather(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PUBLICADO',
                      style: GoogleFonts.inter(
                        fontSize: 5.8,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            chapter.content.isEmpty
                ? 'Este capítulo todavía no tiene contenido.'
                : chapter.content,
            style: GoogleFonts.merriweather(
              fontSize: 9.8,
              height: 1.65,
              color: _textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: AppColors.gold.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 3),
          InkWell(
            onTap: () => _toggleChapterComments(chapter),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 9,
                    color: Color(0xFFB8A2D9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _commentCountLabel(chapter),
                    style: GoogleFonts.inter(
                      fontSize: 6.5,
                      color: _textSecondaryColor(context),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 13,
                      color: _textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: comments.isEmpty
                        ? _buildNoComments(context)
                        : Column(
                            children: comments
                                .map(
                                  (comment) => Padding(
                                    padding: const EdgeInsets.only(bottom: 7),
                                    child: _buildCommentCard(
                                      context,
                                      chapter,
                                      comment,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
