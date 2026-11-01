import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';

part '../widgets/published_story_persistence.dart';
part '../widgets/published_story_header_hero.dart';
part '../widgets/published_story_overview.dart';
part '../widgets/published_story_chapters.dart';
part '../widgets/published_story_comments.dart';
part '../widgets/published_story_menus.dart';


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
    this.isGuest = false,
    this.onGuestRestrictedAction,
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
  final bool isGuest;
  final VoidCallback? onGuestRestrictedAction;

  String get displayedAuthorUsername =>
      authorUsername?.trim().isNotEmpty == true
          ? authorUsername!.trim()
          : currentUsername;

  @override
  State<PublishedStoryScreen> createState() => _PublishedStoryScreenState();
}

class _PublishedStoryScreenState extends State<PublishedStoryScreen> {
  void _updateState(VoidCallback callback) {
    setState(callback);
  }

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

  bool _guardGuestAction() {
    if (!widget.isGuest) return false;

    widget.onGuestRestrictedAction?.call();
    return true;
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

}
