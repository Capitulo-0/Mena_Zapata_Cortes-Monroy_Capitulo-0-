import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';
import '../../services/writer_local_service.dart';
import 'chapter_editor_screen.dart';
import 'create_story_screen.dart';
import 'published_story_screen.dart';

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
    _story = widget.story;
    _refreshStory();
  }

  Future<void> _refreshStory() async {
    final storedStory = await _writerService.getStoryById(_story.id);

    if (!mounted || storedStory == null) return;

    setState(() {
      _story = storedStory;
    });
  }

  Future<void> _saveStory(WriterStory updatedStory) async {
    await _writerService.updateStory(updatedStory);

    if (!mounted) return;

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

  void _openPublishedView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishedStoryScreen(story: _story),
      ),
    );
  }

  Future<void> _toggleStoryPublication() async {
    if (_isLoading) return;

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

    if (!mounted) return;

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

  Future<void> _deleteStory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.24),
            ),
          ),
          title: Text(
            'ELIMINAR HISTORIA',
            style: GoogleFonts.cinzel(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _headingColor,
            ),
          ),
          content: Text(
            '¿Quieres eliminar "${_story.title}"? Esta acción no se puede deshacer.',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              height: 1.5,
              color: _textSecondaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline_rounded, size: 15),
              label: const Text('Eliminar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _writerService.deleteStory(_story.id);

    if (!mounted) return;

    Navigator.of(context).pop(_story);
  }

  Future<void> _toggleChapterPublication(WriterChapter chapter) async {
    final updatedChapters = _story.chapters.map((currentChapter) {
      if (currentChapter.id != chapter.id) return currentChapter;

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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final updatedChapters = _story.chapters
        .where((currentChapter) => currentChapter.id != chapter.id)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final reorderedChapters = <WriterChapter>[];

    for (var index = 0; index < updatedChapters.length; index++) {
      reorderedChapters.add(
        updatedChapters[index].copyWith(order: index + 1),
      );
    }

    final updatedStory = _story.copyWith(
      chapters: reorderedChapters,
      updatedAt: DateTime.now(),
    );

    await _saveStory(updatedStory);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Capítulo eliminado.')));
  }

  Future<void> _openNewChapter() async {
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(builder: (_) => ChapterEditorScreen(story: _story)),
    );

    if (result == null || !mounted) return;

    setState(() {
      _story = result;
    });
  }

  Future<void> _openEditChapter(WriterChapter chapter) async {
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(
        builder: (_) => ChapterEditorScreen(
          story: _story,
          chapter: chapter,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _story = result;
    });
  }

  String _formatDate(DateTime date) {
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
    final chapters = [..._story.chapters]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshStory,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(),
                const SizedBox(height: 10),
                _buildSectionTitle('GESTIÓN DE OBRA'),
                const SizedBox(height: 10),
                _buildHeader(),
                const SizedBox(height: 14),
                _buildStoryCard(),
                const SizedBox(height: 12),
                _buildStats(),
                const SizedBox(height: 14),
                _buildMainActions(),
                const SizedBox(height: 20),
                _buildSectionTitle('PROGRESO DE LA OBRA'),
                const SizedBox(height: 10),
                _buildProgress(),
                const SizedBox(height: 20),
                _buildChapterHeading(),
                const SizedBox(height: 10),
                if (chapters.isEmpty)
                  _buildEmptyChapters()
                else
                  ...chapters.map(
                    (chapter) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildChapterCard(chapter),
                    ),
                  ),
                const SizedBox(height: 10),
                _buildStoryManagement(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pop(_story),
      icon: const Icon(Icons.arrow_back_rounded, size: 15),
      label: Text(
        'Mis historias',
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
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'ADMINISTRAR HISTORIA',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.55,
                  color: _headingColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Organiza capítulos y controla la publicación de tu obra.',
          style: GoogleFonts.inter(
            fontSize: 8.5,
            height: 1.45,
            color: _textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 8.8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.65,
            color: _headingColor,
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

  Widget _buildStatusBadge() {
    final published = _story.isPublished;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: published
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: published
              ? AppColors.accent.withValues(alpha: 0.30)
              : AppColors.gold.withValues(alpha: 0.38),
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
              fontSize: 5.6,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.25,
              color: published ? AppColors.accent : AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.12 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCover(),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _story.title.isEmpty ? 'Historia sin título' : _story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: _textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _story.genre.isEmpty ? 'Sin género' : _story.genre,
                  style: GoogleFonts.inter(
                    fontSize: 7.5,
                    color: _textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.gold,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_story.chapterCount} '
                      '${_story.chapterCount == 1 ? 'capítulo' : 'capítulos'}',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        color: _textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.gold,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Última edición · ${_formatDate(_story.updatedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 6.8,
                          color: _textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _editStory,
                  icon: const Icon(Icons.edit_outlined, size: 12),
                  label: Text(
                    'Editar historia',
                    style: GoogleFonts.inter(
                      fontSize: 7.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _headingColor,
                    side: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.55),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildCover() {
    return Container(
      width: 76,
      height: 106,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _coverColors(_story.coverPath),
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 23,
          ),
          const SizedBox(height: 8),
          Text(
            _story.title.isEmpty ? 'MI HISTORIA' : _story.title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cinzel(
              fontSize: 6.4,
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

  Widget _buildStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.22),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _inlineStat(
            icon: Icons.star_rounded,
            value:
                _story.rating > 0 ? _story.rating.toStringAsFixed(1) : '—',
          ),
          _statDot(),
          _inlineStat(
            icon: Icons.public_rounded,
            value: '${_story.publishedChapterCount} publicados',
          ),
          _statDot(),
          _inlineStat(
            icon: Icons.people_outline_rounded,
            value: '${_story.followers} seguidores',
          ),
        ],
      ),
    );
  }

  Widget _inlineStat({
    required IconData icon,
    required String value,
  }) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.gold),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 6.7,
                color: _textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Text(
        '·',
        style: GoogleFonts.inter(
          fontSize: 8,
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openNewChapter,
            icon: const Icon(Icons.add_rounded, size: 15),
            label: Text(
              'Nuevo capítulo',
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : (_story.isPublished
                    ? _openPublishedView
                    : _toggleStoryPublication),
            icon: Icon(
              _story.isPublished
                  ? Icons.visibility_outlined
                  : Icons.upload_rounded,
              size: 13,
            ),
            label: Text(
              _story.isPublished ? 'Vista publicada' : 'Publicar historia',
              style: GoogleFonts.inter(
                fontSize: 7.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _headingColor,
              side: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.45),
              ),
              padding: const EdgeInsets.symmetric(vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('OPCIONES DE LA OBRA'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            children: [
              if (_story.isPublished) ...[
                _managementAction(
                  icon: Icons.unpublished_outlined,
                  label: 'Volver a borrador',
                  description:
                      'La obra dejará de mostrarse como publicación activa.',
                  onTap: _isLoading ? null : _toggleStoryPublication,
                ),
                Divider(
                  height: 17,
                  color: AppColors.gold.withValues(alpha: 0.14),
                ),
              ],
              _managementAction(
                icon: Icons.delete_outline_rounded,
                label: 'Eliminar historia',
                description: 'Elimina la obra y sus capítulos guardados.',
                destructive: true,
                onTap: _deleteStory,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _managementAction({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback? onTap,
    bool destructive = false,
  }) {
    final actionColor = destructive ? AppColors.accent : _headingColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 7,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: destructive
                    ? AppColors.accent.withValues(alpha: 0.08)
                    : AppColors.gold.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 16,
                color: destructive ? AppColors.accent : AppColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 8.2,
                      fontWeight: FontWeight.w700,
                      color: actionColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 6.6,
                      height: 1.35,
                      color: _textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: _textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final progress = _story.publicationProgress;
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_story.publishedChapterCount} de '
                '${_story.chapterCount} capítulos publicados',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  color: _textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: GoogleFonts.inter(
                fontSize: 7.5,
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.gold.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CAPÍTULOS'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_story.chapterCount} capítulos · '
                '${_story.publishedChapterCount} publicados · '
                '${_story.draftChapterCount} '
                '${_story.draftChapterCount == 1 ? 'borrador' : 'borradores'}',
                style: GoogleFonts.inter(
                  fontSize: 6.8,
                  color: _textSecondaryColor,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.swap_vert_rounded, size: 11),
              label: Text(
                'Ordenar',
                style: GoogleFonts.inter(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyChapters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 31,
            color: AppColors.accent,
          ),
          const SizedBox(height: 10),
          Text(
            'Aún no has creado capítulos',
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textPrimaryColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Presiona “+ Nuevo capítulo” para comenzar.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 7.5,
              height: 1.45,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(WriterChapter chapter) {
    final published = chapter.isPublished;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: published
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.gold.withValues(alpha: 0.28),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: published
                    ? AppColors.accent
                    : AppColors.gold.withValues(alpha: 0.75),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(13),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 9, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _deepColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.40),
                            ),
                          ),
                          alignment: Alignment.center,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.merriweather(
                                  fontSize: 9.8,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: published
                                          ? AppColors.accent
                                          : AppColors.gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    published ? 'PUBLICADO' : 'BORRADOR',
                                    style: GoogleFonts.inter(
                                      fontSize: 5.8,
                                      fontWeight: FontWeight.w800,
                                      color: published
                                          ? AppColors.accent
                                          : AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 39),
                      child: Row(
                        children: [
                          Icon(
                            published
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.remove_rounded,
                            size: 9,
                            color: published
                                ? const Color(0xFFB9A4D8)
                                : AppColors.gold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            published
                                ? '${chapter.wordCount} palabras'
                                : 'Sin publicar',
                            style: GoogleFonts.inter(
                              fontSize: 6.5,
                              color: _textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Divider(
                      height: 1,
                      color: AppColors.gold.withValues(alpha: 0.14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _openEditChapter(chapter),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _headingColor,
                            side: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.40),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Editar',
                                style: GoogleFonts.inter(
                                  fontSize: 6.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 11,
                              ),
                            ],
                          ),
                        ),
                        if (!published) ...[
                          const SizedBox(width: 6),
                          FilledButton.icon(
                            onPressed: () =>
                                _toggleChapterPublication(chapter),
                            icon: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 10,
                            ),
                            label: Text(
                              'Publicar',
                              style: GoogleFonts.inter(
                                fontSize: 6.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 3),
                        PopupMenuButton<String>(
                          tooltip: 'Opciones del capítulo',
                          color: _surfaceColor,
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
                          itemBuilder: (_) => [
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
                          ],
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 15,
                              color: _textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
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
