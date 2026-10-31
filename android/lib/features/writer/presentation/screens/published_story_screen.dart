import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';

class _MockChapterComment {
  _MockChapterComment({
    required this.id,
    required this.username,
    required this.text,
    required this.likes,
    List<Map<String, dynamic>>? replies,
  }) : replies = replies ?? <Map<String, dynamic>>[];

  final String id;
  final String username;
  final String text;
  final List<Map<String, dynamic>> replies;

  int likes;
  bool liked = false;
  bool hidden = false;
  bool replying = false;
  bool repliesExpanded = false;
  bool replyPublic = true;
}

class PublishedStoryScreen extends StatefulWidget {
  const PublishedStoryScreen({
    super.key,
    required this.story,
    required this.currentUsername,
    this.authorUsername,
    this.initiallyFavorite = false,
    this.onToggleFavorite,
  });

  final WriterStory story;

  /// Usuario que está usando la app. Se utiliza para respuestas/comentarios
  /// creados por el usuario actual.
  final String currentUsername;

  /// Autor que debe mostrarse en la publicación.
  /// En Writer normalmente coincide con currentUsername, mientras que una
  /// historia de la comunidad puede pertenecer a otro usuario.
  final String? authorUsername;
  final bool initiallyFavorite;
  final VoidCallback? onToggleFavorite;

  String get displayedAuthorUsername =>
      authorUsername?.trim().isNotEmpty == true
          ? authorUsername!.trim()
          : currentUsername;

  @override
  State<PublishedStoryScreen> createState() => _PublishedStoryScreenState();
}

class _PublishedStoryScreenState extends State<PublishedStoryScreen> {
  final Set<String> _expandedChapterIds = <String>{};
  late final Map<String, List<_MockChapterComment>> _commentsByChapter;
  late bool _isFavorite;
  final Map<String, TextEditingController> _replyControllers = {};

  String get _repliesStorageKey =>
      'published_story_replies_${widget.story.id}';

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _backgroundColor(BuildContext context) =>
      _isDarkMode(context) ? AppColors.darkBackground : AppColors.background;

  Color _surfaceColor(BuildContext context) =>
      _isDarkMode(context) ? AppColors.darkSurface : AppColors.surface;

  Color _textPrimaryColor(BuildContext context) =>
      _isDarkMode(context) ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color _textSecondaryColor(BuildContext context) =>
      _isDarkMode(context)
          ? AppColors.darkTextSecondary
          : AppColors.textSecondary;

  Color _headingColor(BuildContext context) =>
      _isDarkMode(context) ? AppColors.darkTextPrimary : AppColors.deep;

  List<WriterChapter> get _publishedChapters {
    final chapters = widget.story.chapters
        .where((chapter) => chapter.isPublished)
        .toList();

    chapters.sort((a, b) => a.order.compareTo(b.order));
    return chapters;
  }

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initiallyFavorite;

    final chapters = _publishedChapters;
    _commentsByChapter = <String, List<_MockChapterComment>>{};

    for (var index = 0; index < chapters.length; index++) {
      final chapter = chapters[index];

      if (index == 0) {
        _commentsByChapter[chapter.id] = [
          _MockChapterComment(
            id: '${chapter.id}-comment-1',
            username: '@valencruz',
            text: 'El comienzo me dejó con mucha intriga.',
            likes: 13,
          ),
          _MockChapterComment(
            id: '${chapter.id}-comment-2',
            username: '@edu_dev',
            text: 'Muy buena atmósfera para iniciar la historia.',
            likes: 5,
          ),
        ];
      } else if (index == 1) {
        _commentsByChapter[chapter.id] = [
          _MockChapterComment(
            id: '${chapter.id}-comment-1',
            username: '@lectora_sur',
            text: 'Me gustó mucho cómo continúa el misterio.',
            likes: 8,
          ),
        ];
      } else {
        _commentsByChapter[chapter.id] = [];
      }
    }

    for (final comments in _commentsByChapter.values) {
      for (final comment in comments) {
        _replyControllers[comment.id] = TextEditingController();
      }
    }

