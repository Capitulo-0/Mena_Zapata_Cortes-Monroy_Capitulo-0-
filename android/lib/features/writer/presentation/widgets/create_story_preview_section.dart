part of '../screens/create_story_screen.dart';

extension _CreateStoryPreviewSection on _CreateStoryScreenState {
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
}
