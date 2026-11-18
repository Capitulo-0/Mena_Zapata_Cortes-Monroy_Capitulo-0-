part of '../screens/writer_screen.dart';

extension _WriterOverviewSection on _WriterScreenState {
  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
    child: WriterHeader(
      onCreate: _openCreateStory,
      onLegacy: _openLegacy,
      onRefresh: () => _loadStories(notifyParent: true),
      onDiagnostics: _showCoverDiagnostics,
    ),
  );

  Widget _buildNavigation() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
    child: Row(
      children: [
        Expanded(
          child: FilledButton.tonal(
            key: const ValueKey('writer-my-works'),
            onPressed: () =>
                _updateState(() => _selectedFilter = _StoryFilter.all),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
            ),
            child: const Text('Mis obras'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            key: const ValueKey('writer-community'),
            onPressed:
                widget.isGuest || _writerService is CommunityWriterRepository
                ? _openCommunity
                : null,
            child: const Text('Comunidad'),
          ),
        ),
      ],
    ),
  );

  Widget _buildStats() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Row(
      children: [
        _counter(
          'Historias',
          _stories.length,
          AppColors.deep,
          _StoryFilter.all,
        ),
        const SizedBox(width: 7),
        _counter(
          'Publicadas',
          _publishedCount,
          AppColors.accent,
          _StoryFilter.published,
        ),
        const SizedBox(width: 7),
        _counter(
          'Borradores',
          _draftCount,
          AppColors.gold,
          _StoryFilter.drafts,
        ),
      ],
    ),
  );

  Widget _counter(
    String label,
    int count,
    Color color,
    _StoryFilter filter,
  ) => Expanded(
    child: InkWell(
      onTap: () => _updateState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: .72), width: 1.05),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _textSecondaryColor, fontSize: 9),
            ),
          ],
        ),
      ),
    ),
  );

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
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.34)),
        ),
        child: Row(
          children: [
            Expanded(child: _buildFilterButton('Todas', _StoryFilter.all)),
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
