import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';
import '../../services/writer_local_service.dart';
import 'create_story_screen.dart';
import 'chapter_editor_screen.dart';

class ManageStoryScreen extends StatefulWidget {
  const ManageStoryScreen({super.key, required this.story});

  final WriterStory story;

  @override
  State<ManageStoryScreen> createState() => _ManageStoryScreenState();
}

class _ManageStoryScreenState extends State<ManageStoryScreen> {
  final WriterLocalService _writerService = WriterLocalService();

  late WriterStory _story;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _story = widget.story;

    _refreshStory();
  }

  Future<void> _refreshStory() async {
    final storedStory = await _writerService.getStoryById(_story.id);

    if (!mounted || storedStory == null) {
      return;
    }

    setState(() {
      _story = storedStory;
    });
  }

  Future<void> _saveStory(WriterStory updatedStory) async {
    await _writerService.updateStory(updatedStory);

    if (!mounted) {
      return;
    }

    setState(() {
      _story = updatedStory;
    });
  }

  Future<void> _editStory() async {
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(builder: (_) => CreateStoryScreen(story: _story)),
    );

    if (result != null) {
      await _refreshStory();
    }
  }

  Future<void> _toggleStoryPublication() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final updatedStory = _story.copyWith(
      status: _story.isPublished
          ? WriterStoryStatus.draft
          : WriterStoryStatus.published,
      updatedAt: DateTime.now(),
    );

    await _writerService.updateStory(updatedStory);

    if (!mounted) {
      return;
    }

    setState(() {
      _story = updatedStory;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _story.isPublished
              ? 'Historia publicada correctamente.'
              : 'La historia volvió a borrador.',
        ),
      ),
    );
  }

  Future<void> _toggleChapterPublication(WriterChapter chapter) async {
    final updatedChapters = _story.chapters.map((currentChapter) {
      if (currentChapter.id != chapter.id) {
        return currentChapter;
      }

      return currentChapter.copyWith(
        isPublished: !currentChapter.isPublished,
        updatedAt: DateTime.now(),
      );
    }).toList();

    final updatedStory = _story.copyWith(
      chapters: updatedChapters,
      updatedAt: DateTime.now(),
    );

    await _saveStory(updatedStory);
  }

  Future<void> _deleteChapter(WriterChapter chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Eliminar capítulo',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.w700),
          ),
          content: Text(
            '¿Quieres eliminar el capítulo '
            '"${chapter.title.isEmpty ? 'Capítulo ${chapter.order}' : chapter.title}"?',
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

    final updatedChapters = _story.chapters
        .where((currentChapter) => currentChapter.id != chapter.id)
        .toList();

    updatedChapters.sort((a, b) => a.order.compareTo(b.order));

    final reorderedChapters = <WriterChapter>[];

    for (var index = 0; index < updatedChapters.length; index++) {
      reorderedChapters.add(updatedChapters[index].copyWith(order: index + 1));
    }

    final updatedStory = _story.copyWith(
      chapters: reorderedChapters,
      updatedAt: DateTime.now(),
    );

    await _saveStory(updatedStory);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Capítulo eliminado.')));
  }

  Future<void> _openNewChapter() async {
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(builder: (_) => ChapterEditorScreen(story: _story)),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _story = result;
    });
  }

  Future<void> _openEditChapter(WriterChapter chapter) async {
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(
        builder: (_) => ChapterEditorScreen(story: _story, chapter: chapter),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _story = result;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chapters = [..._story.chapters]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshStory,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(context),
                const SizedBox(height: 8),
                _buildHeader(context),
                const SizedBox(height: 22),
                _buildStoryCard(context),
                const SizedBox(height: 18),
                _buildStats(context),
                const SizedBox(height: 20),
                _buildMainActions(context),
                const SizedBox(height: 28),
                _buildProgress(context),
                const SizedBox(height: 28),
                _buildChapterHeading(context),
                const SizedBox(height: 12),
                if (chapters.isEmpty)
                  _buildEmptyChapters(context)
                else
                  ...chapters.map(
                    (chapter) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildChapterCard(context, chapter),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pop(_story);
      },
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: Text(
        'MIS HISTORIAS',
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700),
      ),
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ADMINISTRAR HISTORIA',
                style: GoogleFonts.cinzel(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            _buildStatusBadge(context),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'GESTIÓN DE OBRA',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Organiza capítulos y controla la publicación de tu obra.',
          style: GoogleFonts.inter(
            fontSize: 11,
            height: 1.45,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _story.isPublished
            ? theme.colorScheme.primary.withValues(alpha: 0.13)
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _story.isPublished ? 'PUBLICADA' : 'BORRADOR',
        style: GoogleFonts.inter(
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: _story.isPublished
              ? theme.colorScheme.primary
              : theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCover(context),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _story.title.isEmpty ? 'Historia sin título' : _story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _story.genre.isEmpty ? 'Sin género' : _story.genre,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_story.chapterCount} '
                  '${_story.chapterCount == 1 ? 'capítulo' : 'capítulos'}',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Última edición: ${_formatDate(_story.updatedAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 11),
                OutlinedButton.icon(
                  onPressed: _editStory,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(
                    'Editar historia',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
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

  Widget _buildCover(BuildContext context) {
    final colors = _coverColors(_story.coverPath);

    return Container(
      width: 86,
      height: 124,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 27),
          const SizedBox(height: 10),
          Text(
            _story.title.isEmpty ? 'MI HISTORIA' : _story.title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cinzel(
              fontSize: 7.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
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

  Widget _buildStats(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
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
            child: _buildStat(
              context,
              icon: Icons.star_rounded,
              value: _story.rating > 0 ? _story.rating.toStringAsFixed(1) : '—',
              label: 'Valoración',
            ),
          ),
          Expanded(
            child: _buildStat(
              context,
              icon: Icons.public_rounded,
              value: '${_story.publishedChapterCount}',
              label: 'Publicados',
            ),
          ),
          Expanded(
            child: _buildStat(
              context,
              icon: Icons.people_outline_rounded,
              value: '${_story.followers}',
              label: 'Seguidores',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cinzel(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMainActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openNewChapter,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Nuevo capítulo',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _toggleStoryPublication,
            icon: Icon(
              _story.isPublished
                  ? Icons.unpublished_outlined
                  : Icons.upload_rounded,
            ),
            label: Text(
              _story.isPublished ? 'Volver a borrador' : 'Publicar historia',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(BuildContext context) {
    final theme = Theme.of(context);

    final progress = _story.publicationProgress;
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESO DE LA OBRA',
          style: GoogleFonts.cinzel(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_story.publishedChapterCount} de '
                '${_story.chapterCount} capítulos publicados',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        LinearProgressIndicator(
          value: progress,
          minHeight: 7,
          borderRadius: BorderRadius.circular(20),
        ),
      ],
    );
  }

  Widget _buildChapterHeading(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAPÍTULOS',
          style: GoogleFonts.cinzel(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${_story.chapterCount} capítulos • '
          '${_story.publishedChapterCount} publicados • '
          '${_story.draftChapterCount} borradores',
          style: GoogleFonts.inter(
            fontSize: 9,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChapters(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 38,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no has creado capítulos',
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Presiona “+ Nuevo capítulo” para comenzar.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              height: 1.45,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(BuildContext context, WriterChapter chapter) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CAPÍTULO ${chapter.order.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: chapter.isPublished
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  chapter.isPublished ? 'PUBLICADO' : 'BORRADOR',
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            chapter.title.isEmpty ? 'Capítulo sin título' : chapter.title,
            style: GoogleFonts.merriweather(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${chapter.wordCount} palabras',
            style: GoogleFonts.inter(
              fontSize: 8.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _openEditChapter(chapter);
                  },
                  child: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Opciones del capítulo',
                onSelected: (value) {
                  switch (value) {
                    case 'publish':
                      _toggleChapterPublication(chapter);
                      break;

                    case 'delete':
                      _deleteChapter(chapter);
                      break;
                  }
                },
                itemBuilder: (_) {
                  return [
                    PopupMenuItem<String>(
                      value: 'publish',
                      child: Text(
                        chapter.isPublished
                            ? 'Volver a borrador'
                            : 'Publicar capítulo',
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Eliminar capítulo'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
