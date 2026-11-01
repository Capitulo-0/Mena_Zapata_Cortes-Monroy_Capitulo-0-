part of '../screens/create_story_screen.dart';

extension _CreateStoryProgressActions on _CreateStoryScreenState {
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
