import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
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

  Future<void> _chooseCover() async {
    final selectedCover = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surfaceColor,
      builder: (bottomSheetContext) {
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _headingColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Por ahora puedes elegir una portada base. Más adelante conectaremos la carga de imágenes.',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    height: 1.45,
                    color: _textSecondaryColor,
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

    if (selectedCover == null || !mounted) return;

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
      onTap: () => Navigator.of(context).pop(id),
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
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
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
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: _textPrimaryColor,
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

  Future<WriterStory?> _saveStory({required bool closeAfterSaving}) async {
    if (_isSaving) return null;

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

    if (!mounted) return story;

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
    if (!_canContinue) return;
    await _saveStory(closeAfterSaving: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
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
    );
  }

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back_rounded, size: 16),
      label: Text(
        _isEditing ? 'Volver' : 'Volver',
        style: GoogleFonts.inter(
          fontSize: 9,
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

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? 'EDICIÓN DE OBRA' : 'CREAR HISTORIA',
          style: GoogleFonts.cinzel(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _isEditing ? 'EDITAR HISTORIA' : 'DA FORMA A UNA NUEVA OBRA.',
                style: GoogleFonts.merriweather(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: _headingColor,
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(width: 8),
              _buildStatusPill(widget.story!.isPublished),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _isEditing
              ? 'Actualiza la identidad y presentación de tu obra.'
              : 'Empieza por su identidad, género y la idea que quieres contar.',
          style: GoogleFonts.inter(
            fontSize: 9.5,
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
            fontSize: 9.2,
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

  Widget _buildCoverSection() {
    return Column(
      children: [
        Center(child: _buildLargeCoverPreview()),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _chooseCover,
          icon: const Icon(Icons.auto_awesome_rounded, size: 14),
          label: Text(
            _hasCover ? 'Cambiar portada' : 'Elegir portada',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _headingColor,
            side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.55),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Añade una imagen mediante URL',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 6.8,
            color: _textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLargeCoverPreview() {
    return Container(
      width: 96,
      height: 136,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasCover
          ? _buildPresetCover()
          : Container(
              color: _surfaceColor,
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '✦',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'TU HISTORIA',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      color: _textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 28,
                    height: 1,
                    color: AppColors.gold.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPresetCover() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _coverColors(_selectedCover),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(height: 10),
          Text(
            _hasTitle ? _titleController.text.trim().toUpperCase() : 'TU HISTORIA',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 7,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TÍTULO', style: _fieldLabelStyle()),
        const SizedBox(height: 7),
        TextField(
          controller: _titleController,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.merriweather(
            fontSize: 11,
            color: _textPrimaryColor,
          ),
          decoration: _inputDecoration(
            hintText: 'Título de la historia',
            counterText: '${_titleController.text.length} / 80',
          ),
        ),
        const SizedBox(height: 18),
        Text('GÉNERO', style: _fieldLabelStyle()),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _genres.map((genre) {
            final selected = _selectedGenre == genre;

            return ChoiceChip(
              label: Text(
                genre,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedGenre = genre;
                });
              },
              selectedColor: AppColors.accent,
              backgroundColor: _surfaceColor,
              side: BorderSide(
                color: selected
                    ? AppColors.accent
                    : AppColors.gold.withValues(alpha: 0.28),
              ),
              labelStyle: TextStyle(
                color: selected ? AppColors.background : _textPrimaryColor,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('SINOPSIS', style: _fieldLabelStyle()),
        const SizedBox(height: 7),
        TextField(
          controller: _synopsisController,
          maxLength: 600,
          minLines: 6,
          maxLines: 10,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.merriweather(
            fontSize: 10,
            height: 1.55,
            color: _textPrimaryColor,
          ),
          decoration: _inputDecoration(
            hintText: 'Escribe una breve sinopsis...',
            counterText: '${_synopsisController.text.length} / 600',
          ),
        ),
      ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      hintStyle: GoogleFonts.merriweather(
        fontSize: 9.5,
        color: _textSecondaryColor,
      ),
      counterStyle: GoogleFonts.inter(
        fontSize: 6.8,
        color: _textSecondaryColor,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.gold.withValues(alpha: 0.48),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.gold,
          width: 1.2,
        ),
      ),
    );
  }

  TextStyle _fieldLabelStyle() {
    return GoogleFonts.inter(
      fontSize: 8.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.45,
      color: _textSecondaryColor,
    );
  }

  Widget _buildPreview() {
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
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            height: 86,
            child: _hasCover
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPresetCover(),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? _deepColor.withValues(alpha: 0.35)
                          : const Color(0xFFF1E8DA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'SIN PORTADA',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 5.5,
                        color: _textSecondaryColor,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _hasTitle
                            ? _titleController.text.trim()
                            : 'Título de la historia',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.merriweather(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _textPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildStatusPill(false),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _hasGenre ? _selectedGenre! : 'Sin género',
                  style: GoogleFonts.inter(
                    fontSize: 7.2,
                    color: _textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _hasSynopsis
                      ? _synopsisController.text.trim()
                      : 'Tu sinopsis aparecerá aquí mientras escribes.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    fontSize: 7.3,
                    height: 1.45,
                    color: _textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 1,
                      color: AppColors.gold.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'por ',
                      style: GoogleFonts.inter(
                        fontSize: 6.5,
                        color: _textSecondaryColor,
                      ),
                    ),
                    Text(
                      '@constanza.lectora',
                      style: GoogleFonts.inter(
                        fontSize: 6.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
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

  Widget _buildStatusPill(bool published) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: published
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
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
          const SizedBox(width: 3),
          Text(
            published ? 'PUBLICADA' : 'BORRADOR',
            style: GoogleFonts.inter(
              color: published ? AppColors.accent : AppColors.gold,
              fontSize: 5.3,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final percentage = (_progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$_completedSteps de 4 datos completados',
                style: GoogleFonts.inter(
                  fontSize: 7.7,
                  fontWeight: FontWeight.w600,
                  color: _textSecondaryColor,
                ),
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.inter(
                fontSize: 7.7,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 5,
            backgroundColor: AppColors.gold.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _progressLabel('Portada', _hasCover)),
            Expanded(child: _progressLabel('Título', _hasTitle)),
            Expanded(child: _progressLabel('Género', _hasGenre)),
            Expanded(child: _progressLabel('Sinopsis', _hasSynopsis)),
          ],
        ),
        if (!_canContinue) ...[
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Faltan datos por completar',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  color: _textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _progressLabel(String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? AppColors.accent
                : AppColors.gold.withValues(alpha: 0.18),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 5.8,
            color: completed ? _textPrimaryColor : _textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canContinue && !_isSaving ? _continue : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.24),
              foregroundColor: AppColors.background,
              disabledForegroundColor:
                  AppColors.background.withValues(alpha: 0.92),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'Guardar cambios' : 'Continuar →',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isSaving
              ? null
              : () {
                  _saveStory(closeAfterSaving: false);
                },
          icon: const Icon(Icons.save_outlined, size: 13),
          label: Text(
            _isEditing ? 'Guardar borrador' : 'Guardar borrador',
            style: GoogleFonts.inter(
              fontSize: 7.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _textSecondaryColor,
            side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ],
    );
  }
}
