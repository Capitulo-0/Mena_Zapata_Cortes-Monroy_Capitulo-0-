part of '../screens/profile_screen.dart';

extension _ProfileReadingSummarySection on _ProfileScreenState {
  Widget _buildFavoriteQuote() {
    final quote = _favoriteQuotes[_quoteIndex];
    final work = quote['work'] ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: AppColors.gold, width: 4),
          top: BorderSide(color: AppColors.gold, width: 0.6),
          right: BorderSide(color: AppColors.gold, width: 0.6),
          bottom: BorderSide(color: AppColors.gold, width: 0.6),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: -22,
            child: Text(
              '“',
              style: GoogleFonts.merriweather(
                color: AppColors.gold.withValues(alpha: 0.14),
                fontSize: 58,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'CITA FAVORITA ANCLADA',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _updateState(() {
                        _quoteIndex =
                            (_quoteIndex + 1) % _favoriteQuotes.length;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 26),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Cambiar',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  '“${quote['text']}”',
                  style: GoogleFonts.merriweather(
                    color: _textPrimaryColor,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '— ${quote['author']}${work.isEmpty ? '' : ' · $work'}',
                style: GoogleFonts.inter(
                  color: _textSecondaryColor,
                  fontSize: 7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookDna() {
    final genres = _topGenres;
    final total = _readBooks.isEmpty ? 1 : _readBooks.length;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GÉNEROS MÁS LEÍDOS',
            style: GoogleFonts.cinzel(
              color: _headingColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          if (genres.isEmpty)
            Text(
              'Cuando finalices libros, aquí aparecerá tu ADN lector.',
              style: GoogleFonts.inter(color: _textSecondaryColor, fontSize: 8),
            )
          else
            ...genres.map((entry) {
              final progress = entry.value / total;
              final percent = (progress * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.inter(
                              color: _textPrimaryColor,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _gradientProgressBar(progress, height: 7),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _gradientProgressBar(double progress, {double height = 8}) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(height),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              width: constraints.maxWidth * safeProgress,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE3BD58),
                    Color(0xFFC78335),
                    AppColors.accent,
                  ],
                ),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadingChallenge() {
    final progress = widget.annualGoal > 0
        ? (_booksReadThisYear / widget.annualGoal).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'RETO DE LECTURA ANUAL',
                  style: GoogleFonts.cinzel(
                    color: _headingColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$_booksReadThisYear / ${widget.annualGoal} libros',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _gradientProgressBar(progress, height: 9),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${(progress * 100).round()}% completado',
                  style: GoogleFonts.inter(
                    color: _textSecondaryColor,
                    fontSize: 8,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showMarkBookAsRead,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Registrar libro'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
