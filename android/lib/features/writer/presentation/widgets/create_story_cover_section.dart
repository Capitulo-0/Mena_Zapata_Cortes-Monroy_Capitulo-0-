part of '../screens/create_story_screen.dart';

extension _CreateStoryCoverSection on _CreateStoryScreenState {
  Future<void> _pickOwnCover() async {
    if (_pickingCover || _isSaving) {
      return;
    }
    _updateState(() => _pickingCover = true);
    try {
      final selection = await (widget.coverPicker ?? WriterCoverPicker())
          .pick();
      if (mounted && selection != null) {
        _updateState(() => _localCoverPreview = selection);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message.toString()
                  : 'No se pudo seleccionar la imagen.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        _updateState(() => _pickingCover = false);
      }
    }
  }

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
                  'Elige una portada base. Noche conserva el azul de las historias existentes.',
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
                        label: 'Noche · azul',
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

    _updateState(() {
      _selectedCover = selectedCover;
      _localCoverPreview = null;
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
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
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

  List<Color> _coverColors(String? cover) => WriterCover.colors(cover);

  bool get _hasUnsavedChanges {
    return _localCoverPreview != null ||
        _titleController.text != _initialTitle ||
        _synopsisController.text != _initialSynopsis ||
        _selectedGenre != _initialGenre ||
        _selectedCover != _initialCover;
  }

  Widget _buildCoverSection() {
    return Column(
      children: [
        Center(child: _buildLargeCoverPreview()),
        TextButton.icon(
          key: const ValueKey('writer-upload-cover'),
          onPressed: _pickingCover || _isSaving ? null : _pickOwnCover,
          icon: _pickingCover
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Subir mi portada'),
        ),
        const Text(
          'JPEG, PNG o WebP · hasta 5 MB. Sólo previsualización: almacenamiento compartido aún no configurado.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10),
        ),
        if (_localCoverPreview != null) ...[
          const Text(
            'Imagen local pendiente · no se ha subido ni guardado.',
            key: ValueKey('writer-cover-preview-notice'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
          TextButton(
            onPressed: () => _updateState(() => _localCoverPreview = null),
            child: const Text('Descartar vista previa'),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _chooseCover,
          icon: const Icon(Icons.auto_awesome_rounded, size: 14),
          label: Text(
            _hasCover ? 'Cambiar portada' : 'Elegir portada',
            style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _headingColor,
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.55)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Elige una portada literaria predefinida',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 6.8, color: _textSecondaryColor),
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
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.48)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: (_hasCover || _localCoverPreview != null)
          ? _buildPresetCover()
          : Container(
              color: _surfaceColor,
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '✦',
                    style: TextStyle(color: AppColors.gold, fontSize: 14),
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

  Widget _buildPresetCover() => _localCoverPreview != null
      ? Image.memory(
          _localCoverPreview!.bytes,
          fit: BoxFit.cover,
          gaplessPlayback: false,
        )
      : WriterCover(
          storyId: _storyId,
          coverPath: _selectedCover,
          title: _titleController.text,
        );
}
