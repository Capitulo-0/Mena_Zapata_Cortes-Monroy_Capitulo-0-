part of '../screens/create_story_screen.dart';

extension _CreateStoryIdentitySection on _CreateStoryScreenState {
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
                _updateState(() {
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
}
