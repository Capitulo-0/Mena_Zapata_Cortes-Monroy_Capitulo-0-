import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/writer_story.dart';
import '../../services/writer_local_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key, this.story});

  final WriterStory? story;

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final WriterLocalService _writerService = WriterLocalService();

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

  bool _isSaving = false;

  bool get _isEditing => widget.story != null;

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
    if (!mounted) {
      return;
    }

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

    if (_hasCover) {
      completed++;
    }

    if (_hasTitle) {
      completed++;
    }

    if (_hasGenre) {
      completed++;
    }

    if (_hasSynopsis) {
      completed++;
    }

    return completed;
  }

  double get _progress => _completedSteps / 4;

  bool get _canContinue => _completedSteps == 4;

  Future<void> _chooseCover() async {
    final selectedCover = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ELIGE UNA PORTADA',
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Por ahora puedes elegir una portada base. '
                  'Después conectaremos la carga de imágenes con Cloudinary.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildCoverOption(
                        bottomSheetContext,
                        id: 'preset:classic',
                        label: 'Clásica',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCoverOption(
                        bottomSheetContext,
                        id: 'preset:gold',
                        label: 'Dorada',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCoverOption(
                        bottomSheetContext,
                        id: 'preset:forest',
                        label: 'Bosque',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCoverOption(
                        bottomSheetContext,
                        id: 'preset:night',
                        label: 'Noche',
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

    if (selectedCover == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCover = selectedCover;
    });
  }

  Widget _buildCoverOption(
    BuildContext context, {
    required String id,
    required String label,
  }) {
    final colors = _coverColors(id);

    return InkWell(
      onTap: () {
        Navigator.of(context).pop(id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600),
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

  Future<WriterStory?> _saveStory({required bool closeAfterSaving}) async {
    if (_isSaving) {
      return null;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final currentStory = widget.story;

    final story = WriterStory(
      id: currentStory?.id ?? now.microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      synopsis: _synopsisController.text.trim(),
      genre: _selectedGenre ?? '',
      coverPath: _selectedCover,
      status: currentStory?.status ?? WriterStoryStatus.draft,
      chapters: currentStory?.chapters ?? const [],
      createdAt: currentStory?.createdAt ?? now,
      updatedAt: now,
      followers: currentStory?.followers ?? 0,
      rating: currentStory?.rating ?? 0,
    );

    await _writerService.createStory(story);

    if (!mounted) {
      return story;
    }

    setState(() {
      _isSaving = false;
    });

    if (closeAfterSaving) {
      Navigator.of(context).pop(story);
      return story;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Borrador guardado correctamente.')),
    );

    return story;
  }

  Future<void> _continue() async {
    if (!_canContinue) {
      return;
    }

    await _saveStory(closeAfterSaving: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackButton(context),
              const SizedBox(height: 8),
              _buildHeading(context),
              const SizedBox(height: 26),
              _buildSectionTitle(context, 'PORTADA'),
              const SizedBox(height: 10),
              _buildCoverSection(context),
              const SizedBox(height: 28),
              _buildSectionTitle(context, 'IDENTIDAD DE LA OBRA'),
              const SizedBox(height: 14),
              _buildIdentitySection(context),
              const SizedBox(height: 30),
              _buildSectionTitle(context, 'VISTA PREVIA'),
              const SizedBox(height: 12),
              _buildPreview(context),
              const SizedBox(height: 30),
              _buildProgressSection(context),
              const SizedBox(height: 22),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
      },
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: Text(
        'Volver',
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
    );
  }

  Widget _buildHeading(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? 'EDITAR HISTORIA' : 'CREAR HISTORIA',
          style: GoogleFonts.cinzel(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'DA FORMA A UNA NUEVA OBRA.',
          style: GoogleFonts.merriweather(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.35,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Empieza por su identidad, género y la idea que quieres contar.',
          style: GoogleFonts.inter(
            fontSize: 11,
            height: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: GoogleFonts.cinzel(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildCoverSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCoverPreview(context),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: _chooseCover,
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _hasCover ? 'Cambiar portada' : 'Elegir portada',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Añade una portada que represente la identidad de tu historia.',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_hasCover) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Portada seleccionada',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPreview(BuildContext context) {
    final theme = Theme.of(context);

    if (!_hasCover) {
      return Container(
        width: 100,
        height: 145,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 31,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'TU\nHISTORIA',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 100,
      height: 145,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _coverColors(_selectedCover),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_stories_rounded, size: 31, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            _titleController.text.trim().isEmpty
                ? 'TU HISTORIA'
                : _titleController.text.trim().toUpperCase(),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 8,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TÍTULO', style: _fieldLabelStyle(context)),
        const SizedBox(height: 7),
        TextField(
          controller: _titleController,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Ej: Sombras bajo la lluvia',
            counterText: '${_titleController.text.length}/80',
          ),
        ),
        const SizedBox(height: 20),
        Text('GÉNERO', style: _fieldLabelStyle(context)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genres.map((genre) {
            final selected = _selectedGenre == genre;

            return ChoiceChip(
              label: Text(
                genre,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedGenre = genre;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        Text('SINOPSIS', style: _fieldLabelStyle(context)),
        const SizedBox(height: 7),
        TextField(
          controller: _synopsisController,
          maxLength: 600,
          minLines: 6,
          maxLines: 10,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Cuenta brevemente de qué trata tu historia...',
            alignLabelWithHint: true,
            counterText: '${_synopsisController.text.length}/600',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'La sinopsis ayudará a otros lectores a descubrir tu obra.',
          style: GoogleFonts.inter(
            fontSize: 8.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  TextStyle _fieldLabelStyle(BuildContext context) {
    final theme = Theme.of(context);

    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: theme.colorScheme.onSurface,
    );
  }

  Widget _buildPreview(BuildContext context) {
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
          Transform.scale(
            scale: 0.78,
            alignment: Alignment.topLeft,
            child: _buildCoverPreview(context),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasTitle
                        ? _titleController.text.trim()
                        : 'Título de tu historia',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.merriweather(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _hasGenre ? _selectedGenre! : 'Género',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _hasSynopsis
                        ? _synopsisController.text.trim()
                        : 'Aquí aparecerá la sinopsis de tu obra.',
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tu perfil de autor',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
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
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);

    final percentage = (_progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CREANDO TU HISTORIA',
            style: GoogleFonts.cinzel(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_completedSteps de 4 datos completados',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$percentage%',
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
            value: _progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 16),
          _buildProgressItem(context, label: 'Portada', completed: _hasCover),
          _buildProgressItem(context, label: 'Título', completed: _hasTitle),
          _buildProgressItem(context, label: 'Género', completed: _hasGenre),
          _buildProgressItem(
            context,
            label: 'Sinopsis',
            completed: _hasSynopsis,
          ),
          if (!_canContinue) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  'Faltan datos por completar',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context, {
    required String label,
    required bool completed,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 17,
            color: completed
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: completed ? FontWeight.w700 : FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _canContinue && !_isSaving ? _continue : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(
              'Continuar',
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
                    _saveStory(closeAfterSaving: false);
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
