import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/profile_privacy_store.dart';
import '../widgets/profile_blocked_users_store.dart';
import '../../../clubs/models/reading_club.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../writer/models/writer_story.dart';
import '../../../writer/presentation/screens/published_story_screen.dart';

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


  final List<Map<String, String>> _favoriteQuotes = [
    {
      'text': 'No hay encanto igual a la ternura del corazón.',
      'author': 'Jane Austen',
      'work': 'Emma',
    },
    {
      'text': 'El que lee mucho y anda mucho, ve mucho y sabe mucho.',
      'author': 'Miguel de Cervantes',
      'work': 'Don Quijote de la Mancha',
    },
    {
      'text': 'Una historia puede comenzar en cualquier página.',
      'author': 'Capítulo 0',
      'work': '',
    },
    {
      'text': 'A veces un libro llega justo cuando más lo necesitamos.',
      'author': 'Capítulo 0',
      'work': '',
    },
  ];

  final List<Map<String, String>> _baseMoods = [
    {
      'emoji': '☕',
      'label': 'Leyendo con cafecito',
      'detail': 'Clásicos tranquilos para leer sin prisa',
    },
    {
      'emoji': '🕯️',
      'label': 'Entre sombras y misterio',
      'detail': 'Gótico, misterio y atmósferas intensas',
    },
    {
      'emoji': '💗',
      'label': 'Con el corazón romántico',
      'detail': 'Romance clásico y vínculos inolvidables',
    },
    {
      'emoji': '🌙',
      'label': 'Lecturas para la noche',
      'detail': 'Historias perfectas para el final del día',
    },
  ];

  final List<Map<String, String>> _followers = [
    {
      'name': 'Valentina Cruz',
      'user': '@valencruz',
      'initial': 'V',
      'bio': 'Autora independiente y amante de la poesía contemporánea.',
    },
    {
      'name': 'Marco Ibáñez',
      'user': '@MarcoIbanez17',
      'initial': 'M',
      'bio': 'Lector de misterio, faros y relatos breves.',
    },
    {
      'name': 'María Paz Rojas',
      'user': '@mariaPaz200',
      'initial': 'M',
      'bio': 'Creadora de clubes de lectura y fan de los clásicos.',
    },
  ];

  final List<Map<String, String>> _following = [
    {
      'name': 'Jane Austen',
      'user': '@JaneAusten1',
      'initial': 'J',
      'bio': 'Perfil literario dedicado a los clásicos de Jane Austen.',
    },
    {
      'name': 'Valentina Cruz',
      'user': '@valencruz',
      'initial': 'V',
      'bio': 'Autora independiente y amante de la poesía contemporánea.',
    },
  ];

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
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: ProfilePrivacyStore.isPrivate,
            builder: (context, isPrivate, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'MI PERFIL LITERARIO',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.86,
                            end: 1,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      isPrivate
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      key: ValueKey<bool>(isPrivate),
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        InkWell(
          onTap: widget.onOpenSettings,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 38,
            height: 36,
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold),
            ),
            child: Icon(
              Icons.settings_outlined,
              color: _headingColor,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainProfileCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 1.3),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return Container(
                            color: _deepSurfaceColor,
                            alignment: Alignment.center,
                            child: Text(
                              widget.name.trim().isEmpty
                              ? '?'
                              : widget.name.trim()[0].toUpperCase(),
                              style: GoogleFonts.cinzel(
                                color: AppColors.gold,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _currentMood['emoji']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.merriweather(
                        color: _textPrimaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.username,
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Miembro desde: Marzo 2024',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.biography,
              style: GoogleFonts.merriweather(
                color: _textPrimaryColor,
                fontSize: 10,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.28),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _statItem(
                    value: '${_readBooks.length}',
                    label: 'Total Leídos',
                  ),
                ),
                Expanded(
                  child: _statItem(
                    value: '$_followerCount',
                    label: 'Seguidores',
                    highlighted: true,
                    onTap: () => _showSocialList('Seguidores', _followers),
                  ),
                ),
                Expanded(
                  child: _statItem(
                    value: '$_followingCount',
                    label: 'Siguiendo',
                    highlighted: true,
                    onTap: () => _showSocialList('Siguiendo', _following),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String value,
    required String label,
    bool highlighted = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: highlighted ? AppColors.accent : _headingColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _textSecondaryColor,
                fontSize: 7,
                decoration: highlighted ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderMoodCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADO LECTOR',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Visible en tu perfil',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _showCustomMoodEditor,
                icon: const Icon(Icons.edit_outlined, size: 13),
                label: const Text('Personalizar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  textStyle: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.985, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<String>(
                '${_currentMood['emoji']}-${_currentMood['label']}-$_moodIndex',
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _currentMood['emoji']!,
                    style: const TextStyle(fontSize: 21),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentMood['label']!,
                          style: GoogleFonts.merriweather(
                            color: _textPrimaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentMood['detail']!,
                          style: GoogleFonts.inter(
                            color: _textSecondaryColor,
                            fontSize: 7.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          _buildMoodCarousel(),
        ],
      ),
    );
  }

  Widget _buildMoodCarousel() {
    final nextIndex = (_moodIndex + 1) % _moods.length;

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.center,
              children: [
                ...previousChildren,
                ?currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0.055, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slide,
                child: child,
              ),
            );
          },
          child: Row(
            key: ValueKey<int>(_moodIndex),
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _moodArrow(Icons.chevron_left_rounded, -1),
              const SizedBox(width: 7),
              Expanded(
                flex: 10,
                child: _moodOption(_moodIndex, selectedOverride: true),
              ),
              const SizedBox(width: 7),
              Expanded(
                flex: 9,
                child: _moodOption(nextIndex, selectedOverride: false),
              ),
              const SizedBox(width: 7),
              _moodArrow(Icons.chevron_right_rounded, 1),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_moods.length, (index) {
            final selected = index == _moodIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 7 : 5,
              height: selected ? 7 : 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? _deepSurfaceColor
                    : AppColors.gold.withValues(alpha: 0.34),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _moodArrow(IconData icon, int direction) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _changeMood(direction),
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _deepSurfaceColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDarkMode ? 0.16 : 0.07),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.gold, size: 18),
        ),
      ),
    );
  }

  Widget _moodOption(int index, {bool? selectedOverride}) {
    final mood = _moods[index];
    final selected = selectedOverride ?? index == _moodIndex;

    return InkWell(
      onTap: () => _selectMood(index),
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _deepSurfaceColor : _backgroundColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.88)
                : AppColors.gold.withValues(alpha: 0.30),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isDarkMode ? 0.14 : 0.055,
                    ),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(mood['emoji']!, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                mood['label']!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: selected ? AppColors.background : _textPrimaryColor,
                  fontSize: 7.3,
                  height: 1.28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeMood(int direction) {
    final next = (_moodIndex + direction + _moods.length) % _moods.length;
    _selectMood(next);
  }

  void _selectMood(int index) {
    if (index == _moodIndex) return;
    setState(() => _moodIndex = index);
  }

  Future<void> _showCustomMoodEditor() async {
    final emojiController = TextEditingController(text: _customMoodEmoji);
    final labelController = TextEditingController(text: _customMoodLabel);
    final detailController = TextEditingController(text: _customMoodDetail);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        var isSaving = false;
        var savingDots = 1;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final previewEmoji = emojiController.text.trim().isEmpty
                ? '✨'
                : emojiController.text.trim();
            final previewLabel = labelController.text.trim().isEmpty
                ? 'Mi propio estado'
                : labelController.text.trim();
            final previewDetail = detailController.text.trim().isEmpty
                ? 'Una lectura a mi manera'
                : detailController.text.trim();

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _goldColor.withValues(alpha: 0.38),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isDarkMode ? 0.34 : 0.18,
                      ),
                      blurRadius: 32,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color:
                                  _textSecondaryColor.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _goldColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color:
                                      _goldColor.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: _goldColor,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ESTADO PERSONALIZADO',
                                    style: GoogleFonts.cinzel(
                                      color: _headingColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.25,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Define cómo quieres aparecer ante otros lectores.',
                                    style: GoogleFonts.inter(
                                      color: _textSecondaryColor,
                                      fontSize: 8.3,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Cerrar',
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: _headingColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'VISTA PREVIA',
                          style: GoogleFonts.inter(
                            color: _textSecondaryColor,
                            fontSize: 7.4,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _goldColor.withValues(alpha: 0.36),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _goldColor.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  previewEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      previewLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.merriweather(
                                        color: _headingColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      previewDetail,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: _textSecondaryColor,
                                        fontSize: 7.8,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PERSONALIZACIÓN',
                          style: GoogleFonts.inter(
                            color: _textSecondaryColor,
                            fontSize: 7.4,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 86,
                              child: _customMoodField(
                                controller: emojiController,
                                label: 'Emoji',
                                hintText: '✨',
                                maxLength: 2,
                                enabled: !isSaving,
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _customMoodField(
                                controller: labelController,
                                label: 'Estado',
                                hintText: 'Mi propio estado',
                                enabled: !isSaving,
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        _customMoodField(
                          controller: detailController,
                          label: 'Detalle',
                          hintText: 'Una lectura a mi manera',
                          maxLines: 2,
                          enabled: !isSaving,
                          onChanged: (_) => setModalState(() {}),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final label =
                                        labelController.text.trim();
                                    if (label.isEmpty) return;

                                    setModalState(() {
                                      isSaving = true;
                                      savingDots = 1;
                                    });

                                    for (var step = 0;
                                        step < 4;
                                        step++) {
                                      await Future<void>.delayed(
                                        const Duration(milliseconds: 250),
                                      );

                                      if (!sheetContext.mounted) return;

                                      setModalState(() {
                                        savingDots = (savingDots % 3) + 1;
                                      });
                                    }

                                    if (!mounted ||
                                        !sheetContext.mounted) {
                                      return;
                                    }

                                    setState(() {
                                      _customMoodEmoji =
                                          emojiController.text.trim().isEmpty
                                              ? '✨'
                                              : emojiController.text.trim();
                                      _customMoodLabel = label;
                                      _customMoodDetail =
                                          detailController.text.trim().isEmpty
                                              ? 'Estado lector personalizado'
                                              : detailController.text.trim();
                                      _moodIndex = _moods.length - 1;
                                    });

                                    Navigator.of(sheetContext).pop();
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: isSaving
                                  ? _accentColor.withValues(alpha: 0.58)
                                  : _accentColor,
                              disabledBackgroundColor:
                                  _accentColor.withValues(alpha: 0.58),
                              foregroundColor: AppColors.background,
                              disabledForegroundColor:
                                  AppColors.background.withValues(alpha: 0.82),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              isSaving
                                  ? 'Guardando${'.' * savingDots}'
                                  : 'Guardar estado',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));
    emojiController.dispose();
    labelController.dispose();
    detailController.dispose();
  }


  Widget _customMoodField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    final isMultiline = maxLines > 1;

    final field = TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      maxLines: isMultiline ? null : 1,
      minLines: isMultiline ? null : 1,
      expands: isMultiline,
      textAlignVertical: TextAlignVertical.center,
      maxLength: maxLength,
      style: GoogleFonts.inter(
        color: _textPrimaryColor,
        fontSize: 10.5,
        height: 1.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        counterText: '',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: GoogleFonts.inter(
          color: _textSecondaryColor,
          fontSize: 8.5,
        ),
        hintStyle: GoogleFonts.inter(
          color: _textSecondaryColor.withValues(alpha: 0.72),
          fontSize: 9.5,
        ),
        filled: true,
        fillColor: _backgroundColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isMultiline ? 0 : 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _goldColor.withValues(alpha: 0.48),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _goldColor.withValues(alpha: 0.95),
            width: 1.25,
          ),
        ),
      ),
    );

    if (!isMultiline) return field;

    return SizedBox(
      height: 58,
      child: field,
    );
  }


  Widget _buildClubsCard() {
    final joinedClubs = _joinedClubs;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MIS CLUBES DE LECTURA',
                  style: GoogleFonts.cinzel(
                    color: _headingColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${joinedClubs.length} ${joinedClubs.length == 1 ? 'club' : 'clubes'}',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (joinedClubs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'Aún no te has unido a un club desde Inicio.',
                style: GoogleFonts.merriweather(
                  color: _textSecondaryColor,
                  fontSize: 8.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...joinedClubs.map((club) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            club.name,
                            style: GoogleFonts.merriweather(
                              color: _textPrimaryColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _showClubDetails(club),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.gold,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                minimumSize: const Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: GoogleFonts.inter(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Ver'),
                            ),
                            TextButton(
                              onPressed: () => widget.onToggleClub(club.id),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: GoogleFonts.inter(
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                              child: const Text('Salir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Leyendo: ${club.book}',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '📅 ${club.date} · ${club.members} lectores',
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Modalidad: ${club.modality}',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
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
      backgroundColor: _backgroundColor,
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
                                color: _textPrimaryColor,
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
                                color: _surfaceColor,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: AppColors.gold,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentClub.name,
                                    style: GoogleFonts.merriweather(
                                      color: _textPrimaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentClub.description,
                                    style: GoogleFonts.inter(
                                      color: _textPrimaryColor,
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
                                          color: _textSecondaryColor,
                                          fontSize: 8,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          extra['author']!,
                                          style: GoogleFonts.inter(
                                            color: AppColors.accent,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppColors.accent,
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
                                        color: AppColors.accent,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Debate: ${currentClub.date}',
                                          style: GoogleFonts.inter(
                                            color: _textSecondaryColor,
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
                                        color: _deepSurfaceColor,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${currentClub.members} lectores',
                                        style: GoogleFonts.inter(
                                          color: _textSecondaryColor,
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
                                        color: _deepSurfaceColor,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Modalidad: ${currentClub.modality}',
                                        style: GoogleFonts.inter(
                                          color: _textSecondaryColor,
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
                                color: _surfaceColor,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'REDES SOCIALES',
                                    style: GoogleFonts.cinzel(
                                      color: _textPrimaryColor,
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
                        color: _backgroundColor,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.16),
                          ),
                        ),
                      ),
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: () {
                            widget.onToggleClub(id);
                            setSheetState(() {});
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: joined
                                ? AppColors.surfaceSoftOf(context)
                                : AppColors.accent,
                            foregroundColor: joined
                                ? _textPrimaryColor
                                : AppColors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: joined
                                ? BorderSide(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.55),
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
            color: _textSecondaryColor,
            size: 13,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _textSecondaryColor,
              fontSize: 8,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.accent,
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
      color: AppColors.gold.withValues(alpha: 0.14),
    );
  }

  Widget _buildFavoriteQuote() {
    final quote = _favoriteQuotes[_quoteIndex];
    final work = quote['work'] ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: AppColors.gold, width: 4),
          top: BorderSide(color: AppColors.gold, width: 0.6),
          right: BorderSide(color: AppColors.gold, width: 0.6),
          bottom: BorderSide(color: AppColors.gold, width: 0.6),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: -22,
            child: Text(
              '“',
              style: GoogleFonts.merriweather(
                color: AppColors.gold.withValues(alpha: 0.14),
                fontSize: 58,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'CITA FAVORITA ANCLADA',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _quoteIndex =
                            (_quoteIndex + 1) % _favoriteQuotes.length;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 26),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Cambiar',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  '“${quote['text']}”',
                  style: GoogleFonts.merriweather(
                    color: _textPrimaryColor,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '— ${quote['author']}${work.isEmpty ? '' : ' · $work'}',
                style: GoogleFonts.inter(
                  color: _textSecondaryColor,
                  fontSize: 7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookDna() {
    final genres = _topGenres;
    final total = _readBooks.isEmpty ? 1 : _readBooks.length;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GÉNEROS MÁS LEÍDOS',
            style: GoogleFonts.cinzel(
              color: _headingColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          if (genres.isEmpty)
            Text(
              'Cuando finalices libros, aquí aparecerá tu ADN lector.',
              style: GoogleFonts.inter(color: _textSecondaryColor, fontSize: 8),
            )
          else
            ...genres.map((entry) {
              final progress = entry.value / total;
              final percent = (progress * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.inter(
                              color: _textPrimaryColor,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _gradientProgressBar(progress, height: 7),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _gradientProgressBar(double progress, {double height = 8}) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(height),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              width: constraints.maxWidth * safeProgress,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE3BD58),
                    Color(0xFFC78335),
                    AppColors.accent,
                  ],
                ),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadingChallenge() {
    final progress = widget.annualGoal > 0
        ? (_booksReadThisYear / widget.annualGoal).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'RETO DE LECTURA ANUAL',
                  style: GoogleFonts.cinzel(
                    color: _headingColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$_booksReadThisYear / ${widget.annualGoal} libros',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _gradientProgressBar(progress, height: 9),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${(progress * 100).round()}% completado',
                  style: GoogleFonts.inter(
                    color: _textSecondaryColor,
                    fontSize: 8,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showMarkBookAsRead,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Registrar libro'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMarkBookAsRead() {
    final readingBooks = widget.books
        .where((book) => widget.statuses[book.id] == BookStatus.leyendo)
        .toList();

    bool showSuccessMessage = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.64,
              minChildSize: 0.42,
              maxChildSize: 0.86,
              builder: (context, scrollController) {
                return Container(
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.45),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 9),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _textSecondaryColor.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 14, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: _goldColor.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              color: _accentColor,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REGISTRAR LIBRO FINALIZADO',
                                  style: GoogleFonts.cinzel(
                                    color: _headingColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Solo aparecen los libros que tienes actualmente en Leyendo.',
                                  style: GoogleFonts.inter(
                                    color: _textSecondaryColor,
                                    fontSize: 8,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: _headingColor,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: _goldColor.withValues(alpha: 0.18),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: showSuccessMessage
                          ? Padding(
                              key: const ValueKey('register-success'),
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? const Color(0xFF283125)
                                      : const Color(0xFFF4F7EE),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF78935F)
                                        .withValues(alpha: 0.72),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF708A56),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 11),
                                    Expanded(
                                      child: Text(
                                        'Libro registrado correctamente',
                                        style: GoogleFonts.merriweather(
                                          color: _isDarkMode
                                              ? const Color(0xFFE7EEDC)
                                              : const Color(0xFF3F4F33),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.auto_stories_rounded,
                                      color: _goldColor.withValues(alpha: 0.76),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('register-success-empty'),
                            ),
                    ),
                    Expanded(
                      child: readingBooks.isEmpty
                          ? ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                34,
                                22,
                                26,
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: _surfaceColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _goldColor.withValues(alpha: 0.30),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: _goldColor.withValues(alpha: 0.10),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.menu_book_rounded,
                                          color: _goldColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No tienes libros en lectura',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.merriweather(
                                          color: _headingColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Cuando tengas un libro en el estante Leyendo, aparecerá aquí para poder registrarlo como finalizado.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          color: _textSecondaryColor,
                                          fontSize: 8,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                24,
                              ),
                              itemCount: readingBooks.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 9),
                              itemBuilder: (context, index) {
                                final book = readingBooks[index];
                                final progress =
                                    (widget.progresses[book.id] ?? 0)
                                        .clamp(0, 100)
                                        .toInt();

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(15),
                                    onTap: () {
                                      widget.onStatusChanged(
                                        book.id,
                                        BookStatus.leido,
                                      );
                                      widget.onProgressChanged(book.id, 100);

                                      setSheetState(() {
                                        readingBooks.removeWhere(
                                          (candidate) => candidate.id == book.id,
                                        );
                                        showSuccessMessage = true;
                                      });

                                      Future<void>.delayed(
                                        const Duration(milliseconds: 2500),
                                        () {
                                          if (!sheetContext.mounted) return;

                                          setSheetState(() {
                                            showSuccessMessage = false;
                                          });
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _surfaceColor,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: _goldColor.withValues(alpha: 0.34),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              book.cover,
                                              width: 47,
                                              height: 66,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  Container(
                                                width: 47,
                                                height: 66,
                                                color: _deepSurfaceColor,
                                                child: Icon(
                                                  Icons.menu_book_rounded,
                                                  color: _goldColor,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 11),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  book.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      GoogleFonts.merriweather(
                                                    color: _headingColor,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  book.author,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    color:
                                                        _textSecondaryColor,
                                                    fontSize: 7.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          LinearProgressIndicator(
                                                        value:
                                                            progress / 100,
                                                        minHeight: 4,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          99,
                                                        ),
                                                        backgroundColor:
                                                            _goldColor.withValues(
                                                          alpha: 0.14,
                                                        ),
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          _accentColor,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 7),
                                                    Text(
                                                      '$progress%',
                                                      style:
                                                          GoogleFonts.inter(
                                                        color:
                                                            _accentColor,
                                                        fontSize: 7.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: _accentColor
                                                  .withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: _accentColor
                                                    .withValues(alpha: 0.24),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.check_rounded,
                                              color: _accentColor,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  Widget _buildTabs() {
    final worksCount = widget.publishedStories.length;
    const badgesCount = 5;

    final tabs = [
      {'id': 'favoritos', 'label': 'Favoritos'},
      {'id': 'resenas', 'label': 'Mis Reseñas'},
      {'id': 'lecturas', 'label': 'Mis Lecturas'},
      {
        'id': 'obras',
        'label': worksCount > 0 ? 'Mis obras ($worksCount)' : 'Mis obras',
      },
      {
        'id': 'insignias',
        'label': badgesCount > 0 ? 'Insignias ($badgesCount)' : 'Insignias',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final active = _selectedTab == tab['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedTab = tab['id']!),
              child: Container(
                padding: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab['label']!,
                  style: GoogleFonts.inter(
                    color: active ? AppColors.accent : _textSecondaryColor,
                    fontSize: 8,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedTab) {
      case 'favoritos':
        return _buildFavorites();
      case 'resenas':
        return _buildReviews();
      case 'lecturas':
        return _buildShelf();
      case 'obras':
        return _buildWorks();
      case 'insignias':
        return _buildBadges();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFavorites() {
    if (_favoriteShelfItems.isEmpty) {
      return _emptyCard('Todavía no tienes favoritos.');
    }

    return _sectionCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MI ESTANTE FAVORITO',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Todos tus favoritos, tanto libros como obras de la comunidad, se guardan automáticamente aquí.',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_favoriteCount favoritos',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _showExpandedFavoriteShelf,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      backgroundColor:
                          AppColors.accent.withValues(alpha: 0.08),
                      minimumSize: const Size(0, 26),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ver estante',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildShelfVisual(
            compact: true,
            sourceItems: _favoriteShelfItems,
          ),
        ],
      ),
    );
  }

  void _openFavoriteCommunityStory(WriterStory story) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublishedStoryScreen(
          story: story,
          currentUsername: widget.username,
          initiallyFavorite: true,
          onToggleFavorite: () {
            widget.onToggleCommunityStoryFavorite(story);
          },
        ),
      ),
    );
  }

  LibraryBook? _bookById(int id) {
    for (final book in widget.books) {
      if (book.id == id) return book;
    }
    return null;
  }

  Widget _buildReviews() {
    final reviewEntries = widget.reviews.entries
        .where((entry) => entry.value.isPublic)
        .toList();
    if (reviewEntries.isEmpty) {
      return _emptyCard('Aún no has publicado reseñas.');
    }
    return Column(
      children: reviewEntries.map((entry) {
        final book = _bookById(entry.key);
        if (book == null) return const SizedBox.shrink();
        final review = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: InkWell(
            onTap: () => _openBookDetail(book),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.36),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      book.cover,
                      width: 52,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 52,
                        height: 74,
                        color: _deepSurfaceColor,
                        child: const Icon(
                          Icons.menu_book,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: GoogleFonts.merriweather(
                            color: _textPrimaryColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          List<String>.filled(review.rating, '★').join(),
                          style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          review.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            color: _textSecondaryColor,
                            fontSize: 7.7,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _smallBadge(
                              review.isPublic ? 'Pública' : 'Privada',
                            ),
                            const Spacer(),
                            Text(
                              'Abrir libro →',
                              style: GoogleFonts.inter(
                                color: AppColors.accent,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _smallBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _headingColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: _headingColor,
          fontSize: 6.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildShelf() {
    return _sectionCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MI ESTANTE LEÍDO',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cada lectura terminada deja un libro en tu colección.',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_readBooks.length} libros',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _showExpandedShelf,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                      minimumSize: const Size(0, 26),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ver estante',
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_readBooks.isEmpty)
            Text(
              'Cuando finalices un libro desde Mi Biblioteca aparecerá automáticamente aquí.',
              style: GoogleFonts.merriweather(
                color: _textSecondaryColor,
                fontSize: 8,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            _buildShelfVisual(compact: true),
        ],
      ),
    );
  }

  Widget _buildShelfVisual({
    required bool compact,
    List<Object>? sourceItems,
  }) {
    final books = sourceItems ?? _readBooks.cast<Object>();
    final rowCount = compact ? 2 : 4;
    final perRow = compact ? 5 : 6;
    final maxBooks = rowCount * perRow;
    final visibleBooks = books.take(maxBooks).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 10,
        compact ? 8 : 10,
        compact ? 8 : 10,
        compact ? 9 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFC58C61),
        borderRadius: BorderRadius.circular(compact ? 15 : 19),
        border: Border.all(color: const Color(0xFF9A623C), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C321D).withValues(alpha: 0.22),
            blurRadius: compact ? 8 : 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(compact ? 12 : 16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD7A57C),
                    Color(0xFFC38E66),
                    Color(0xFFB77C54),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _shelfSideRail(compact),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _shelfSideRail(compact),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 11),
            child: Column(
              children: List.generate(rowCount, (rowIndex) {
                final start = rowIndex * perRow;
                final end = (start + perRow).clamp(0, visibleBooks.length);
                final rowBooks = start < visibleBooks.length
                    ? visibleBooks.sublist(start, end)
                    : <Object>[];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: rowIndex == rowCount - 1 ? 0 : (compact ? 8 : 10),
                  ),
                  child: _buildShelfRow(
                    books: rowBooks,
                    compact: compact,
                    rowIndex: rowIndex,
                    globalStartIndex: start,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shelfSideRail(bool compact) {
    return Container(
      width: compact ? 7 : 10,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF774528), Color(0xFFB36F43), Color(0xFF6E3D23)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 4,
            offset: const Offset(1, 0),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfRow({
    required List<Object> books,
    required bool compact,
    required int rowIndex,
    required int globalStartIndex,
  }) {
    final rowHeight = compact ? 91.0 : 122.0;

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 9 : 12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD8AE89), Color(0xFFC39169), Color(0xFFB47B52)],
        ),
        border: Border.all(color: const Color(0xFF99603A), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: compact ? 7 : 9,
            right: compact ? 7 : 9,
            bottom: compact ? 10 : 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _leftShelfDecoration(rowIndex, compact),
                SizedBox(width: compact ? 5 : 7),
                ...books.asMap().entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(right: compact ? 3 : 4),
                    child: _shelfSpine(
                      entry.value,
                      index: globalStartIndex + entry.key,
                      compact: compact,
                    ),
                  );
                }),
                const Spacer(),
                _rightShelfDecoration(rowIndex, compact),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: compact ? 9 : 12,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFA86239),
                    Color(0xFF774023),
                    Color(0xFF5B2F1A),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftShelfDecoration(int rowIndex, bool compact) {
    switch (rowIndex % 4) {
      case 0:
        return _plantDecoration(compact, flower: false);
      case 1:
        return _flowerPotDecoration(compact);
      case 2:
        return _candleDecoration(compact);
      default:
        return _bookendDecoration(compact);
    }
  }

  Widget _rightShelfDecoration(int rowIndex, bool compact) {
    switch (rowIndex % 4) {
      case 0:
        return _flowerPotDecoration(compact);
      case 1:
        return _candleDecoration(compact);
      case 2:
        return _plantDecoration(compact, flower: false);
      default:
        return _lighthouseDecoration(compact);
    }
  }

  Widget _shelfSpine(
    Object item, {
    required int index,
    required bool compact,
  }) {
    const colors = [
      Color(0xFF2E6293),
      Color(0xFFE8D7B8),
      Color(0xFF283C37),
      Color(0xFFB8794D),
      Color(0xFF2C4D68),
      Color(0xFF71573C),
      Color(0xFF5F785C),
      Color(0xFFD2A851),
      Color(0xFF85433B),
      Color(0xFF3D5E78),
      Color(0xFF6E4933),
      Color(0xFF9E5A49),
    ];

    final String title;
    final VoidCallback onTap;

    if (item is LibraryBook) {
      title = item.title;
      onTap = () => _openBookDetail(item);
    } else if (item is WriterStory) {
      title = item.title;
      onTap = () => _openFavoriteCommunityStory(item);
    } else {
      title = 'Favorito';
      onTap = () {};
    }

    final color = colors[index % colors.length];
    final width = compact ? 17.0 + (index % 3) : 21.0 + (index % 3) * 1.5;
    final height =
        compact ? 53.0 + (index % 4) * 6 : 76.0 + (index % 4) * 8;
    final lightText = color.computeLuminance() < 0.48;

    return Tooltip(
      message: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.20),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 2,
                offset: const Offset(1.3, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 2,
                right: 2,
                top: compact ? 5 : 7,
                child: Container(
                  height: 1,
                  color: lightText
                      ? Colors.white.withValues(alpha: 0.28)
                      : AppColors.deep.withValues(alpha: 0.28),
                ),
              ),
              Positioned(
                left: 2,
                right: 2,
                bottom: compact ? 5 : 7,
                child: Container(
                  height: 1,
                  color: lightText
                      ? Colors.white.withValues(alpha: 0.28)
                      : AppColors.deep.withValues(alpha: 0.28),
                ),
              ),
              Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: lightText
                            ? const Color(0xFFF8EEDB)
                            : const Color(0xFF4A2B1D),
                        fontSize: compact ? 4.3 : 5.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plantDecoration(bool compact, {required bool flower}) {
    return SizedBox(
      width: compact ? 23 : 30,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            flower ? '🌸' : '🌿',
            style: TextStyle(fontSize: compact ? 15 : 21),
          ),
          Container(
            width: compact ? 13 : 17,
            height: compact ? 8 : 11,
            decoration: BoxDecoration(
              color: const Color(0xFFB56F48),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(5),
              ),
              border: Border.all(color: const Color(0xFF77452C), width: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowerPotDecoration(bool compact) {
    return _plantDecoration(compact, flower: true);
  }

  Widget _candleDecoration(bool compact) {
    return SizedBox(
      width: compact ? 17 : 22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: const Color(0xFFF3B34B),
            size: compact ? 9 : 12,
          ),
          Container(
            width: compact ? 7 : 9,
            height: compact ? 15 : 20,
            decoration: BoxDecoration(
              color: const Color(0xFFF1E7D1),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFFCAB58A), width: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookendDecoration(bool compact) {
    return Container(
      width: compact ? 9 : 12,
      height: compact ? 22 : 30,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE1CB),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFFB89A73), width: 0.7),
      ),
    );
  }

  Widget _lighthouseDecoration(bool compact) {
    return SizedBox(
      width: compact ? 20 : 28,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.light_mode_rounded,
            color: const Color(0xFFF4C568),
            size: compact ? 9 : 12,
          ),
          Container(
            width: compact ? 9 : 12,
            height: compact ? 24 : 33,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF3E8D4),
                  Color(0xFFA94A3F),
                  Color(0xFFF3E8D4),
                ],
                stops: [0, 0.52, 1],
              ),
            ),
          ),
          Container(
            width: compact ? 15 : 20,
            height: compact ? 3 : 4,
            decoration: BoxDecoration(
              color: const Color(0xFF67402A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  void _showExpandedFavoriteShelf() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _backgroundColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MI BIBLIOTECA PERSONAL',
                            style: GoogleFonts.inter(
                              color: _textSecondaryColor,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'MIS FAVORITOS',
                            style: GoogleFonts.cinzel(
                              color: _headingColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Todos tus libros y obras favoritas, reunidos en un solo estante.',
                            style: GoogleFonts.merriweather(
                              color: _textSecondaryColor,
                              fontSize: 8,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8A5939),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Confirmar',
                        style: GoogleFonts.inter(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E0D0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD4B18F),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        '$_favoriteCount favoritos guardados',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8C5A37),
                          fontSize: 6.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Toca un lomo para abrir el libro.',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 6.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: _favoriteShelfItems.isEmpty
                        ? _emptyCard(
                            'Cuando marques algo como favorito, aparecerá aquí.',
                          )
                        : _buildShelfVisual(
                            compact: false,
                            sourceItems: _favoriteShelfItems,
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

  void _showExpandedShelf() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _backgroundColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MI BIBLIOTECA PERSONAL',
                            style: GoogleFonts.inter(
                              color: _textSecondaryColor,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'MIS LECTURAS',
                            style: GoogleFonts.cinzel(
                              color: _headingColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Portadas, lomos y pequeñas historias de una colección que sigue creciendo.',
                            style: GoogleFonts.merriweather(
                              color: _textSecondaryColor,
                              fontSize: 8,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8A5939),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Confirmar',
                        style: GoogleFonts.inter(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E0D0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD4B18F),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        '${_readBooks.length} lecturas registradas',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8C5A37),
                          fontSize: 6.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Los libros del usuario son interactivos.',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 6.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: _readBooks.isEmpty
                        ? _emptyCard(
                            'Cuando finalices libros, aparecerán aquí.',
                          )
                        : _buildShelfVisual(compact: false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorks() {
    final stories = widget.publishedStories;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MIS OBRAS',
                  style: GoogleFonts.cinzel(
                    color: _headingColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${stories.length} ${stories.length == 1 ? 'obra' : 'obras'}',
                style: GoogleFonts.inter(
                  color: AppColors.accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (stories.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    color: AppColors.gold.withValues(alpha: 0.85),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aún no has publicado obras.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.merriweather(
                      color: _textPrimaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cuando publiques una historia desde Escribir, aparecerá automáticamente aquí.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _textSecondaryColor,
                      fontSize: 7.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ...stories.asMap().entries.map((entry) {
              final story = entry.value;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == stories.length - 1 ? 0 : 9,
                ),
                child: InkWell(
                  onTap: () => _openPublishedWork(story),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWriterStoryCover(story),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.title.trim().isEmpty
                                    ? 'Historia sin título'
                                    : story.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.merriweather(
                                  color: _textPrimaryColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                story.genre.trim().isEmpty
                                    ? 'Sin género'
                                    : story.genre,
                                style: GoogleFonts.inter(
                                  color: _textSecondaryColor,
                                  fontSize: 7.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _publishedWorkBadge(),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      '${story.publishedChapterCount} ${story.publishedChapterCount == 1 ? 'capítulo publicado' : 'capítulos publicados'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: _textSecondaryColor,
                                        fontSize: 6.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Text(
                                story.synopsis.trim().isEmpty
                                    ? 'Sin sinopsis.'
                                    : story.synopsis,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.merriweather(
                                  color: _textSecondaryColor,
                                  fontSize: 7.2,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.gold.withValues(alpha: 0.90),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWriterStoryCover(WriterStory story) {
    final cover = story.coverPath?.trim() ?? '';
    final hasNetworkCover =
        cover.startsWith('http://') || cover.startsWith('https://');

    return Container(
      width: 50,
      height: 70,
      decoration: BoxDecoration(
        color: _deepSurfaceColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasNetworkCover
          ? Image.network(
              cover,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _writerStoryCoverPlaceholder(story),
            )
          : _writerStoryCoverPlaceholder(story),
    );
  }

  Widget _writerStoryCoverPlaceholder(WriterStory story) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _deepSurfaceColor,
            _deepSurfaceColor.withValues(alpha: 0.78),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: AppColors.gold,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            story.title.trim().isEmpty
                ? 'TU OBRA'
                : story.title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              color: AppColors.background,
              fontSize: 4.8,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _publishedWorkBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        'PUBLICADA',
        style: GoogleFonts.inter(
          color: AppColors.accent,
          fontSize: 5.7,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  void _openPublishedWork(WriterStory story) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublishedStoryScreen(
          story: story,
          currentUsername: widget.username,
        ),
      ),
    );
  }

  Widget _buildBadges() {
    final badges = <Map<String, Object>>[
      {
        'icon': Icons.auto_stories_rounded,
        'title': 'Lectora constante',
        'description': 'Mantienes el hábito de lectura activo.',
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'title': 'Racha de 14 días',
        'description': 'Dos semanas leyendo sin perder el ritmo.',
      },
      {
        'icon': Icons.dark_mode_rounded,
        'title': 'Amante del gótico',
        'description': 'Tus lecturas reflejan tu lado más oscuro.',
      },
      {
        'icon': Icons.star_rounded,
        'title': '${widget.reviews.values.where((review) => review.isPublic).length} reseñas guardadas',
        'description': 'Compartes tu opinión sobre lo que lees.',
      },
      {
        'icon': Icons.emoji_events_rounded,
        'title': '$_booksReadThisYear libros este año',
        'description': 'Cada libro terminado suma a tu recorrido.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _goldColor.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: _goldColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: _goldColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TUS LOGROS LECTORES',
                      style: GoogleFonts.cinzel(
                        color: _headingColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${badges.length} insignias desbloqueadas',
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 1.28,
          ),
          itemBuilder: (context, index) {
            final badge = badges[index];
            final icon = badge['icon']! as IconData;
            final title = badge['title']! as String;
            final description = badge['description']! as String;

            return Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _goldColor.withValues(alpha: 0.34),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: index == 1
                          ? _accentColor.withValues(alpha: 0.09)
                          : _goldColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: index == 1
                            ? _accentColor.withValues(alpha: 0.20)
                            : _goldColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: index == 1 ? _accentColor : _goldColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.merriweather(
                      color: _headingColor,
                      fontSize: 8.2,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _textSecondaryColor,
                      fontSize: 6.9,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.merriweather(
          color: _textSecondaryColor,
          fontSize: 8.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(13),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.38)),
      ),
      child: child,
    );
  }

  void _openBookDetail(LibraryBook book) {
    final bookData = <String, dynamic>{
      'id': book.id,
      'title': book.title,
      'author': book.authorHandle ?? book.author,
      'authorReal': book.author,
      'rating': 4.8,
      'year': book.year,
      'genre': book.genre,
      'availability': 'GRATIS',
      'isbn': book.isbn,
      'cover': book.cover,
      'synopsis': book.synopsis,
    };

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => HomeBookDetailScreen(
              book: bookData,
              currentUsername: widget.username,
              isGuest: false,
              onGuestRestrictedAction: () {},
              initialReview: widget.reviews[book.id],
              onReviewSaved: widget.onReviewSaved,
              initiallyFavorite: widget.favorites.contains(book.id),
              onToggleFavorite: () {
                widget.onToggleFavorite(book.id);
              },
              onOpenOwnProfile: () {
                Navigator.of(context).pop();
              },
              onAddToLibrary: () {
                widget.onStatusChanged(
                  book.id,
                  widget.statuses[book.id] ?? BookStatus.porLeer,
                );
                _showMessage('${book.title} está en tu biblioteca.');
              },
            ),
          ),
        )
        .then((_) {
          if (mounted) setState(() {});
        });
  }

  void _showSocialList(String title, List<Map<String, String>> users) {
    final isFollowers = title == 'Seguidores';

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        String? socialSuccessMessage;

        return StatefulBuilder(
          builder: (context, modalSetState) {
            final visibleUsers = users
                .where((user) => !_blockedUsers.contains(user['user']))
                .toList();

            return Container(
              height: MediaQuery.sizeOf(sheetContext).height * 0.70,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border(
                  top: BorderSide(
                    color: _goldColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 9),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _textSecondaryColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _deepSurfaceColor,
                            border: Border.all(
                              color: _goldColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            isFollowers
                                ? Icons.people_outline_rounded
                                : Icons.person_add_alt_1_rounded,
                            color: _goldColor,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.toUpperCase(),
                                style: GoogleFonts.cinzel(
                                  color: _headingColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isFollowers
                                    ? 'Personas que siguen tu perfil literario'
                                    : 'Perfiles que sigues actualmente',
                                style: GoogleFonts.inter(
                                  color: _textSecondaryColor,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: _textPrimaryColor,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: _goldColor.withValues(alpha: 0.16),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: socialSuccessMessage != null
                        ? Padding(
                            key: const ValueKey('social-block-success'),
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? const Color(0xFF283125)
                                    : const Color(0xFFF4F7EE),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF78935F)
                                      .withValues(alpha: 0.72),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF708A56),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Text(
                                      socialSuccessMessage!,
                                      style: GoogleFonts.merriweather(
                                        color: _isDarkMode
                                            ? const Color(0xFFE7EEDC)
                                            : const Color(0xFF3F4F33),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.person_off_outlined,
                                    color: _goldColor.withValues(alpha: 0.76),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('social-block-success-empty'),
                          ),
                  ),
                  Expanded(
                    child: visibleUsers.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFollowers
                                        ? Icons.people_outline_rounded
                                        : Icons.person_outline_rounded,
                                    size: 36,
                                    color: _goldColor.withValues(alpha: 0.75),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isFollowers
                                        ? 'No tienes seguidores visibles.'
                                        : 'No estás siguiendo perfiles visibles.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: _textSecondaryColor,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(14, 12, 14, 24),
                            itemCount: visibleUsers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = visibleUsers[index];

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: () => _showPublicProfile(user),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      7,
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _surfaceColor,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: _goldColor.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _deepSurfaceColor,
                                            border: Border.all(
                                              color: _goldColor.withValues(
                                                alpha: 0.55,
                                              ),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            user['initial']!,
                                            style: GoogleFonts.cinzel(
                                              color: _goldColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name']!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    GoogleFonts.merriweather(
                                                  color: _textPrimaryColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                user['user']!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: _accentColor,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Más opciones',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () async {
                                            final blocked =
                                                await _showSocialUserActions(
                                              user,
                                            );

                                            if (blocked && mounted) {
                                              setState(() {});

                                              modalSetState(() {
                                                socialSuccessMessage =
                                                    '${user['user'] ?? 'Usuario'} bloqueado correctamente';
                                              });

                                              Future<void>.delayed(
                                                const Duration(
                                                  milliseconds: 2500,
                                                ),
                                                () {
                                                  if (!sheetContext.mounted) {
                                                    return;
                                                  }

                                                  modalSetState(() {
                                                    socialSuccessMessage = null;
                                                  });
                                                },
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            color: _textSecondaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: isFollowers
                                              ? 'Eliminar seguidor'
                                              : 'Dejar de seguir',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () async {
                                            final removed =
                                                await _confirmRemoveSocialUser(
                                              user: user,
                                              isFollowers: isFollowers,
                                            );

                                            if (!removed || !mounted) {
                                              return;
                                            }

                                            setState(() {
                                              users.remove(user);
                                            });
                                            modalSetState(() {});
                                          },
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: _accentColor.withValues(
                                              alpha: 0.78,
                                            ),
                                            size: 19,
                                          ),
                                        ),
                                      ],
                                    ),
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
  }

  Future<bool> _showSocialUserActions(Map<String, String> user) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      isScrollControlled: true,
      builder: (actionContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _goldColor.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _textSecondaryColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _deepSurfaceColor,
                        border: Border.all(
                          color: _goldColor.withValues(alpha: 0.38),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user['initial']!,
                        style: GoogleFonts.cinzel(
                          color: _goldColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name']!,
                            style: GoogleFonts.merriweather(
                              color: _textPrimaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user['user']!,
                            style: GoogleFonts.inter(
                              color: _textSecondaryColor,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () {
                      Navigator.of(actionContext).pop(true);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 31,
                            height: 31,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor.withValues(alpha: 0.11),
                            ),
                            child: Icon(
                              Icons.block_rounded,
                              color: _accentColor,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bloquear',
                                  style: GoogleFonts.inter(
                                    color: _accentColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'No podrá interactuar contigo ni ver tu perfil.',
                                  style: GoogleFonts.inter(
                                    color: _textSecondaryColor,
                                    fontSize: 7.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: _accentColor,
                            size: 19,
                          ),
                        ],
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

    if (result != true || !mounted) {
      return false;
    }

    final confirmed = await _confirmBlockUser(user);

    if (confirmed != true || !mounted) {
      return false;
    }

    ProfileBlockedUsersStore.block(user);

    if (mounted) {
      setState(() {});
    }

    return true;
  }

  Future<bool?> _confirmBlockUser(Map<String, String> user) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var isBlocking = false;
        var blockingDots = 1;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentColor.withValues(alpha: 0.10),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        color: _accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      '¿Bloquear a ${user['user']}?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        color: _textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Este usuario no podrá ver tu perfil ni nada relacionado a ti.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _textSecondaryColor,
                        fontSize: 9,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton(
                              onPressed: isBlocking
                                  ? null
                                  : () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _textPrimaryColor,
                                disabledForegroundColor:
                                    _textSecondaryColor.withValues(alpha: 0.55),
                                side: BorderSide(
                                  color: _goldColor.withValues(alpha: 0.38),
                                ),
                                backgroundColor:
                                    _surfaceColor.withValues(alpha: 0.48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: FilledButton(
                              onPressed: isBlocking
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isBlocking = true;
                                        blockingDots = 1;
                                      });

                                      for (var step = 0;
                                          step < 4;
                                          step++) {
                                        await Future<void>.delayed(
                                          const Duration(milliseconds: 250),
                                        );

                                        if (!dialogContext.mounted) return;

                                        setDialogState(() {
                                          blockingDots =
                                              (blockingDots % 3) + 1;
                                        });
                                      }

                                      if (!dialogContext.mounted) return;
                                      Navigator.of(dialogContext).pop(true);
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: isBlocking
                                    ? _accentColor.withValues(alpha: 0.58)
                                    : _accentColor,
                                disabledBackgroundColor:
                                    _accentColor.withValues(alpha: 0.58),
                                foregroundColor: AppColors.background,
                                disabledForegroundColor:
                                    AppColors.background.withValues(alpha: 0.82),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isBlocking
                                    ? 'Bloqueando${'.' * blockingDots}'
                                    : 'Bloquear',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
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
        );
      },
    );
  }



  Future<bool> _confirmRemoveSocialUser({
    required Map<String, String> user,
    required bool isFollowers,
  }) async {
    final username = user['user'] ?? '@usuario';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _goldColor.withValues(alpha: 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentColor.withValues(alpha: 0.10),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(
                    isFollowers
                        ? Icons.person_remove_alt_1_rounded
                        : Icons.person_off_outlined,
                    color: _accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  '¿Eliminar a $username?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: _textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isFollowers
                      ? '$username no recibirá una notificación de que ya no te sigue.'
                      : '$username no recibirá una notificación de que ya no lo sigues.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _textSecondaryColor,
                    fontSize: 9,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textPrimaryColor,
                            side: BorderSide(
                              color: _goldColor.withValues(alpha: 0.38),
                            ),
                            backgroundColor:
                                _surfaceColor.withValues(alpha: 0.48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Eliminar',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
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
    );

    return confirmed == true;
  }

  void _showPublicProfile(Map<String, String> user) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: _deepSurfaceColor,
                foregroundColor: AppColors.gold,
                child: Text(
                  user['initial']!,
                  style: GoogleFonts.cinzel(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user['name']!,
                style: GoogleFonts.merriweather(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                user['user']!,
                style: GoogleFonts.inter(color: AppColors.accent, fontSize: 9),
              ),
              const SizedBox(height: 10),
              Text(
                user['bio']!,
                textAlign: TextAlign.center,
                style: GoogleFonts.merriweather(fontSize: 9, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
