import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';
import '../../services/writer_local_service.dart';

class ChapterEditorScreen extends StatefulWidget {
  const ChapterEditorScreen({super.key, required this.story, this.chapter});

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

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _chapterId = widget.chapter?.id ?? now.microsecondsSinceEpoch.toString();

    _chapterOrder = widget.chapter?.order ?? widget.story.chapters.length + 1;

    _createdAt = widget.chapter?.createdAt ?? now;

    _titleController = TextEditingController(text: widget.chapter?.title ?? '');

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
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  int get _wordCount {
    final text = _contentController.text.trim();

    if (text.isEmpty) {
      return 0;
    }

    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  int get _characterCount {
    return _contentController.text.length;
  }

  int get _readingMinutes {
    if (_wordCount == 0) {
      return 0;
    }

    return (_wordCount / 200).ceil();
  }

  bool get _canPublish {
    return _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty;
  }

  Future<void> _saveChapter({required bool publish}) async {
    if (_isSaving) {
      return;
    }

    if (publish && !_canPublish) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el título y el contenido antes de publicar.'),
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

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    Navigator.of(context).pop(updatedStory);
  }

  Future<bool> _confirmExit() async {
    final hasChanges =
        _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;

    if (!hasChanges) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Salir del editor',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Si sales sin guardar, los cambios de este capítulo se perderán.',
            style: GoogleFonts.inter(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Seguir escribiendo'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _goBack() async {
    final canExit = await _confirmExit();

    if (!mounted || !canExit) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        await _goBack();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(context),
                const SizedBox(height: 10),
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildStoryInformation(context),
                const SizedBox(height: 26),
                _buildTitleSection(context),
                const SizedBox(height: 24),
                _buildContentSection(context),
                const SizedBox(height: 14),
                _buildWritingStats(context),
                const SizedBox(height: 28),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return TextButton.icon(
      onPressed: _goBack,
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: Text(
        'Administrar capítulos',
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
        Text(
          _isEditing ? 'EDITAR CAPÍTULO' : 'NUEVO CAPÍTULO',
          style: GoogleFonts.cinzel(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'CAPÍTULO ${_chapterOrder.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                widget.chapter?.isPublished == true ? 'PUBLICADO' : 'BORRADOR',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          _isEditing
              ? 'Continúa desarrollando esta parte de tu historia.'
              : 'Comienza una nueva parte de tu historia.',
          style: GoogleFonts.inter(
            fontSize: 11,
            height: 1.45,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryInformation(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.story.genre.isEmpty
                      ? 'Sin género'
                      : widget.story.genre,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
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

  Widget _buildTitleSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAPÍTULO ${_chapterOrder.toString().padLeft(2, '0')} · TÍTULO',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          maxLength: 100,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Ej: La última carta',
            counterText: '${_titleController.text.length}/100',
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTENIDO',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          minLines: 18,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Comienza a escribir tu capítulo...',
            alignLabelWithHint: true,
          ),
          style: GoogleFonts.merriweather(
            fontSize: 13,
            height: 1.75,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildWritingStats(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStat(
              context,
              value: '$_wordCount',
              label: 'palabras',
              icon: Icons.notes_rounded,
            ),
          ),
          Expanded(
            child: _buildStat(
              context,
              value: '$_characterCount',
              label: 'caracteres',
              icon: Icons.text_fields_rounded,
            ),
          ),
          Expanded(
            child: _buildStat(
              context,
              value: '$_readingMinutes',
              label: 'min de lectura',
              icon: Icons.schedule_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 17, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 7.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
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
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.public_rounded),
            label: Text(
              'Publicar capítulo',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSaving
                ? null
                : () {
                    _saveChapter(publish: false);
                  },
            icon: const Icon(Icons.save_outlined),
            label: Text(
              'Guardar borrador',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
