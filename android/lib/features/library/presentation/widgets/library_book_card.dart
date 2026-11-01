import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/book_review.dart';
import '../../models/book_status.dart';
import '../../models/library_book.dart';

class LibraryBookCard extends StatelessWidget {
  const LibraryBookCard({
    super.key,
    required this.book,
    required this.status,
    required this.progress,
    required this.review,
    required this.onOpen,
    required this.onStartReading,
    required this.onAdvance,
    required this.onFinish,
    required this.onReviewTap,
  });

  final LibraryBook book;
  final BookStatus status;
  final int progress;
  final BookReview? review;
  final VoidCallback onOpen;
  final VoidCallback onStartReading;
  final VoidCallback onAdvance;
  final VoidCallback onFinish;
  final VoidCallback onReviewTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepOf(context).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(url: book.cover, width: 62, height: 88),
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
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.author,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (status == BookStatus.leyendo) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Progreso',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondaryOf(context),
                              fontSize: 7.5,
                            ),
                          ),
                        ),
                        Text(
                          '$progress%',
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _ProgressBar(value: progress / 100),
                    const SizedBox(height: 8),
                  ],
                  if (status == BookStatus.leido && review != null) ...[
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < review!.rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 12,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          review!.isPublic
                              ? 'Reseña pública'
                              : 'Reseña privada',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                  ],
                  _StatusActions(
                    status: status,
                    hasReview: review != null,
                    onStartReading: onStartReading,
                    onAdvance: onAdvance,
                    onFinish: onFinish,
                    onReviewTap: onReviewTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.status,
    required this.hasReview,
    required this.onStartReading,
    required this.onAdvance,
    required this.onFinish,
    required this.onReviewTap,
  });

  final BookStatus status;
  final bool hasReview;
  final VoidCallback onStartReading;
  final VoidCallback onAdvance;
  final VoidCallback onFinish;
  final VoidCallback onReviewTap;

  @override
  Widget build(BuildContext context) {
    if (status == BookStatus.porLeer) {
      return _PrimaryButton(
        label: 'Comenzar lectura',
        onTap: onStartReading,
      );
    }

    if (status == BookStatus.leyendo) {
      return Row(
        children: [
          Expanded(
            child: _PrimaryButton(
              label: '+ Avanzar',
              onTap: onAdvance,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SecondaryButton(
              label: 'Finalizar ✓',
              onTap: onFinish,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 34,
      child: hasReview
          ? OutlinedButton.icon(
              onPressed: onReviewTap,
              icon: const Icon(
                Icons.rate_review_outlined,
                size: 13,
              ),
              label: Text(
                'Ver / editar reseña',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentOf(context),
                backgroundColor:
                    AppColors.accentOf(context).withValues(alpha: 0.05),
                side: BorderSide(
                  color: AppColors.accentOf(context)
                      .withValues(alpha: 0.45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: onReviewTap,
              icon: const Icon(
                Icons.star_outline_rounded,
                size: 14,
              ),
              label: Text(
                'Calificar y reseñar',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepOf(context),
                foregroundColor: AppColors.goldOf(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          minimumSize: const Size(0, 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryOf(context),
          side: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.85),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      BookStatus.leyendo => ('LEYENDO', AppColors.accent),
      BookStatus.porLeer => ('POR LEER', AppColors.gold),
      BookStatus.leido => ('LEÍDO', AppColors.textPrimaryOf(context)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.65),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 6.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.surfaceSoftOf(context),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0).toDouble(),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold,
                      AppColors.accent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.url,
    required this.width,
    required this.height,
  });

  final String url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return Container(
              color: AppColors.deepOf(context),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.gold,
              ),
            );
          },
        ),
      ),
    );
  }
}
