part of '../screens/profile_screen.dart';

extension _ProfileTabsFavoritesSection on _ProfileScreenState {
  Widget _buildTabs() {
    final worksCount = widget.publishedStories.length;
    const badgesCount = 5;

    final tabs = [
      {'id': 'favoritos', 'label': 'Favoritos'},
      {'id': 'resenas', 'label': 'Mis Reseñas'},
      {'id': 'lecturas', 'label': 'Mis Lecturas'},
      {
        'id': 'obras',
        'label': worksCount > 0 ? 'Mis obras ($worksCount)' : 'Mis obras',
      },
      {
        'id': 'insignias',
        'label': badgesCount > 0 ? 'Insignias ($badgesCount)' : 'Insignias',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final active = _selectedTab == tab['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _updateState(() => _selectedTab = tab['id']!),
              child: Container(
                padding: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab['label']!,
                  style: GoogleFonts.inter(
                    color: active ? AppColors.accent : _textSecondaryColor,
                    fontSize: 8,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedTab) {
      case 'favoritos':
        return _buildFavorites();
      case 'resenas':
        return _buildReviews();
      case 'lecturas':
        return _buildShelf();
      case 'obras':
        return _buildWorks();
      case 'insignias':
        return _buildBadges();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFavorites() {
    if (_favoriteShelfItems.isEmpty) {
      return _emptyCard('Todavía no tienes favoritos.');
    }

    return _sectionCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MI ESTANTE FAVORITO',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Todos tus favoritos, tanto libros como obras de la comunidad, se guardan automáticamente aquí.',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_favoriteCount favoritos',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _showExpandedFavoriteShelf,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      backgroundColor:
                          AppColors.accent.withValues(alpha: 0.08),
                      minimumSize: const Size(0, 26),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ver estante',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildShelfVisual(
            compact: true,
            sourceItems: _favoriteShelfItems,
          ),
        ],
      ),
    );
  }

  void _openFavoriteCommunityStory(WriterStory story) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublishedStoryScreen(
          story: story,
          currentUsername: widget.username,
          initiallyFavorite: true,
          onToggleFavorite: () {
            widget.onToggleCommunityStoryFavorite(story);
          },
        ),
      ),
    );
  }

  LibraryBook? _bookById(int id) {
    for (final book in widget.books) {
      if (book.id == id) return book;
    }
    return null;
  }
}
