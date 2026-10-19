import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/writer_story.dart';
import '../../services/writer_local_service.dart';
import 'create_story_screen.dart';
import 'manage_story_screen.dart';

enum _StoryFilter { all, published, drafts }

class WriterScreen extends StatefulWidget {
  const WriterScreen({super.key});

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen> {
  final WriterLocalService _writerService = WriterLocalService();

  List<WriterStory> _stories = [];

  _StoryFilter _selectedFilter = _StoryFilter.all;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
    });

    final stories = await _writerService.getStories();

    if (!mounted) {
      return;
    }

    setState(() {
      _stories = stories;
      _isLoading = false;
    });
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

  int get _publishedCount {
    return _stories.where((story) => story.isPublished).length;
  }

  int get _draftCount {
    return _stories.where((story) => story.isDraft).length;
  }

  Future<void> _togglePublish(WriterStory story) async {
    final updatedStory = story.copyWith(
      status: story.isPublished
          ? WriterStoryStatus.draft
          : WriterStoryStatus.published,
      updatedAt: DateTime.now(),
    );

    await _writerService.updateStory(updatedStory);

    await _loadStories();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedStory.isPublished
              ? 'Historia publicada.'
              : 'Historia guardada como borrador.',
        ),
      ),
    );
  }

  Future<void> _deleteStory(WriterStory story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Eliminar historia',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.w700),
          ),
          content: Text(
            '¿Quieres eliminar "${story.title}"? Esta acción no se puede deshacer.',
            style: GoogleFonts.inter(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _writerService.deleteStory(story.id);

    await _loadStories();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Historia eliminada.')));
  }

  Future<void> _openCreateStory() async {
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );

    if (result != null) {
      await _loadStories();
    }
  }

  Future<void> _openManageStory(WriterStory story) async {
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(builder: (_) => ManageStoryScreen(story: story)),
    );

    if (result != null) {
      await _loadStories();
    }
  }

  String _formatUpdatedDate(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    }

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    }

    if (difference.inDays == 1) {
      return 'Ayer';
    }

    if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStories,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildStats(context)),
              SliverToBoxAdapter(child: _buildFilters(context)),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredStories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: _filteredStories.length,
                    itemBuilder: (context, index) {
                      return _buildStoryCard(context, _filteredStories[index]);
                    },
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 14);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MIS HISTORIAS',
                      style: GoogleFonts.cinzel(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Escribe, organiza y publica tus propias historias.',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        height: 1.4,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _openCreateStory,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Crear historia',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ESTADÍSTICAS
  // ─────────────────────────────────────────────────────────────

  Widget _buildStats(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                value: '${_stories.length}',
                label: 'Historias',
              ),
            ),
            _buildVerticalDivider(context),
            Expanded(
              child: _buildStatItem(
                context,
                value: '$_publishedCount',
                label: 'Publicadas',
              ),
            ),
            _buildVerticalDivider(context),
            Expanded(
              child: _buildStatItem(
                context,
                value: '$_draftCount',
                label: 'Borradores',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cinzel(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 1,
      height: 32,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FILTROS
  // ─────────────────────────────────────────────────────────────

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              context,
              label: 'Todas',
              filter: _StoryFilter.all,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _buildFilterButton(
              context,
              label: 'Publicadas',
              filter: _StoryFilter.published,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _buildFilterButton(
              context,
              label: 'Borradores',
              filter: _StoryFilter.drafts,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required String label,
    required _StoryFilter filter,
  }) {
    final theme = Theme.of(context);
    final selected = _selectedFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    String description;

    switch (_selectedFilter) {
      case _StoryFilter.all:
        title = 'Aún no tienes historias';
        description = 'Crea tu primera obra y comienza a escribir capítulos.';
        break;

      case _StoryFilter.published:
        title = 'No tienes historias publicadas';
        description =
            'Cuando publiques una historia, aparecerá en esta sección.';
        break;

      case _StoryFilter.drafts:
        title = 'No tienes borradores';
        description = 'Tus historias sin publicar aparecerán guardadas aquí.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 30, 32, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.merriweather(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_selectedFilter == _StoryFilter.all) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _openCreateStory,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear mi primera historia'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TARJETA DE HISTORIA
  // ─────────────────────────────────────────────────────────────

  Widget _buildStoryCard(BuildContext context, WriterStory story) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: story.isPublished
              ? theme.colorScheme.primary.withValues(alpha: 0.22)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.16 : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCover(context, story),
                const SizedBox(width: 12),
                Expanded(child: _buildStoryInformation(context, story)),
                _buildStoryMenu(context, story),
              ],
            ),
            const SizedBox(height: 13),
            _buildStoryMetrics(context, story),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _openManageStory(story);
                },
                icon: const Icon(Icons.edit_note_rounded, size: 19),
                label: Text(
                  'Administrar',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, WriterStory story) {
    final theme = Theme.of(context);

    return Container(
      width: 78,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.65),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (story.coverPath == null || story.coverPath!.trim().isEmpty)
            const SizedBox.shrink(),
          if (story.coverPath == null || story.coverPath!.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 28,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story.title.isEmpty
                        ? 'MI HISTORIA'
                        : story.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cinzel(
                      fontSize: 7.5,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryInformation(BuildContext context, WriterStory story) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          story.title.isEmpty ? 'Historia sin título' : story.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.merriweather(
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          story.genre.isEmpty ? 'Sin género' : story.genre,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatusBadge(context, story),
        const SizedBox(height: 9),
        if (story.isPublished)
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                size: 16,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 3),
              Text(
                story.rating > 0
                    ? story.rating.toStringAsFixed(1)
                    : 'Sin valoraciones',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          )
        else
          Text(
            'Última edición: ${_formatUpdatedDate(story.updatedAt)}',
            style: GoogleFonts.inter(
              fontSize: 8.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, WriterStory story) {
    final theme = Theme.of(context);

    final backgroundColor = story.isPublished
        ? theme.colorScheme.primary.withValues(alpha: 0.13)
        : theme.colorScheme.secondaryContainer;

    final foregroundColor = story.isPublished
        ? theme.colorScheme.primary
        : theme.colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        story.isPublished ? 'PUBLICADA' : 'BORRADOR',
        style: GoogleFonts.inter(
          fontSize: 7.5,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
        ),
      ),
    );
  }

  Widget _buildStoryMenu(BuildContext context, WriterStory story) {
    return PopupMenuButton<String>(
      tooltip: 'Opciones',
      icon: const Icon(Icons.more_vert_rounded, size: 21),
      onSelected: (value) {
        switch (value) {
          case 'publish':
            _togglePublish(story);
            break;

          case 'delete':
            _deleteStory(story);
            break;
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            value: 'publish',
            child: Row(
              children: [
                Icon(
                  story.isPublished
                      ? Icons.unpublished_outlined
                      : Icons.public_rounded,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Text(
                  story.isPublished ? 'Volver a borrador' : 'Publicar historia',
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, size: 19),
                SizedBox(width: 10),
                Text('Eliminar'),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildStoryMetrics(BuildContext context, WriterStory story) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetric(
              context,
              icon: Icons.format_list_numbered_rounded,
              value: '${story.chapterCount}',
              label: 'capítulos',
            ),
          ),
          Expanded(
            child: _buildMetric(
              context,
              icon: Icons.notes_rounded,
              value: '${story.totalWordCount}',
              label: 'palabras',
            ),
          ),
          Expanded(
            child: _buildMetric(
              context,
              icon: Icons.people_outline_rounded,
              value: '${story.followers}',
              label: 'seguidores',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 7.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
