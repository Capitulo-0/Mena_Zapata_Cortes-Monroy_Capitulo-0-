import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/profile_demo_data.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_main_card.dart';
import '../widgets/profile_blocked_users_store.dart';
import '../../../home/presentation/screens/home_book_detail_screen.dart';
import '../../../clubs/models/reading_club.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../writer/models/writer_story.dart';
import '../../../writer/presentation/screens/published_story_screen.dart';


part '../widgets/profile_mood_section.dart';
part '../widgets/profile_clubs_section.dart';
part '../widgets/profile_reading_summary_section.dart';
part '../widgets/profile_mark_read_sheet.dart';
part '../widgets/profile_tabs_favorites_section.dart';
part '../widgets/profile_reviews_reading_section.dart';
part '../widgets/profile_works_badges_section.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({
    super.key,
    required this.onOpenSettings,
    required this.name,
    required this.username,
    required this.biography,
    required this.readingFormat,
    required this.annualGoal,
    required this.clubs,
    required this.joinedClubIds,
    required this.onToggleClub,
    required this.books,
    required this.statuses,
    required this.progresses,
    required this.reviews,
    required this.favorites,
    required this.favoriteCommunityStories,
    required this.onToggleCommunityStoryFavorite,
    required this.onStatusChanged,
    required this.onProgressChanged,
    required this.onReviewSaved,
    required this.onToggleFavorite,
    required this.publishedStories,
  });

  final VoidCallback onOpenSettings;

  final String name;
  final String username;
  final String biography;
  final String readingFormat;
  final int annualGoal;

  final List<ReadingClub> clubs;
  final Set<int> joinedClubIds;
  final ValueChanged<int> onToggleClub;

  final List<LibraryBook> books;
  final Map<int, BookStatus> statuses;
  final Map<int, int> progresses;
  final Map<int, BookReview> reviews;
  final Set<int> favorites;

  final List<WriterStory> favoriteCommunityStories;
  final ValueChanged<WriterStory> onToggleCommunityStoryFavorite;

  final void Function(int bookId, BookStatus status) onStatusChanged;
  final void Function(int bookId, int progress) onProgressChanged;
  final void Function(int bookId, BookReview review) onReviewSaved;
  final void Function(int bookId) onToggleFavorite;

  final List<WriterStory> publishedStories;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _updateState(VoidCallback callback) {
    setState(callback);
  }

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      _isDarkMode ? AppColors.darkBackground : AppColors.background;

  Color get _surfaceColor =>
      _isDarkMode ? AppColors.darkSurface : AppColors.surface;

  Color get _textPrimaryColor =>
      _isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get _textSecondaryColor =>
      _isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get _headingColor =>
      _isDarkMode ? AppColors.darkTextPrimary : AppColors.deep;

  Color get _deepSurfaceColor =>
      _isDarkMode ? AppColors.darkDeep : AppColors.deep;

  Color get _goldColor =>
      _isDarkMode ? AppColors.darkGold : AppColors.gold;

  Color get _accentColor =>
      _isDarkMode ? AppColors.darkAccent : AppColors.accent;

  String _selectedTab = 'favoritos';
  int _quoteIndex = 0;
  int _moodIndex = 0;
  String _customMoodEmoji = '✨';
  String _customMoodLabel = 'Mi propio estado';
  String _customMoodDetail = 'Una lectura a mi manera';


  List<Map<String, String>> get _favoriteQuotes =>
      ProfileDemoData.favoriteQuotes;

  List<Map<String, String>> get _baseMoods =>
      ProfileDemoData.baseMoods;

  List<Map<String, String>> get _followers =>
      ProfileDemoData.followers;

  List<Map<String, String>> get _following =>
      ProfileDemoData.following;

  Set<String> get _blockedUsers => ProfileBlockedUsersStore.usernames;

  List<Map<String, String>> get _moods => [
    ..._baseMoods,
    {
      'emoji': _customMoodEmoji,
      'label': _customMoodLabel,
      'detail': _customMoodDetail,
    },
  ];

  Map<String, String> get _currentMood =>
      _moods[_moodIndex.clamp(0, _moods.length - 1).toInt()];

  List<LibraryBook> get _readBooks => widget.books
      .where((book) => widget.statuses[book.id] == BookStatus.leido)
      .toList();

  List<LibraryBook> get _favoriteBooks =>
      widget.books.where((book) => widget.favorites.contains(book.id)).toList();

  List<Object> get _favoriteShelfItems => <Object>[
        ..._favoriteBooks,
        ...widget.favoriteCommunityStories,
      ];

  int get _favoriteCount => _favoriteShelfItems.length;

  List<ReadingClub> get _joinedClubs => widget.clubs
      .where((club) => widget.joinedClubIds.contains(club.id))
      .toList();

  int get _followerCount =>
      139 +
      _followers
          .where((user) => !_blockedUsers.contains(user['user']))
          .length;

  int get _followingCount =>
      87 +
      _following
          .where((user) => !_blockedUsers.contains(user['user']))
          .length;
  int get _booksReadThisYear => _readBooks.length;

  Map<String, int> get _genreCounts {
    final result = <String, int>{};
    for (final book in _readBooks) {
      result.update(book.genre, (value) => value + 1, ifAbsent: () => 1);
    }
    return result;
  }

  List<MapEntry<String, int>> get _topGenres {
    final entries = _genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _backgroundColor,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildMainProfileCard(),
            const SizedBox(height: 12),
            _buildReaderMoodCard(),
            const SizedBox(height: 12),
            _buildClubsCard(),
            const SizedBox(height: 12),
            _buildFavoriteQuote(),
            const SizedBox(height: 12),
            _buildBookDna(),
            const SizedBox(height: 12),
            _buildReadingChallenge(),
            const SizedBox(height: 13),
            _buildTabs(),
            const SizedBox(height: 10),
            _buildSelectedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ProfileHeader(
      onOpenSettings: widget.onOpenSettings,
    );
  }

  Widget _buildMainProfileCard() {
    return ProfileMainCard(
      name: widget.name,
      username: widget.username,
      biography: widget.biography,
      moodEmoji: _currentMood['emoji']!,
      readBooksCount: _readBooks.length,
      followerCount: _followerCount,
      followingCount: _followingCount,
      onFollowersTap: () => _showSocialList(
        'Seguidores',
        _followers,
      ),
      onFollowingTap: () => _showSocialList(
        'Siguiendo',
        _following,
      ),
    );
  }

}

