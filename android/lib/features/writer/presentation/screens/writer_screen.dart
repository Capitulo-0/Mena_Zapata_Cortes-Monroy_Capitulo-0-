import '../widgets/writer_cover.dart';
import '../widgets/writer_header.dart';

import 'package:flutter/material.dart';

import '../../../../core/session/local_account_scope.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/writer_story.dart';
import '../../services/writer_repository.dart';
import 'create_story_screen.dart';
import 'manage_story_screen.dart';
import 'published_story_screen.dart';

part '../widgets/writer_overview_section.dart';
part '../widgets/writer_story_card_section.dart';

enum _StoryFilter { all, published, drafts }

class WriterScreen extends StatefulWidget {
  const WriterScreen({
    super.key,
    this.repository,
    this.active = true,
    required this.currentName,
    required this.currentUsername,
    this.onStoriesChanged,
    this.isGuest = false,
    this.onGuestRestrictedAction,
  });

  final String currentName;
  final String currentUsername;
  final ValueChanged<List<WriterStory>>? onStoriesChanged;
  final bool isGuest;
  final VoidCallback? onGuestRestrictedAction;

  final WriterRepository? repository;
  final bool active;

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen> {
  void _updateState(VoidCallback callback) {
    setState(callback);
  }

  bool _blockGuestAction() {
    if (!widget.isGuest) return false;
    widget.onGuestRestrictedAction?.call();
    return true;
  }

  late final WriterRepository _writerService =
      widget.repository ?? const UnavailableWriterRepository();

  List<WriterStory> _stories = [];
  _StoryFilter _selectedFilter = _StoryFilter.all;
  int _storiesRequest = 0;
  bool _isLoading = true;
  String? _loadError;

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      _isDarkMode ? AppColors.darkBackground : AppColors.background;

  Color get _surfaceColor =>
      _isDarkMode ? AppColors.darkSurface : AppColors.surface;

  Color get _textPrimaryColor =>
      _isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get _textSecondaryColor =>
      _isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get _headingColor =>
      _isDarkMode ? AppColors.darkTextPrimary : AppColors.deep;

  String get _writerDisplayName {
    final currentName = widget.currentName.trim();
    if (currentName.isNotEmpty) return currentName;
    final currentUsername = widget.currentUsername.trim();
    if (currentUsername.isNotEmpty) return currentUsername;
    return 'lectora';
  }

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _loadStories();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(covariant WriterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _loadStories(notifyParent: true);
    }
  }

  Future<void> _loadStories({bool notifyParent = false}) async {
    final request = ++_storiesRequest;
    setState(() => _isLoading = true);

    try {
      final stories = widget.isGuest
          ? <WriterStory>[]
          : await _writerService.getStories();
      if (!mounted || request != _storiesRequest) return;
      setState(() {
        _stories = stories;
        _isLoading = false;
        _loadError = null;
      });
      if (notifyParent) {
        widget.onStoriesChanged?.call(List<WriterStory>.unmodifiable(stories));
      }
    } catch (error) {
      if (mounted && request == _storiesRequest) {
        setState(() {
          _isLoading = false;
          _loadError = writerError(error);
        });
      }
    }
  }

  List<WriterStory> get _filteredStories {
    switch (_selectedFilter) {
      case _StoryFilter.all:
        return _stories;
      case _StoryFilter.published:
        return _stories.where((story) => story.isPublished).toList();
      case _StoryFilter.drafts:
        return _stories.where((story) => story.isDraft).toList();
    }
  }

  int get _publishedCount =>
      _stories.where((story) => story.isPublished).length;

  int get _draftCount => _stories.where((story) => story.isDraft).length;

  Future<void> _openCreateStory() async {
    if (_blockGuestAction()) return;

    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(
        builder: (_) => CreateStoryScreen(repository: _writerService),
      ),
    );

    if (result != null) {
      await _loadStories(notifyParent: true);
    }
  }

  Future<void> _openEditStory(WriterStory story) async {
    if (_blockGuestAction()) return;

    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(
        builder: (_) =>
            CreateStoryScreen(story: story, repository: _writerService),
      ),
    );

    if (result != null) {
      await _loadStories(notifyParent: true);
    }
  }

  void _openPublishedStory(WriterStory story) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishedStoryScreen(
          story: story,
          currentUsername: widget.currentUsername,
        ),
      ),
    );
  }

  Future<void> _openManageStory(WriterStory story) async {
    if (_blockGuestAction()) return;

    await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(
        builder: (_) => ManageStoryScreen(
          story: story,
          repository: _writerService,
          ownerUid: LocalAccountScope.read(context),
          currentUsername: widget.currentUsername,
        ),
      ),
    );

    if (!mounted) return;

    await _loadStories(notifyParent: true);
  }

  String _formatUpdatedDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sept',
      'oct',
      'nov',
      'dic',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadStories(notifyParent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildStats()),
              SliverToBoxAdapter(child: _buildWorksSectionTitle()),
              SliverToBoxAdapter(child: _buildFilters()),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          _loadError!,
                          key: const ValueKey('writer-load-error'),
                        ),
                        TextButton(
                          onPressed: _loadStories,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredStories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 130),
                  sliver: SliverList.separated(
                    itemCount: _filteredStories.length,
                    itemBuilder: (context, index) {
                      return _buildStoryCard(_filteredStories[index]);
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
