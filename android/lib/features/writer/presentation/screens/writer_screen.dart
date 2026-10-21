import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/writer_story.dart';
import '../../services/writer_local_service.dart';
import 'create_story_screen.dart';
import 'manage_story_screen.dart';
import 'published_story_screen.dart';

enum _StoryFilter { all, published, drafts }

class WriterScreen extends StatefulWidget {
  const WriterScreen({
    super.key,
    this.onStoriesChanged,
  });

  final ValueChanged<List<WriterStory>>? onStoriesChanged;

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen> {
  final WriterLocalService _writerService = WriterLocalService();

  List<WriterStory> _stories = [];
  _StoryFilter _selectedFilter = _StoryFilter.all;
  bool _isLoading = true;

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

  Color get _deepColor => _isDarkMode ? AppColors.darkDeep : AppColors.deep;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories({bool notifyParent = false}) async {
    setState(() => _isLoading = true);

    final stories = await _writerService.getStories();

    if (!mounted) return;

    setState(() {
      _stories = stories;
      _isLoading = false;
    });

    if (notifyParent) {
      widget.onStoriesChanged?.call(
        List<WriterStory>.unmodifiable(stories),
      );
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
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );

    if (result != null) {
      await _loadStories(notifyParent: true);
    }
  }

  Future<void> _openEditStory(WriterStory story) async {
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(
        builder: (_) => CreateStoryScreen(story: story),
      ),
    );

    if (result != null) {
      await _loadStories(notifyParent: true);
    }
  }

  void _openPublishedStory(WriterStory story) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishedStoryScreen(story: story),
      ),
    );
  }

  Future<void> _openManageStory(WriterStory story) async {
    await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(builder: (_) => ManageStoryScreen(story: story)),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MIS HISTORIAS',
                  style: GoogleFonts.cinzel(
                    color: _headingColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      'Tu espacio de escritura',
                      style: GoogleFonts.merriweather(
                        color: _textSecondaryColor,
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Text(
                      '✦',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 8,
                      ),
                    ),
                    Text(
                      'Constanza',
                      style: GoogleFonts.inter(
                        color: _textPrimaryColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _openCreateStory,
            icon: const Icon(Icons.add_rounded, size: 15),
            label: Text(
              'Crear historia',
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.24),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStat(
                value: '${_stories.length}',
                label: _stories.length == 1 ? 'historia' : 'historias',
                valueColor: _headingColor,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildStat(
                value: '$_publishedCount',
                label: _publishedCount == 1 ? 'publicada' : 'publicadas',
                valueColor: AppColors.accent,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildStat(
                value: '$_draftCount',
                label: _draftCount == 1 ? 'borrador' : 'borradores',
                valueColor: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.merriweather(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: _textSecondaryColor,
              fontSize: 7.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 25,
      color: AppColors.gold.withValues(alpha: 0.25),
    );
  }

  Widget _buildWorksSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 9),
      child: Row(
        children: [
          Text(
            'TUS OBRAS',
            style: GoogleFonts.cinzel(
              color: _headingColor,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
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
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? _surfaceColor
              : AppColors.gold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.34),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildFilterButton('Todas', _StoryFilter.all),
            ),
            Expanded(
              child: _buildFilterButton('Publicadas', _StoryFilter.published),
            ),
            Expanded(
              child: _buildFilterButton('Borradores', _StoryFilter.drafts),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, _StoryFilter filter) {
    final selected = _selectedFilter == filter;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: selected ? AppColors.background : _textPrimaryColor,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String description;

    switch (_selectedFilter) {
      case _StoryFilter.all:
        title = 'Aún no tienes historias';
        description = 'Crea tu primera obra y comienza a escribir capítulos.';
        break;
      case _StoryFilter.published:
        title = 'No tienes historias publicadas';
        description = 'Cuando publiques una historia, aparecerá aquí.';
        break;
      case _StoryFilter.drafts:
        title = 'No tienes borradores';
        description = 'Tus historias sin publicar aparecerán aquí.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 35, 28, 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.32),
                ),
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                color: _headingColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.merriweather(
                color: _textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _textSecondaryColor,
                fontSize: 9,
                height: 1.45,
              ),
            ),
            if (_selectedFilter == _StoryFilter.all) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _openCreateStory,
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Crear mi primera historia'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
