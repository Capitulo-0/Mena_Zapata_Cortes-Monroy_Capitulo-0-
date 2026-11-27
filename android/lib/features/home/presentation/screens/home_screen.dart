import 'dart:async';
import 'dart:convert';

import '../../../catalog/data/catalog_repository.dart';
import '../../data/home_recommendation_repository.dart';
import '../../data/local_recommendation_fallback.dart';
import '../../data/recommendation_titles.dart';
import '../../../gutendex/models/free_work.dart';
import '../../../gutendex/presentation/screens/free_library_screen.dart';
import '../home_recommendation_controller.dart';
import '../../../gutendex/presentation/screens/gutendex_catalog_screen.dart';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../profile/data/user_search_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/home_quotes.dart';

import '../dialogs/home_isbn_scanner_dialog.dart';
import '../dialogs/home_gemini_selection_dialog.dart';
import '../widgets/home_quote_section.dart';
import '../widgets/home_search_section.dart';
import 'home_book_detail_screen.dart';
import '../widgets/community_stories_section.dart';
import '../widgets/continue_reading_section.dart';
import '../widgets/home_welcome_section.dart';
import '../widgets/nearby_reading_point_section.dart';
import '../../../maps/models/map_point.dart';
import '../widgets/reading_clubs_section.dart';
import '../widgets/library_recommendations_section.dart';
import '../widgets/recommended_books_section.dart';
import '../../../clubs/models/reading_club.dart';
import '../../../clubs/data/reading_club_repository.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../writer/models/writer_story.dart';
import '../../../writer/models/writer_publication.dart';
import '../../../writer/services/writer_repository.dart';
import '../../../writer/presentation/screens/published_story_screen.dart';
import 'community_publications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onReadBook,
    this.catalogBooks,
    this.catalogRepository,
    this.recommendationRepository,

    this.userSearchRepository,
    this.communityWriterRepository,
    this.progresses = const {},
    this.statuses = const {},
    this.onBookStatusChanged,
    this.finishedReadingTitle,
    this.onAddBook,
    required this.isGuest,
    required this.onGuestRestrictedAction,
    required this.onOpenLibrary,
    required this.onOpenWriter,
    required this.onOpenPoints,
    this.onOpenNearbyPoint,
    required this.onOpenProfile,
    this.onOpenUserProfile,
    required this.currentName,
    required this.currentUsername,
    required this.reviews,
    required this.onReviewSaved,
    required this.favoriteBookIds,
    required this.onToggleFavoriteBook,
    required this.favoriteCommunityStoryIds,
    required this.onToggleCommunityStoryFavorite,
    required this.clubs,
    this.readingClubRepository,
    required this.joinedClubIds,
    required this.onToggleClub,
    required this.continueReadingBook,
    required this.continueReadingProgress,
    required this.onContinueReadingProgressChanged,
  });

  final CatalogRepository? catalogRepository;
  final HomeRecommendationRepository? recommendationRepository;

  final UserSearchRepository? userSearchRepository;
  final CommunityWriterRepository? communityWriterRepository;
  final List<Map<String, dynamic>>? catalogBooks;
  final Future<int?> Function(BuildContext context, int bookId)? onReadBook;
  final Map<int, int> progresses;
  final Map<int, BookStatus> statuses;
  final FutureOr<void> Function(int bookId, BookStatus status)?
  onBookStatusChanged;
  final String? finishedReadingTitle;
  final FutureOr<void> Function(Map<String, dynamic>)? onAddBook;

  final bool isGuest;
  final VoidCallback onGuestRestrictedAction;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenWriter;
  final VoidCallback onOpenPoints;
  final ValueChanged<MapPoint>? onOpenNearbyPoint;
  final VoidCallback onOpenProfile;
  final ValueChanged<String>? onOpenUserProfile;
  final String currentName;
  final String currentUsername;
  final Map<int, BookReview> reviews;
  final void Function(int bookId, BookReview review) onReviewSaved;

  final Set<int> favoriteBookIds;
  final ValueChanged<int> onToggleFavoriteBook;

  final Set<String> favoriteCommunityStoryIds;
  final ValueChanged<WriterStory> onToggleCommunityStoryFavorite;

  final List<ReadingClub> clubs;
  final ReadingClubRepository? readingClubRepository;
  final Set<int> joinedClubIds;
  final FutureOr<void> Function(int) onToggleClub;

  final LibraryBook? continueReadingBook;
  final int continueReadingProgress;
  final FutureOr<void> Function(int bookId, int progress)
  onContinueReadingProgressChanged;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool searchSubmitted = false;
  bool _openingBook = false;
  late HomeRecommendationController _recommendations;
  String _recommendationRevision = '';
  String? _recommendationExplanation;

  bool _geminiDialogOpen = false;
  BuildContext? _geminiDialogContext;
  int carouselOffset = 0;
  HomeRecommendations? _visibleRecommendations;

  @override
  void initState() {
    super.initState();
    _bindRecommendations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) reloadCommunityStories();
    });
  }

  String _revision() {
    final catalog = widget.catalogRepository;
    final scope = widget.isGuest
        ? 'guest'
        : catalog is ApiCatalogRepository
        ? catalog.api.auth.currentUser?.uid ?? ''
        : widget.currentUsername;
    final personal =
        !widget.isGuest &&
        (catalog is ApiCatalogRepository ||
            widget.recommendationRepository != null);
    return jsonEncode([
      scope,
      if (personal) widget.catalogBooks,
      if (personal)
        widget.statuses.map((key, value) => MapEntry('$key', value.name)),
    ]);
  }

  void _bindRecommendations() {
    _recommendationExplanation = null;
    carouselOffset = 0;
    _recommendationRevision = _revision();
    final catalog = widget.catalogRepository;
    final uid = catalog is ApiCatalogRepository
        ? catalog.api.auth.currentUser?.uid
        : null;
    final remoteRepository =
        widget.recommendationRepository ??
        (!widget.isGuest && catalog is ApiCatalogRepository && uid != null
            ? ApiHomeRecommendationRepository(catalog.api, uid)
            : ExplorationRecommendationRepository(
                catalog,
                widget.isGuest ? 'guest' : widget.currentUsername,
              ));
    final repository = remoteRepository is ApiHomeRecommendationRepository
        ? LocalRecommendationFallbackRepository(
            remoteRepository,
            widget.catalogBooks ?? [],
          )
        : remoteRepository;
    _recommendations = HomeRecommendationController(repository)
      ..addListener(_catalogChanged);
    unawaited(_recommendations.load());
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_recommendationRevision != _revision() ||
        oldWidget.catalogRepository != widget.catalogRepository ||
        oldWidget.recommendationRepository != widget.recommendationRepository) {
      _dismissGeminiDialog();
      _recommendations
        ..removeListener(_catalogChanged)
        ..dispose();
      _bindRecommendations();
    }
    if (oldWidget.communityWriterRepository !=
            widget.communityWriterRepository ||
        oldWidget.currentUsername != widget.currentUsername ||
        oldWidget.isGuest != widget.isGuest) {
      reloadCommunityStories();
    }
  }

  void _catalogChanged() {
    if (!identical(_visibleRecommendations, _recommendations.data)) {
      carouselOffset = 0;
      _visibleRecommendations = _recommendations.data;
    }
    if (mounted) setState(() {});
  }

  void _dismissGeminiDialog() {
    final dialogContext = _geminiDialogContext;
    _geminiDialogContext = null;
    if (dialogContext == null || !dialogContext.mounted) return;
    final route = ModalRoute.of(dialogContext);
    final navigator = Navigator.of(dialogContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted && route != null && route.isActive) {
        navigator.removeRoute(route);
      }
    });
  }

  @override
  void dispose() {
    _dismissGeminiDialog();
    _recommendations
      ..removeListener(_catalogChanged)
      ..dispose();
    super.dispose();
  }

  // Colores adaptativos al tema global.
  Color get _background => AppColors.backgroundOf(context);
  Color get _surface => AppColors.surfaceOf(context);
  Color get _surfaceSoft => AppColors.surfaceSoftOf(context);
  Color get _deepSurface => AppColors.deepOf(context);
  Color get _textPrimary => AppColors.textPrimaryOf(context);
  Color get _textSecondary => AppColors.textSecondaryOf(context);
  Color get _gold => AppColors.goldOf(context);
  Color get _accent => AppColors.accentOf(context);

  // Colores de contenido sobre fondos oscuros, burdeos o dorados.
  Color get _onAccent => AppColors.isDark(context)
      ? AppColors.darkTextPrimary
      : AppColors.background;

  final List<Map<String, String>> quotes = HomeQuotes.quotes
      .map(Map<String, String>.from)
      .toList();

  List<Map<String, dynamic>> get books =>
      (widget.catalogRepository == null
          ? null
          : _recommendations.data?.items) ??
      widget.catalogBooks ??
      const <Map<String, dynamic>>[];

  List<WriterPublication> _communityPublications = [];
  bool _communityLoading = false;
  String? _communityError;
  int _communityRequest = 0;
  String? _openingPublication;

  Future<void> reloadCommunityStories() async {
    final request = ++_communityRequest;
    final repository = widget.communityWriterRepository;
    if (widget.isGuest || repository == null) {
      if (mounted) {
        setState(() {
          _communityPublications = [];
          _communityLoading = false;
          _communityError = null;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _communityLoading = true;
        _communityError = null;
      });
    }
    try {
      final publications = await repository.getPublications();
      if (mounted && request == _communityRequest) {
        setState(() => _communityPublications = publications);
      }
    } catch (_) {
      if (mounted && request == _communityRequest) {
        setState(() => _communityError = 'No pudimos cargar las historias.');
      }
    } finally {
      if (mounted && request == _communityRequest) {
        setState(() => _communityLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            if (!searchSubmitted) _buildWelcome(),
            if (_openingBook) const LinearProgressIndicator(),
            HomeSearchSection(
              key: const ValueKey('home-search'),
              catalogRepository: widget.catalogRepository,
              userSearchRepository: widget.userSearchRepository,
              books: books,
              onBookTap: _showBookDetails,
              onUserTap: widget.onOpenUserProfile,
              onSearchModeChanged: (submitted) {
                if (!mounted || searchSubmitted == submitted) {
                  return;
                }

                setState(() {
                  searchSubmitted = submitted;
                });
              },
            ),
            if (!searchSubmitted) ...[
              HomeQuoteSection(quotes: quotes),
              _buildContinueReading(),
              _buildRecommendedBooks(),
              LibraryRecommendationsSection(
                controller: _recommendations,
                onBookTap: _showBookDetails,

                showBooks: false,
                explanation: _recommendationExplanation,
                onShowExplanation: _showRecommendationExplanation,
                onCloseExplanation: () =>
                    setState(() => _recommendationExplanation = null),
                carouselOffset: carouselOffset,
              ),
              _buildReadingClubs(),
              _buildCommunityStories(),
              _buildNearbyReadingPoint(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return HomeWelcomeSection(
      isGuest: widget.isGuest,
      currentName: widget.currentName,
    );
  }

  Widget _buildContinueReading() {
    final book = widget.continueReadingBook;
    return ContinueReadingSection(
      book: book,
      progress: widget.continueReadingProgress,
      finishedReadingTitle: widget.finishedReadingTitle,
      isGuest: widget.isGuest,
      onContinue: () {
        if (book != null) widget.onReadBook?.call(context, book.id);
      },
      onFinish: () {
        if (widget.isGuest) {
          _guestMessage('progreso de lectura');
          return;
        }
        if (book != null) widget.onContinueReadingProgressChanged(book.id, 100);
      },
      onOpenLibrary: widget.onOpenLibrary,
      onOpenFreeLibrary: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const GutendexCatalogScreen()),
      ),
      onGuestRestricted: () => _guestMessage('biblioteca'),
    );
  }

  void _showRecommendationExplanation(String message) {
    setState(() => _recommendationExplanation = message);
  }

  Widget _buildRecommendedBooks() {
    final items = RecommendationTitles.unique(
      _recommendations.data?.items ?? <Map<String, dynamic>>[],
    ).take(5).toList();
    final maxOffset = items.isEmpty ? 0 : ((items.length - 1) ~/ 3) * 3;
    final start = min(carouselOffset, maxOffset);
    return RecommendedBooksSection(
      heading: _recommendations.data?.personalized == true
          ? 'Recomendado para ti'
          : 'Exploración general',
      books: items,
      carouselOffset: start,
      onPrevious: () => setState(() {
        carouselOffset = max(0, start - 3);
        _recommendationExplanation = null;
      }),
      onNext: () => setState(() {
        carouselOffset = min(maxOffset, start + 3);
        _recommendationExplanation = null;
      }),
      onBookTap: _showBookDetails,
    );
  }

  Widget _buildReadingClubs() {
    return ReadingClubsSection(
      clubs: widget.clubs,
      joinedClubIds: widget.joinedClubIds,
      onShowAll: _showAllClubs,
      onShowDetails: _showClubDetails,
      onToggleClub: _toggleClub,
    );
  }

  void _toggleClub(int id) {
    if (widget.isGuest) {
      _guestMessage('clubes de lectura');
      return;
    }

    widget.onToggleClub(id);
  }

  Widget _buildCommunityStories() {
    return CommunityStoriesSection(
      stories: _communityPublications.take(3).toList(),
      loading: _communityLoading,
      error: _communityError,
      onRetry: reloadCommunityStories,
      onCommunity: _openCommunity,
      onAuthorTap: _openPublicationAuthor,
      onStoryTap: _readCommunityPublication,
      openingPublicationId: _openingPublication,
    );
  }

  void _openCommunity() {
    final repository = widget.communityWriterRepository;
    if (widget.isGuest) {
      widget.onGuestRestrictedAction();
      return;
    }
    if (repository == null) {
      _showMessage('La comunidad no está disponible por ahora.');
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => CommunityPublicationsScreen(
              repository: repository,
              currentUsername: widget.currentUsername,
              onAuthorTap: _openPublicationAuthor,
              favoriteIds: widget.favoriteCommunityStoryIds,
              onToggleFavorite: widget.onToggleCommunityStoryFavorite,
            ),
          ),
        )
        .then((_) {
          if (mounted) reloadCommunityStories();
        });
  }

  void _openPublicationAuthor(WriterPublication publication) {
    final username = publication.authorUsername?.trim();
    if (username == null || username.isEmpty) {
      _showMessage('Este autor todavía no tiene un perfil público disponible.');
      return;
    }
    widget.onOpenUserProfile?.call(username);
  }

  Future<void> _readCommunityPublication(WriterPublication publication) async {
    final repository = widget.communityWriterRepository;
    if (repository == null || _openingPublication != null) return;
    setState(() => _openingPublication = publication.id);
    try {
      // Volvemos al servidor: una historia retirada no abre desde el catálogo.
      final story = await repository.readPublication(publication.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PublishedStoryScreen(
            story: story,
            currentUsername: widget.currentUsername,
            authorUsername: publication.author,
            initiallyFavorite: widget.favoriteCommunityStoryIds.contains(
              story.id,
            ),
            onToggleFavorite: () =>
                widget.onToggleCommunityStoryFavorite(story),
            isGuest: widget.isGuest,
            onGuestRestrictedAction: widget.onGuestRestrictedAction,
          ),
        ),
      );
      if (mounted) await reloadCommunityStories();
    } catch (_) {
      _showMessage(
        'Esta historia ya no está disponible. Actualiza la comunidad.',
      );
      await reloadCommunityStories();
    } finally {
      if (mounted) setState(() => _openingPublication = null);
    }
  }

  Widget _buildNearbyReadingPoint() {
    return NearbyReadingPointSection(
      onOpenPoints: widget.onOpenPoints,
      onOpenNearbyPoint: widget.onOpenNearbyPoint,
    );
  }

  Future<void> _showBookDetails(Map<String, dynamic> book) async {
    if (_openingBook) return;
    if (book['freeWorkId'] is String) {
      final matches = freeWorks.where(
        (work) => work.id == book['freeWorkId'] && work.available,
      );
      if (matches.isEmpty) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FreeWorkDetailScreen(work: matches.first),
        ),
      );
      return;
    }
    if (book['googleVolumeId'] is String && widget.catalogRepository != null) {
      setState(() => _openingBook = true);
      try {
        final detail = await widget.catalogRepository!.detail(
          book['googleVolumeId'] as String,
        );
        // Keep an existing internal identity; fetching metadata must never import.
        final matches = (widget.catalogBooks ?? <Map<String, dynamic>>[]).where(
          (saved) => saved['googleVolumeId'] == book['googleVolumeId'],
        );
        book = {
          ...book,
          ...detail,
          if (book['id'] is int)
            'id': book['id']
          else if (matches.isNotEmpty)
            'id': matches.first['id'],
        };
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos cargar la ficha. Vuelve a intentarlo.'),
          ),
        );
        return;
      } finally {
        if (mounted) setState(() => _openingBook = false);
      }
      if (!mounted) return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeBookDetailScreen(
          book: book,
          initialProgress: widget.progresses[book['id']] ?? 0,
          readStatus: () => widget.statuses[book['id']],
          readProgress: () => widget.progresses[book['id']] ?? 0,
          onStatusChanged: widget.onBookStatusChanged == null
              ? null
              : (status) async {
                  if (book['id'] is int) {
                    await widget.onBookStatusChanged!(
                      book['id'] as int,
                      status,
                    );
                  }
                },
          onRead: () async {
            if (widget.isGuest) {
              widget.onGuestRestrictedAction();
              return Future<int?>.value();
            }
            await widget.onAddBook?.call(book);
            if (!mounted ||
                (widget.onAddBook != null &&
                    !widget.statuses.containsKey(book['id']))) {
              return null;
            }
            return widget.onReadBook?.call(context, book['id'] as int) ??
                Future<int?>.value();
          },
          currentUsername: widget.currentUsername,
          initialReview: widget.reviews[book['id']],
          onReviewSaved: widget.onReviewSaved,
          initiallyFavorite: widget.favoriteBookIds.contains(book['id']),
          onToggleFavorite: () {
            if (book['id'] is int) {
              widget.onToggleFavoriteBook(book['id'] as int);
            }
          },
          onOpenOwnProfile: () {
            Navigator.of(context).pop();
            widget.onOpenProfile();
          },
          onAddToLibrary: () async {
            if (widget.isGuest) {
              _guestMessage('biblioteca');
              return;
            }

            await widget.onAddBook?.call(book);
            if (!mounted || !widget.statuses.containsKey(book['id'])) return;
            Navigator.of(context).pop();
            widget.onOpenLibrary();
          },
          isGuest: widget.isGuest,
          onGuestRestrictedAction: widget.onGuestRestrictedAction,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _findBookByIsbn(String rawIsbn) async {
    final isbn = rawIsbn.replaceAll(RegExp(r'[^0-9Xx]'), '');

    final repository = widget.catalogRepository;

    if (repository != null) {
      final result = await repository.search(isbn, mode: 'isbn');

      for (final book in result.items) {
        final bookIsbn = book['isbn']?.toString().replaceAll(
          RegExp(r'[^0-9Xx]'),
          '',
        );

        if (bookIsbn == isbn) {
          return book;
        }
      }
    }

    for (final book in books) {
      final bookIsbn = book['isbn']?.toString().replaceAll(
        RegExp(r'[^0-9Xx]'),
        '',
      );

      if (bookIsbn == isbn) {
        return book;
      }
    }

    return null;
  }

  void showIsbnScanner() {
    showHomeIsbnScannerDialog(
      context: context,
      books: books,
      onSearchIsbn: _findBookByIsbn,
      onBookSelected: _showBookDetails,
      onMessage: _showMessage,
    );
  }

  Future<void> openAssistantBook(Map<String, dynamic> book) =>
      _showBookDetails(book);

  void showGeminiAssistant() {
    unawaited(_confirmGemini());
  }

  Future<void> _confirmGemini() async {
    if (_geminiDialogOpen || !mounted) return;
    final controller = _recommendations;
    _geminiDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          _geminiDialogContext = dialogContext;
          return HomeGeminiSelectionDialog(
            controller: controller,
            isCurrent: () => mounted && identical(controller, _recommendations),
          );
        },
      );
    } finally {
      _geminiDialogContext = null;
      _geminiDialogOpen = false;
    }
  }

  Map<String, String> _clubExtraData(ReadingClub club) {
    final username = club.organizerUsername?.trim() ?? '';

    return {
      'author': username.isEmpty
          ? 'Organizador no disponible'
          : '@${username.replaceFirst(RegExp(r'^@'), '')}',
      'instagram': club.instagram?.trim().isNotEmpty == true
          ? club.instagram!.trim()
          : 'No informado',
      'facebook': club.facebook?.trim().isNotEmpty == true
          ? club.facebook!.trim()
          : 'No informado',
      'x': club.xHandle?.trim().isNotEmpty == true
          ? club.xHandle!.trim()
          : 'No informado',
    };
  }

  void _showClubDetails(ReadingClub club) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final id = club.id;
        final extra = _clubExtraData(club);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final joined = widget.joinedClubIds.contains(id);

            ReadingClub currentClub = club;
            for (final candidate in widget.clubs) {
              if (candidate.id == id) {
                currentClub = candidate;
                break;
              }
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.58,
              minChildSize: 0.38,
              maxChildSize: 0.84,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DETALLE DEL CLUB',
                              style: GoogleFonts.cinzel(
                                color: _textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.25,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: _gold, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentClub.name,
                                    style: GoogleFonts.merriweather(
                                      color: _textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentClub.description,
                                    style: GoogleFonts.inter(
                                      color: _textPrimary,
                                      fontSize: 9.2,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Autor/a del club: ',
                                        style: GoogleFonts.inter(
                                          color: _textSecondary,
                                          fontSize: 8,
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            final username = currentClub
                                                .organizerUsername
                                                ?.trim();
                                            final openProfile =
                                                widget.onOpenUserProfile;
                                            if (username == null ||
                                                username.isEmpty ||
                                                openProfile == null) {
                                              return;
                                            }
                                            Navigator.of(sheetContext).pop();
                                            openProfile(
                                              username.replaceFirst(
                                                RegExp(r'^@'),
                                                '',
                                              ),
                                            );
                                          },
                                          child: Text(
                                            extra['author']!,
                                            style: GoogleFonts.inter(
                                              color: _accent,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: _accent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        color: _accent,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Debate: ${currentClub.date}',
                                          style: GoogleFonts.inter(
                                            color: _textSecondary,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.groups_2_outlined,
                                        color: _deepSurface,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${currentClub.members} lectores',
                                        style: GoogleFonts.inter(
                                          color: _textSecondary,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        currentClub.modality.toLowerCase() ==
                                                'online'
                                            ? Icons.language_rounded
                                            : Icons.location_on_outlined,
                                        color: _deepSurface,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Modalidad: ${currentClub.modality}',
                                        style: GoogleFonts.inter(
                                          color: _textSecondary,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 11),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(13, 12, 13, 8),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: _gold.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'REDES SOCIALES',
                                    style: GoogleFonts.cinzel(
                                      color: _textPrimary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _clubSocialRow(
                                    icon: Icons.photo_camera_outlined,
                                    label: 'Instagram:',
                                    value: extra['instagram']!,
                                  ),
                                  _clubSocialDivider(),
                                  _clubSocialRow(
                                    icon: Icons.facebook_outlined,
                                    label: 'Facebook:',
                                    value: extra['facebook']!,
                                  ),
                                  _clubSocialDivider(),
                                  _clubSocialRow(
                                    icon: Icons.close_rounded,
                                    label: 'X:',
                                    value: extra['x']!,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      decoration: BoxDecoration(
                        color: _background,
                        border: Border(
                          top: BorderSide(color: _gold.withValues(alpha: 0.16)),
                        ),
                      ),
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: () async {
                            if (widget.isGuest) {
                              Navigator.of(sheetContext).pop();
                              _guestMessage('clubes de lectura');
                              return;
                            }

                            await widget.onToggleClub(id);
                            if (sheetContext.mounted) {
                              setSheetState(() {});
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: joined ? _surfaceSoft : _accent,
                            foregroundColor: joined ? _textPrimary : _onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: joined
                                ? BorderSide(
                                    color: _gold.withValues(alpha: 0.55),
                                  )
                                : BorderSide.none,
                          ),
                          child: Text(
                            joined ? 'Salir del club' : 'Unirme al club',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _clubSocialRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _textSecondary, size: 13),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(color: _textSecondary, fontSize: 8),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _accent,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clubSocialDivider() {
    return Divider(height: 1, color: _gold.withValues(alpha: 0.14));
  }

  // El panel consulta páginas independientes de los tres clubes de Inicio.
  void _showAllClubs() {
    final repository = widget.readingClubRepository;
    if (repository == null) {
      _showMessage('No está disponible la lista de clubes.');
      return;
    }

    final allClubs = <ReadingClub>[];
    var nextPage = 0;
    var hasMore = true;
    var loading = false;
    String? loadError;
    StateSetter? refreshSheet;
    BuildContext? modalContext;

    // Compatibilidad con las distintas envolturas de páginas del repositorio.
    List<ReadingClub> pageClubs(dynamic page) {
      dynamic entries;
      try {
        entries = page.clubs;
      } catch (_) {}
      if (entries == null) {
        try {
          entries = page.items;
        } catch (_) {}
      }
      if (entries == null) {
        try {
          entries = page.content;
        } catch (_) {}
      }
      if (entries is List) {
        return entries.cast<ReadingClub>();
      }
      throw StateError('Respuesta de clubes no reconocida.');
    }

    Future<void> loadNextPage() async {
      if (loading || !hasMore) {
        return;
      }
      refreshSheet?.call(() {
        loading = true;
        loadError = null;
      });
      // La primera petición se dispara después de construir el panel.
      loading = true;
      loadError = null;
      try {
        final page = await repository.allClubs(page: nextPage, size: 12);
        final received = pageClubs(page);
        if (modalContext?.mounted != true) {
          return;
        }
        refreshSheet?.call(() {
          final existing = allClubs.map((club) => club.id).toSet();
          for (final club in received) {
            if (existing.add(club.id)) {
              allClubs.add(club);
            }
          }
          nextPage++;
          // Una página corta indica el final. Una última página llena
          // podrá confirmar el final con la siguiente petición.
          hasMore = received.length == 12;
          loading = false;
        });
      } catch (_) {
        if (modalContext?.mounted != true) {
          return;
        }
        refreshSheet?.call(() {
          loading = false;
          loadError = 'No pudimos cargar los clubes. Reintenta.';
        });
      }
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        var firstLoadScheduled = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            refreshSheet = setSheetState;
            modalContext = context;
            if (!firstLoadScheduled) {
              firstLoadScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (sheetContext.mounted) {
                  unawaited(loadNextPage());
                }
              });
            }
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.52,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(color: _gold.withValues(alpha: 0.34)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 9),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _deepSurface,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _gold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _gold.withValues(alpha: 0.26),
                                ),
                              ),
                              child: Icon(
                                Icons.groups_2_outlined,
                                color: _gold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CLUBES DE LECTURA',
                                    style: GoogleFonts.cinzel(
                                      color: _textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${allClubs.length} clubes cargados${hasMore ? ' · hay más' : ''}',
                                    style: GoogleFonts.inter(
                                      color: _textSecondary,
                                      fontSize: 8,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              splashRadius: 18,
                              icon: Icon(
                                Icons.close_rounded,
                                color: _textPrimary,
                                size: 21,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: _gold.withValues(alpha: 0.15)),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                          itemCount: allClubs.length + 1,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 11),
                          itemBuilder: (context, index) {
                            if (index == allClubs.length) {
                              if (loading) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(18),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (loadError != null) {
                                return Center(
                                  child: TextButton.icon(
                                    onPressed: loadNextPage,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: Text(loadError!),
                                  ),
                                );
                              }
                              if (allClubs.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Center(
                                    child: Text(
                                      'Todavía no hay clubes publicados.',
                                      style: GoogleFonts.inter(
                                        color: _textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (!hasMore) {
                                return const SizedBox.shrink();
                              }
                              return Center(
                                child: OutlinedButton.icon(
                                  onPressed: loadNextPage,
                                  icon: const Icon(Icons.expand_more_rounded),
                                  label: const Text('Cargar más clubes'),
                                ),
                              );
                            }
                            final club = allClubs[index];
                            final id = club.id;
                            final joined = widget.joinedClubIds.contains(id);
                            final isOnline =
                                club.modality.toLowerCase() == 'online';

                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.96, end: 1),
                              duration: Duration(
                                milliseconds: 220 + (index * 45),
                              ),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: ((value - 0.96) / 0.04).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  child: Transform.scale(
                                    scale: value,
                                    alignment: Alignment.topCenter,
                                    child: child,
                                  ),
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: joined
                                      ? _gold.withValues(alpha: 0.08)
                                      : _surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: joined
                                        ? _gold.withValues(alpha: 0.72)
                                        : _gold.withValues(alpha: 0.32),
                                    width: joined ? 1.15 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.035,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _deepSurface,
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                            border: Border.all(
                                              color: _gold.withValues(
                                                alpha: 0.28,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.auto_stories_outlined,
                                            color: _gold,
                                            size: 19,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      club.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.merriweather(
                                                            color: _textPrimary,
                                                            fontSize: 10.8,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                  if (joined)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 7,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: _gold.withValues(
                                                          alpha: 0.16,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              99,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'UNIDO',
                                                        style:
                                                            GoogleFonts.inter(
                                                              color:
                                                                  _deepSurface,
                                                              fontSize: 6.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              letterSpacing:
                                                                  0.45,
                                                            ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              if (club.book.trim().isNotEmpty)
                                                Text(
                                                  'Leyendo: ${club.book}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    color: _textSecondary,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 11),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _allClubsInfoChip(
                                          icon: Icons.calendar_month_outlined,
                                          text: club.date,
                                        ),
                                        _allClubsInfoChip(
                                          icon: Icons.people_outline_rounded,
                                          text: '${club.members} lectores',
                                        ),
                                        _allClubsInfoChip(
                                          icon: isOnline
                                              ? Icons.language_rounded
                                              : Icons.location_on_outlined,
                                          text: club.modality,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 36,
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                Navigator.of(sheetContext)
                                                    .pop();
                                                _showClubDetails(club);
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: _textPrimary,
                                                side: BorderSide(
                                                  color: _gold.withValues(
                                                    alpha: 0.72,
                                                  ),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                              ),
                                              icon: Icon(
                                                Icons.visibility_outlined,
                                                size: 14,
                                                color: _gold,
                                              ),
                                              label: Text(
                                                'Ver detalles',
                                                style: GoogleFonts.inter(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SizedBox(
                                            height: 36,
                                            child: FilledButton(
                                              onPressed: () async {
                                                if (widget.isGuest) {
                                                  Navigator.of(sheetContext)
                                                      .pop();
                                                  _guestMessage(
                                                    'clubes de lectura',
                                                  );
                                                  return;
                                                }

                                                await widget.onToggleClub(id);
                                                if (sheetContext.mounted) {
                                                  setSheetState(() {});
                                                }
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor: joined
                                                    ? _surfaceSoft
                                                    : _accent,
                                                foregroundColor: joined
                                                    ? _textPrimary
                                                    : _onAccent,
                                                side: joined
                                                    ? BorderSide(
                                                        color: _gold.withValues(
                                                          alpha: 0.50,
                                                        ),
                                                      )
                                                    : BorderSide.none,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                              ),
                                              child: AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                child: Text(
                                                  joined ? 'Unido ✓' : 'Unirme',
                                                  key: ValueKey(joined),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
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
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _allClubsInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _gold.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _gold),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _guestMessage(String feature) {
    widget.onGuestRestrictedAction();
  }

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
      );
  }
}
