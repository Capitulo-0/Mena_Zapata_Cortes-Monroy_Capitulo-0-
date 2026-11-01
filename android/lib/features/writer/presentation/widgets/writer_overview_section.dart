part of '../screens/writer_screen.dart';

extension _WriterOverviewSection on _WriterScreenState {
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MIS HISTORIAS',
                  style: GoogleFonts.cinzel(
                    color: _headingColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Tu espacio de escritura, ',
                        style: GoogleFonts.merriweather(
                          color: _textSecondaryColor,
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${widget.currentName.trim().isEmpty ? 'LECTOR/A' : widget.currentName.trim().toUpperCase()} ✦',
                        style: GoogleFonts.cinzel(
                          color: _textPrimaryColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _openCreateStory,
            icon: const Icon(Icons.add_rounded, size: 15),
            label: Text(
              'Crear historia',
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.24),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStat(
                value: '${_stories.length}',
                label: _stories.length == 1 ? 'historia' : 'historias',
                valueColor: _headingColor,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildStat(
                value: '$_publishedCount',
                label: _publishedCount == 1 ? 'publicada' : 'publicadas',
                valueColor: AppColors.accent,
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildStat(
                value: '$_draftCount',
                label: _draftCount == 1 ? 'borrador' : 'borradores',
                valueColor: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.merriweather(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: _textSecondaryColor,
              fontSize: 7.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 25,
      color: AppColors.gold.withValues(alpha: 0.25),
    );
  }

  Widget _buildWorksSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 9),
      child: Row(
        children: [
          Text(
            'TUS OBRAS',
            style: GoogleFonts.cinzel(
              color: _headingColor,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
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
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? _surfaceColor
              : AppColors.gold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.34),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildFilterButton('Todas', _StoryFilter.all),
            ),
            Expanded(
              child: _buildFilterButton('Publicadas', _StoryFilter.published),
            ),
            Expanded(
              child: _buildFilterButton('Borradores', _StoryFilter.drafts),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, _StoryFilter filter) {
    final selected = _selectedFilter == filter;

    return InkWell(
      onTap: () => _updateState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: selected ? AppColors.background : _textPrimaryColor,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String description;

    switch (_selectedFilter) {
      case _StoryFilter.all:
        title = 'Aún no tienes historias';
        description = 'Crea tu primera obra y comienza a escribir capítulos.';
        break;
      case _StoryFilter.published:
        title = 'No tienes historias publicadas';
        description = 'Cuando publiques una historia, aparecerá aquí.';
        break;
      case _StoryFilter.drafts:
        title = 'No tienes borradores';
        description = 'Tus historias sin publicar aparecerán aquí.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 35, 28, 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.32),
                ),
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                color: _headingColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.merriweather(
                color: _textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _textSecondaryColor,
                fontSize: 9,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