class _ProfileBookDetailScreen extends StatefulWidget {
  const _ProfileBookDetailScreen({
    required this.name,
    required this.book,
    required this.initialStatus,
    required this.initialProgress,
    required this.initialReview,
    required this.initiallyFavorite,
    required this.onStatusChanged,
    required this.onProgressChanged,
    required this.onReviewSaved,
    required this.onToggleFavorite,
  });

  final String name;

  final LibraryBook book;
  final BookStatus? initialStatus;
  final int initialProgress;
  final BookReview? initialReview;
  final bool initiallyFavorite;
  final void Function(int bookId, BookStatus status) onStatusChanged;
  final void Function(int bookId, int progress) onProgressChanged;
  final void Function(int bookId, BookReview review) onReviewSaved;
  final void Function(int bookId) onToggleFavorite;

  @override
  State<_ProfileBookDetailScreen> createState() =>
      _ProfileBookDetailScreenState();
}

class _ProfileBookDetailScreenState extends State<_ProfileBookDetailScreen> {
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      _isDarkMode ? AppColors.darkBackground : AppColors.background;

  Color get _surfaceColor =>
      _isDarkMode ? AppColors.darkSurface : AppColors.surface;

  Color get _textPrimaryColor =>
      _isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get _textSecondaryColor =>
      _isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get _headingColor =>
      _isDarkMode ? AppColors.darkTextPrimary : AppColors.deep;

  Color get _deepSurfaceColor =>
      _isDarkMode ? AppColors.darkDeep : AppColors.deep;

  late BookStatus? _status;
  late int _progress;
  late BookReview? _review;
  late bool _favorite;

