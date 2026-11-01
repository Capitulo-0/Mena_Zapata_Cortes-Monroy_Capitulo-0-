import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/chapter_preview_screen.dart';
import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';
import '../../services/writer_local_service.dart';


part '../widgets/chapter_editor_header_section.dart';
part '../widgets/chapter_editor_story_info.dart';
part '../widgets/chapter_editor_fields_section.dart';
part '../widgets/chapter_editor_stats_status.dart';
part '../widgets/chapter_editor_preview_actions.dart';

class ChapterEditorScreen extends StatefulWidget {
  const ChapterEditorScreen({
    super.key,
    required this.story,
    this.chapter,
  });

  final WriterStory story;
  final WriterChapter? chapter;

  @override
  State<ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends State<ChapterEditorScreen> {
  final WriterLocalService _writerService = WriterLocalService();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  late final String _chapterId;
  late final int _chapterOrder;
  late final DateTime _createdAt;

  bool _isSaving = false;

  bool get _isEditing => widget.chapter != null;

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

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _chapterId = widget.chapter?.id ?? now.microsecondsSinceEpoch.toString();
    _chapterOrder =
        widget.chapter?.order ?? widget.story.chapters.length + 1;
    _createdAt = widget.chapter?.createdAt ?? now;

    _titleController = TextEditingController(
      text: widget.chapter?.title ?? '',
    );

    _contentController = TextEditingController(
      text: widget.chapter?.content ?? '',
    );

    _titleController.addListener(_refresh);
    _contentController.addListener(_refresh);
  }

  @override
  void dispose() {
    _titleController.removeListener(_refresh);
    _contentController.removeListener(_refresh);

    _titleController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  int get _wordCount {
    final text = _contentController.text.trim();

    if (text.isEmpty) return 0;

    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  int get _characterCount => _contentController.text.length;

  int get _readingMinutes {
    if (_wordCount == 0) return 0;
    return (_wordCount / 200).ceil();
  }

  bool get _canPublish {
    return _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty;
  }

  Future<void> _saveChapter({required bool publish}) async {
    if (_isSaving) return;

    if (publish && !_canPublish) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa el título y el contenido antes de publicar.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final latestStory =
        await _writerService.getStoryById(widget.story.id) ?? widget.story;

    final now = DateTime.now();

    final chapter = WriterChapter(
      id: _chapterId,
      title: _titleController.text.trim(),
      content: _contentController.text,
      order: _chapterOrder,
      isPublished: publish,
      createdAt: _createdAt,
      updatedAt: now,
    );

    final updatedChapters = [...latestStory.chapters];

    final existingIndex = updatedChapters.indexWhere(
      (existingChapter) => existingChapter.id == _chapterId,
    );

    if (existingIndex == -1) {
      updatedChapters.add(chapter);
    } else {
      updatedChapters[existingIndex] = chapter;
    }

    updatedChapters.sort((a, b) => a.order.compareTo(b.order));

    final updatedStory = latestStory.copyWith(
      chapters: updatedChapters,
      updatedAt: now,
    );

    await _writerService.updateStory(updatedStory);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    Navigator.of(context).pop(updatedStory);
  }

  Future<bool> _confirmExit() async {
    final hasChanges =
        _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;

    if (!hasChanges) return true;

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
                color: AppColors.gold.withValues(alpha: 0.34),
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
                      color: AppColors.accent.withValues(alpha: 0.20),
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.accent,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  '¿SALIR DEL EDITOR?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _headingColor,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Si sales ahora, los cambios que aún no hayas guardado en este capítulo se perderán.',
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
                            'Seguir editando',
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
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Salir',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
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

    return confirmed ?? false;
  }

  Future<void> _goBack() async {
    final canExit = await _confirmExit();

    if (!mounted || !canExit) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _goBack();
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(),
                const SizedBox(height: 10),
                _buildSectionTitle('NUEVO CAPÍTULO'),
                const SizedBox(height: 10),
                _buildHeader(),
                const SizedBox(height: 14),
                _buildStoryInformation(),
                const SizedBox(height: 22),
                _buildTitleSection(),
                const SizedBox(height: 18),
                _buildContentSection(),
                const SizedBox(height: 8),
                _buildCompactStats(),
                const SizedBox(height: 10),
                _buildPendingStatus(),
                const SizedBox(height: 10),
                _buildPreviewButton(),
                const SizedBox(height: 14),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
