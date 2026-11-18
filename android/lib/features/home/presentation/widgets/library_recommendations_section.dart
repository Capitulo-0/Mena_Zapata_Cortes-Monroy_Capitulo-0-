import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../home_recommendation_controller.dart';
import '../../data/home_recommendation_repository.dart';
import 'recommended_books_section.dart';
import '../../data/recommendation_titles.dart';
import 'recommendation_explanation.dart';

/// Compact controls; individual reasons live on their cards, not in a repeated text block.
class LibraryRecommendationsSection extends StatefulWidget {
  const LibraryRecommendationsSection({
    super.key,
    required this.controller,
    required this.onBookTap,

    this.showBooks = true,
    this.carouselOffset,
    this.explanation,
    this.onShowExplanation,
    this.onCloseExplanation,
  });
  final String? explanation;
  final ValueChanged<String>? onShowExplanation;
  final VoidCallback? onCloseExplanation;
  final bool showBooks;
  final int? carouselOffset;
  final HomeRecommendationController controller;
  final ValueChanged<Map<String, dynamic>> onBookTap;

  @override
  State<LibraryRecommendationsSection> createState() =>
      _LibraryRecommendationsSectionState();
}

class _LibraryRecommendationsSectionState
    extends State<LibraryRecommendationsSection> {
  int offset = 0;
  HomeRecommendations? _visibleSet;
  String? _explanation;
  final _explanationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.explanation != null) _revealExplanation();
  }

  void _revealExplanation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final panel = _explanationKey.currentContext;
      if (mounted &&
          panel != null &&
          ModalRoute.of(panel)?.isCurrent != false) {
        Scrollable.ensureVisible(
          panel,
          alignment: .5,
          duration: const Duration(milliseconds: 180),
        );
      }
    });
  }

  void _showExplanation(String message) {
    if (widget.onShowExplanation != null) {
      widget.onShowExplanation!(message);
    } else {
      setState(() => _explanation = message);
      _revealExplanation();
    }
  }

  void _closeExplanation() {
    if (widget.onCloseExplanation != null) {
      widget.onCloseExplanation!();
    } else {
      setState(() => _explanation = null);
    }
  }

  @override
  void didUpdateWidget(covariant LibraryRecommendationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      offset = 0;
      _explanation = null;
    }
    if (oldWidget.explanation != widget.explanation &&
        widget.explanation != null) {
      _revealExplanation();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final explanation = widget.onShowExplanation == null
          ? _explanation
          : widget.explanation;
      final data = controller.data;
      if (!identical(data, _visibleSet)) {
        offset = 0;
        _visibleSet = data;
      }
      final items = RecommendationTitles.unique(
        data?.items ?? <Map<String, dynamic>>[],
      ).take(5).toList();
      final start = min(
        widget.carouselOffset ?? offset,
        items.isEmpty ? 0 : ((items.length - 1) ~/ 3) * 3,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.loading || controller.enriching)
            const LinearProgressIndicator(
              key: ValueKey('recommendations-loading'),
            ),
          if (widget.showBooks)
            RecommendedBooksSection(
              heading: data?.personalized == true
                  ? 'Recomendado para ti'
                  : 'Exploración general',
              books: items,
              carouselOffset: start,
              onPrevious: () => setState(() {
                offset = max(0, start - 3);
                _explanation = null;
              }),
              onNext: () => setState(() {
                offset = min(
                  items.isEmpty ? 0 : ((items.length - 1) ~/ 3) * 3,
                  start + 3,
                );
                _explanation = null;
              }),
              onBookTap: widget.onBookTap,
              onShowExplanation: _showExplanation,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (explanation != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RecommendationExplanation(
                      key: _explanationKey,
                      message: explanation,
                      onClose: _closeExplanation,
                    ),
                  ),
                if (items.isEmpty &&
                    !controller.loading &&
                    controller.error == null)
                  const Text(
                    'Aún no hay sugerencias relacionadas. Añade lecturas con autor o categoría y actualiza.',
                    style: TextStyle(fontSize: 12),
                  ),
                if (controller.error != null)
                  Text(
                    controller.error!,
                    key: const ValueKey('recommendations-error'),
                    style: const TextStyle(fontSize: 12),
                  ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      'Español · ${items.length} obras',
                      semanticsLabel:
                          items.any(
                            (b) => b['recommendationSource'] == 'LOCAL_FREE',
                          )
                          ? 'Fuentes: Google Books y Biblioteca gratuita local'
                          : 'Fuente: Google Books',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: .15,
                        color: AppColors.textPrimaryOf(context)
                            .withValues(alpha: .85),
                      ),
                    ),
                    if (data?.aiStatus == 'ENRICHED')
                      Text(
                        'Selección con Gemini',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    if (data?.notice.isNotEmpty == true)
                      RecommendationInfoButton(
                        message: data!.notice,
                        onPressed: () => _showExplanation(data.notice),
                      ),
                    if (controller.error == null)
                      IconButton(
                        key: const ValueKey('recommendations-refresh'),
                        tooltip: 'Actualizar recomendaciones',
                        icon: const Icon(Icons.refresh, size: 19),
                        onPressed: controller.loading || controller.enriching
                            ? null
                            : controller.load,
                      )
                    else
                      TextButton(
                        key: const ValueKey('recommendations-refresh'),
                        onPressed: controller.loading || controller.enriching
                            ? null
                            : controller.load,
                        child: const Text(
                          'Google Books: no disponible. Reintentar',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
