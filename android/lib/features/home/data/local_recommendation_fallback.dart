import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';

import '../../gutendex/models/free_work.dart';
import 'home_recommendation_repository.dart';
import 'recommendation_titles.dart';
import 'spanish_recommendations.dart';

/// Last resort from the reviewed, bundled collection. No fabricated Google IDs.
class LocalRecommendationFallbackRepository
    implements HomeRecommendationRepository {
  LocalRecommendationFallbackRepository(
    this.source,
    List<Map<String, dynamic>> saved,
  ) : saved = saved
          .map((b) => Map<String, dynamic>.unmodifiable(b))
          .toList(growable: false);
  final HomeRecommendationRepository source;
  final List<Map<String, dynamic>> saved;
  final int _rotation = DateTime.now().millisecondsSinceEpoch ~/ 60000;
  int _order(String id) {
    var hash = 17;
    for (final unit in '$accountScope:$_rotation:$id'.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  @override
  String get accountScope => source.accountScope;
  @override
  bool get supportsGemini => source.supportsGemini;
  @override
  Future<HomeRecommendations> load() async {
    try {
      return _complete(await source.load());
    } catch (error) {
      if (error is ApiFailure &&
          const {401, 403, 409}.contains(error.statusCode)) {
        rethrow;
      }
      final fallback = _complete(
        const HomeRecommendations(
          personalized: true,
          notice: 'Google Books no respondió. Sólo se muestran obras locales relacionadas verificadas.',
        ),
      );
      if (fallback.items.isEmpty) {
        rethrow;
      }
      return fallback;
    }
  }

  @override
  Future<HomeRecommendations> enrich(String candidateSetId) async =>
      _complete(await source.enrich(candidateSetId));
  static String key(Object? s) => RecommendationTitles.key(s?.toString() ?? '');
  static Set<String> genres(Iterable<Object?> values) {
    final result = <String>{};
    for (final value in values) {
      for (final part in (value?.toString() ?? '').split(RegExp(r'[,/;>:]'))) {
        final normalized = key(part);
        final genre = switch (normalized) {
          'fiction' || 'novela' || 'novelas' => 'ficcion',
          'fantasy' => 'fantasia',
          'history' => 'historia',
          'short stories' || 'cuento' => 'cuentos',
          'poetry' => 'poesia',
          'science fiction' => 'ciencia ficcion',
          'horror' => 'terror',
          _ => normalized,
        };
        if (genre.isNotEmpty && genre != 'general') {
          result.add(genre);
        }
      }
    }
    return result;
  }

  HomeRecommendations _complete(HomeRecommendations base) {
    final ownedTitles = saved.map((b) => key(b['title'])).toSet();
    final ownedIds = saved
        .map((b) => b['googleVolumeId'])
        .whereType<String>()
        .toSet();
    final ownedLocal = saved
        .map((b) => b['freeWorkId'])
        .whereType<String>()
        .toSet();
    final authors = <String>{};
    final topics = <String>{};
    for (final book in saved) {
      final metadata = book['googleBooks'];
      authors.add(key(book['author']));
      if (metadata is Map) {
        authors.addAll((metadata['authors'] as List? ?? []).map(key));
      }
      topics.addAll(
        genres([
          book['genre'],
          if (metadata is Map) ...(metadata['categories'] as List? ?? []),
        ]),
      );
    }
    authors.removeAll({
      '',
      'anonimo',
      'autor desconocido',
      'desconocido',
      'autor no disponible',
    });
    final ids = <String>{};
    final items = RecommendationTitles.unique(
      base.items.where((b) {
        final id =
            b['googleVolumeId']?.toString() ??
            b['freeWorkId']?.toString() ??
            '';
        return SpanishRecommendations.accepts(b) &&
            id.isNotEmpty &&
            ids.add(id) &&
            !ownedIds.contains(id) &&
            !ownedLocal.contains(id) &&
            !ownedTitles.contains(key(b['title']));
      }).toList(),
    ).take(5).toList();
    final titles = items.map((b) => key(b['title'])).toSet();
    final ranked = freeWorks
        .where(
          (work) =>
              work.available &&
              work.language == 'es' &&
              !ownedLocal.contains(work.id) &&
              !ownedTitles.contains(key(work.title)) &&
              !titles.contains(key(work.title)) &&
              (saved.length <= 2 ||
                  authors.contains(key(work.author)) ||
                  genres([work.genre]).intersection(topics).isNotEmpty),
        )
        .toList();
    int relevance(FreeWork work) => authors.contains(key(work.author))
        ? 2
        : genres([work.genre]).intersection(topics).isNotEmpty
        ? 1
        : 0;
    ranked.sort((a, b) {
      final score = relevance(b).compareTo(relevance(a));
      return score != 0 ? score : _order(a.id).compareTo(_order(b.id));
    });
    var added = 0, relatedAdded = 0;
    final varietyGenres = <String>{};
    for (final relaxed in [false, true]) {
      for (final work in ranked) {
        if (items.length >= 5) {
          break;
        }
        final topic = genres([work.genre]).firstOrNull ?? 'sin genero';
        if (!relaxed && relevance(work) == 0 && varietyGenres.contains(topic)) {
          continue;
        }
        if (!titles.add(key(work.title))) {
          continue;
        }
        items.add({
          'id': work.id,
          'freeWorkId': work.id,
          'recommendationSource': 'LOCAL_FREE',
          'title': work.title,
          'author': work.author,
          'language': work.language,
          'genre': work.genre ?? '',
          'cover': '',
          'synopsis': work.edition,
          'availability': 'GRATIS',
          'recommendationReason':
              'Biblioteca gratuita local · ${relevance(work) == 2
                  ? 'autor de tus lecturas'
                  : relevance(work) == 1
                  ? 'género relacionado: ${work.genre}'
                  : 'clásico en español · selección variada'}',
        });
        added++;
        if (relevance(work) > 0) {
          relatedAdded++;
        } else {
          varietyGenres.add(topic);
        }
      }
    }
    debugPrint(
      'recommendation_completion remote=${base.items.length} local=$added selected=${items.length} stop=${items.length >= 5 ? 'TARGET_REACHED' : 'NO_MORE_RELEVANT_LOCAL_WORKS'}',
    );
    return HomeRecommendations(
      candidateSetId: base.candidateSetId,
      personalized: base.personalized || relatedAdded > 0,
      items: RecommendationTitles.unique(items).take(5).toList(),
      aiStatus: base.aiStatus,
      geminiAvailable: base.geminiAvailable,
      notice: added == 0
          ? base.notice
          : '${base.notice} Incluye $added obras de la Biblioteca gratuita local, disponibles sin conexión.',
    );
  }
}
