import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import 'home_network_cover.dart';
import 'home_section_title.dart';

class RecommendedBooksSection extends StatelessWidget {
  const RecommendedBooksSection({
    super.key,
    required this.books,
    required this.carouselOffset,
    required this.onPrevious,
    required this.onNext,
    required this.onBookTap,
  });

  final List<Map<String, dynamic>> books;
  final int carouselOffset;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<Map<String, dynamic>> onBookTap;

  @override
  Widget build(BuildContext context) {
    final maxOffset = max(0, books.length - 3);
    final visible = books.skip(carouselOffset).take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: HomeSectionTitle('Lecturas Recomendadas'),
                ),
                _CarouselButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: carouselOffset > 0,
                  onTap: onPrevious,
                ),
                const SizedBox(width: 6),
                _CarouselButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: carouselOffset < maxOffset,
                  onTap: onNext,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(visible.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < visible.length - 1 ? 7 : 0,
                    ),
                    child: SizedBox(
                      height: 226,
                      child: _RecommendedBookCard(
                        book: visible[index],
                        onTap: () => onBookTap(visible[index]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselButton extends StatelessWidget {
  const _CarouselButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.goldOf(context);
    final deep = AppColors.deepOf(context);
    final surface = AppColors.surfaceOf(context);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.35,
        duration: const Duration(milliseconds: 180),
        child: Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? deep : surface,
            border: Border.all(color: gold),
          ),
          child: Icon(icon, color: gold, size: 16),
        ),
      ),
    );
  }
}

class _RecommendedBookCard extends StatelessWidget {
  const _RecommendedBookCard({
    required this.book,
    required this.onTap,
  });

  final Map<String, dynamic> book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final gold = AppColors.goldOf(context);
    final accent = AppColors.accentOf(context);

    final author = book['author'] as String;
    final isUserAuthor = author.startsWith('@');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: gold.withValues(alpha: 0.72),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 122,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HomeNetworkCover(
                    url: book['cover'] as String,
                    width: double.infinity,
                    height: 122,
                    radius: 0,
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.03),
                              Colors.black.withValues(alpha: 0.20),
                            ],
                            stops: const [0.45, 0.72, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.merriweather(
                        color: textPrimary,
                        fontSize: 8.4,
                        fontWeight: FontWeight.w700,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isUserAuthor ? accent : gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: isUserAuthor ? accent : textSecondary,
                              fontSize: 6.8,
                              fontWeight: isUserAuthor
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E793E)
                            .withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF2E793E)
                              .withValues(alpha: 0.34),
                        ),
                      ),
                      child: Text(
                        'GRATIS',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2E793E),
                          fontSize: 5.6,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: gold,
                            size: 10.5,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${book['rating']}',
                            style: GoogleFonts.inter(
                              color: textPrimary,
                              fontSize: 6.7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
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
