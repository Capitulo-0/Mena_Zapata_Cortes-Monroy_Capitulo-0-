part of '../screens/manage_story_screen.dart';

extension _ManageStoryChaptersSection on _ManageStoryScreenState {
  Widget _buildChapterHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CAPÍTULOS'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_story.chapterCount} capítulos · '
                '${_story.publishedChapterCount} publicados · '
                '${_story.draftChapterCount} '
                '${_story.draftChapterCount == 1 ? 'borrador' : 'borradores'}',
                style: GoogleFonts.inter(
                  fontSize: 6.8,
                  color: _textSecondaryColor,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.swap_vert_rounded, size: 11),
              label: Text(
                'Ordenar',
                style: GoogleFonts.inter(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyChapters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 31,
            color: AppColors.accent,
          ),
          const SizedBox(height: 10),
          Text(
            'Aún no has creado capítulos',
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textPrimaryColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Presiona “+ Nuevo capítulo” para comenzar.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 7.5,
              height: 1.45,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(WriterChapter chapter) {
    final published = chapter.isPublished;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: published
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.gold.withValues(alpha: 0.28),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: published
                    ? AppColors.accent
                    : AppColors.gold.withValues(alpha: 0.75),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(13),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 9, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _deepColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.40),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            chapter.order.toString().padLeft(2, '0'),
                            style: GoogleFonts.cinzel(
                              fontSize: 6.8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapter.title.isEmpty
                                    ? 'Capítulo sin título'
                                    : chapter.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.merriweather(
                                  fontSize: 9.8,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: published
                                          ? AppColors.accent
                                          : AppColors.gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    published ? 'PUBLICADO' : 'BORRADOR',
                                    style: GoogleFonts.inter(
                                      fontSize: 5.8,
                                      fontWeight: FontWeight.w800,
                                      color: published
                                          ? AppColors.accent
                                          : AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 39),
                      child: Row(
                        children: [
                          Icon(
                            published
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.remove_rounded,
                            size: 9,
                            color: published
                                ? const Color(0xFFB9A4D8)
                                : AppColors.gold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            published
                                ? '${chapter.wordCount} palabras'
                                : 'Sin publicar',
                            style: GoogleFonts.inter(
                              fontSize: 6.5,
                              color: _textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Divider(
                      height: 1,
                      color: AppColors.gold.withValues(alpha: 0.14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _openEditChapter(chapter),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _headingColor,
                            side: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.40),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Editar',
                                style: GoogleFonts.inter(
                                  fontSize: 6.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 11,
                              ),
                            ],
                          ),
                        ),
                        if (!published) ...[
                          const SizedBox(width: 6),
                          FilledButton.icon(
                            onPressed: () =>
                                _toggleChapterPublication(chapter),
                            icon: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 10,
                            ),
                            label: Text(
                              'Publicar',
                              style: GoogleFonts.inter(
                                fontSize: 6.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 3),
                        PopupMenuButton<String>(
                          tooltip: 'Opciones del capítulo',
                          color: _surfaceColor,
                          onSelected: (value) {
                            switch (value) {
                              case 'publish':
                                _toggleChapterPublication(chapter);
                                break;
                              case 'delete':
                                _deleteChapter(chapter);
                                break;
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem<String>(
                              value: 'publish',
                              child: Text(
                                chapter.isPublished
                                    ? 'Volver a borrador'
                                    : 'Publicar capítulo',
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Eliminar capítulo'),
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 15,
                              color: _textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
