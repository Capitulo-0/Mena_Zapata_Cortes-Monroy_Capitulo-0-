import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/book_review.dart';
import '../../models/book_status.dart';
import '../../models/library_book.dart';
import '../../models/personal_library_list.dart';
import '../dialogs/library_review_dialog.dart';
import '../dialogs/library_export_dialogs.dart';
import '../dialogs/personal_list_dialogs.dart';
import '../widgets/personal_lists_view.dart';
import 'library_book_detail_screen.dart';
import '../widgets/library_book_card.dart';
import '../widgets/library_feedback_widgets.dart';
import '../widgets/library_header.dart';
import '../widgets/library_search_field.dart';
import '../widgets/library_status_counters.dart';
import '../widgets/library_view_selector.dart';

export '../../models/book_review.dart';
export '../../models/book_status.dart';
export '../../models/library_book.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.books,
    required this.statuses,
    required this.progresses,
    required this.reviews,
    required this.favorites,
    required this.currentName,
    required this.currentUsername,
    required this.onOpenProfile,
    required this.onStatusChanged,
    required this.onProgressChanged,
    required this.onReviewSaved,
    required this.onToggleFavorite,
    this.isGuest = false,
    this.onGuestRestrictedAction,
  });

  final List<LibraryBook> books;
  final Map<int, BookStatus> statuses;
  final Map<int, int> progresses;
  final Map<int, BookReview> reviews;
  final Set<int> favorites;
  final String currentName;
  final String currentUsername;
  final VoidCallback onOpenProfile;

  final void Function(int bookId, BookStatus status) onStatusChanged;
  final void Function(int bookId, int progress) onProgressChanged;
  final void Function(int bookId, BookReview review) onReviewSaved;
  final void Function(int bookId) onToggleFavorite;
  final bool isGuest;
  final VoidCallback? onGuestRestrictedAction;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _blockGuestAction() {
    if (!widget.isGuest) return false;
    widget.onGuestRestrictedAction?.call();
    return true;
  }

  final TextEditingController _searchController = TextEditingController();

  String _view = 'libros';
  String _filter = 'leyendo';
  String _query = '';
  bool _showFinishSuccess = false;

  final List<PersonalLibraryList> _personalLists = <PersonalLibraryList>[];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LibraryBook> get _booksInLibrary {
    return widget.books
        .where((book) => widget.statuses.containsKey(book.id))
        .toList();
  }

  List<LibraryBook> get _filteredBooks {
    var result = _booksInLibrary;

    result = result.where((book) {
      final status = widget.statuses[book.id];
      if (_filter == 'leyendo') return status == BookStatus.leyendo;
      if (_filter == 'porLeer') return status == BookStatus.porLeer;
      if (_filter == 'leidos') return status == BookStatus.leido;
      return false;
    }).toList();

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((book) {
        return book.title.toLowerCase().contains(q) ||
            book.author.toLowerCase().contains(q) ||
            book.genre.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  int _count(BookStatus status) {
    return widget.statuses.values.where((value) => value == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundOf(context),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildViewSelector(),
            const SizedBox(height: 12),
            if (_view == 'libros') ...[
              _buildSearch(),
              const SizedBox(height: 10),
              _buildCounters(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _showFinishSuccess
                    ? Padding(
                        key: const ValueKey('finish-success'),
                        padding: const EdgeInsets.only(top: 10),
                        child: _buildFinishSuccessMessage(),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('finish-success-empty'),
                      ),
              ),
              const SizedBox(height: 12),
              if (_filteredBooks.isEmpty)
                _buildEmptyState()
              else
                ..._filteredBooks.map(_buildBookCard),
            ] else
              _buildListsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LibraryHeader(
      currentName: widget.currentName,
      onOptionsTap: _showLibraryOptions,
    );
  }

  Widget _buildViewSelector() {
    return LibraryViewSelector(
      view: _view,
      onChanged: (view) {
        if (_view == view) return;

        setState(() {
          _view = view;
        });
      },
    );
  }

  Widget _buildSearch() {
    return LibrarySearchField(
      controller: _searchController,
      query: _query,
      onChanged: (value) {
        setState(() {
          _query = value;
        });
      },
      onClear: () {
        _searchController.clear();
        setState(() {
          _query = '';
        });
      },
    );
  }

  Widget _buildCounters() {
    return LibraryStatusCounters(
      filter: _filter,
      readingCount: _count(BookStatus.leyendo),
      pendingCount: _count(BookStatus.porLeer),
      readCount: _count(BookStatus.leido),
      onChanged: (filter) {
        if (_filter == filter) return;

        setState(() {
          _filter = filter;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return LibraryEmptyState(
      libraryEmpty: _booksInLibrary.isEmpty,
    );
  }

  Widget _buildBookCard(LibraryBook book) {
    final status = widget.statuses[book.id] ?? BookStatus.porLeer;
    final progress = widget.progresses[book.id] ?? 0;
    final review = widget.reviews[book.id];

    return LibraryBookCard(
      book: book,
      status: status,
      progress: progress,
      review: review,
      onOpen: () => _openBookDetail(book),
      onStartReading: () {
        widget.onStatusChanged(book.id, BookStatus.leyendo);
        widget.onProgressChanged(book.id, 0);
        setState(() {});
      },
      onAdvance: () {
        final next = (progress + 10).clamp(0, 100).toInt();
        widget.onProgressChanged(book.id, next);

        if (next >= 100) {
          widget.onStatusChanged(book.id, BookStatus.leido);
        }

        setState(() {});
      },
      onFinish: () {
        widget.onProgressChanged(book.id, 100);
        widget.onStatusChanged(book.id, BookStatus.leido);

        setState(() {
          _showFinishSuccess = true;
        });

        Future<void>.delayed(
          const Duration(milliseconds: 2500),
          () {
            if (!mounted) return;

            setState(() {
              _showFinishSuccess = false;
            });
          },
        );
      },
      onReviewTap: () => _openReviewEditor(book),
    );
  }

  Widget _buildFinishSuccessMessage() {
    return const LibraryFinishSuccessMessage();
  }

  Widget _buildListsView() {
    return PersonalListsView(
      lists: _personalLists,
      onCreateList: _showCreateListSheet,
      onOpenList: _showPersonalListDetail,
      onOpenMenu: _showPersonalListMiniMenu,
    );
  }

  Future<void> _showPersonalListMiniMenu(int index) async {
    final list = _personalLists[index];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 9, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.backgroundOf(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.32),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.deepOf(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      list.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.merriweather(
                          color: AppColors.textPrimaryOf(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _libraryOptionTile(
                  icon: Icons.playlist_add_rounded,
                  title: 'Agregar libro',
                  highlighted: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Future<void>.delayed(
                      const Duration(milliseconds: 160),
                      () => _showAddBookToListSheet(index),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _libraryOptionTile(
                  icon: Icons.edit_outlined,
                  title: 'Editar lista',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Future<void>.delayed(
                      const Duration(milliseconds: 160),
                      () => _showEditListSheet(index),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddBookToListSheet(int index) async {
    final list = _personalLists[index];

    final selected = await PersonalListDialogs.showAddBooksSheet(
      context: context,
      list: list,
      booksInLibrary: _booksInLibrary,
      statuses: widget.statuses,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _personalLists[index] = list.copyWith(
        bookIds: selected.toList(),
      );
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          duration: const Duration(milliseconds: 2500),
          padding: EdgeInsets.zero,
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF283125)
                  : const Color(0xFFF4F7EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    const Color(0xFF78935F).withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
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
                    selected.isEmpty
                        ? 'Guardado correctamente'
                        : 'Libros guardados correctamente a ${list.name}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.merriweather(
                      color: isDark
                          ? const Color(0xFFE7EEDC)
                          : const Color(0xFF3F4F33),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.playlist_add_check_rounded,
                  color: AppColors.gold.withValues(alpha: 0.76),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
  }

  Future<void> _showEditListSheet(int index) async {
    final updated = await PersonalListDialogs.showEditListSheet(
      context: context,
      list: _personalLists[index],
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _personalLists[index] = updated;
    });
  }

  Future<void> _showPersonalListDetail(int index) async {
    if (_blockGuestAction()) return;

    await PersonalListDialogs.showListDetail(
      context: context,
      list: _personalLists[index],
      books: widget.books,
    );
  }

  Future<void> _showLibraryOptions() async {
    if (_blockGuestAction()) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 9, 18, 22),
              decoration: BoxDecoration(
                color: AppColors.backgroundOf(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.deepOf(context),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'OPCIONES DE BIBLIOTECA',
                            style: GoogleFonts.cinzel(
                              color: AppColors.textPrimaryOf(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Text(
                          '✦',
                          style: TextStyle(
                            color: AppColors.goldOf(context),
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _libraryOptionTile(
                      icon: Icons.add_box_outlined,
                      title: 'Crear lista',
                      highlighted: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Future<void>.delayed(
                          const Duration(milliseconds: 180),
                          _showCreateListSheet,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _libraryOptionTile(
                      icon: Icons.download_outlined,
                      title: 'Exportar mi biblioteca',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Future<void>.delayed(
                          const Duration(milliseconds: 160),
                          _showExportLibraryDialog,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _libraryOptionTile(
                      icon: Icons.ios_share_outlined,
                      title: 'Exportar mi lista',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Future<void>.delayed(
                          const Duration(milliseconds: 160),
                          _showExportListDialog,
                        );
                      },
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

  Widget _libraryOptionTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.goldOf(context).withValues(alpha: 0.14)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.goldOf(context).withValues(
              alpha: highlighted ? 0.70 : 0.42,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.deepOf(context),
              size: 20,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconTheme(
              data: IconThemeData(
                color: AppColors.textPrimaryOf(context),
                size: 20,
              ),
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExportLibraryDialog() async {
    if (_blockGuestAction()) return;

    final total = _booksInLibrary.length;
    final reading = _count(BookStatus.leyendo);
    final pending = _count(BookStatus.porLeer);
    final read = _count(BookStatus.leido);

    await LibraryExportDialogs.showLibraryShareDialog(
      context: context,
      barrierLabel: 'Exportar biblioteca',
      eyebrow: 'EXPORTAR MI BIBLIOTECA',
      title: '¿Dónde deseas compartir?',
      summaryTitle: 'Se exportarán estos libros:',
      summaryMain:
          '$total ${total == 1 ? 'libro en tu biblioteca' : 'libros en tu biblioteca'}',
      summaryDetail:
          '$read leídos · $reading leyendo · $pending por leer',
      linkText:
          'Capítulo 0 · Mi biblioteca · $total libros · $read leídos · $reading leyendo · $pending por leer',
    );
  }

  Future<void> _showExportListDialog() async {
    if (_blockGuestAction()) return;

    await LibraryExportDialogs.showListSelector(
      context: context,
      lists: _personalLists,
    );
  }

  Future<void> _showCreateListSheet() async {
    if (_blockGuestAction()) return;

    final list = await PersonalListDialogs.showCreateListSheet(
      context: context,
    );

    if (list == null || !mounted) {
      return;
    }

    setState(() {
      _personalLists.add(list);
      _view = 'listas';
    });
  }

  void _openBookDetail(LibraryBook book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LibraryBookDetailScreen(
          book: book,
          currentUsername: widget.currentUsername,
          initialReview: widget.reviews[book.id],
          initiallyFavorite: widget.favorites.contains(book.id),
          status: widget.statuses[book.id],
          progress: widget.progresses[book.id] ?? 0,
          onReviewSaved: (review) {
            widget.onReviewSaved(book.id, review);
            setState(() {});
          },
          onToggleFavorite: () {
            widget.onToggleFavorite(book.id);
            setState(() {});
          },
          onOpenOwnProfile: widget.onOpenProfile,
          onStatusChanged: (status) {
            widget.onStatusChanged(book.id, status);
            if (status == BookStatus.leido) {
              widget.onProgressChanged(book.id, 100);
            }
            setState(() {});
          },
          onProgressChanged: (progress) {
            widget.onProgressChanged(book.id, progress);
            if (progress >= 100) {
              widget.onStatusChanged(book.id, BookStatus.leido);
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  void _openReviewEditor(LibraryBook book) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return LibraryReviewDialog(
          initial: widget.reviews[book.id],
          bookTitle: book.title,
          onSave: (review) {
            widget.onReviewSaved(book.id, review);
            setState(() {});
          },
        );
      },
    );
  }

}

