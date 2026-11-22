part of '../screens/profile_screen.dart';

extension _ProfileWorksBadgesSection on _ProfileScreenState {
  Widget _buildWorks() {
    final stories = widget.publishedStories;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MIS OBRAS',
                  style: GoogleFonts.cinzel(
                    color: _headingColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${stories.length} ${stories.length == 1 ? 'obra' : 'obras'}',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (stories.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    color: AppColors.gold.withValues(alpha: 0.85),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aún no has publicado obras.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.merriweather(
                      color: _textPrimaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cuando publiques una historia desde Escribir, aparecerá automáticamente aquí.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _textSecondaryColor,
                      fontSize: 7.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ...stories.asMap().entries.map((entry) {
              final story = entry.value;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == stories.length - 1 ? 0 : 9,
                ),
                child: InkWell(
                  onTap: () => _openPublishedWork(story),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWriterStoryCover(story),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.title.trim().isEmpty
                                    ? 'Historia sin título'
                                    : story.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.merriweather(
                                  color: _textPrimaryColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                story.genre.trim().isEmpty
                                    ? 'Sin género'
                                    : story.genre,
                                style: GoogleFonts.inter(
                                  color: _textSecondaryColor,
                                  fontSize: 7.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _publishedWorkBadge(),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      '${story.publishedChapterCount} ${story.publishedChapterCount == 1 ? 'capítulo publicado' : 'capítulos publicados'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: _textSecondaryColor,
                                        fontSize: 6.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Text(
                                story.synopsis.trim().isEmpty
                                    ? 'Sin sinopsis.'
                                    : story.synopsis,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.merriweather(
                                  color: _textSecondaryColor,
                                  fontSize: 7.2,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.gold.withValues(alpha: 0.90),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWriterStoryCover(WriterStory story) => WriterCover(
    storyId: story.id,
    coverPath: story.coverPath,
    title: story.title,
    width: 50,
    height: 70,
  );

  Widget _publishedWorkBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        'PUBLICADA',
        style: GoogleFonts.inter(
          color: AppColors.accent,
          fontSize: 5.7,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  void _openPublishedWork(WriterStory story) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublishedStoryScreen(
          story: story,
          currentUsername: widget.username,
        ),
      ),
    );
  }

  Widget _buildBadges() {
    // Las insignias se conectarán a los logros reales de Library.
    // No se otorgan logros simulados a las cuentas.
    final badges = <Map<String, Object>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _goldColor.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: _goldColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: _goldColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TUS LOGROS LECTORES',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${badges.length} insignias desbloqueadas',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (badges.isEmpty)
          _sectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: 48,
                  color: _goldColor.withValues(alpha: 0.65),
                ),
                const SizedBox(height: 14),
                Text(
                  'AÚN NO TIENES INSIGNIAS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: _headingColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cada lectura es un nuevo logro. '
                  'Pronto podrás desbloquear insignias '
                  'mientras avanzas en tu aventura literaria.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.merriweather(
                    color: _textSecondaryColor,
                    fontSize: 10,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: 1.28,
            ),
            itemBuilder: (context, index) {
              final badge = badges[index];
              final icon = badge['icon']! as IconData;
              final title = badge['title']! as String;
              final description = badge['description']! as String;

              return Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _goldColor.withValues(alpha: 0.34)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: index == 1
                            ? _accentColor.withValues(alpha: 0.09)
                            : _goldColor.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: index == 1
                              ? _accentColor.withValues(alpha: 0.20)
                              : _goldColor.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: index == 1 ? _accentColor : _goldColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.merriweather(
                        color: _headingColor,
                        fontSize: 8.2,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 6.9,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.merriweather(
          color: _textSecondaryColor,
          fontSize: 8.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(13),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.38)),
      ),
      child: child,
    );
  }

  void _openBookDetail(LibraryBook book) {
    if (widget.readOnly) return;
    final bookData = <String, dynamic>{
      'id': book.id,
      'title': book.title,
      'author': book.authorHandle ?? book.author,
      'authorReal': book.author,
      'rating': book.isBackendBook ? 0.0 : 4.8,
      'isBackendBook': book.isBackendBook,
      'googleVolumeId': book.googleVolumeId,
      'googleBooks': book.googleBooks,
      'year': book.year,
      'genre': book.genre,
      'availability': book.isFree ? 'GRATIS' : 'EXTERNA',
      'isbn': book.isbn,
      'cover': book.cover,
      'synopsis': book.synopsis,
    };

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => HomeBookDetailScreen(
              book: bookData,
              initialProgress: widget.progresses[book.id] ?? 0,
              readStatus: () => widget.statuses[book.id],
              readProgress: () => widget.progresses[book.id] ?? 0,
              onStatusChanged: (status) =>
                  widget.onStatusChanged(book.id, status),
              onRead: () =>
                  widget.onReadBook?.call(context, book.id) ??
                  Future<int?>.value(),
              currentUsername: widget.username,
              isGuest: false,
              onGuestRestrictedAction: () {},
              initialReview: widget.reviews[book.id],
              onReviewSaved: widget.onReviewSaved,
              initiallyFavorite: widget.favorites.contains(book.id),
              onToggleFavorite: () {
                widget.onToggleFavorite(book.id);
              },
              onOpenOwnProfile: () {
                Navigator.of(context).pop();
              },
              onAddToLibrary: () async {
                await widget.onStatusChanged(
                  book.id,
                  widget.statuses[book.id] ?? BookStatus.porLeer,
                );
                if (mounted && widget.statuses.containsKey(book.id)) {
                  _showMessage('${book.title} está en tu biblioteca.');
                }
              },
            ),
          ),
        )
        .then((_) {
          if (mounted) _updateState(() {});
        });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
