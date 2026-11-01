import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/home_demo_data.dart';
import '../dialogs/home_gemini_assistant_sheet.dart';
import '../dialogs/home_isbn_scanner_dialog.dart';
import '../widgets/home_quote_section.dart';
import '../widgets/home_search_section.dart';
import 'home_book_detail_screen.dart';
import '../widgets/community_stories_section.dart';
import '../widgets/continue_reading_section.dart';
import '../widgets/home_welcome_section.dart';
import '../widgets/nearby_reading_point_section.dart';
import '../widgets/reading_clubs_section.dart';
import '../widgets/recommended_books_section.dart';
import '../../../clubs/models/reading_club.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../writer/models/writer_chapter.dart';
import '../../../writer/models/writer_story.dart';
import '../../../writer/presentation/screens/published_story_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isGuest,
    required this.onGuestRestrictedAction,
    required this.onOpenLibrary,
    required this.onOpenWriter,
    required this.onOpenPoints,
    required this.onOpenProfile,
    required this.currentName,
    required this.currentUsername,
    required this.reviews,
    required this.onReviewSaved,
    required this.favoriteBookIds,
    required this.onToggleFavoriteBook,
    required this.favoriteCommunityStoryIds,
    required this.onToggleCommunityStoryFavorite,
    required this.clubs,
    required this.joinedClubIds,
    required this.onToggleClub,
    required this.continueReadingBook,
    required this.continueReadingProgress,
    required this.onContinueReadingProgressChanged,
  });

  final bool isGuest;
  final VoidCallback onGuestRestrictedAction;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenWriter;
  final VoidCallback onOpenPoints;
  final VoidCallback onOpenProfile;
  final String currentName;
  final String currentUsername;
  final Map<int, BookReview> reviews;
  final void Function(int bookId, BookReview review) onReviewSaved;

  final Set<int> favoriteBookIds;
  final ValueChanged<int> onToggleFavoriteBook;

  final Set<String> favoriteCommunityStoryIds;
  final ValueChanged<WriterStory> onToggleCommunityStoryFavorite;

  final List<ReadingClub> clubs;
  final Set<int> joinedClubIds;
  final ValueChanged<int> onToggleClub;

  final LibraryBook? continueReadingBook;
  final int continueReadingProgress;
  final void Function(int bookId, int progress)
      onContinueReadingProgressChanged;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool searchSubmitted = false;








  int carouselOffset = 0;

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

  final List<Map<String, String>> quotes =
      HomeDemoData.quotes.map(Map<String, String>.from).toList();

  final List<Map<String, dynamic>> books =
      HomeDemoData.books.map(Map<String, dynamic>.from).toList();

  final List<Map<String, String>> stories =
      HomeDemoData.stories.map(Map<String, String>.from).toList();

  ButtonStyle _accentButtonStyle({double height = 31}) {
    return FilledButton.styleFrom(
      backgroundColor: _accent,
      foregroundColor: _onAccent,
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    );
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
            HomeSearchSection(
              books: books,
              onBookTap: _showBookDetails,
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

    if (book == null) {
      return const SizedBox.shrink();
    }

    return ContinueReadingSection(
      book: book,
      progress: widget.continueReadingProgress,
      isGuest: widget.isGuest,
      onContinue: widget.onOpenLibrary,
      onAdvance: () => _advanceSharedReading(
        book,
        widget.continueReadingProgress.clamp(0, 100).toInt(),
      ),
      onGuestRestricted: () => _guestMessage('biblioteca'),
    );
  }

  void _advanceSharedReading(
    LibraryBook book,
    int currentProgress,
  ) {
    if (widget.isGuest) {
      _guestMessage('progreso de lectura');
      return;
    }

    final nextProgress =
        (currentProgress + 10).clamp(0, 100).toInt();

    widget.onContinueReadingProgressChanged(
      book.id,
      nextProgress,
    );

  }

  Widget _buildRecommendedBooks() {
    final maxOffset = max(0, books.length - 3);

    return RecommendedBooksSection(
      books: books,
      carouselOffset: carouselOffset,
      onPrevious: () {
        setState(() {
          carouselOffset = max(0, carouselOffset - 1);
        });
      },
      onNext: () {
        setState(() {
          carouselOffset = min(maxOffset, carouselOffset + 1);
        });
      },
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
      stories: stories,
      isGuest: widget.isGuest,
      onWrite: widget.onOpenWriter,
      onGuestRestricted: () => _guestMessage('escribir'),
      onAuthorTap: _showAuthorProfile,
      onStoryTap: _showStory,
    );
  }

  Widget _buildNearbyReadingPoint() {
    return NearbyReadingPointSection(
      onOpenPoints: widget.onOpenPoints,
    );
  }

  void _showBookDetails(Map<String, dynamic> book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeBookDetailScreen(
          book: book,
          currentUsername: widget.currentUsername,
          initialReview: widget.reviews[book['id'] as int],
          onReviewSaved: widget.onReviewSaved,
          initiallyFavorite:
              widget.favoriteBookIds.contains(book['id'] as int),
          onToggleFavorite: () {
            widget.onToggleFavoriteBook(book['id'] as int);
          },
          onOpenOwnProfile: () {
            Navigator.of(context).pop();
            widget.onOpenProfile();
          },
          onAddToLibrary: () {
            if (widget.isGuest) {
              _guestMessage('biblioteca');
              return;
            }

            Navigator.of(context).pop();
            widget.onOpenLibrary();
          },
          isGuest: widget.isGuest,
          onGuestRestrictedAction: widget.onGuestRestrictedAction,
        ),
      ),
    );
  }

  void showIsbnScanner() {
    showHomeIsbnScannerDialog(
      context: context,
      books: books,
      onBookSelected: _showBookDetails,
      onMessage: _showMessage,
    );
  }

  void showGeminiAssistant() {
    showHomeGeminiAssistantSheet(context: context);
  }

  void _showAuthorProfile(Map<String, String> story) {
    final isOwnProfile = story['user'] == '@constanza.lectora';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Perfil literario',
                        style: GoogleFonts.cinzel(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _gold.withValues(alpha: 0.55)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: _surfaceSoft,
                            child: Text(
                              _initials(story['author']!),
                              style: GoogleFonts.cinzel(
                                color: _textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story['author']!,
                                  style: GoogleFonts.merriweather(
                                    color: _textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  story['user']!,
                                  style: GoogleFonts.inter(
                                    color: _accent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Miembro desde ${story['memberSince']}',
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
                      const SizedBox(height: 12),
                      Text(
                        story['bio']!,
                        style: GoogleFonts.merriweather(
                          color: _textPrimary,
                          fontSize: 9,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _profileStat('24', 'Leídos'),
                          _profileStat(
                            isOwnProfile ? '142' : '86',
                            'Seguidores',
                          ),
                          _profileStat(isOwnProfile ? '89' : '51', 'Siguiendo'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OBRA DESTACADA',
                        style: GoogleFonts.cinzel(
                          color: _textPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story['title']!,
                        style: GoogleFonts.merriweather(
                          color: _textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story['extract']!,
                        style: GoogleFonts.merriweather(
                          color: _textPrimary,
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _showStory(story);
                        },
                        style: _accentButtonStyle(),
                        child: const Text('Leer historia'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cinzel(
              color: _accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(color: _textSecondary, fontSize: 7),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final clean = name.replaceAll('@', '').trim();
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, String> _clubExtraData(ReadingClub club) {
    switch (club.id) {
      case 1:
        return {
          'author': '@mariaPaz200',
          'instagram': '@adictosclasicos',
          'facebook': 'Adictos a los Clásicos',
          'x': '@adictosclasicos_x',
        };
      case 2:
        return {
          'author': '@valencruz',
          'instagram': '@mansiongotica',
          'facebook': 'Mansión Gótica',
          'x': '@mansiongotica_club',
        };
      case 3:
        return {
          'author': '@marcoibanez17',
          'instagram': '@plumasdelsur',
          'facebook': 'Plumas del Sur',
          'x': '@plumasdelsur',
        };
      default:
        return {
          'author': '@capitulo0',
          'instagram': '@capitulo0',
          'facebook': 'Capítulo 0',
          'x': '@capitulo0',
        };
    }
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
                                border: Border.all(
                                  color: _gold,
                                  width: 1,
                                ),
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
                              padding: const EdgeInsets.fromLTRB(
                                13,
                                12,
                                13,
                                8,
                              ),
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
                          top: BorderSide(
                            color: _gold.withValues(alpha: 0.16),
                          ),
                        ),
                      ),
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: () {
                            if (widget.isGuest) {
                              Navigator.of(sheetContext).pop();
                              _guestMessage('clubes de lectura');
                              return;
                            }

                            widget.onToggleClub(id);
                            setSheetState(() {});
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                joined ? _surfaceSoft : _accent,
                            foregroundColor:
                                joined ? _textPrimary : _onAccent,
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
          Icon(
            icon,
            color: _textSecondary,
            size: 13,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 8,
            ),
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
    return Divider(
      height: 1,
      color: _gold.withValues(alpha: 0.14),
    );
  }

  void _showAllClubs() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      top: BorderSide(
                        color: _gold.withValues(alpha: 0.34),
                      ),
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
                                    '${widget.clubs.length} clubes disponibles para descubrir',
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
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(),
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
                      Divider(
                        height: 1,
                        color: _gold.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                          itemCount: widget.clubs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 11),
                          itemBuilder: (context, index) {
                            final club = widget.clubs[index];
                            final id = club.id;
                            final joined =
                                widget.joinedClubIds.contains(id);
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
                                  opacity: ((value - 0.96) / 0.04)
                                      .clamp(0.0, 1.0),
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
                                            borderRadius:
                                                BorderRadius.circular(11),
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
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 7,
                                                        vertical: 3,
                                                      ),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: _gold.withValues(
                                                          alpha: 0.16,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(99),
                                                      ),
                                                      child: Text(
                                                        'UNIDO',
                                                        style:
                                                            GoogleFonts.inter(
                                                          color: _deepSurface,
                                                          fontSize: 6.5,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: 0.45,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
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
                                              onPressed: () {
                                                if (widget.isGuest) {
                                                  Navigator.of(sheetContext)
                                                      .pop();
                                                  _guestMessage(
                                                    'clubes de lectura',
                                                  );
                                                  return;
                                                }

                                                widget.onToggleClub(id);
                                                setSheetState(() {});
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
                                                  joined
                                                      ? 'Unido ✓'
                                                      : 'Unirme',
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

  Widget _allClubsInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: _gold.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: _gold,
          ),
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

  void _showStory(Map<String, String> story) {
    final publishedStory = _communityStoryToWriterStory(story);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublishedStoryScreen(
          story: publishedStory,
          currentUsername: widget.currentUsername,
          authorUsername: story['user'],
          initiallyFavorite:
              widget.favoriteCommunityStoryIds.contains(publishedStory.id),
          onToggleFavorite: () {
            widget.onToggleCommunityStoryFavorite(publishedStory);
          },
          isGuest: widget.isGuest,
          onGuestRestrictedAction: widget.onGuestRestrictedAction,
        ),
      ),
    );
  }

  WriterStory _communityStoryToWriterStory(
    Map<String, String> story,
  ) {
    final title = story['title']?.trim() ?? '';
    final synopsis = story['extract']?.trim() ?? '';
    final fullText = story['full']?.trim() ?? '';
    final author = story['user']?.trim() ?? '@autor';

    final storyId =
        'community_${_stableCommunityId('$author|$title')}';

    final now = DateTime.now();

    return WriterStory(
      id: storyId,
      title: title,
      synopsis: synopsis,
      genre: 'Ficción',
      coverPath: 'preset:classic',
      status: WriterStoryStatus.published,
      chapters: _communityStoryChapters(
        storyId: storyId,
        fullText: fullText,
        now: now,
      ),
      createdAt: now,
      updatedAt: now,
      followers: 0,
      rating: 0,
    );
  }

  List<WriterChapter> _communityStoryChapters({
    required String storyId,
    required String fullText,
    required DateTime now,
  }) {
    if (fullText.trim().isEmpty) {
      return [
        WriterChapter(
          id: '$storyId-chapter-1',
          title: 'Historia completa',
          content: 'Esta historia todavía no tiene contenido disponible.',
          order: 1,
          isPublished: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }

    final headingPattern = RegExp(
      r'Capítulo\s+(\d+)\s*:\s*([^\n]+)',
      caseSensitive: false,
    );

    final matches = headingPattern.allMatches(fullText).toList();

    if (matches.isEmpty) {
      return [
        WriterChapter(
          id: '$storyId-chapter-1',
          title: 'Historia completa',
          content: fullText,
          order: 1,
          isPublished: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }

    final chapters = <WriterChapter>[];

    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      final nextStart = index + 1 < matches.length
          ? matches[index + 1].start
          : fullText.length;

      var content = fullText
          .substring(match.end, nextStart)
          .trim();

      if (content.isEmpty) {
        content = 'Capítulo sin contenido.';
      }

      final number =
          int.tryParse(match.group(1) ?? '') ?? index + 1;
      final chapterTitle =
          match.group(2)?.trim().isNotEmpty == true
              ? match.group(2)!.trim()
              : 'Capítulo $number';

      chapters.add(
        WriterChapter(
          id: '$storyId-chapter-$number',
          title: chapterTitle,
          content: content,
          order: number,
          isPublished: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    chapters.sort((a, b) => a.order.compareTo(b.order));
    return chapters;
  }

  int _stableCommunityId(String value) {
    var hash = 0x811C9DC5;

    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }

    return hash;
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
