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
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
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

  Widget _buildWriterStoryCover(WriterStory story) {
    final cover = story.coverPath?.trim() ?? '';
    final hasNetworkCover =
        cover.startsWith('http://') || cover.startsWith('https://');

    return Container(
      width: 50,
      height: 70,
      decoration: BoxDecoration(
        color: _deepSurfaceColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasNetworkCover
          ? Image.network(
              cover,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _writerStoryCoverPlaceholder(story),
            )
          : _writerStoryCoverPlaceholder(story),
    );
  }

  Widget _writerStoryCoverPlaceholder(WriterStory story) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _deepSurfaceColor,
            _deepSurfaceColor.withValues(alpha: 0.78),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: AppColors.gold,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            story.title.trim().isEmpty
                ? 'TU OBRA'
                : story.title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              color: AppColors.background,
              fontSize: 4.8,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _publishedWorkBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.30),
        ),
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
    final badges = <Map<String, Object>>[
      {
        'icon': Icons.auto_stories_rounded,
        'title': 'Lectora constante',
        'description': 'Mantienes el hábito de lectura activo.',
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'title': 'Racha de 14 días',
        'description': 'Dos semanas leyendo sin perder el ritmo.',
      },
      {
        'icon': Icons.dark_mode_rounded,
        'title': 'Amante del gótico',
        'description': 'Tus lecturas reflejan tu lado más oscuro.',
      },
      {
        'icon': Icons.star_rounded,
        'title': '${widget.reviews.values.where((review) => review.isPublic).length} reseñas guardadas',
        'description': 'Compartes tu opinión sobre lo que lees.',
      },
      {
        'icon': Icons.emoji_events_rounded,
        'title': '$_booksReadThisYear libros este año',
        'description': 'Cada libro terminado suma a tu recorrido.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _goldColor.withValues(alpha: 0.30),
            ),
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
                border: Border.all(
                  color: _goldColor.withValues(alpha: 0.34),
                ),
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
    final bookData = <String, dynamic>{
      'id': book.id,
      'title': book.title,
      'author': book.authorHandle ?? book.author,
      'authorReal': book.author,
      'rating': 4.8,
      'year': book.year,
      'genre': book.genre,
      'availability': 'GRATIS',
      'isbn': book.isbn,
      'cover': book.cover,
      'synopsis': book.synopsis,
    };

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => HomeBookDetailScreen(
              book: bookData,
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
              onAddToLibrary: () {
                widget.onStatusChanged(
                  book.id,
                  widget.statuses[book.id] ?? BookStatus.porLeer,
                );
                _showMessage('${book.title} está en tu biblioteca.');
              },
            ),
          ),
        )
        .then((_) {
          if (mounted) _updateState(() {});
        });
  }

  void _showSocialList(String title, List<Map<String, String>> users) {
    final isFollowers = title == 'Seguidores';

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        String? socialSuccessMessage;

        return StatefulBuilder(
          builder: (context, modalSetState) {
            final visibleUsers = users
                .where((user) => !_blockedUsers.contains(user['user']))
                .toList();

            return Container(
              height: MediaQuery.sizeOf(sheetContext).height * 0.70,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border(
                  top: BorderSide(
                    color: _goldColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 9),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _textSecondaryColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _deepSurfaceColor,
                            border: Border.all(
                              color: _goldColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            isFollowers
                                ? Icons.people_outline_rounded
                                : Icons.person_add_alt_1_rounded,
                            color: _goldColor,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.toUpperCase(),
                                style: GoogleFonts.cinzel(
                                  color: _headingColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isFollowers
                                    ? 'Personas que siguen tu perfil literario'
                                    : 'Perfiles que sigues actualmente',
                                style: GoogleFonts.inter(
                                  color: _textSecondaryColor,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: _textPrimaryColor,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: _goldColor.withValues(alpha: 0.16),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: socialSuccessMessage != null
                        ? Padding(
                            key: const ValueKey('social-block-success'),
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? const Color(0xFF283125)
                                    : const Color(0xFFF4F7EE),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF78935F)
                                      .withValues(alpha: 0.72),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF708A56),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Text(
                                      socialSuccessMessage!,
                                      style: GoogleFonts.merriweather(
                                        color: _isDarkMode
                                            ? const Color(0xFFE7EEDC)
                                            : const Color(0xFF3F4F33),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.person_off_outlined,
                                    color: _goldColor.withValues(alpha: 0.76),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('social-block-success-empty'),
                          ),
                  ),
                  Expanded(
                    child: visibleUsers.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFollowers
                                        ? Icons.people_outline_rounded
                                        : Icons.person_outline_rounded,
                                    size: 36,
                                    color: _goldColor.withValues(alpha: 0.75),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isFollowers
                                        ? 'No tienes seguidores visibles.'
                                        : 'No estás siguiendo perfiles visibles.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: _textSecondaryColor,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(14, 12, 14, 24),
                            itemCount: visibleUsers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = visibleUsers[index];

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: () => _showPublicProfile(user),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      7,
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _surfaceColor,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: _goldColor.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _deepSurfaceColor,
                                            border: Border.all(
                                              color: _goldColor.withValues(
                                                alpha: 0.55,
                                              ),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            user['initial']!,
                                            style: GoogleFonts.cinzel(
                                              color: _goldColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name']!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    GoogleFonts.merriweather(
                                                  color: _textPrimaryColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                user['user']!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: _accentColor,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Más opciones',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () async {
                                            final blocked =
                                                await _showSocialUserActions(
                                              user,
                                            );

                                            if (blocked && mounted) {
                                              _updateState(() {});

                                              modalSetState(() {
                                                socialSuccessMessage =
                                                    '${user['user'] ?? 'Usuario'} bloqueado correctamente';
                                              });

                                              Future<void>.delayed(
                                                const Duration(
                                                  milliseconds: 2500,
                                                ),
                                                () {
                                                  if (!sheetContext.mounted) {
                                                    return;
                                                  }

                                                  modalSetState(() {
                                                    socialSuccessMessage = null;
                                                  });
                                                },
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            color: _textSecondaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: isFollowers
                                              ? 'Eliminar seguidor'
                                              : 'Dejar de seguir',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () async {
                                            final removed =
                                                await _confirmRemoveSocialUser(
                                              user: user,
                                              isFollowers: isFollowers,
                                            );

                                            if (!removed || !mounted) {
                                              return;
                                            }

                                            _updateState(() {
                                              users.remove(user);
                                            });
                                            modalSetState(() {});
                                          },
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: _accentColor.withValues(
                                              alpha: 0.78,
                                            ),
                                            size: 19,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _showSocialUserActions(Map<String, String> user) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      isScrollControlled: true,
      builder: (actionContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _goldColor.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _textSecondaryColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _deepSurfaceColor,
                        border: Border.all(
                          color: _goldColor.withValues(alpha: 0.38),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user['initial']!,
                        style: GoogleFonts.cinzel(
                          color: _goldColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name']!,
                            style: GoogleFonts.merriweather(
                              color: _textPrimaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user['user']!,
                            style: GoogleFonts.inter(
                              color: _textSecondaryColor,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () {
                      Navigator.of(actionContext).pop(true);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 31,
                            height: 31,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor.withValues(alpha: 0.11),
                            ),
                            child: Icon(
                              Icons.block_rounded,
                              color: _accentColor,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bloquear',
                                  style: GoogleFonts.inter(
                                    color: _accentColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'No podrá interactuar contigo ni ver tu perfil.',
                                  style: GoogleFonts.inter(
                                    color: _textSecondaryColor,
                                    fontSize: 7.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: _accentColor,
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true || !mounted) {
      return false;
    }

    final confirmed = await _confirmBlockUser(user);

    if (confirmed != true || !mounted) {
      return false;
    }

    ProfileBlockedUsersStore.block(user);

    if (mounted) {
      _updateState(() {});
    }

    return true;
  }

  Future<bool?> _confirmBlockUser(Map<String, String> user) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var isBlocking = false;
        var blockingDots = 1;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentColor.withValues(alpha: 0.10),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        color: _accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      '¿Bloquear a ${user['user']}?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        color: _textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Este usuario no podrá ver tu perfil ni nada relacionado a ti.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 9,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton(
                              onPressed: isBlocking
                                  ? null
                                  : () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _textPrimaryColor,
                                disabledForegroundColor:
                                    _textSecondaryColor.withValues(alpha: 0.55),
                                side: BorderSide(
                                  color: _goldColor.withValues(alpha: 0.38),
                                ),
                                backgroundColor:
                                    _surfaceColor.withValues(alpha: 0.48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: FilledButton(
                              onPressed: isBlocking
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isBlocking = true;
                                        blockingDots = 1;
                                      });

                                      for (var step = 0;
                                          step < 4;
                                          step++) {
                                        await Future<void>.delayed(
                                          const Duration(milliseconds: 250),
                                        );

                                        if (!dialogContext.mounted) return;

                                        setDialogState(() {
                                          blockingDots =
                                              (blockingDots % 3) + 1;
                                        });
                                      }

                                      if (!dialogContext.mounted) return;
                                      Navigator.of(dialogContext).pop(true);
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: isBlocking
                                    ? _accentColor.withValues(alpha: 0.58)
                                    : _accentColor,
                                disabledBackgroundColor:
                                    _accentColor.withValues(alpha: 0.58),
                                foregroundColor: AppColors.background,
                                disabledForegroundColor:
                                    AppColors.background.withValues(alpha: 0.82),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isBlocking
                                    ? 'Bloqueando${'.' * blockingDots}'
                                    : 'Bloquear',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
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
      },
    );
  }



  Future<bool> _confirmRemoveSocialUser({
    required Map<String, String> user,
    required bool isFollowers,
  }) async {
    final username = user['user'] ?? '@usuario';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _goldColor.withValues(alpha: 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentColor.withValues(alpha: 0.10),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(
                    isFollowers
                        ? Icons.person_remove_alt_1_rounded
                        : Icons.person_off_outlined,
                    color: _accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  '¿Eliminar a $username?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: _textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isFollowers
                      ? '$username no recibirá una notificación de que ya no te sigue.'
                      : '$username no recibirá una notificación de que ya no lo sigues.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _textSecondaryColor,
                    fontSize: 9,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textPrimaryColor,
                            side: BorderSide(
                              color: _goldColor.withValues(alpha: 0.38),
                            ),
                            backgroundColor:
                                _surfaceColor.withValues(alpha: 0.48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Eliminar',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
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

    return confirmed == true;
  }

  void _showPublicProfile(Map<String, String> user) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: _deepSurfaceColor,
                foregroundColor: AppColors.gold,
                child: Text(
                  user['initial']!,
                  style: GoogleFonts.cinzel(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user['name']!,
                style: GoogleFonts.merriweather(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                user['user']!,
                style: GoogleFonts.inter(color: AppColors.accent, fontSize: 9),
              ),
              const SizedBox(height: 10),
              Text(
                user['bio']!,
                textAlign: TextAlign.center,
                style: GoogleFonts.merriweather(fontSize: 9, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
