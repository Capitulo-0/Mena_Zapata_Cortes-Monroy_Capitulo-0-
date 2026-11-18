import '../../../core/network/api_client.dart';
import 'spanish_recommendations.dart';
import '../../catalog/data/catalog_repository.dart';

class HomeRecommendations {
  const HomeRecommendations({
    this.candidateSetId = '',
    this.personalized = false,
    this.items = const [],
    this.aiStatus = 'NORMAL',
    this.geminiAvailable = false,
    this.notice = '',
  });
  final String candidateSetId;
  final bool personalized;
  final List<Map<String, dynamic>> items;
  final String aiStatus;
  final bool geminiAvailable;
  final String notice;
}

abstract interface class HomeRecommendationRepository {
  String get accountScope;
  bool get supportsGemini;
  Future<HomeRecommendations> load();
  Future<HomeRecommendations> enrich(String candidateSetId);
}

/// Uses the existing authenticated transport and Google Books presentation contract.
class ApiHomeRecommendationRepository implements HomeRecommendationRepository {
  ApiHomeRecommendationRepository(this.api, this.accountScope);
  final ApiClient api;
  @override
  final String accountScope;
  @override
  bool get supportsGemini => true;

  HomeRecommendations _parse(Object? rawData) {
    final data = Map<String, dynamic>.from(rawData as Map);
    final seen = <String>{};
    final items = <Map<String, dynamic>>[];
    for (final raw in data['items'] as List? ?? []) {
      final item = Map<String, dynamic>.from(raw as Map);
      final book = Map<String, dynamic>.from(item['book'] as Map);
      final id = book['volumeId'] as String? ?? '';
      if (id.isEmpty ||
          !seen.add(id) ||
          !SpanishRecommendations.accepts(
            ApiCatalogRepository.presentation(book),
          )) {
        continue;
      }
      items.add({
        ...ApiCatalogRepository.presentation(book),
        'recommendationReason': item['reason'] as String? ?? '',
      });
    }
    return HomeRecommendations(
      candidateSetId: data['candidateSetId'] as String? ?? '',
      personalized: data['personalized'] == true,
      items: items,
      aiStatus: data['aiStatus'] as String? ?? 'NORMAL',
      geminiAvailable: data['geminiAvailable'] == true,
      notice: data['notice'] as String? ?? '',
    );
  }

  @override
  Future<HomeRecommendations> load() async => _parse(
    await api.requestJson(
      'GET',
      '/api/me/recommendations',
      expectedUid: accountScope,
    ),
  );

  @override
  Future<HomeRecommendations> enrich(String candidateSetId) async => _parse(
    await api.requestJson(
      'POST',
      '/api/me/recommendations/gemini',
      expectedUid: accountScope,
      body: {'candidateSetId': candidateSetId},
    ),
  );
}

/// Guest/offline test-shell exploration never claims to know personal preferences.
class ExplorationRecommendationRepository
    implements HomeRecommendationRepository {
  ExplorationRecommendationRepository(this.catalog, this.accountScope);
  final CatalogRepository? catalog;
  @override
  final String accountScope;
  @override
  bool get supportsGemini => false;
  @override
  Future<HomeRecommendations> load() async {
    final source = catalog;
    final page = source is ApiCatalogRepository
        ? await source.searchSpanish('subject:fiction')
        : await source?.search('subject:fiction');
    final seen = <String>{};
    return HomeRecommendations(
      notice: 'Exploración general · Fuente: Google Books',
      items: (page?.items ?? []).where((book) {
        final id = book['googleVolumeId'] as String?;
        return id != null &&
            id.isNotEmpty &&
            seen.add(id) &&
            SpanishRecommendations.accepts(book);
      }).toList(),
    );
  }

  @override
  Future<HomeRecommendations> enrich(String candidateSetId) => load();
}
