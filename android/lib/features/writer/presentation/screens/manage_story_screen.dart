import '../widgets/writer_cover.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';
import '../../services/writer_repository.dart';
import '../../services/writer_draft_store.dart';
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
    this.repository,
    this.ownerUid,
    required this.story,
    required this.currentUsername,
  });

  final WriterStory story;
  final String currentUsername;

  final WriterRepository? repository;
  final String? ownerUid;

  @override
  State<ManageStoryScreen> createState() => _ManageStoryScreenState();
}

class _ManageStoryScreenState extends State<ManageStoryScreen> {
  late final WriterRepository _writerService =
      widget.repository ?? const UnavailableWriterRepository();

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

  void _showError(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(writerError(error))));
    }
  }

  Future<void> _refreshStory() async {
    try {
      final stored = await _writerService.getStoryById(_story.id);
      if (mounted && stored != null && stored.revision >= _story.revision) {
        setState(() => _story = stored);
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<bool> _saveStory(WriterStory updated) async {
    if (_isLoading) return false;
    if (updated.isPublished &&
        (updated.chapters.isEmpty ||
            updated.chapters.any(
              (c) => c.title.trim().isEmpty || c.content.trim().isEmpty,
            ))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Retira la historia antes de eliminar el último capítulo o guardar contenido incompleto.',
          ),
        ),
      );
      return false;
    }
    setState(() => _isLoading = true);
    try {
      final saved = await _writerService.save(updated);
      if (mounted) setState(() => _story = saved);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editStory() async {
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(
        builder: (_) =>
            CreateStoryScreen(story: _story, repository: _writerService),
      ),
    );

    if (result != null && mounted) {
      setState(() => _story = result);
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
    final publishing = !_story.isPublished;
    if (publishing &&
        (_story.chapters.isEmpty ||
            _story.chapters.any(
              (c) => c.title.trim().isEmpty || c.content.trim().isEmpty,
            ))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa al menos un capitulo y todos los capitulos antes de publicar.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialog) {
        final isDark = Theme.of(dialog).brightness == Brightness.dark;
        final surface = isDark ? AppColors.darkSurface : AppColors.surface;
        final heading = isDark ? AppColors.darkTextPrimary : AppColors.deep;
        final textPrimary = isDark
            ? AppColors.darkTextPrimary
            : AppColors.textPrimary;
        final textSecondary = isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary;
        final accent = isDark ? AppColors.darkAccent : AppColors.accent;

        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: publishing
                            ? AppColors.accent.withValues(alpha: 0.14)
                            : AppColors.gold.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        publishing
                            ? Icons.auto_stories_rounded
                            : Icons.edit_note_rounded,
                        color: publishing ? accent : AppColors.deepOf(context),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            publishing
                                ? 'Publicar historia'
                                : 'Volver a borrador',
                            style: GoogleFonts.merriweather(
                              fontSize: 24,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: heading,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            publishing
                                ? 'Tu obra quedará lista para ser leída por otros usuarios.'
                                : 'La obra dejará de estar visible para otros lectores.',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              height: 1.35,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOf(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Qué ocurrirá ahora?',
                        style: GoogleFonts.cinzel(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: heading,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        publishing
                            ? '• Se publicarán todos los capítulos completos.\n'
                                  '• Los lectores autenticados podrán encontrar tu obra en la comunidad.\n'
                                  '• Siempre podrás volverla a borrador más adelante.'
                            : '• La historia saldrá de la comunidad de lectura.\n'
                                  '• Los lectores dejarán de verla como publicada.\n'
                                  '• Tus capítulos seguirán guardados en tu cuenta.',
                        style: GoogleFonts.inter(
                          fontSize: 12.8,
                          height: 1.45,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialog, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          side: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.8),
                          ),
                          foregroundColor: heading,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('writer-confirm-publication'),
                        onPressed: () => Navigator.pop(dialog, true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          publishing ? 'Publicar' : 'Volver a borrador',
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
      _isPublishingStory = publishing;
    });
    try {
      final saved = await _writerService.setPublished(_story, publishing);
      if (!mounted) return;
      setState(() => _story = saved);
      _showPublicationSuccessMessage(
        publishing
            ? 'Historia publicada en tu cuenta'
            : 'Historia guardada como borrador',
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPublishingStory = false;
        });
      }
    }
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

    try {
      await _writerService.remove(_story);
      if (mounted) Navigator.of(context).pop(_story);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDeletingStory = false;
        });
      }
    }
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

    final updatedChapters =
        _story.chapters
            .where((currentChapter) => currentChapter.id != chapter.id)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final reorderedChapters = <WriterChapter>[];

    for (var index = 0; index < updatedChapters.length; index++) {
      reorderedChapters.add(updatedChapters[index].copyWith(order: index + 1));
    }

    final updatedStory = _story.copyWith(
      chapters: reorderedChapters,
      updatedAt: DateTime.now(),
    );

    final saved = await _saveStory(updatedStory);

    if (!mounted || !saved) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Capítulo eliminado.')));
  }

  WriterDraftStore? _draftFor(WriterChapter? chapter) => widget.ownerUid == null
      ? null
      : WriterDraftStore(
          ownerUid: widget.ownerUid!,
          storyId: _story.id,
          chapterId: chapter?.id,
        );

  Future<void> _openNewChapter() async {
    final result = await Navigator.of(context).push<WriterStory>(
      MaterialPageRoute(
        builder: (_) => ChapterEditorScreen(
          story: _story,
          repository: _writerService,
          draftStore: _draftFor(null),
        ),
      ),
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
          draftStore: _draftFor(chapter),
          repository: _writerService,
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
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ])
              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
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
