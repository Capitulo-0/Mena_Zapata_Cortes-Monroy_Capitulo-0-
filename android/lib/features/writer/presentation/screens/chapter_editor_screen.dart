import '../widgets/writer_cover.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/session/local_account_scope.dart';
import '../../services/writer_draft_store.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/chapter_preview_screen.dart';
import '../../models/writer_chapter.dart';
import '../../models/writer_story.dart';
import '../../services/writer_repository.dart';
import '../../services/literary_chat.dart';
import '../widgets/literary_chat_screen.dart';

part '../widgets/chapter_editor_header_section.dart';
part '../widgets/chapter_editor_story_info.dart';
part '../widgets/chapter_editor_fields_section.dart';
part '../widgets/chapter_editor_stats_status.dart';
part '../widgets/chapter_editor_preview_actions.dart';

class ChapterEditorScreen extends StatefulWidget {
  const ChapterEditorScreen({
    super.key,
    this.repository,
    required this.story,
    this.chapter,
    this.draftStore,
  });

  final WriterStory story;
  final WriterChapter? chapter;
  final WriterDraftStore? draftStore;

  final WriterRepository? repository;

  @override
  State<ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends State<ChapterEditorScreen> {
  late final WriterRepository _writerService =
      widget.repository ?? const UnavailableWriterRepository();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  late String _chapterId;
  late int _chapterOrder;
  late final DateTime _createdAt;

  late int _baseRevision = widget.story.revision;
  bool _isSaving = false;
  bool _restoring = true,
      _choosingDraft = false,
      _restored = false,
      _draftConflict = false;
  String? _localError;
  WriterDraftStore? _draftStore;
  bool get _hasChanges =>
      _restored ||
      _titleController.text != (widget.chapter?.title ?? '') ||
      _contentController.text != (widget.chapter?.content ?? '');

  Future<void> _recoverDraft() async {
    final uid = LocalAccountScope.read(context);
    _draftStore =
        widget.draftStore ??
        (uid == null
            ? null
            : WriterDraftStore(
                ownerUid: uid,
                storyId: widget.story.id,
                chapterId: widget.chapter?.id,
              ));
    try {
      final draft = await _draftStore?.load();
      if (!mounted || draft == null) return;
      setState(() => _choosingDraft = true);
      final restore = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialog) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Edición local pendiente'),
            content: const Text(
              'Hay texto que no se confirmó en el servidor. Puedes recuperarlo para revisarlo. No se enviará automáticamente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Usar versión guardada'),
              ),
              FilledButton(
                key: const ValueKey('writer-restore-draft'),
                onPressed: () => Navigator.pop(dialog, true),
                child: const Text('Recuperar texto'),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      if (restore == true) {
        _titleController.text = draft['title'] as String;
        _contentController.text = draft['content'] as String;
        _chapterId = draft['chapterId'] as String;
        _chapterOrder = draft['order'] as int;
        _restored = true;
        _baseRevision = draft['revision'] as int;
        _draftConflict = _baseRevision != widget.story.revision;
      } else if (restore == false) {
        await _draftStore?.clear();
      }
    } catch (_) {
      _localError = 'No se pudo recuperar la copia local. Los datos guardados en el servidor siguen disponibles.';
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _persistDraft() async {
    if (_restoring || _draftStore == null) return;
    try {
      if (!_hasChanges) {
        await _draftStore!.clear();
        return;
      }
      await _draftStore!.save({
        'title': _titleController.text,
        'content': _contentController.text,
        'revision': _baseRevision,
        'chapterId': _chapterId,
        'order': _chapterOrder,
      });
      if (mounted) setState(() => _localError = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => _localError = 'No se pudo guardar la copia local. Guarda en tu cuenta antes de salir.',
        );
      }
    }
  }

  Widget _recoveryNotice() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.story.isPublished)
        const Text(
          'Historia publicada: los cambios completos se publican al guardar. Retírala primero para trabajar con capítulos incompletos.',
        ),
      if (_restored)
        Text(
          _draftConflict
              ? 'Copia local de una revisión anterior. El guardado está bloqueado para proteger la versión del servidor. Copia tu texto y vuelve a abrir el capítulo para combinarlo.'
              : 'Texto recuperado de este dispositivo, pendiente de guardar en tu cuenta.',
          key: const ValueKey('writer-draft-notice'),
        ),
      if (_draftConflict)
        TextButton(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(
                text: '${_titleController.text}\n\n${_contentController.text}',
              ),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Texto copiado. La copia local se conserva hasta que elijas usar la versión guardada.',
                  ),
                ),
              );
            }
          },
          child: const Text('Copiar texto recuperado'),
        ),
      if (_localError != null) Text(_localError!),
    ],
  );

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
    _chapterOrder = widget.chapter?.order ?? widget.story.chapters.length + 1;
    _createdAt = widget.chapter?.createdAt ?? now;

    _titleController = TextEditingController(text: widget.chapter?.title ?? '');

    _contentController = TextEditingController(
      text: widget.chapter?.content ?? '',
    );

    _titleController.addListener(_refresh);
    _contentController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverDraft());
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
    _persistDraft();
  }

  int get _wordCount {
    final text = _contentController.text.trim();

    if (text.isEmpty) return 0;

    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
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

  Future<void> _saveChapter() async {
    if (_restoring || _draftConflict) return;
    if (_isSaving) return;

    if (widget.story.isPublished && !_canPublish) {
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

    try {
      final latestStory = widget.story;
      final now = DateTime.now();

      final chapter = WriterChapter(
        id: _chapterId,
        title: _titleController.text.trim(),
        content: _contentController.text,
        order: _chapterOrder,
        isPublished: widget.story.isPublished,
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

      final saved = await _writerService.save(updatedStory);
      try {
        await _draftStore?.clear();
      } catch (_) {
        /* Recovery copy can safely remain. */
      }
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(writerError(error))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmExit() async {
    if (_isSaving) return false;
    final hasChanges = _hasChanges;

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
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.34)),
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
                  'Los cambios aún no están guardados en tu cuenta. La recuperación local queda solo en este dispositivo cuando está disponible.',
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

  ({String before, String inserted})? _assistantInsertion;

  bool get _canUndoAssistantInsertion {
    final insertion = _assistantInsertion;
    return insertion != null &&
        _contentController.text.startsWith(
          insertion.before + insertion.inserted,
        );
  }

  void _undoAssistantInsertion() {
    final insertion = _assistantInsertion;
    if (insertion == null || !_canUndoAssistantInsertion) return;
    final start = insertion.before.length;
    final text = _contentController.text.replaceRange(
      start,
      start + insertion.inserted.length,
      '',
    );
    _assistantInsertion = null;
    _contentController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start),
    );
  }

  Future<void> _openAssistant(LiteraryChatRepository repository) async {
    final before = _contentController.text;
    final selection = _contentController.selection;
    final excerpt = selection.isValid && !selection.isCollapsed
        ? selection.textInside(before)
        : before;
    final suggestion = await LiteraryChatScreen.open(
      context,
      LiteraryChatScreen(
        repository: repository,
        editor: ChatEditor.chapter,
        genre: widget.story.genre,
        excerpt: excerpt.length <= 4000 ? excerpt : '',
      ),
    );
    if (!mounted ||
        suggestion == null ||
        _isSaving ||
        _contentController.text != before ||
        suggestion.action != 'INSERT' ||
        !repository.chatAccountIsCurrent) {
      return;
    }
    final inserted = before.isEmpty
        ? suggestion.text
        : '\n\n${suggestion.text}';
    final text = before + inserted;
    if (text.length > 200000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El capítulo supera el límite de longitud.'),
        ),
      );
      return;
    }
    _assistantInsertion = (before: before, inserted: inserted);
    _contentController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
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
          child: AbsorbPointer(
            absorbing: _isSaving || _restoring,
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
                  _recoveryNotice(),
                  if (_restoring && !_choosingDraft)
                    const LinearProgressIndicator(),
                  _buildTitleSection(),
                  const SizedBox(height: 18),
                  if (widget.repository case LiteraryChatRepository assistant)
                    Wrap(
                      children: [
                        TextButton.icon(
                          onPressed: () => _openAssistant(assistant),
                          icon: const Icon(Icons.auto_awesome, size: 17),
                          label: const Text('Asistente IA'),
                        ),
                        if (_canUndoAssistantInsertion)
                          TextButton(
                            onPressed: _undoAssistantInsertion,
                            child: const Text('Deshacer inserción IA'),
                          ),
                      ],
                    ),
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
      ),
    );
  }
}
