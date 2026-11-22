import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/home_recommendation_repository.dart';
import '../data/recommendation_titles.dart';
import '../data/spanish_recommendations.dart';

class HomeRecommendationController extends ChangeNotifier {
  HomeRecommendationController(this.repository);
  final HomeRecommendationRepository repository;
  HomeRecommendations? data;
  bool loading = false;
  bool enriching = false;
  String? error;
  String? aiMessage;
  bool _disposed = false;
  int _generation = 0;

  Future<void> load() async {
    if (loading || enriching || _disposed) return;
    final generation = ++_generation;
    loading = true;
    error = null;
    aiMessage = null;
    notifyListeners();
    try {
      final value = await repository.load();
      if (!_disposed && generation == _generation) data = _unique(value);
    } catch (_) {
      if (!_disposed && generation == _generation) {
        error =
            'No pudimos actualizar Google Books. Tus lecturas se conservan.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> enrich() async {
    final previous = data;
    if (_disposed ||
        loading ||
        enriching ||
        previous == null ||
        !previous.personalized ||
        !previous.geminiAvailable ||
        previous.items.isEmpty ||
        !repository.supportsGemini ||
        previous.aiStatus == 'ENRICHED') {
      return;
    }
    final generation = ++_generation;
    enriching = true;
    aiMessage = null;
    notifyListeners();
    try {
      final value = await repository.enrich(previous.candidateSetId);
      if (_disposed || generation != _generation) return;
      if (value.candidateSetId != previous.candidateSetId ||
          value.items.any(
            (book) => !previous.items.any(
              (old) =>
                  (old['googleVolumeId'] ?? old['freeWorkId']) ==
                  (book['googleVolumeId'] ?? book['freeWorkId']),
            ),
          )) {
        aiMessage = 'La selección de IA no fue válida. Conservamos las recomendaciones de Biblioteca.';
      } else if (value.aiStatus == 'ENRICHED') {
        data = _unique(
          HomeRecommendations(
            candidateSetId: value.candidateSetId,
            personalized: value.personalized,
            items: [...value.items, ...previous.items],
            aiStatus: value.aiStatus,
            geminiAvailable: value.geminiAvailable,
            notice: value.notice,
          ),
        );
      } else {
        if (!value.geminiAvailable) {
          data = HomeRecommendations(
            candidateSetId: previous.candidateSetId,
            personalized: previous.personalized,
            items: previous.items,
            aiStatus: previous.aiStatus,
            notice: previous.notice,
          );
        }
        aiMessage = switch (value.aiStatus) {
          'NOT_CONFIGURED' || 'NOT_AVAILABLE' =>
            'La selección inteligente no está disponible por ahora.',
          'QUOTA' ||
          'BUSY' => 'Gemini alcanzó su límite de uso. Intenta más tarde.',
          'TIMEOUT' => 'Gemini tardó demasiado. Puedes reintentar.',
          'INVALID' => 'Gemini no entregó una selección verificable.',
          _ => 'Gemini no está disponible. Puedes reintentar.',
        };
      }
    } catch (e) {
      if (!_disposed && generation == _generation) {
        aiMessage = e is ApiFailure && e.statusCode == 409
            ? 'Tu Biblioteca o la sesión de candidatos cambió. Actualiza las recomendaciones.'
            : 'Gemini no respondió. Conservamos las recomendaciones de Biblioteca.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        enriching = false;
        notifyListeners();
      }
    }
  }

  HomeRecommendations _unique(HomeRecommendations value) {
    final seenIds = <String>{};
    final items =
        RecommendationTitles.unique(
              value.items.where(SpanishRecommendations.accepts).toList(),
            )
            .where((book) {
              final id =
                  (book['googleVolumeId'] ?? book['freeWorkId'] ?? book['id'])
                      ?.toString();
              return id == null || seenIds.add(id);
            })
            .take(5)
            .toList(growable: false);
    return HomeRecommendations(
      candidateSetId: value.candidateSetId,
      personalized: value.personalized,
      items: items,
      aiStatus: value.aiStatus,
      geminiAvailable: value.geminiAvailable,
      notice: items.length < 5 && !value.notice.contains('obras verificables')
          ? '${value.notice} Hay ${items.length} obras verificables en español; no se completa con otros idiomas.'
          : value.notice,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