    _loadPersistedReplies();
  }

  Future<void> _loadPersistedReplies() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_repliesStorageKey);

    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return;
      }

      for (final comments in _commentsByChapter.values) {
        for (final comment in comments) {
          final storedReplies = decoded[comment.id];

          if (storedReplies is List) {
            final parsedReplies = <Map<String, dynamic>>[];

            for (final storedReply in storedReplies) {
              if (storedReply is String && storedReply.trim().isNotEmpty) {
                // Compatibilidad con respuestas guardadas antes de añadir privacidad.
                parsedReplies.add({
                  'text': storedReply.trim(),
                  'isPublic': true,
                });
                continue;
              }

              if (storedReply is Map) {
                final replyText =
                    storedReply['text']?.toString().trim() ?? '';

                if (replyText.isEmpty) continue;

                parsedReplies.add({
                  'text': replyText,
                  'isPublic': storedReply['isPublic'] as bool? ?? true,
                });
              }
            }

            comment.replies
              ..clear()
              ..addAll(parsedReplies);
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {});
    } catch (_) {
      // Si los datos locales están dañados, simplemente mantenemos
      // los comentarios mock sin respuestas persistidas.
    }
  }

  Future<void> _savePersistedReplies() async {
    final preferences = await SharedPreferences.getInstance();

    final data = <String, List<Map<String, dynamic>>>{};

    for (final comments in _commentsByChapter.values) {
      for (final comment in comments) {
        if (comment.replies.isNotEmpty) {
          data[comment.id] = comment.replies
              .map((reply) => Map<String, dynamic>.from(reply))
              .toList();
        }
      }
    }

    await preferences.setString(
      _repliesStorageKey,
      jsonEncode(data),
    );
  }

  @override
  void dispose() {
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  List<_MockChapterComment> _visibleComments(WriterChapter chapter) {
    return (_commentsByChapter[chapter.id] ?? const [])
        .where((comment) => !comment.hidden)
        .toList();
  }

  String _commentCountLabel(WriterChapter chapter) {
    final count = _visibleComments(chapter).length;
    return '$count ${count == 1 ? 'comentario' : 'comentarios'}';
  }

  void _toggleChapterComments(WriterChapter chapter) {
    setState(() {
      if (_expandedChapterIds.contains(chapter.id)) {
        _expandedChapterIds.remove(chapter.id);
      } else {
        _expandedChapterIds.add(chapter.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapters = _publishedChapters;

    return Scaffold(
      backgroundColor: _backgroundColor(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar(context)),
            SliverToBoxAdapter(child: _buildHero(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildSectionTitle(context, 'SINOPSIS'),
                    const SizedBox(height: 10),
                    _buildSynopsis(context),
                    const SizedBox(height: 16),
                    _buildMetrics(context),
                    const SizedBox(height: 18),
                    _buildSectionTitle(context, 'CAPÍTULOS'),
                    const SizedBox(height: 12),
                    if (chapters.isEmpty)
                      _buildEmptyChapters(context)
                    else
                      ...chapters.map(
                        (chapter) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildChapterCard(context, chapter),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        widget.onToggleFavorite?.call();

        setState(() {
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
                  setState(() {
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
                  setState(() {
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
                    setState(() {
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
                                      setState(() {
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
                                      setState(() {
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
                                  setState(() {
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
                                  final replyText =
                                      controller.text.trim();

                                  if (replyText.isEmpty) {
                                    return;
                                  }

                                  setState(() {
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

  Future<void> _showCommentMenu(
    BuildContext context,
    WriterChapter chapter,
    _MockChapterComment comment,
    Offset tapPosition,
  ) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Opciones del comentario',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final size = MediaQuery.of(dialogContext).size;
        const menuWidth = 160.0;
        const menuHeight = 88.0;

        final left = (tapPosition.dx - menuWidth)
            .clamp(12.0, size.width - menuWidth - 12.0);
        final top = (tapPosition.dy + 5)
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
                    color: _surfaceColor(dialogContext),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.13),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _commentMenuOption(
                        dialogContext,
                        icon: Icons.flag_rounded,
                        label: 'Reportar',
                        color: _headingColor(dialogContext),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _showCommentReportDialog(context, comment);
                        },
                      ),
                      Divider(
                        height: 1,
                        color: AppColors.gold.withValues(alpha: 0.14),
                      ),
                      _commentMenuOption(
                        dialogContext,
                        icon: Icons.visibility_off_outlined,
                        label: 'Ocultar comentario',
                        color: AppColors.accent,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _showHideCommentDialog(
                            context,
                            chapter,
                            comment,
                          );
                        },
                      ),
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
          opacity: animation,
          child: ScaleTransition(
            alignment: Alignment.topRight,
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  Widget _commentMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 7.2,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCommentReportDialog(
    BuildContext context,
    _MockChapterComment comment,
  ) async {
    final reasons = <String>[
      'Spam o contenido repetitivo',
      'Acoso o ataques personales',
      'Contenido ofensivo o inapropiado',
      'Discurso de odio',
      'Spoiler sin advertencia',
      'Otro',
    ];

    String? selectedReason;
    final detailController = TextEditingController();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reportar comentario',
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Container(
                    width: MediaQuery.of(dialogContext).size.width * 0.80,
                    constraints: const BoxConstraints(maxWidth: 370),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                    decoration: BoxDecoration(
                      color: _surfaceColor(dialogContext),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.27),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⚑ REPORTAR COMENTARIO',
                                      style: GoogleFonts.cinzel(
                                        fontSize: 7.2,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.55,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '¿Qué ocurre con este comentario?',
                                      style: GoogleFonts.merriweather(
                                        fontSize: 13.5,
                                        height: 1.25,
                                        fontWeight: FontWeight.w700,
                                        color: _headingColor(dialogContext),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.of(dialogContext).pop(),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.gold.withValues(alpha: 0.36),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: _textSecondaryColor(dialogContext),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _backgroundColor(dialogContext),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.username,
                                  style: GoogleFonts.inter(
                                    fontSize: 6.6,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '“${comment.text}”',
                                  style: GoogleFonts.merriweather(
                                    fontSize: 7,
                                    height: 1.4,
                                    color: _textPrimaryColor(dialogContext),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...reasons.map((reason) {
                            final selected = selectedReason == reason;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedReason = reason;
                                  });
                                },
                                borderRadius: BorderRadius.circular(9),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.accent.withValues(alpha: 0.07)
                                        : _backgroundColor(dialogContext),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.accent.withValues(alpha: 0.40)
                                          : AppColors.gold.withValues(alpha: 0.20),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          reason,
                                          style: GoogleFonts.inter(
                                            fontSize: 7.2,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: _textPrimaryColor(dialogContext),
                                          ),
                                        ),
                                      ),
                                      if (selected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: AppColors.accent,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 5),
                          TextField(
                            controller: detailController,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: 300,
                            style: GoogleFonts.inter(
                              fontSize: 7.2,
                              color: _textPrimaryColor(dialogContext),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Añade un detalle opcional...',
                              counterText: '',
                              filled: true,
                              fillColor: _backgroundColor(dialogContext),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 7,
                                color: _textSecondaryColor(dialogContext),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 10,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide(
                                  color: AppColors.gold.withValues(alpha: 0.28),
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
                          const SizedBox(height: 9),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: selectedReason == null
                                  ? null
                                  : () {
                                      Navigator.of(dialogContext).pop();

                                      if (!mounted) return;
                                      _showModerationSuccess(
                                        this.context,
                                        title: 'Comentario reportado',
                                        eyebrow: 'MODERACIÓN',
                                        message:
                                            'Gracias. El reporte fue registrado para revisión de moderación.',
                                      );
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                disabledBackgroundColor:
                                    AppColors.accent.withValues(alpha: 0.32),
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: Text(
                                'Enviar reporte',
                                style: GoogleFonts.inter(
                                  fontSize: 7.4,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
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
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );

    detailController.dispose();
  }

  Future<void> _showHideCommentDialog(
    BuildContext context,
    WriterChapter chapter,
    _MockChapterComment comment,
  ) async {
    final shouldHide = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Ocultar comentario',
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.78,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                decoration: BoxDecoration(
                  color: _surfaceColor(dialogContext),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.27),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '● OCULTAR COMENTARIO',
                                style: GoogleFonts.cinzel(
                                  fontSize: 7.2,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.55,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '¿Estás seguro de que quieres ocultar este comentario?',
                                style: GoogleFonts.merriweather(
                                  fontSize: 13.5,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                  color: _headingColor(dialogContext),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              Navigator.of(dialogContext).pop(false),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.36),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: _textSecondaryColor(dialogContext),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _backgroundColor(dialogContext),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.username,
                            style: GoogleFonts.inter(
                              fontSize: 6.6,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '“${comment.text}”',
                            style: GoogleFonts.merriweather(
                              fontSize: 7,
                              height: 1.4,
                              color: _textPrimaryColor(dialogContext),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      'Como autor puedes ocultarlo de tu publicación. '
                      'El comentario no se elimina de forma permanente; '
                      'más adelante esta acción se conectará con la moderación del backend.',
                      style: GoogleFonts.inter(
                        fontSize: 6.7,
                        height: 1.5,
                        color: _textSecondaryColor(dialogContext),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _headingColor(dialogContext),
                              side: BorderSide(
                                color: AppColors.gold.withValues(alpha: 0.34),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.inter(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.background,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              'Ocultar comentario',
                              style: GoogleFonts.inter(
                                fontSize: 6.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );

    if (shouldHide == true) {
      if (!mounted) return;

      setState(() {
        comment.hidden = true;
      });

      _showModerationSuccess(
        this.context,
        title: 'Comentario ocultado',
        eyebrow: 'MODERACIÓN DE TU OBRA',
        message:
            'Este comentario ya no se muestra en la vista pública de tu obra.',
      );
    }
  }

  Future<void> _showModerationSuccess(
    BuildContext context, {
    required String title,
    required String eyebrow,
    required String message,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.76,
                constraints: const BoxConstraints(maxWidth: 350),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: _surfaceColor(dialogContext),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 47,
                      height: 47,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.42),
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 25,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      eyebrow,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 6.9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.62,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.merriweather(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _headingColor(dialogContext),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 7.2,
                        height: 1.45,
                        color: _textSecondaryColor(dialogContext),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Entendido',
                          style: GoogleFonts.inter(
                            fontSize: 7.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.88,
              end: 1,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildEmptyChapters(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 31,
            color: AppColors.gold,
          ),
          const SizedBox(height: 9),
          Text(
            'Aún no hay capítulos publicados',
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _textPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportMenu(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Opciones de publicación',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(dialogContext);
        final top = media.padding.top + 54;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: top,
              right: 18,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 170,
                  decoration: BoxDecoration(
                    color: _surfaceColor(dialogContext),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _showReportDialog(context);
                    },
                    borderRadius: BorderRadius.circular(13),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            size: 15,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Reportar publicación',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
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
          child: ScaleTransition(
            alignment: Alignment.topRight,
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    final reasons = <String>[
      'Contenido inapropiado',
      'Spam o contenido engañoso',
      'Acoso o lenguaje ofensivo',
      'Otro motivo',
    ];

    final detailController = TextEditingController();
    String? selectedReason;
    var isSending = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSending,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
                decoration: BoxDecoration(
                  color: _surfaceColor(dialogContext),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AbsorbPointer(
                  absorbing: isSending,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.accent
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accent
                                    .withValues(alpha: 0.20),
                              ),
                            ),
                            child: const Icon(
                              Icons.flag_rounded,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MODERACIÓN',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 7.2,
                                    fontWeight:
                                        FontWeight.w700,
                                    letterSpacing: 0.65,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reportar publicación',
                                  style:
                                      GoogleFonts.merriweather(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: _headingColor(
                                      dialogContext,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Selecciona el motivo que mejor describe el problema.',
                                  style: GoogleFonts.inter(
                                    fontSize: 7.5,
                                    height: 1.4,
                                    color:
                                        _textSecondaryColor(
                                      dialogContext,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                Navigator.of(dialogContext)
                                    .pop(),
                            customBorder:
                                const CircleBorder(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold
                                      .withValues(
                                    alpha: 0.34,
                                  ),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color:
                                    _textSecondaryColor(
                                  dialogContext,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...reasons.map((reason) {
                        final selected =
                            selectedReason == reason;

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 7,
                          ),
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedReason = reason;
                              });
                            },
                            borderRadius:
                                BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(
                                milliseconds: 170,
                              ),
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accent
                                        .withValues(
                                          alpha: 0.08,
                                        )
                                    : _backgroundColor(
                                        dialogContext,
                                      ),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.accent
                                          .withValues(
                                            alpha: 0.42,
                                          )
                                      : AppColors.gold
                                          .withValues(
                                            alpha: 0.22,
                                          ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons
                                            .radio_button_checked_rounded
                                        : Icons
                                            .radio_button_unchecked_rounded,
                                    size: 15,
                                    color: selected
                                        ? AppColors.accent
                                        : _textSecondaryColor(
                                            dialogContext,
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style:
                                          GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: selected
                                            ? FontWeight
                                                .w700
                                            : FontWeight
                                                .w500,
                                        color:
                                            _textPrimaryColor(
                                          dialogContext,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 5),
                      Text(
                        'DETALLE ADICIONAL · OPCIONAL',
                        style: GoogleFonts.cinzel(
                          fontSize: 6.7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.45,
                          color: _textSecondaryColor(
                            dialogContext,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: detailController,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 300,
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          color: _textPrimaryColor(
                            dialogContext,
                          ),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Cuéntanos brevemente qué ocurrió...',
                          counterText: '',
                          filled: true,
                          fillColor:
                              _backgroundColor(dialogContext),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 7.2,
                            color: _textSecondaryColor(
                              dialogContext,
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 10,
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.gold
                                  .withValues(alpha: 0.28),
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: FilledButton(
                          onPressed: selectedReason == null
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isSending = true;
                                  });

                                  await Future<void>.delayed(
                                    const Duration(
                                      milliseconds: 1000,
                                    ),
                                  );

                                  if (!dialogContext.mounted) {
                                    return;
                                  }

                                  Navigator.of(dialogContext)
                                      .pop();

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Reporte enviado para revisión.',
                                      ),
                                    ),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppColors.accent,
                            disabledBackgroundColor:
                                isSending
                                    ? Colors.grey.shade600
                                    : AppColors.accent
                                        .withValues(
                                          alpha: 0.30,
                                        ),
                            foregroundColor:
                                AppColors.background,
                            disabledForegroundColor:
                                isSending
                                    ? Colors.white
                                    : AppColors.background
                                        .withValues(
                                          alpha: 0.72,
                                        ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                          child: isSending
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'Enviando reporte...',
                                      style:
                                          GoogleFonts.inter(
                                        fontSize: 7.8,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Enviar reporte',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    detailController.dispose();
  }

  Future<void> _showShareDialog(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Compartir obra',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.76,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: _surfaceColor(dialogContext),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COMPARTIR OBRA',
                                style: GoogleFonts.cinzel(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.65,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '¿Dónde deseas compartir?',
                                style: GoogleFonts.merriweather(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _headingColor(dialogContext),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(dialogContext).pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.38),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: _textSecondaryColor(dialogContext),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _shareOption(
                            dialogContext,
                            label: 'W · WhatsApp',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _shareOption(
                            dialogContext,
                            label: 'I · Instagram',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _shareOption(
                            dialogContext,
                            label: 'X · X',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _shareOption(
                            dialogContext,
                            label: '↗ · Enlace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _shareOption(
    BuildContext context, {
    required String label,
  }) {
    return InkWell(
      onTap: null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: _backgroundColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.34),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 7.4,
            fontWeight: FontWeight.w700,
            color: _textPrimaryColor(context),
          ),
        ),
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
