import 'dart:async';

import '../widgets/writer_cover.dart';


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../social/presentation/controllers/chapter_comments_controller.dart';
import '../../../social/models/social_comment.dart';
import '../../../social/models/social_review.dart';
import '../../../social/presentation/controllers/story_reviews_controller.dart';
import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';

part '../widgets/published_story_comments.dart';
part '../widgets/published_story_header_hero.dart';
part '../widgets/published_story_overview.dart';
part '../widgets/published_story_chapters.dart';
part '../widgets/published_story_menus.dart';
part '../widgets/published_story_reviews.dart';

// Estado exclusivamente visual; los datos provienen del controlador HTTP.
class _ChapterCommentView {
  _ChapterCommentView(this.data);
  SocialComment data;
  int get id => data.id;
  String get username => data.deleted ? 'Comentario eliminado' : data.hidden ? 'Comentario oculto' : data.username ?? '@anonimo';
  String get text => data.content ?? (data.deleted ? 'Este comentario fue eliminado.' : 'Este comentario está oculto.');
  int get likes => data.likeCount;
  bool get liked => data.likedByMe;
  bool get active => !data.deleted && !data.hidden;
  bool replying = false;
  bool repliesExpanded = false;
  bool replyPublic = true;
  List<_ChapterCommentView> replies = [];
}

class PublishedStoryScreen extends StatefulWidget {
  const PublishedStoryScreen({
    super.key,
    required this.story,
    required this.currentUsername,
    this.authorUsername,
    this.socialApi,
    this.socialExpectedUid,
    this.initiallyFavorite = false,
    this.onToggleFavorite,
    this.isGuest = false,
    this.onGuestRestrictedAction,
  });

  final WriterStory story;
  final ApiClient? socialApi;
  final String? socialExpectedUid;

  bool get socialActionsEnabled => false;

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
  final Map<String, ChapterCommentsController> _chapterControllers = {};
  final Map<int, _ChapterCommentView> _commentViews = {};
  final Map<int, TextEditingController> _replyControllers = {};
  late bool _isFavorite;
  final TextEditingController _reviewController = TextEditingController();
  StoryReviewsController? _reviews;
  bool _hasReview = false;
  bool _reviewEditorOpen = false;
  bool _reviewIsPublic = true;
  bool _draftReviewIsPublic = true;
  int _rating = 5;
  int _draftRating = 5;
  String _reviewText = '';

  Color get _background => AppColors.backgroundOf(context);
  Color get _surface => AppColors.surfaceOf(context);
  Color get _textPrimary => AppColors.textPrimaryOf(context);
  Color get _textSecondary => AppColors.textSecondaryOf(context);
  Color get _gold => AppColors.goldOf(context);
  Color get _accent => AppColors.accentOf(context);

  void _reviewsChanged() {
    if (!mounted) return;
    final own = _reviews?.ownReview;
    setState(() {
      _hasReview = own != null;
      _rating = own?.rating ?? 5;
      _reviewIsPublic = own == null || own.visibility == ReviewVisibility.public;
      _reviewText = own?.reviewText ?? '';
      if (widget.socialApi?.auth.currentUser?.uid != _socialUid) {
        _reviewEditorOpen = false;
        _reviewController.clear();
      }
    });
  }


  List<_ChapterCommentView> _visibleComments(WriterChapter chapter) {
    final controller = _controllerFor(chapter);
    if (controller == null) return [];
    final views = <int, _ChapterCommentView>{};
    for (final data in controller.comments) {
      final view = _commentViews.putIfAbsent(data.id, () => _ChapterCommentView(data));
      view.data = data;
      view.replies = [];
      views[data.id] = view;
    }
    for (final view in views.values) {
      views[view.data.parentId]?.replies.add(view);
    }
    return views.values.where((view) => view.data.parentId == null).toList();
  }

  void _showCommentFailure(WriterChapter chapter) {
    if (!mounted) return;
    final error = _controllerFor(chapter)?.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  String? _socialUid;

  bool get _chapterCommentsAvailable => !widget.isGuest && widget.story.isPublished &&
      _socialUid != null && widget.socialApi != null;

  ChapterCommentsController? _controllerFor(WriterChapter chapter) =>
      _chapterControllers[chapter.id];

  void _onCommentsChanged() {
    if (mounted) setState(() {});
  }

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _backgroundColor(BuildContext context) =>
      _isDarkMode(context) ? AppColors.darkBackground : AppColors.background;

  Color _surfaceColor(BuildContext context) =>
      _isDarkMode(context) ? AppColors.darkSurface : AppColors.surface;

  Color _textPrimaryColor(BuildContext context) =>
      _isDarkMode(context) ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color _textSecondaryColor(BuildContext context) => _isDarkMode(context)
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

    _socialUid = widget.socialExpectedUid ?? widget.socialApi?.auth.currentUser?.uid;
    final api = widget.socialApi;
    final uid = _socialUid;
    if (!widget.isGuest && widget.story.isPublished && api != null && uid != null &&
        api.auth.currentUser?.uid == uid &&
        RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(widget.story.id)) {
      _reviews = StoryReviewsController(api, expectedUid: uid, storyKey: widget.story.id)
        ..addListener(_reviewsChanged);
      unawaited(_reviews!.refresh());
    }
  }

  @override
  void dispose() {
    _reviews?.removeListener(_reviewsChanged);
    _reviews?.dispose();
    _reviewController.dispose();
    for (final controller in _chapterControllers.values) {
      controller.removeListener(_onCommentsChanged);
      controller.dispose();
    }
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

  String _commentCountLabel(WriterChapter chapter) {
    final controller = _controllerFor(chapter);
    if (controller == null || !controller.loaded) return 'Comentarios';
    final count = controller.comments.where((comment) => !comment.hidden && !comment.deleted).length;
    return '$count ${count == 1 ? 'comentario' : 'comentarios'}';
  }

  void _toggleChapterComments(WriterChapter chapter) {
    if (_guardGuestAction() || !_chapterCommentsAvailable) return;
    if (_expandedChapterIds.contains(chapter.id)) {
      setState(() => _expandedChapterIds.remove(chapter.id));
      return;
    }
    if (widget.socialApi!.auth.currentUser?.uid != _socialUid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La sesión cambió. Vuelve a abrir la historia.')));
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(widget.story.id) ||
        !RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(chapter.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos identificar este capítulo.')));
      return;
    }
    final controller = _chapterControllers.putIfAbsent(chapter.id, () =>
        ChapterCommentsController(widget.socialApi!, expectedUid: _socialUid!,
            storyKey: widget.story.id, chapterId: chapter.id)..addListener(_onCommentsChanged));
    setState(() => _expandedChapterIds.add(chapter.id));
    controller.refresh();
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
                delegate: SliverChildListDelegate([
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
                  if (chapters.isNotEmpty && (_reviews != null || widget.isGuest)) ...[
                    const SizedBox(height: 18),
                    _buildSectionTitle(context, 'CALIFICACIONES Y RESEÑAS'),
                    const SizedBox(height: 12),
                    _buildReviewSection(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
