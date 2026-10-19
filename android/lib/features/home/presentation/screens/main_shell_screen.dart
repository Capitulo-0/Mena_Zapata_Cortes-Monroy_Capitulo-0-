import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/settings_screen.dart';
import 'home_screen.dart';
import '../../../writer/presentation/screens/writer_screen.dart';

import 'package:android/features/maps/presentation/screens/maps_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.isGuest,
    required this.onLogout,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isGuest;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int selectedIndex = 0;

  bool showSettings = false;

  // Estado compartido de Biblioteca. En el siguiente paso Perfil consumirá
  // exactamente estas mismas colecciones para mantener contadores, reto y estante
  // sincronizados con los cambios realizados en Mi Biblioteca.
  final List<LibraryBook> _libraryBooks = const [
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

  void _changeBookStatus(int bookId, BookStatus status) {
    setState(() {
      _bookStatuses[bookId] = status;
      if (status == BookStatus.leido) {
        _bookProgresses[bookId] = 100;
      } else if (status == BookStatus.porLeer) {
        _bookProgresses[bookId] = 0;
      } else if ((_bookProgresses[bookId] ?? 0) >= 100) {
        _bookProgresses[bookId] = 0;
      }
    });
  }

  void _changeBookProgress(int bookId, int progress) {
    final safeProgress = progress.clamp(0, 100).toInt();
    setState(() {
      _bookProgresses[bookId] = safeProgress;
      if (safeProgress >= 100) {
        _bookStatuses[bookId] = BookStatus.leido;
      } else if (_bookStatuses[bookId] == BookStatus.leido) {
        _bookStatuses[bookId] = BookStatus.leyendo;
      }
    });
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

  void _selectTab(int index) {
    if (widget.isGuest && (index == 1 || index == 2 || index == 4)) {
      _showGuestAccessDialog(index);
      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  void _showGuestAccessDialog(int index) {
    String title;
    String message;

    switch (index) {
      case 1:
        title = 'Tu biblioteca te está esperando';
        message = 'Inicia sesión para guardar tus lecturas, organizar tu estantería y llevar tu progreso.';
        break;

      case 2:
        title = 'Convierte tus ideas en historias';
        message = 'Para crear, guardar y publicar tus propias historias necesitas una cuenta de Capítulo 0.';
        break;

      case 4:
        title = 'Haz tu experiencia más personal';
        message = 'Inicia sesión para acceder a tu perfil, seguidores, reseñas y preferencias literarias.';
        break;

      default:
        title = 'Inicia sesión';
        message = 'Esta función requiere una cuenta.';
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                color: AppColors.goldOf(context),
                size: 42,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  color: AppColors.deepOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onLogout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOf(context),
                    foregroundColor: AppColors.backgroundOf(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Iniciar sesión',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Seguir como invitado',
                  style: GoogleFonts.inter(
                    color: AppColors.accentOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _currentScreen() {
    switch (selectedIndex) {
      case 0:
        return HomeScreen(
          isGuest: widget.isGuest,
          onOpenLibrary: () {
            _selectTab(1);
          },
          onOpenWriter: () {
            _selectTab(2);
          },
          onOpenPoints: () {
            _selectTab(3);
          },
        );

      case 1:
        return LibraryScreen(
          books: _libraryBooks,
          statuses: _bookStatuses,
          progresses: _bookProgresses,
          reviews: _bookReviews,
          favorites: _favoriteBookIds,
          onStatusChanged: _changeBookStatus,
          onProgressChanged: _changeBookProgress,
          onReviewSaved: _saveBookReview,
          onToggleFavorite: _toggleFavoriteBook,
        );

      case 2:
        return const WriterScreen();

      case 3:
        return const MapsScreen();

      case 4:
        return ProfileScreen(
          onOpenSettings: () {
            setState(() {
              showSettings = true;
            });
          },
          books: _libraryBooks,
          statuses: _bookStatuses,
          progresses: _bookProgresses,
          reviews: _bookReviews,
          favorites: _favoriteBookIds,
          onStatusChanged: _changeBookStatus,
          onProgressChanged: _changeBookProgress,
          onReviewSaved: _saveBookReview,
          onToggleFavorite: _toggleFavoriteBook,
        );

      default:
        return const SizedBox.shrink();
    }
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
        onDeleteAccount: widget.onLogout,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onProfileSaved: (name, username, biography, readingFormat, annualGoal) {
          // En el próximo paso conectaremos
          // estos datos directamente con ProfileScreen.
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: _currentScreen(),
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
                duration: const Duration(milliseconds: 220),
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedIndex == 2
                      ? const Color(0xFFB58B3D)
                      : AppColors.goldOf(context),
                  border: Border.all(
                    color: AppColors.deepOf(context),
                    width: selectedIndex == 2 ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(
                  selectedIndex == 2 ? Icons.edit_outlined : Icons.add_rounded,
                  color: AppColors.deepOf(context),
                  size: 30,
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
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 50,
        decoration: BoxDecoration(
          color: active ? AppColors.goldOf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active
                  ? AppColors.deepOf(context)
                  : AppColors.backgroundOf(context).withValues(alpha: 0.68),
              size: 23,
            ),
            if (active) ...[
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
          ],
        ),
      ),
    );
  }
}
