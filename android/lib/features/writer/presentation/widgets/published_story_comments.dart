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
    _ChapterCommentView comment,
  ) {
    final controller = _replyControllers.putIfAbsent(comment.id, TextEditingController.new);
    final social = _controllerFor(chapter)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
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
              if (comment.active || comment.data.canModerate)
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
                onTap: !comment.active || social.busy ? null : () async {
                  if (_guardGuestAction()) return;
                  if (!await social.setLiked(comment.id, !comment.liked)) {
                    _showCommentFailure(chapter);
                  }
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
                onTap: !comment.active || social.busy ? null : () {
                  if (_guardGuestAction()) return;
                  _updateState(() { comment.replying = !comment.replying; });
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
            child: comment.replying && comment.active
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
                              hintText: 'Responder a ${comment.username}...',
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
                                color: AppColors.gold.withValues(alpha: 0.24),
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
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
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
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
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
                                  style: GoogleFonts.inter(fontSize: 5.8),
                                ),
                              ),
                              const SizedBox(width: 4),
                              FilledButton(
                                onPressed: social.busy ? null : () async {
                                  if (_guardGuestAction()) return;

                                  final replyText = controller.text.trim();

                                  if (replyText.isEmpty) {
                                    return;
                                  }

                                  final saved = await social.publish(replyText,
                                    anonymous: !comment.replyPublic, parentId: comment.id);
                                  if (!mounted) return;
                                  if (!saved) { _showCommentFailure(chapter); return; }
                                  controller.clear();
                                  _updateState(() {
                                    comment.replying = false;
                                    comment.repliesExpanded = true;
                                    comment.replyPublic = true;
                                  });
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.background,
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
                                child: _buildReplyCard(context, chapter, reply),
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

  Widget _buildReplyCard(BuildContext context, WriterChapter chapter, _ChapterCommentView reply) {
    final isPublic = !reply.data.anonymous;
    final replyText = reply.text;
    final social = _controllerFor(chapter)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
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
                  '↳ ${reply.username}',
                  style: GoogleFonts.inter(
                    fontSize: 6.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
              if (reply.active || reply.data.canModerate)
                GestureDetector(
                  onTapDown: (details) => _showCommentMenu(context, chapter, reply, details.globalPosition),
                  child: Icon(Icons.more_vert_rounded, size: 14, color: _textSecondaryColor(context)),
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
          if (reply.active)
            InkWell(
              onTap: social.busy ? null : () async {
                if (!await social.setLiked(reply.id, !reply.liked)) _showCommentFailure(chapter);
              },
              child: Text('${reply.liked ? '♥' : '♡'} ${reply.likes} Me gusta',
                style: GoogleFonts.inter(fontSize: 6.1, color: AppColors.accent)),
            ),
          if (reply.active)
            TextButton(onPressed: social.busy ? null : () => _showCommentEditor(context, chapter, parent: reply),
              child: Text('Responder', style: GoogleFonts.inter(fontSize: 6.2, color: AppColors.accent))),
          ...reply.replies.map((child) => _buildReplyCard(context, chapter, child)),
        ],
      ),
    );
  }
}
