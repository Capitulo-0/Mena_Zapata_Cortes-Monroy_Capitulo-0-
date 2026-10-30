import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';
import '../../services/writer_local_service.dart';

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

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: _goBack,
      icon: const Icon(Icons.arrow_back_rounded, size: 15),
      label: Text(
        'Administrar capítulos',
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 8.8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.65,
            color: AppColors.accent,
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

  Widget _buildHeader() {
    final isPublished = widget.chapter?.isPublished == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _isEditing
                    ? 'CAPÍTULO ${_chapterOrder.toString().padLeft(2, '0')}'
                    : 'CAPÍTULO ${_chapterOrder.toString().padLeft(2, '0')}',
                style: GoogleFonts.merriweather(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _headingColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusPill(isPublished),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          _isEditing
              ? 'Continúa desarrollando esta parte de tu historia.'
              : 'Comienza una nueva parte de tu historia.',
          style: GoogleFonts.inter(
            fontSize: 8.5,
            height: 1.45,
            color: _textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(bool published) {
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
              : AppColors.gold.withValues(alpha: 0.40),
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
            published ? 'PUBLICADO' : 'BORRADOR',
            style: GoogleFonts.inter(
              fontSize: 5.7,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.25,
              color: published ? AppColors.accent : AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _isDarkMode ? 0.10 : 0.035,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _coverColors(widget.story.coverPath),
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.story.title.isEmpty
                      ? 'Historia sin título'
                      : widget.story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.story.genre.isEmpty
                      ? 'Sin género'
                      : widget.story.genre,
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '${widget.story.chapterCount} capítulos',
                      style: GoogleFonts.inter(
                        fontSize: 6.5,
                        color: _textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '·',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Capítulo ${_chapterOrder.toString().padLeft(2, '0')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 6.5,
                          color: _textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAPÍTULO ${_chapterOrder.toString().padLeft(2, '0')} · TÍTULO',
          style: _fieldLabelStyle(),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _titleController,
          maxLength: 100,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.merriweather(
            fontSize: 10.5,
            color: _textPrimaryColor,
          ),
          decoration: _inputDecoration(
            hintText: 'Ej: La última carta',
            counterText: '${_titleController.text.length} / 100',
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTENIDO',
          style: _fieldLabelStyle(),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _contentController,
          minLines: 16,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.merriweather(
            fontSize: 10.5,
            height: 1.65,
            color: _textPrimaryColor,
          ),
          decoration: _inputDecoration(
            hintText: 'Comienza a escribir tu capítulo...',
            counterText: '',
          ).copyWith(
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
          ),
        ),
      ],
    );
  }

  TextStyle _fieldLabelStyle() {
    return GoogleFonts.inter(
      fontSize: 8,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.45,
      color: _textSecondaryColor,
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required String counterText,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: counterText,
      filled: true,
      fillColor: _surfaceColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      hintStyle: GoogleFonts.merriweather(
        fontSize: 9.5,
        color: _textSecondaryColor,
      ),
      counterStyle: GoogleFonts.inter(
        fontSize: 6.5,
        color: _textSecondaryColor,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.gold.withValues(alpha: 0.42),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.gold,
          width: 1.1,
        ),
      ),
    );
  }

  Widget _buildCompactStats() {
    return Row(
      children: [
        _compactStat(
          icon: Icons.notes_rounded,
          value: '$_wordCount palabras',
        ),
        _compactDot(),
        _compactStat(
          icon: Icons.text_fields_rounded,
          value: '$_characterCount caracteres',
        ),
        _compactDot(),
        _compactStat(
          icon: Icons.schedule_rounded,
          value: '$_readingMinutes min de lectura',
        ),
      ],
    );
  }

  Widget _compactStat({
    required IconData icon,
    required String value,
  }) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 9,
            color: AppColors.gold,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 6.2,
                color: _textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        '·',
        style: GoogleFonts.inter(
          fontSize: 7,
          color: AppColors.gold,
        ),
      ),
    );
  }

  Widget _buildPendingStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: _titleController.text.trim().isEmpty &&
                      _contentController.text.trim().isEmpty
                  ? AppColors.gold.withValues(alpha: 0.30)
                  : AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _titleController.text.trim().isEmpty &&
                    _contentController.text.trim().isEmpty
                ? 'Sin cambios pendientes'
                : 'Cambios pendientes',
            style: GoogleFonts.inter(
              fontSize: 6.8,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChapterPreview() async {
    if (!_canPublish) return;

    FocusScope.of(context).unfocus();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ChapterPreviewScreen(
          storyTitle: widget.story.title,
          chapterNumber: _chapterOrder,
          chapterTitle: _titleController.text.trim(),
          content: _contentController.text.trim(),
          readingMinutes: _readingMinutes,
          wordCount: _wordCount,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }

  Widget _buildPreviewButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _canPublish ? _openChapterPreview : null,
        icon: const Icon(Icons.visibility_outlined, size: 12),
        label: Text(
          'Vista previa',
          style: GoogleFonts.inter(
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _headingColor,
          disabledForegroundColor:
              _textSecondaryColor.withValues(alpha: 0.45),
          side: BorderSide(
            color: _canPublish
                ? AppColors.gold.withValues(alpha: 0.45)
                : AppColors.gold.withValues(alpha: 0.16),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSaving || !_canPublish
                ? null
                : () {
                    _saveChapter(publish: true);
                  },
            icon: _isSaving
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_upward_rounded, size: 13),
            label: Text(
              'Publicar capítulo',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor:
                  AppColors.accent.withValues(alpha: 0.23),
              foregroundColor: AppColors.background,
              disabledForegroundColor:
                  AppColors.background.withValues(alpha: 0.90),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        OutlinedButton.icon(
          onPressed: _isSaving
              ? null
              : () {
                  _saveChapter(publish: false);
                },
          icon: const Icon(Icons.save_outlined, size: 12),
          label: Text(
            'Guardar como borrador',
            style: GoogleFonts.inter(
              fontSize: 7.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _textSecondaryColor,
            side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
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
    );
  }
}

class _ChapterPreviewScreen extends StatelessWidget {
  const _ChapterPreviewScreen({
    required this.storyTitle,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.content,
    required this.readingMinutes,
    required this.wordCount,
    required this.isDarkMode,
  });

  final String storyTitle;
  final int chapterNumber;
  final String chapterTitle;
  final String content;
  final int readingMinutes;
  final int wordCount;
  final bool isDarkMode;

  Color get _backgroundColor =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;

  Color get _surfaceColor =>
      isDarkMode ? AppColors.darkSurface : AppColors.surface;

  Color get _textPrimaryColor =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get _textSecondaryColor =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get _headingColor =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.deep;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(34, 34),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VISTA PREVIA',
                          style: GoogleFonts.cinzel(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: _headingColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Así verá este capítulo el lector.',
                          style: GoogleFonts.inter(
                            fontSize: 7.5,
                            color: _textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      'BORRADOR',
                      style: GoogleFonts.inter(
                        fontSize: 5.8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.20),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 48),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 620),
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDarkMode ? 0.12 : 0.04,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storyTitle.isEmpty
                              ? 'Historia sin título'
                              : storyTitle.toUpperCase(),
                          style: GoogleFonts.cinzel(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'CAPÍTULO ${chapterNumber.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: _textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          chapterTitle,
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: _textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$readingMinutes min de lectura',
                              style: GoogleFonts.inter(
                                fontSize: 7,
                                color: _textSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '·',
                              style: GoogleFonts.inter(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '$wordCount palabras',
                              style: GoogleFonts.inter(
                                fontSize: 7,
                                color: _textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          height: 1,
                          width: 54,
                          color: AppColors.gold.withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 20),
                        SelectableText(
                          content,
                          style: GoogleFonts.merriweather(
                            fontSize: 11,
                            height: 1.8,
                            color: _textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