  final List<Map<String, dynamic>> _comments = [
    {
      'name': 'Valentina Cruz',
      'text': 'La atmósfera de este libro me encantó. Hay escenas que se quedan dando vueltas por días.',
      'likes': 8,
      'liked': false,
    },
    {
      'name': 'Marco Ibáñez',
      'text': 'Lo terminé esta semana. Gran recomendación para conversar en un club de lectura.',
      'likes': 5,
      'liked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _progress = widget.initialProgress;
    _review = widget.initialReview;
    _favorite = widget.initiallyFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_rounded, color: _headingColor),
        ),
        title: Text(
          'DETALLE DEL LIBRO',
          style: GoogleFonts.cinzel(
            color: _headingColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _shareBook,
            icon: Icon(Icons.ios_share_rounded, color: _headingColor),
          ),
          IconButton(
            onPressed: () {
              widget.onToggleFavorite(widget.book.id);
              setState(() => _favorite = !_favorite);
            },
            icon: Icon(
              _favorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _favorite ? AppColors.accent : _headingColor,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          _buildHero(),
          const SizedBox(height: 14),
          _buildSynopsis(),
          const SizedBox(height: 12),
          _buildInfo(),
          const SizedBox(height: 12),
          _buildLibraryActions(),
          const SizedBox(height: 12),
          if (widget.book.isFree) _buildFreeReaderButton(),
          if (widget.book.isFree) const SizedBox(height: 12),
          _buildReviewSection(),
          const SizedBox(height: 12),
          _buildComments(),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.38)),
      ),
      child: child,
    );
  }

  Widget _buildHero() {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.network(
              widget.book.cover,
              width: 92,
              height: 132,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 92,
                height: 132,
                color: _deepSurfaceColor,
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.gold,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.book.title,
                  style: GoogleFonts.merriweather(
                    color: _textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.book.author,
                  style: GoogleFonts.inter(
                    color: AppColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _detailLine(Icons.category_outlined, widget.book.genre),
                _detailLine(
                  Icons.calendar_today_outlined,
                  '${widget.book.year}',
                ),
                _detailLine(Icons.qr_code_rounded, 'ISBN ${widget.book.isbn}'),
                if (_review != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    List<String>.filled(_review!.rating, '★').join(),
                    style: const TextStyle(color: AppColors.gold, fontSize: 15),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 13),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(color: _textSecondaryColor, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSynopsis() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('SINOPSIS'),
          const SizedBox(height: 7),
          Text(
            widget.book.synopsis,
            style: GoogleFonts.merriweather(
              color: _textPrimaryColor,
              fontSize: 9,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('INFORMACIÓN BIBLIOGRÁFICA'),
          const SizedBox(height: 9),
          _infoRow('Autor', widget.book.author),
          _infoRow('Año', '${widget.book.year}'),
          _infoRow('Género', widget.book.genre),
          _infoRow('ISBN', widget.book.isbn),
          _infoRow(
            'Disponibilidad',
            widget.book.isFree
                ? 'Lectura gratuita disponible'
                : 'Ficha bibliográfica',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: _textSecondaryColor,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: _textPrimaryColor,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryActions() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('MI BIBLIOTECA'),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _statusButton('Por leer', BookStatus.porLeer),
              _statusButton('Leyendo', BookStatus.leyendo),
              _statusButton('Leído ✓', BookStatus.leido),
            ],
          ),
          if (_status == BookStatus.leyendo) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Progreso de lectura',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$_progress%',
                  style: GoogleFonts.inter(
                    color: AppColors.accent,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Slider(
              value: _progress.toDouble().clamp(0.0, 100.0).toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: AppColors.accent,
              inactiveColor: AppColors.gold.withValues(alpha: 0.22),
              onChanged: (value) {
                final progress = value.round();
                setState(() {
                  _progress = progress;
                  if (progress >= 100) _status = BookStatus.leido;
                });
                widget.onProgressChanged(widget.book.id, progress);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusButton(String text, BookStatus status) {
    final selected = _status == status;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _status = status;
          if (status == BookStatus.leido) _progress = 100;
          if (status == BookStatus.porLeer) _progress = 0;
        });
        widget.onStatusChanged(widget.book.id, status);
        if (status == BookStatus.leido) {
          widget.onProgressChanged(widget.book.id, 100);
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.background : _headingColor,
        backgroundColor: selected ? AppColors.accent : _surfaceColor,
        side: BorderSide(color: selected ? AppColors.accent : AppColors.gold),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        textStyle: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700),
      ),
      child: Text(text),
    );
  }

  Widget _buildFreeReaderButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _openFreeReader,
        icon: const Icon(Icons.menu_book_rounded, size: 18),
        label: const Text('Leer gratis'),
        style: FilledButton.styleFrom(
          backgroundColor: _deepSurfaceColor,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('MI RESEÑA')),
              TextButton.icon(
                onPressed: _openReviewEditor,
                icon: const Icon(Icons.edit_outlined, size: 13),
                label: Text(_review == null ? 'Calificar y reseñar' : 'Editar'),
              ),
            ],
          ),
          if (_review == null)
            Text(
              'Todavía no has reseñado este libro.',
              style: GoogleFonts.merriweather(
                color: _textSecondaryColor,
                fontSize: 8.5,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            Text(
              List<String>.filled(_review!.rating, '★').join(),
              style: const TextStyle(color: AppColors.gold, fontSize: 17),
            ),
            const SizedBox(height: 5),
            Text(
              _review!.text,
              style: GoogleFonts.merriweather(fontSize: 9, height: 1.5),
            ),
            const SizedBox(height: 7),
            Text(
              _review!.isPublic ? 'Reseña pública' : 'Reseña privada',
              style: GoogleFonts.inter(
                color: AppColors.accent,
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComments() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('COMENTARIOS DE LA COMUNIDAD'),
          const SizedBox(height: 10),
          ..._comments.asMap().entries.map((entry) {
            final index = entry.key;
            final comment = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['name'] as String,
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment['text'] as String,
                      style: GoogleFonts.merriweather(
                        fontSize: 8.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              final liked = comment['liked'] as bool;
                              comment['liked'] = !liked;
                              comment['likes'] =
                                  (comment['likes'] as int) + (liked ? -1 : 1);
                            });
                          },
                          icon: Icon(
                            (comment['liked'] as bool)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14,
                          ),
                          label: Text('${comment['likes']} Me gusta'),
                          style: TextButton.styleFrom(
                            foregroundColor: (comment['liked'] as bool)
                                ? AppColors.accent
                                : _textSecondaryColor,
                            textStyle: GoogleFonts.inter(fontSize: 7.5),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _replyToComment(index),
                          child: Text(
                            'Responder',
                            style: GoogleFonts.inter(
                              color: AppColors.accent,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.cinzel(
        color: _headingColor,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void _shareBook() {
    Clipboard.setData(
      ClipboardData(
        text: '${widget.book.title} — ${widget.book.author} · Capítulo 0',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Libro copiado para compartir.')),
    );
  }

  void _openFreeReader() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.78,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.book.title,
                        style: GoogleFonts.cinzel(
                          color: _headingColor,
                          fontSize: 14,
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
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      'LECTURA DE MUESTRA\n\n'
                      'Esta vista representa el lector gratuito integrado de Capítulo 0. '
                      'Aquí se mostrará el contenido autorizado del libro o de la obra disponible gratuitamente.\n\n'
                      '${widget.book.synopsis}\n\n'
                      '— Fin de la muestra —',
                      style: GoogleFonts.merriweather(
                        color: _textPrimaryColor,
                        fontSize: 12,
                        height: 1.8,
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
  }

  void _openReviewEditor() {
    int rating = _review?.rating ?? 5;
    bool isPublic = _review?.isPublic ?? true;
    final controller = TextEditingController(text: _review?.text ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALIFICAR Y RESEÑAR',
                    style: GoogleFonts.cinzel(
                      color: _headingColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        onPressed: () => modalSetState(() => rating = value),
                        icon: Icon(
                          value <= rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.gold,
                          size: 28,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: controller,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Tu reseña',
                      hintText: '¿Qué te pareció este libro?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: isPublic,
                    onChanged: (value) => modalSetState(() => isPublic = value),
                    title: Text(
                      'Reseña pública',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        final review = BookReview(
                          rating: rating,
                          text: text,
                          isPublic: isPublic,
                        );
                        widget.onReviewSaved(widget.book.id, review);
                        setState(() => _review = review);
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Reseña guardada')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                      ),
                      child: const Text('Guardar reseña'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => controller.dispose());
  }

  void _replyToComment(int index) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Responder a ${_comments[index]['name']}',
            style: GoogleFonts.cinzel(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Escribe tu respuesta...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                setState(() {
                  _comments.add({
                    'name': '${widget.name} · respuesta',
                    'text': text,
                    'likes': 0,
                    'liked': false,
                  });
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Responder'),
            ),
          ],
        );
      },
    ).whenComplete(() => controller.dispose());
  }
}
