part of '../screens/published_story_screen.dart';

extension _PublishedStoryComments on _PublishedStoryScreenState {
  Widget _buildNoComments(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      child: Text(
        'Aún no hay comentarios en este capítulo.',
        style: GoogleFonts.inter(
          fontSize: 7,
          color: _textSecondaryColor(context),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCommentCard(
    BuildContext context,
    WriterChapter chapter,
    _MockChapterComment comment,
  ) {
    final controller = _replyControllers[comment.id]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  comment.username,
                  style: GoogleFonts.inter(
                    fontSize: 6.8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
              GestureDetector(
                onTapDown: (details) {
                  if (_guardGuestAction()) return;

                  _showCommentMenu(
                    context,
                    chapter,
                    comment,
                    details.globalPosition,
                  );
                },
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: _surfaceColor(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.26),
                    ),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 14,
                    color: _textSecondaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            comment.text,
            style: GoogleFonts.merriweather(
              fontSize: 7.4,
              height: 1.45,
              color: _textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () {
                  if (_guardGuestAction()) return;

                  _updateState(() {
                    comment.liked = !comment.liked;
                    comment.likes += comment.liked ? 1 : -1;
                  });
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: comment.liked
                        ? AppColors.accent.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        comment.liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 9,
                        color: comment.liked
                            ? AppColors.accent
                            : _textSecondaryColor(context),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${comment.likes} Me gusta',
                        style: GoogleFonts.inter(
                          fontSize: 6.1,
                          fontWeight: comment.liked
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: comment.liked
                              ? AppColors.accent
                              : _textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 9),
              InkWell(
                onTap: () {
                  if (_guardGuestAction()) return;

                  _updateState(() {
                    comment.replying = !comment.replying;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Responder',
                    style: GoogleFonts.inter(
                      fontSize: 6.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (comment.replies.isNotEmpty)
                InkWell(
                  onTap: () {
                    _updateState(() {
                      comment.repliesExpanded = !comment.repliesExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _surfaceColor(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRotation(
                          turns: comment.repliesExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 11,
                            color: _textSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          comment.repliesExpanded
                              ? 'Ocultar respuestas (${comment.replies.length})'
                              : 'Ver respuestas (${comment.replies.length})',
                          style: GoogleFonts.inter(
                            fontSize: 5.8,
                            fontWeight: FontWeight.w600,
                            color: _textSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: comment.replying
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                      decoration: BoxDecoration(
                        color: _surfaceColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: controller,
                            maxLength: 220,
                            minLines: 2,
                            maxLines: 4,
                            style: GoogleFonts.inter(
                              fontSize: 7,
                              color: _textPrimaryColor(context),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText:
                                  'Responder a ${comment.username}...',
                              counterStyle: GoogleFonts.inter(
                                fontSize: 5.5,
                                color: _textSecondaryColor(context),
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 6.8,
                                color: _textSecondaryColor(context),
                              ),
                              filled: true,
                              fillColor: _backgroundColor(context),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide(
                                  color: AppColors.gold.withValues(alpha: 0.26),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: const BorderSide(
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'PRIVACIDAD DE LA RESPUESTA',
                            style: GoogleFonts.cinzel(
                              color: _headingColor(context),
                              fontSize: 6.3,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 32,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: _backgroundColor(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    AppColors.gold.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      _updateState(() {
                                        comment.replyPublic = true;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: comment.replyPublic
                                            ? AppColors.deepOf(context)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🌐 Pública',
                                        style: GoogleFonts.inter(
                                          fontSize: 6.4,
                                          fontWeight: FontWeight.w700,
                                          color: comment.replyPublic
                                              ? AppColors.backgroundOf(context)
                                              : _textPrimaryColor(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      _updateState(() {
                                        comment.replyPublic = false;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: !comment.replyPublic
                                            ? AppColors.deepOf(context)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🔒 Privada',
                                        style: GoogleFonts.inter(
                                          fontSize: 6.4,
                                          fontWeight: FontWeight.w700,
                                          color: !comment.replyPublic
                                              ? AppColors.backgroundOf(context)
                                              : _textPrimaryColor(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  controller.clear();
                                  _updateState(() {
                                    comment.replying = false;
                                    comment.replyPublic = true;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 5,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Cancelar',
                                  style:
                                      GoogleFonts.inter(fontSize: 5.8),
                                ),
                              ),
                              const SizedBox(width: 4),
                              FilledButton(
                                onPressed: () {
                                  if (_guardGuestAction()) return;

                                  final replyText =
                                      controller.text.trim();

                                  if (replyText.isEmpty) {
                                    return;
                                  }

                                  _updateState(() {
                                    comment.replies.add({
                                      'text': replyText,
                                      'isPublic': comment.replyPublic,
                                    });
                                    comment.replying = false;
                                    comment.repliesExpanded = true;
                                    comment.replyPublic = true;
                                  });

                                  controller.clear();
                                  _savePersistedReplies();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor:
                                      AppColors.background,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Responder',
                                  style: GoogleFonts.inter(
                                    fontSize: 5.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: comment.repliesExpanded && comment.replies.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: _surfaceColor(context),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        children: comment.replies
                            .map(
                              (reply) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _buildReplyCard(
                                  context,
                                  reply,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(
    BuildContext context,
    Map<String, dynamic> reply,
  ) {
    final isPublic = reply['isPublic'] as bool? ?? true;
    final replyText = reply['text']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.52),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '↳ ${isPublic ? widget.currentUsername : '@anonimo'}',
                  style: GoogleFonts.inter(
                    fontSize: 6.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
              Text(
                isPublic ? '🌐 Pública' : '🔒 Privada',
                style: GoogleFonts.inter(
                  fontSize: 5.5,
                  fontWeight: FontWeight.w600,
                  color: _textSecondaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            replyText,
            style: GoogleFonts.merriweather(
              fontSize: 7,
              height: 1.4,
              color: _textPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
