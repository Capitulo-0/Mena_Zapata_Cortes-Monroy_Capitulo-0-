import '../../../library/data/library_repository.dart';
import '../../../library/models/library_entry.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../library/presentation/dialogs/add_library_book_dialog.dart';
import '../../../library/presentation/widgets/library_sync_bar.dart';
import '../../../../core/session/local_account_scope.dart';
import 'dart:async';
import '../../../catalog/data/catalog_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../clubs/models/reading_club.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/settings_screen.dart';
import 'home_screen.dart';
import '../../../library/models/reading_record.dart';
import '../../../library/presentation/screens/simulated_reader_screen.dart';
import '../../../library/presentation/dialogs/reading_record_dialog.dart';
import '../widgets/main_header.dart';
import '../../../writer/models/writer_story.dart';
import '../../../writer/services/writer_local_service.dart';
import '../../../writer/presentation/screens/writer_screen.dart';

import 'package:android/features/maps/presentation/screens/maps_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.isGuest,
    required this.onLogout,
    required this.onGuestLoginRequested,
    required this.onGuestRegisterRequested,
    required this.isDarkMode,
    this.profileDisplayName,
    this.libraryRepository,
    this.catalogRepository,
    required this.onDarkModeChanged,
  });

  final bool isGuest;
  final LibraryRepository? libraryRepository;
  final CatalogRepository? catalogRepository;
  final String? profileDisplayName;
  final VoidCallback onLogout;
  final VoidCallback onGuestLoginRequested;
  final VoidCallback onGuestRegisterRequested;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int selectedIndex = 0;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  bool _headerCompact = false;

  late final WriterLocalService _writerService = WriterLocalService(scope: LocalAccountScope.read(context));
  List<WriterStory> _writerStories = <WriterStory>[];

  bool showSettings = false;
  LibraryController? _remoteLibrary;
  String? _shownLibraryError;

  void _syncRemoteLibrary() {
    final remote = _remoteLibrary;
    if (!mounted || remote == null) return;
    setState(() {
      _libraryBooks..clear()..addAll(remote.catalog);
      _bookStatuses..clear()..addAll({for (final entry in remote.entries.values) entry.book.id: entry.status});
      _bookProgresses..clear()..addAll({for (final entry in remote.entries.values) entry.book.id: entry.progressPercentage.floor()});
      _readingRecords..clear()..addAll({for (final entry in remote.entries.values) entry.book.id: entry.record});
      final reading = remote.entries.values.where((entry) => entry.status == BookStatus.leyendo).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _lastAdvancedBookId = reading.isEmpty ? null : reading.first.book.id;
    });
    if (remote.error != null && _shownLibraryError != remote.error) {
      _shownLibraryError = remote.error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(remote.error ?? 'No se pudo sincronizar la biblioteca.')));
      });
    } else if (remote.error == null) { _shownLibraryError = null; }
  }

  void _addRealBook() {
    final remote = _remoteLibrary;
    if (remote != null && remote.canWrite) showAddLibraryBookDialog(context, remote, initialManual: true);
  }

  Widget _libraryBody(Widget child) {
    final remote = _remoteLibrary;
    if (remote == null) return child;
    return Column(children: [
      if (selectedIndex == 1) LibrarySyncBar(controller: remote, onAdd: _addRealBook),
      Expanded(key: const ValueKey('library-main-stack'), child: child),
    ]);
  }

  late String _profileName = widget.profileDisplayName ?? 'Constanza Mena';
  String _profileUsername = '@constanza.lectora';
  String _profileBiography =
      'Entre libros, café y lugares tranquilos para leer.';
  String _readingFormat = 'Ambos';
  int _annualGoal = 25;


  @override
  void initState() {
    super.initState();
    _loadWriterStories();
    if (!widget.isGuest && widget.libraryRepository != null) {
      _libraryBooks.clear();
      _bookStatuses.clear();
      _bookProgresses.clear();
      _readingRecords.clear();
      _bookReviews.clear();
      _favoriteBookIds.clear();
      _lastAdvancedBookId = null;
      _remoteLibrary = LibraryController(widget.libraryRepository!)..addListener(_syncRemoteLibrary);
      unawaited(_remoteLibrary!.load());
    }
  }

  Future<void> _loadWriterStories() async {
    final stories = await _writerService.getStories();

    if (!mounted) return;

    setState(() {
      _writerStories = stories;
    });
  }

  void _handleWriterStoriesChanged(List<WriterStory> stories) {
    // No hacemos setState aquí porque WriterScreen está actualmente visible.
    // El cambio se reflejará cuando MainShell cambie de pestaña.
    _writerStories = List<WriterStory>.from(stories);
  }

  List<WriterStory> get _publishedWriterStories => _writerStories
      .where((story) => story.isPublished)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  // Estado compartido de clubes de lectura.
  final List<ReadingClub> _clubs = [
    const ReadingClub(
      id: 1,
      name: 'Adictos a los Clásicos ☕',
      members: 342,
      book: 'Cumbres Borrascosas',
      date: 'Viernes 20:00',
      modality: 'Presencial',
      description:
          'Un espacio para quienes aman los grandes clásicos de la literatura universal. Cada semana conversamos sobre capítulos, personajes y contexto histórico.',
    ),
    const ReadingClub(
      id: 2,
      name: 'Mansión Gótica 🕯️',
      members: 189,
      book: 'Jane Eyre',
      date: 'Sábado 18:30',
      modality: 'Online',
      description:
          'Para amantes de la literatura gótica y victoriana. Misterio, romanticismo oscuro y personajes inolvidables.',
    ),
    const ReadingClub(
      id: 3,
      name: 'Plumas del Sur ✍️',
      members: 98,
      book: 'El Jardín de los Recuerdos',
      date: 'Miércoles 19:00',
      modality: 'Presencial',
      description:
          'Club dedicado a literatura latinoamericana contemporánea y autores independientes.',
    ),
  ];

  final Set<int> _joinedClubIds = <int>{};

  // Estado compartido de Biblioteca. En el siguiente paso Perfil consumirá
  // exactamente estas mismas colecciones para mantener contadores, reto y estante
  // sincronizados con los cambios realizados en Mi Biblioteca.
  final List<LibraryBook> _libraryBooks = [
    LibraryBook(
      id: 1,
      title: 'Orgullo y Prejuicio',
      author: 'Jane Austen',
      authorHandle: '@JaneAusten1',
      year: 1813,
      genre: 'Romance clásico',
      isbn: '9780141439518',
      cover: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Elizabeth Bennet aprende que las primeras impresiones pueden engañar mientras ella y el orgulloso señor Darcy atraviesan prejuicios, diferencias sociales y sentimientos inesperados.',
    ),
    LibraryBook(
      id: 2,
      title: 'Cumbres Borrascosas',
      author: 'Emily Brontë',
      authorHandle: '@EmilyBronte',
      year: 1847,
      genre: 'Ficción gótica',
      isbn: '9780141439556',
      cover: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Una historia intensa de amor, obsesión y venganza situada en los páramos ingleses, marcada por la relación destructiva entre Catherine Earnshaw y Heathcliff.',
    ),
    LibraryBook(
      id: 3,
      isFree: false,
      publisher: 'Editorial demo',
      totalPages: 300,
      title: 'Jane Eyre',
      author: 'Charlotte Brontë',
      authorHandle: '@CharlotteBronte',
      year: 1847,
      genre: 'Ficción gótica',
      isbn: '9780141441146',
      cover: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Jane Eyre busca independencia, dignidad y afecto mientras enfrenta una infancia difícil y los secretos de Thornfield Hall.',
    ),
    LibraryBook(
      id: 4,
      title: 'Frankenstein',
      author: 'Mary Shelley',
      authorHandle: '@MaryShelley',
      year: 1818,
      genre: 'Ficción gótica',
      isbn: '9780141439471',
      cover: 'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Victor Frankenstein crea vida y descubre las consecuencias morales y emocionales de abandonar a la criatura que él mismo dio origen.',
    ),
    LibraryBook(
      id: 5,
      isFree: false,
      publisher: 'Editorial demo',
      totalPages: 200,
      title: 'Emma',
      author: 'Jane Austen',
      authorHandle: '@JaneAusten1',
      year: 1815,
      genre: 'Romance clásico',
      isbn: '9780141439587',
      cover: 'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Emma Woodhouse disfruta interviniendo en la vida sentimental de quienes la rodean, hasta que sus propios sentimientos comienzan a contradecir sus certezas.',
    ),
    LibraryBook(
      id: 6,
      title: 'Drácula',
      author: 'Bram Stoker',
      authorHandle: '@BramStoker',
      year: 1897,
      genre: 'Terror gótico',
      isbn: '9780141439846',
      cover: 'https://images.unsplash.com/photo-1516979187457-637abb4f9353?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Cartas, diarios y testimonios reconstruyen el enfrentamiento entre un grupo de amigos y el conde Drácula.',
    ),
    LibraryBook(
      id: 7,
      title: 'El retrato de Dorian Gray',
      author: 'Oscar Wilde',
      authorHandle: '@OscarWilde',
      year: 1890,
      genre: 'Ficción gótica',
      isbn: '9780141439570',
      cover: 'https://images.unsplash.com/photo-1519682337058-a94d519337bc?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Dorian Gray conserva una juventud impecable mientras un retrato oculto refleja el deterioro causado por sus decisiones.',
    ),
    LibraryBook(
      id: 8,
      title: 'Mujercitas',
      author: 'Louisa May Alcott',
      authorHandle: '@LouisaMayAlcott',
      year: 1868,
      genre: 'Clásico',
      isbn: '9780140390698',
      cover: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Las hermanas March crecen, crean, aman y enfrentan pérdidas mientras intentan construir una vida fiel a sus propios deseos.',
    ),
    LibraryBook(
      id: 9,
      title: 'Rebecca',
      author: 'Daphne du Maurier',
      year: 1938,
      genre: 'Ficción gótica',
      isbn: '9780380730407',
      cover: 'https://images.unsplash.com/photo-1511108690759-009324a90311?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Una joven llega a Manderley y descubre que la presencia de Rebecca, la primera esposa de su marido, continúa dominando la casa y a quienes la habitan.',
    ),
    LibraryBook(
      id: 10,
      title: 'Persuasión',
      author: 'Jane Austen',
      year: 1817,
      genre: 'Romance clásico',
      isbn: '9780141439686',
      cover: 'https://images.unsplash.com/photo-1519682337058-a94d519337bc?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Anne Elliot vuelve a encontrarse con el hombre al que años atrás dejó escapar y debe decidir si aún existe una segunda oportunidad para ambos.',
    ),
    LibraryBook(
      id: 11,
      title: 'La abadía de Northanger',
      author: 'Jane Austen',
      year: 1817,
      genre: 'Romance clásico',
      isbn: '9780141439792',
      cover: 'https://images.unsplash.com/photo-1474932430478-367dbb6832c1?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Catherine Morland descubre que la imaginación gótica puede ser tan engañosa como divertida cuando conoce la vida social de Bath y Northanger Abbey.',
    ),
    LibraryBook(
      id: 12,
      title: 'El extraño caso del Dr. Jekyll y Mr. Hyde',
      author: 'Robert Louis Stevenson',
      year: 1886,
      genre: 'Ficción gótica',
      isbn: '9780141439730',
      cover: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Un abogado investiga la relación entre el respetado doctor Jekyll y el inquietante señor Hyde, descubriendo una verdad sobre la dualidad humana.',
    ),
    LibraryBook(
      id: 13,
      title: 'El fantasma de la ópera',
      author: 'Gaston Leroux',
      year: 1910,
      genre: 'Misterio gótico',
      isbn: '9780060809249',
      cover: 'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Una figura enmascarada habita los pasadizos de la Ópera de París y desarrolla una obsesión por la joven cantante Christine Daaé.',
    ),
    LibraryBook(
      id: 14,
      title: 'Sentido y sensibilidad',
      author: 'Jane Austen',
      year: 1811,
      genre: 'Romance clásico',
      isbn: '9780141439662',
      cover: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Las hermanas Dashwood enfrentan el amor y la pérdida desde temperamentos opuestos mientras intentan mantener su independencia y dignidad.',
    ),
    LibraryBook(
      id: 15,
      title: 'El jardín secreto',
      author: 'Frances Hodgson Burnett',
      year: 1911,
      genre: 'Clásico',
      isbn: '9780141321066',
      cover: 'https://images.unsplash.com/photo-1526243741027-444d633d7365?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Mary Lennox descubre un jardín cerrado y, al devolverle la vida, transforma también su relación con quienes la rodean.',
    ),
    LibraryBook(
      id: 16,
      title: 'Ana de las Tejas Verdes',
      author: 'Lucy Maud Montgomery',
      year: 1908,
      genre: 'Clásico',
      isbn: '9780553213133',
      cover: 'https://images.unsplash.com/photo-1509266272358-7701da638078?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Anne Shirley llega por error a Green Gables y conquista a su nueva familia y comunidad con imaginación, carácter y una energía imposible de ignorar.',
    ),
    LibraryBook(
      id: 17,
      title: 'La mujer de blanco',
      author: 'Wilkie Collins',
      year: 1859,
      genre: 'Misterio gótico',
      isbn: '9780141439617',
      cover: 'https://images.unsplash.com/photo-1535905557558-afc4877a26fc?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Un encuentro nocturno con una misteriosa mujer vestida de blanco conduce a un complejo secreto familiar lleno de identidad, engaños y peligro.',
    ),
    LibraryBook(
      id: 18,
      title: 'El castillo de Otranto',
      author: 'Horace Walpole',
      year: 1764,
      genre: 'Ficción gótica',
      isbn: '9780199537211',
      cover: 'https://images.unsplash.com/photo-1515542706656-8e6ef17a1521?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Un antiguo castillo, una profecía y sucesos sobrenaturales dan forma a una de las obras fundacionales de la tradición gótica.',
    ),
    LibraryBook(
      id: 19,
      title: 'La caída de la Casa Usher',
      author: 'Edgar Allan Poe',
      year: 1839,
      genre: 'Terror gótico',
      isbn: '9780143122364',
      cover: 'https://images.unsplash.com/photo-1504052434569-70ad5836ab65?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Un visitante llega a la decadente mansión de los Usher y presencia una atmósfera de enfermedad, aislamiento y terror creciente.',
    ),
    LibraryBook(
      id: 20,
      title: 'El corazón delator',
      author: 'Edgar Allan Poe',
      year: 1843,
      genre: 'Terror gótico',
      isbn: '9780486290974',
      cover: 'https://images.unsplash.com/photo-1495640388908-05fa85288e61?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Un narrador insiste en su cordura mientras relata un crimen y la culpa que comienza a perseguirlo de manera insoportable.',
    ),
    LibraryBook(
      id: 21,
      title: 'La letra escarlata',
      author: 'Nathaniel Hawthorne',
      year: 1850,
      genre: 'Clásico',
      isbn: '9780142437261',
      cover: 'https://images.unsplash.com/photo-1496104679561-38d3af73f9b0?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Hester Prynne enfrenta el juicio de una comunidad puritana mientras protege secretos y construye una identidad más allá del castigo social.',
    ),
    LibraryBook(
      id: 22,
      title: 'La vuelta de tuerca',
      author: 'Henry James',
      year: 1898,
      genre: 'Misterio gótico',
      isbn: '9780141441351',
      cover: 'https://images.unsplash.com/photo-1541963463532-d68292c34b19?w=500&h=720&fit=crop&auto=format',
      synopsis: 'Una institutriz cree ver presencias inquietantes alrededor de los niños a su cuidado, en un relato donde nunca resulta del todo claro qué es real.',
    ),
  ];

  final Map<int, BookStatus> _bookStatuses = {
    1: BookStatus.leido,
    2: BookStatus.leido,
    3: BookStatus.porLeer,
    4: BookStatus.leido,
    5: BookStatus.leyendo,
    6: BookStatus.porLeer,
    7: BookStatus.leyendo,
    8: BookStatus.leido,
    9: BookStatus.leido,
    10: BookStatus.leido,
    11: BookStatus.leido,
    12: BookStatus.leido,
    13: BookStatus.leido,
    14: BookStatus.leido,
    15: BookStatus.leido,
    16: BookStatus.leido,
    17: BookStatus.leido,
    18: BookStatus.leido,
    19: BookStatus.leido,
    20: BookStatus.leido,
    21: BookStatus.leido,
    22: BookStatus.leido,
  };

  int? _lastAdvancedBookId = 7;

  final Map<int, int> _bookProgresses = {
    1: 100,
    2: 100,
    3: 0,
    4: 100,
    5: 30,
    6: 0,
    7: 65,
    8: 100,
    9: 100,
    10: 100,
    11: 100,
    12: 100,
    13: 100,
    14: 100,
    15: 100,
    16: 100,
    17: 100,
    18: 100,
    19: 100,
    20: 100,
    21: 100,
    22: 100,
  };

  final Map<int, BookReview> _bookReviews = {
    1: const BookReview(
      rating: 5,
      text: 'Ingeniosa, elegante y profundamente humana. Elizabeth Bennet sigue siendo una de mis protagonistas favoritas.',
    ),
    2: const BookReview(
      rating: 5,
      text: 'Una obra intensa y oscura que se queda contigo mucho después de cerrar el libro.',
    ),
    4: const BookReview(
      rating: 4,
      text: 'Más melancólica y filosófica de lo que recordaba. Una lectura gótica preciosa.',
      isPublic: false,
    ),
  };

  final Set<int> _favoriteBookIds = {1, 2, 3, 4};
  final Map<String, WriterStory> _favoriteCommunityStories =
      <String, WriterStory>{};

  Timer? _finishReadingTimer;
  int? _finishingBookId;
  final Map<int, int> _lastIncompleteProgresses = {};
  final Map<int, ReadingRecord> _lastIncompleteRecords = {};

  @override
  void dispose() {
    _finishReadingTimer?.cancel();
    _remoteLibrary?..removeListener(_syncRemoteLibrary)..dispose();
    super.dispose();
  }

  void _rememberIncompleteReading(int bookId) {
    final progress = _bookProgresses[bookId] ?? 0;
    if (_bookStatuses[bookId] != BookStatus.leyendo || progress <= 0 || progress >= 100) return;
    _lastIncompleteProgresses[bookId] = progress;
    final record = _readingRecords[bookId];
    if (record != null) _lastIncompleteRecords[bookId] = record;
  }

  void _afterReadingChange(int bookId, BookStatus status, bool wasCurrent) {
    if (status == BookStatus.leido && wasCurrent) {
      _finishReadingTimer?.cancel();
      setState(() => _finishingBookId = bookId);
      _finishReadingTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _finishingBookId = null);
      });
    } else if (status == BookStatus.leyendo || (status == BookStatus.porLeer && _finishingBookId == bookId)) {
      _finishReadingTimer?.cancel();
      if (_finishingBookId != null) setState(() => _finishingBookId = null);
    }
  }

  String? get _finishedReadingTitle {
    for (final book in _libraryBooks) {
      if (book.id == _finishingBookId) return book.title;
    }
    return null;
  }

  final Map<int, ReadingRecord> _readingRecords = {
    5: const ReadingRecord(
      format: 'Físico',
      currentPage: 60,
      totalPages: 200,
      publisher: 'Editorial demo',
      status: BookStatus.leyendo,
    ),
  };

  Future<void> _addToLibrary(Map<String, dynamic> data) async {
    if (widget.isGuest) { _showGuestAccessDialog(); return; }
    if (_remoteLibrary != null) {
      if (data['googleVolumeId'] is String && widget.catalogRepository != null) {
        await _remoteLibrary!.addExternal(() => widget.catalogRepository!.importBook(data['googleVolumeId'] as String));
        final found = _remoteLibrary!.entries.values.where((entry) => entry.book.googleVolumeId == data['googleVolumeId']);
        if (found.isNotEmpty) { data['id'] = found.first.book.id; data['isBackendBook'] = true; }
        return;
      }
      if (data['isBackendBook'] != true) return;
      await _remoteLibrary!.add(data['id'] as int);
      return;
    }
    final id = data['id'] as int;
    setState(() {
      if (!_libraryBooks.any((book) => book.id == id)) {
        _libraryBooks.add(
          LibraryBook(
            id: id,
            title: data['title'] as String,
            author: data['authorReal'] as String? ?? '',
            authorHandle: data['author'] as String?,
            year: data['year'] as int? ?? 0,
            genre: data['genre'] as String? ?? '',
            isbn: data['isbn'] as String? ?? '',
            cover: data['cover'] as String? ?? '',
            synopsis: data['synopsis'] as String? ?? '',
            isFree: data['availability'] == 'GRATIS',
            publisher: data['publisher'] as String? ?? '',
            totalPages: data['totalPages'] as int? ?? 0,
          ),
        );
      }
      _bookStatuses.putIfAbsent(id, () => BookStatus.porLeer);
      _bookProgresses.putIfAbsent(id, () => 0);
    });
  }

  Future<int?> _openReading(BuildContext sourceContext, int bookId) async {
    if (widget.isGuest) {
      _showGuestAccessDialog();
      return null;
    }
    final matches = _libraryBooks.where((book) => book.id == bookId);
    if (matches.isEmpty) return null;
    final book = matches.first;
    if (_remoteLibrary != null) {
      if (!_remoteLibrary!.canWrite || !_bookStatuses.containsKey(bookId)) return null;
      final record = await showReadingRecordDialog(context: sourceContext, book: book,
        initial: _readingRecords[bookId], status: _bookStatuses[bookId]!, progress: _bookProgresses[bookId] ?? 0,
        allowUnknownTotal: true);
      if (record != null) await _remoteLibrary!.saveRecord(bookId, record);
      return mounted ? _bookProgresses[bookId] : null;
    }
    if (book.isFree && (_bookStatuses[bookId] ?? BookStatus.porLeer) == BookStatus.porLeer) {
      _changeBookStatus(bookId, BookStatus.leyendo);
    }
    void save(ReadingRecord record) {
      if (!mounted) return;
      final wasCurrent = _lastAdvancedBook?.id == bookId;
      setState(() {
        _rememberIncompleteReading(bookId);
        _readingRecords[bookId] = record;
        _bookStatuses[bookId] = record.status;
        _bookProgresses[bookId] = record.progress;
        _lastAdvancedBookId = bookId;
        _rememberIncompleteReading(bookId);
      });
      _afterReadingChange(bookId, record.status, wasCurrent);
    }

    if (book.isFree) {
      await Navigator.of(sourceContext).push<void>(MaterialPageRoute(builder: (_) =>
        SimulatedReaderScreen(book: book, initialProgress: _bookProgresses[bookId] ?? 0,
          initialStatus: _bookStatuses[bookId] ?? BookStatus.porLeer, onChanged: save)));
    } else {
      final record = await showReadingRecordDialog(
        context: sourceContext,
        book: book,
        initial: _readingRecords[bookId],
        status: _bookStatuses[bookId] ?? BookStatus.porLeer,
        progress: _bookProgresses[bookId] ?? 0,
      );
      if (record != null) save(record);
    }
    return _bookProgresses[bookId];
  }

  Future<bool> _removeFromLibrary(BuildContext sourceContext, int bookId) async {
    if (widget.isGuest) { _showGuestAccessDialog(); return false; }
    if (!_bookStatuses.containsKey(bookId)) return false;
    final book = _libraryBooks.firstWhere((book) => book.id == bookId);
    final confirmed = await showDialog<bool>(context: sourceContext, builder: (dialogContext) =>
      AlertDialog(backgroundColor: AppColors.surfaceOf(dialogContext),
        title: const Text('¿Eliminar de Mi Biblioteca?'),
        content: Text('Se quitará «${book.title}» de tu Biblioteca y se borrará su seguimiento de lectura. '
          'Tus favoritos y reseñas se conservarán. El libro seguirá en el catálogo.'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar'))]));
    if (confirmed != true || !mounted) return false;
    if (_remoteLibrary != null && !await _remoteLibrary!.remove(bookId)) return false;
    if (!mounted) return false;
    setState(() {
      _bookStatuses.remove(bookId);
      _bookProgresses.remove(bookId);
      _readingRecords.remove(bookId);
      _lastIncompleteProgresses.remove(bookId);
      _lastIncompleteRecords.remove(bookId);
      if (_finishingBookId == bookId) {
        _finishReadingTimer?.cancel();
        _finishingBookId = null;
      }
      if (_lastAdvancedBookId == bookId) _lastAdvancedBookId = null;
    });
    return true;
  }

  Future<void> _changeBookStatus(int bookId, BookStatus status) async {
    if (_remoteLibrary != null) {
      final wasCurrent = _lastAdvancedBook?.id == bookId;
      if (!_remoteLibrary!.entries.containsKey(bookId)) {
        if (!await _remoteLibrary!.add(bookId)) return;
      }
      if (await _remoteLibrary!.setStatus(bookId, status) && mounted) {
        _afterReadingChange(bookId, status, wasCurrent);
      }
      return;
    }
    if (widget.isGuest) { _showGuestAccessDialog(); return; }
    final wasCurrent = _lastAdvancedBook?.id == bookId;
    final previousStatus = _bookStatuses[bookId];
    setState(() {
      _rememberIncompleteReading(bookId);
      final current = _bookProgresses[bookId] ?? 0;
      var progress = status == BookStatus.porLeer ? 0 : status == BookStatus.leido ? 100
        : current >= 100 ? (_lastIncompleteProgresses[bookId] ?? 99) : current;
      final record = _readingRecords[bookId];
      if (record != null) {
        final updated = record.withStatus(status, resume: _lastIncompleteRecords[bookId]);
        _readingRecords[bookId] = updated;
        progress = updated.progress;
      }
      _bookStatuses[bookId] = status;
      _bookProgresses[bookId] = progress;
      if (status == BookStatus.leyendo) _lastAdvancedBookId = bookId;
      _rememberIncompleteReading(bookId);
    });
    if (status != previousStatus) _afterReadingChange(bookId, status, wasCurrent);
  }

  Future<void> _changeBookProgress(int bookId, int progress) async {
    if (_remoteLibrary != null) {
      final wasCurrent = _lastAdvancedBook?.id == bookId;
      if (await _remoteLibrary!.setProgress(bookId, progress) && mounted) {
        _afterReadingChange(bookId, _bookStatuses[bookId]!, wasCurrent);
      }
      return;
    }
    if (widget.isGuest) { _showGuestAccessDialog(); return; }
    final safeProgress = progress.clamp(0, 100).toInt();
    var status = safeProgress == 100 ? BookStatus.leido : BookStatus.leyendo;
    final wasCurrent = _lastAdvancedBook?.id == bookId;
    setState(() {
      _rememberIncompleteReading(bookId);
      final record = _readingRecords[bookId];
      if (record != null) {
        final updated = record.withProgress(safeProgress, status);
        status = updated.status;
        _readingRecords[bookId] = updated;
        _bookProgresses[bookId] = updated.progress;
      } else {
        _bookProgresses[bookId] = safeProgress;
      }
      _bookStatuses[bookId] = status;
      _lastAdvancedBookId = bookId;
      _rememberIncompleteReading(bookId);
    });
    _afterReadingChange(bookId, status, wasCurrent);
  }

  void _saveBookReview(int bookId, BookReview review) {
    setState(() {
      _bookReviews[bookId] = review;
    });
  }

  void _toggleFavoriteBook(int bookId) {
    setState(() {
      if (_favoriteBookIds.contains(bookId)) {
        _favoriteBookIds.remove(bookId);
      } else {
        _favoriteBookIds.add(bookId);
      }
    });
  }


  void _toggleFavoriteCommunityStory(WriterStory story) {
    setState(() {
      if (_favoriteCommunityStories.containsKey(story.id)) {
        _favoriteCommunityStories.remove(story.id);
      } else {
        _favoriteCommunityStories[story.id] = story;
      }
    });
  }


  void _toggleClub(int clubId) {
    final index = _clubs.indexWhere((club) => club.id == clubId);

    if (index == -1) {
      return;
    }

    final currentClub = _clubs[index];
    final wasJoined = _joinedClubIds.contains(clubId);

    final updatedMembers = wasJoined
        ? (currentClub.members > 0 ? currentClub.members - 1 : 0)
        : currentClub.members + 1;

    setState(() {
      if (wasJoined) {
        _joinedClubIds.remove(clubId);
      } else {
        _joinedClubIds.add(clubId);
      }

      _clubs[index] = ReadingClub(
        id: currentClub.id,
        name: currentClub.name,
        members: updatedMembers,
        book: currentClub.book,
        date: currentClub.date,
        description: currentClub.description,
        modality: currentClub.modality,
      );
    });
  }

  void _selectTab(int index) {
    if (widget.isGuest && (index == 3 || index == 4)) {
      _showGuestAccessDialog();
      return;
    }

    setState(() {
      selectedIndex = index;
      _headerCompact = false;
    });
  }

  bool _handleMainScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final compact = notification.metrics.pixels > 24;

    if (compact != _headerCompact) {
      setState(() {
        _headerCompact = compact;
      });
    }

    return false;
  }

  void _openHeaderScanner() {
    _homeKey.currentState?.showIsbnScanner();
  }

  void _openHeaderGemini() {
    _homeKey.currentState?.showGeminiAssistant();
  }

  void _showGuestAccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (dialogContext) {
        final background = AppColors.backgroundOf(dialogContext);
        final surface = AppColors.surfaceOf(dialogContext);
        final textPrimary = AppColors.textPrimaryOf(dialogContext);
        final textSecondary = AppColors.textSecondaryOf(dialogContext);
        final gold = AppColors.goldOf(dialogContext);
        final accent = AppColors.accentOf(dialogContext);
        final deep = AppColors.deepOf(dialogContext);

        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: gold.withValues(alpha: 0.48),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: gold.withValues(alpha: 0.34),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    color: gold,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'ESTÁS EN MODO INVITADO',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Para acceder a las diferentes funcionalidades de Capítulo 0, inicia sesión o crea una cuenta.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: 9.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 43,
                        child: FilledButton(
                          onPressed: () {
                            final navigator = Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            );

                            navigator.pop();
                            navigator.popUntil((route) => route.isFirst);

                            widget.onGuestLoginRequested();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Iniciar sesión',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SizedBox(
                        height: 43,
                        child: OutlinedButton(
                          onPressed: () {
                            final navigator = Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            );

                            navigator.pop();
                            navigator.popUntil((route) => route.isFirst);

                            widget.onGuestRegisterRequested();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: deep,
                            backgroundColor: background,
                            side: BorderSide(
                              color: gold.withValues(alpha: 0.72),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Registrarse',
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                  ),
                  child: Text(
                    'Seguir en modo invitado',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  LibraryBook? get _lastAdvancedBook {
    LibraryBook? fallback;
    for (final book in _libraryBooks) {
      if (_bookStatuses[book.id] != BookStatus.leyendo) continue;
      if (book.id == _lastAdvancedBookId) return book;
      fallback ??= book;
    }
    return fallback;
  }

  int get _lastAdvancedBookProgress => _bookProgresses[_lastAdvancedBook?.id] ?? 0;

  List<Widget> _mainScreens() {
    return [
      HomeScreen(
        catalogRepository: widget.catalogRepository,
        catalogBooks: _remoteLibrary == null ? null : _libraryBooks.map(LibraryEntry.homeData).toList(),
        onReadBook: _openReading,
        onAddBook: _addToLibrary,
        onBookStatusChanged: _changeBookStatus,
        finishedReadingTitle: widget.isGuest ? null : _finishedReadingTitle,
        statuses: widget.isGuest ? const <int, BookStatus>{} : _bookStatuses,
        progresses: widget.isGuest ? const <int, int>{} : _bookProgresses,
        key: _homeKey,
        isGuest: widget.isGuest,
        currentName: _profileName,
        currentUsername: _profileUsername,
        reviews: _bookReviews,
        onReviewSaved: (bookId, review) {
          if (widget.isGuest) {
            _showGuestAccessDialog();
            return;
          }
          _saveBookReview(bookId, review);
        },
        favoriteBookIds: _favoriteBookIds,
        onToggleFavoriteBook: (bookId) {
          if (widget.isGuest) {
            _showGuestAccessDialog();
            return;
          }
          _toggleFavoriteBook(bookId);
        },
        favoriteCommunityStoryIds:
            _favoriteCommunityStories.keys.toSet(),
        onToggleCommunityStoryFavorite: (story) {
          if (widget.isGuest) {
            _showGuestAccessDialog();
            return;
          }
          _toggleFavoriteCommunityStory(story);
        },
        clubs: _clubs,
        joinedClubIds: _joinedClubIds,
        onToggleClub: (clubId) {
          if (widget.isGuest) {
            _showGuestAccessDialog();
            return;
          }
          _toggleClub(clubId);
        },
        continueReadingBook: widget.isGuest ? null : _lastAdvancedBook,
        continueReadingProgress: widget.isGuest ? 0 : _lastAdvancedBookProgress,
        onContinueReadingProgressChanged: (bookId, progress) async {
          if (widget.isGuest) {
            _showGuestAccessDialog();
            return;
          }
          await _changeBookProgress(bookId, progress);
        },
        onGuestRestrictedAction: _showGuestAccessDialog,
        onOpenLibrary: () => _selectTab(1),
        onOpenWriter: () => _selectTab(2),
        onOpenPoints: () => _selectTab(3),
        onOpenProfile: () => _selectTab(4),
      ),
      LibraryScreen(
        dataAvailable: _remoteLibrary?.loaded ?? true,
        onRemoveBook: _removeFromLibrary,
        onReadBook: _openReading,
        isGuest: widget.isGuest,
        onGuestRestrictedAction: _showGuestAccessDialog,
        books: widget.isGuest ? const <LibraryBook>[] : _libraryBooks,
        statuses: widget.isGuest ? const <int, BookStatus>{} : _bookStatuses,
        progresses: widget.isGuest ? const <int, int>{} : _bookProgresses,
        reviews: widget.isGuest ? const <int, BookReview>{} : _bookReviews,
        favorites: widget.isGuest ? const <int>{} : _favoriteBookIds,
        currentName: widget.isGuest ? 'Invitado' : _profileName,
        currentUsername: widget.isGuest ? '@invitado' : _profileUsername,
        onOpenProfile: () => _selectTab(4),
        onStatusChanged: _changeBookStatus,
        onProgressChanged: _changeBookProgress,
        onReviewSaved: _saveBookReview,
        onToggleFavorite: _toggleFavoriteBook,
      ),
      WriterScreen(
        isGuest: widget.isGuest,
        onGuestRestrictedAction: _showGuestAccessDialog,
        currentName: widget.isGuest ? 'Invitado' : _profileName,
        currentUsername: widget.isGuest ? '@invitado' : _profileUsername,
        onStoriesChanged: _handleWriterStoriesChanged,
      ),
      MapsScreen(
        clubs: _clubs,
        joinedClubIds: _joinedClubIds,
        currentUsername: _profileUsername,
        currentName: _profileName,
      ),
      ProfileScreen(
        onReadBook: _openReading,
        onOpenSettings: () {
          setState(() {
            showSettings = true;
          });
        },
        name: _profileName,
        username: _profileUsername,
        biography: _profileBiography,
        readingFormat: _readingFormat,
        annualGoal: _annualGoal,
        clubs: _clubs,
        joinedClubIds: _joinedClubIds,
        onToggleClub: _toggleClub,
        books: _libraryBooks,
        statuses: widget.isGuest ? const <int, BookStatus>{} : _bookStatuses,
        progresses: widget.isGuest ? const <int, int>{} : _bookProgresses,
        reviews: _bookReviews,
        favorites: _favoriteBookIds,
        favoriteCommunityStories:
            _favoriteCommunityStories.values.toList(),
        onToggleCommunityStoryFavorite:
            _toggleFavoriteCommunityStory,
        onStatusChanged: _changeBookStatus,
        onProgressChanged: _changeBookProgress,
        onReviewSaved: _saveBookReview,
        onToggleFavorite: _toggleFavoriteBook,
        publishedStories: _publishedWriterStories,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (showSettings) {
      return SettingsScreen(
        onBack: () {
          setState(() {
            showSettings = false;
          });
        },
        onLogout: widget.onLogout,
        onDeleteAccount: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('La eliminación de cuenta aún no está disponible. No se eliminó ningún dato.'),
          ));
        },

        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,

        initialName: _profileName,
        initialUsername: _profileUsername,
        initialBiography: _profileBiography,
        initialReadingFormat: _readingFormat,
        initialAnnualGoal: _annualGoal,
        
        onProfileSaved: (
          name,
          username,
          biography,
          readingFormat,
          annualGoal,
        ) {
          setState(() {
            _profileName = name;
            _profileUsername = username;
            _profileBiography = biography;
            _readingFormat = readingFormat;
            _annualGoal = annualGoal;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Column(
        children: [
          MainHeader(
            compact: _headerCompact,
            isGuest: widget.isGuest,
            onScannerTap: _openHeaderScanner,
            onGeminiTap: _openHeaderGemini,
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleMainScroll,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: _libraryBody(IndexedStack(
                  index: selectedIndex,
                  children: _mainScreens(),
                )),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: SizedBox(
        height: 76,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                height: 62,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.deepOf(context),
                  borderRadius: BorderRadius.circular(31),
                  border: Border.all(
                    color: AppColors.goldOf(context).withValues(alpha: 0.20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _navItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Inicio',
                      ),
                    ),
                    Expanded(
                      child: _navItem(
                        index: 1,
                        icon: Icons.menu_book_outlined,
                        activeIcon: Icons.menu_book_rounded,
                        label: 'Biblioteca',
                      ),
                    ),
                    Expanded(
                      child: _navItem(
                        index: 3,
                        icon: Icons.location_on_outlined,
                        activeIcon: Icons.location_on_rounded,
                        label: 'Puntos',
                      ),
                    ),
                    Expanded(
                      child: _navItem(
                        index: 4,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person_rounded,
                        label: 'Perfil',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () {
                _selectTab(2);
              },
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: selectedIndex == 2 ? 68 : 62,
                height: selectedIndex == 2 ? 68 : 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedIndex == 2
                      ? const Color(0xFFC3963F)
                      : AppColors.goldOf(context),
                  border: Border.all(
                    color: AppColors.deepOf(context),
                    width: selectedIndex == 2 ? 1.6 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: selectedIndex == 2 ? 0.28 : 0.22,
                      ),
                      blurRadius: selectedIndex == 2 ? 21 : 17,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.72,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: selectedIndex == 2
                      ? SizedBox(
                          key: const ValueKey('writer-quill'),
                          width: 31,
                          height: 31,
                          child: CustomPaint(
                            painter: _QuillPainter(
                              color: AppColors.deepOf(context),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.add_rounded,
                          key: const ValueKey('writer-add'),
                          color: AppColors.deepOf(context),
                          size: 31,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final active = selectedIndex == index;

    return InkWell(
      onTap: () {
        _selectTab(index);
      },
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 58,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: active ? 68 : 42,
            height: active ? 58 : 42,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.goldOf(context)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(active ? 28 : 999),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.goldOf(context)
                            .withValues(alpha: 0.16),
                        blurRadius: 13,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.88,
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
              child: active
                  ? Column(
                      key: ValueKey('active-$index'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          activeIcon,
                          color: AppColors.deepOf(context),
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.deepOf(context),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      icon,
                      key: ValueKey('inactive-$index'),
                      color: AppColors.backgroundOf(context)
                          .withValues(alpha: 0.68),
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }

}


class _QuillPainter extends CustomPainter {
  const _QuillPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final feather = Path()
      ..moveTo(size.width * 0.24, size.height * 0.78)
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.51,
        size.width * 0.50,
        size.height * 0.22,
        size.width * 0.79,
        size.height * 0.16,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.43,
        size.width * 0.68,
        size.height * 0.68,
        size.width * 0.43,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.73,
        size.width * 0.29,
        size.height * 0.76,
        size.width * 0.24,
        size.height * 0.78,
      );

    canvas.drawPath(feather, stroke);

    final shaft = Path()
      ..moveTo(size.width * 0.23, size.height * 0.84)
      ..cubicTo(
        size.width * 0.39,
        size.height * 0.66,
        size.width * 0.54,
        size.height * 0.49,
        size.width * 0.74,
        size.height * 0.25,
      );
    canvas.drawPath(shaft, stroke);

    final barb1 = Path()
      ..moveTo(size.width * 0.39, size.height * 0.65)
      ..lineTo(size.width * 0.31, size.height * 0.54);
    final barb2 = Path()
      ..moveTo(size.width * 0.49, size.height * 0.54)
      ..lineTo(size.width * 0.40, size.height * 0.43);
    final barb3 = Path()
      ..moveTo(size.width * 0.59, size.height * 0.43)
      ..lineTo(size.width * 0.52, size.height * 0.32);
    final barb4 = Path()
      ..moveTo(size.width * 0.46, size.height * 0.58)
      ..lineTo(size.width * 0.62, size.height * 0.57);
    final barb5 = Path()
      ..moveTo(size.width * 0.57, size.height * 0.46)
      ..lineTo(size.width * 0.71, size.height * 0.43);

    canvas.drawPath(barb1, stroke);
    canvas.drawPath(barb2, stroke);
    canvas.drawPath(barb3, stroke);
    canvas.drawPath(barb4, stroke);
    canvas.drawPath(barb5, stroke);

    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.85),
      1.45,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _QuillPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
