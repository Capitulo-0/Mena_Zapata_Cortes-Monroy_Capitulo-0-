import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';
import '../../services/writer_local_service.dart';
import 'chapter_editor_screen.dart';
import 'create_story_screen.dart';
import 'published_story_screen.dart';


part '../widgets/manage_story_header_summary.dart';
part '../widgets/manage_story_stats_actions.dart';
part '../widgets/manage_story_management_section.dart';
part '../widgets/manage_story_progress_section.dart';
part '../widgets/manage_story_chapters_section.dart';

class ManageStoryScreen extends StatefulWidget {
  const ManageStoryScreen({
    super.key,
    required this.story,
    required this.currentUsername,
  });

  final WriterStory story;
  final String currentUsername;

  @override
  State<ManageStoryScreen> createState() => _ManageStoryScreenState();
}

class _ManageStoryScreenState extends State<ManageStoryScreen> {
  final WriterLocalService _writerService = WriterLocalService();

  late WriterStory _story;
  bool _isLoading = false;
  bool _isPublishingStory = false;
  bool _isDeletingStory = false;

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
        builder: (_) => PublishedStoryScreen(
          story: _story,
          currentUsername: widget.currentUsername,
        ),
      ),
    );
  }

  Future<void> _toggleStoryPublication() async {
    if (_isLoading) return;

    final wasPublished = _story.isPublished;

    setState(() {
      _isLoading = true;
      _isPublishingStory = !wasPublished;
    });

    // Simulación visual de escritura en backend.
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final updatedStory = _story.copyWith(
      status: wasPublished
          ? WriterStoryStatus.draft
          : WriterStoryStatus.published,
      updatedAt: DateTime.now(),
    );

    await _writerService.updateStory(updatedStory);

    if (!mounted) return;

    setState(() {
      _story = updatedStory;
      _isLoading = false;
      _isPublishingStory = false;
    });

    if (!wasPublished) {
      _showPublicationSuccessMessage('Historia publicada correctamente');
      return;
    }

    _showPublicationSuccessMessage('Historia volvió a borrador');
  }

  void _showPublicationSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          duration: const Duration(milliseconds: 2500),
          padding: EdgeInsets.zero,
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF283125)
                  : const Color(0xFFF4F7EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF78935F).withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFF708A56),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.merriweather(
                      color: _isDarkMode
                          ? const Color(0xFFE7EEDC)
                          : const Color(0xFF3F4F33),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.gold.withValues(alpha: 0.76),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
  }

  Future<void> _deleteStory() async {
    if (_isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  '¿ELIMINAR HISTORIA?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _headingColor,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Esta historia y todos sus capítulos se eliminarán de forma permanente. Esta acción no se puede deshacer.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    height: 1.5,
                    color: _textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _headingColor,
                            side: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.42),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 15,
                          ),
                          label: Text(
                            'Eliminar',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _isDeletingStory = true;
    });

    // Simulación visual de eliminación en backend.
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    await _writerService.deleteStory(_story.id);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isDeletingStory = false;
    });

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
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: ColorFiltered(
          colorFilter: _isLoading
              ? const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ])
              : const ColorFilter.mode(
                  Colors.transparent,
                  BlendMode.dst,
                ),
          child: SafeArea(
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
        ),
      ),
    );
  }

}
