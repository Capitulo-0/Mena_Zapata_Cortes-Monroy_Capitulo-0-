import '../widgets/writer_cover.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/writer_story.dart';
import '../../services/writer_repository.dart';
import '../../services/literary_chat.dart';
import '../widgets/literary_chat_screen.dart';
import '../../services/writer_cover_picker.dart';

part '../widgets/create_story_header_section.dart';
part '../widgets/create_story_cover_section.dart';
part '../widgets/create_story_identity_section.dart';
part '../widgets/create_story_preview_section.dart';
part '../widgets/create_story_progress_actions.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({
    super.key,
    this.story,
    this.repository,
    this.coverPicker,
  });

  final WriterStory? story;

  final WriterRepository? repository;
  final WriterCoverPicker? coverPicker;

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  void _updateState(VoidCallback callback) {
    setState(callback);
  }

  late final WriterRepository _writerService =
      widget.repository ?? const UnavailableWriterRepository();

  late final TextEditingController _titleController;
  late final TextEditingController _synopsisController;

  final List<String> _genres = const [
    'Romance',
    'Fantasía',
    'Misterio',
    'Terror',
    'Ciencia ficción',
    'Poesía',
    'Cuento',
    'Drama',
    'Aventura',
  ];

  String? _selectedGenre;
  String? _selectedCover;
  WriterCoverSelection? _localCoverPreview;
  bool _pickingCover = false;
  bool _isSaving = false;
  WriterStory? _savedStory;
  late final String _storyId =
      widget.story?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

  late String _initialTitle;
  late String _initialSynopsis;
  late String? _initialGenre;
  late String? _initialCover;

  WriterStory? get _currentStory => _savedStory ?? widget.story;
  bool get _isEditing => _currentStory != null;

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

    _titleController = TextEditingController(text: widget.story?.title ?? '');
    _synopsisController = TextEditingController(
      text: widget.story?.synopsis ?? '',
    );

    _selectedGenre = widget.story?.genre.isNotEmpty == true
        ? widget.story!.genre
        : null;

    _selectedCover = widget.story?.coverPath;

    _initialTitle = _titleController.text;
    _initialSynopsis = _synopsisController.text;
    _initialGenre = _selectedGenre;
    _initialCover = _selectedCover;

    _titleController.addListener(_refreshForm);
    _synopsisController.addListener(_refreshForm);
  }

  @override
  void dispose() {
    _titleController.removeListener(_refreshForm);
    _synopsisController.removeListener(_refreshForm);
    _titleController.dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  void _refreshForm() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _hasCover =>
      _selectedCover != null && _selectedCover!.trim().isNotEmpty;

  bool get _hasTitle => _titleController.text.trim().isNotEmpty;

  bool get _hasGenre =>
      _selectedGenre != null && _selectedGenre!.trim().isNotEmpty;

  bool get _hasSynopsis => _synopsisController.text.trim().isNotEmpty;

  int get _completedSteps {
    var completed = 0;
    if (_hasCover) completed++;
    if (_hasTitle) completed++;
    if (_hasGenre) completed++;
    if (_hasSynopsis) completed++;
    return completed;
  }

  double get _progress => _completedSteps / 4;

  bool get _canContinue => _completedSteps == 4;

  Future<bool> _confirmExit() async {
    if (_isSaving) return false;
    if (!_hasUnsavedChanges) return true;

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
                  'Si sales ahora, los cambios que aún no hayas guardado en esta historia se perderán.',
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

    Navigator.of(context).pop(_savedStory ?? widget.story);
  }

  Future<WriterStory?> _saveStory({required bool closeAfterSaving}) async {
    if (_isSaving) return null;
    if (_localCoverPreview != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La imagen es sólo una vista previa local. Falta configurar almacenamiento privado; elige una portada predeterminada para guardar.',
          ),
        ),
      );
      return null;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un titulo antes de guardar.')),
      );
      return null;
    }
    setState(() => _isSaving = true);
    final inputTitle = _titleController.text;
    final inputSynopsis = _synopsisController.text;
    final inputGenre = _selectedGenre;
    final inputCover = _selectedCover;
    final now = DateTime.now();
    final current = _savedStory ?? widget.story;
    final story = WriterStory(
      id: _storyId,
      revision: current?.revision ?? 0,
      title: _titleController.text.trim(),
      synopsis: _synopsisController.text.trim(),
      genre: _selectedGenre ?? '',
      coverPath: _selectedCover,
      status: current?.status ?? WriterStoryStatus.draft,
      chapters: current?.chapters ?? const [],
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      final saved = await _writerService.save(story);
      if (!mounted) return saved;
      setState(() {
        _savedStory = saved;
        _initialTitle = inputTitle;
        _initialSynopsis = inputSynopsis;
        _initialGenre = inputGenre;
        _initialCover = inputCover;
      });
      if (closeAfterSaving) {
        Navigator.of(context).pop(saved);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved.isPublished
                  ? 'Cambios publicados en tu cuenta.'
                  : 'Borrador guardado en tu cuenta.',
            ),
          ),
        );
      }
      return saved;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(writerError(error))));
      }
      return null;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _continue() async {
    if (!_canContinue) return;
    await _saveStory(closeAfterSaving: true);
  }

  Future<void> _openAssistant(LiteraryChatRepository repository) async {
    final title = _titleController.text;
    final synopsis = _synopsisController.text;
    final suggestion = await LiteraryChatScreen.open(
      context,
      LiteraryChatScreen(
        repository: repository,
        editor: ChatEditor.story,
        genre: _selectedGenre ?? '',
        title: title,
        excerpt: synopsis.length <= 4000 ? synopsis : '',
      ),
    );
    if (!mounted ||
        suggestion == null ||
        _isSaving ||
        !repository.chatAccountIsCurrent) {
      return;
    }
    if (_titleController.text != title ||
        _synopsisController.text != synopsis) {
      return;
    }
    if (suggestion.action == 'TITLE') {
      _titleController.text = suggestion.text;
    } else if (suggestion.action == 'SYNOPSIS') {
      _synopsisController.text = suggestion.text;
    }
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
            absorbing: _isSaving,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBackButton(),
                  const SizedBox(height: 8),
                  _buildHeading(),
                  const SizedBox(height: 20),

                  _buildSectionTitle('PORTADA'),
                  const SizedBox(height: 12),
                  _buildCoverSection(),
                  const SizedBox(height: 25),

                  _buildSectionTitle('IDENTIDAD DE LA OBRA'),
                  const SizedBox(height: 14),
                  _buildIdentitySection(),
                  if (widget.repository case LiteraryChatRepository assistant)
                    TextButton.icon(
                      onPressed: () => _openAssistant(assistant),
                      icon: const Icon(Icons.auto_awesome, size: 17),
                      label: const Text('Asistente IA'),
                    ),
                  const SizedBox(height: 28),

                  _buildSectionTitle('VISTA PREVIA'),
                  const SizedBox(height: 12),
                  _buildPreview(),
                  const SizedBox(height: 28),

                  _buildSectionTitle('CREANDO TU HISTORIA'),
                  const SizedBox(height: 12),
                  _buildProgressSection(),
                  const SizedBox(height: 18),

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
