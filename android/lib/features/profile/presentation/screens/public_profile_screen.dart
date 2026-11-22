import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../follow/data/follow_repository.dart';
import '../../data/public_profile_repository.dart';
import '../../domain/public_profile.dart';
import '../../domain/public_profile_activity.dart';
import '../widgets/profile_main_card.dart';
import 'profile_screen.dart';
import '../../../library/presentation/screens/library_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.username,
    required this.repository,
    this.followRepository,
  });

  final String username;
  final PublicProfileRepository repository;

  /// Se conectará desde MainShellScreen en el próximo paso.
  final FollowRepository? followRepository;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<PublicProfile> _profileFuture;
  Future<PublicProfileActivity>? _activityFuture;
  FollowStatus? _followStatus;
  bool _loadingFollowStatus = false;
  bool _changingFollow = false;
  String? _followError;
  int _followGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadFollowStatus();
  }

  @override
  void didUpdateWidget(covariant PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username ||
        oldWidget.repository != widget.repository) {
      _loadProfile();
    }
    if (oldWidget.username != widget.username ||
        oldWidget.followRepository != widget.followRepository) {
      _loadFollowStatus();
    }
  }

  void _loadProfile() {
    _profileFuture = widget.repository.getProfile(widget.username);
    _activityFuture = null;
  }

  void _retry() {
    setState(_loadProfile);
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    final generation = ++_followGeneration;
    final repository = widget.followRepository;
    if (repository == null) {
      if (mounted) {
        setState(() {
          _followStatus = null;
          _changingFollow = false;
          _loadingFollowStatus = false;
          _followError = null;
        });
      }
      return;
    }

    setState(() {
      _loadingFollowStatus = true;
      _changingFollow = false;
      _followError = null;
      _followStatus = null;
    });
    try {
      final status = await repository.getStatus(widget.username);
      if (!mounted || generation != _followGeneration) return;
      setState(() {
        _followStatus = status;
        _loadingFollowStatus = false;
      });
    } catch (error) {
      if (!mounted || generation != _followGeneration) return;
      setState(() {
        _loadingFollowStatus = false;
        _followError = _errorMessage(error);
      });
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiFailure) return error.message;
    return 'No pudimos actualizar el seguimiento. Inténtalo de nuevo.';
  }

  Future<void> _changeFollow() async {
    final repository = widget.followRepository;
    if (repository == null ||
        _changingFollow ||
        _loadingFollowStatus ||
        _followError != null) {
      return;
    }

    final username = widget.username;
    final generation = _followGeneration;
    final previousStatus = _followStatus;
    if (previousStatus != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            previousStatus == FollowStatus.pending
                ? '¿Cancelar solicitud?'
                : '¿Dejar de seguir?',
          ),
          content: Text(
            previousStatus == FollowStatus.pending
                ? 'Se cancelará tu solicitud para seguir a @$username.'
                : 'Dejarás de seguir a @$username.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted || generation != _followGeneration) {
        return;
      }
    }

    setState(() => _changingFollow = true);
    try {
      FollowStatus? nextStatus;
      if (previousStatus == null) {
        final relationship = await repository.follow(username);
        nextStatus = relationship.status;
      } else {
        await repository.unfollow(username);
      }
      if (!mounted || generation != _followGeneration) return;
      setState(() {
        _followStatus = nextStatus;
        _changingFollow = false;
        _loadProfile();
      });
    } catch (error) {
      if (!mounted || generation != _followGeneration) return;
      setState(() => _changingFollow = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Widget _buildFollowButton(BuildContext context) {
    if (widget.followRepository == null) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final gold = dark ? AppColors.darkGold : AppColors.gold;
    final isBusy = _loadingFollowStatus || _changingFollow;
    final status = _followStatus;

    if (_followError != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _loadFollowStatus,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar estado de seguimiento'),
        ),
      );
    }

    final label = _loadingFollowStatus
        ? 'Consultando...'
        : status == FollowStatus.pending
        ? 'Esperando aprobación'
        : status == FollowStatus.accepted
        ? 'Siguiendo'
        : 'Seguir';
    final icon = status == FollowStatus.pending
        ? Icons.schedule_rounded
        : status == FollowStatus.accepted
        ? Icons.check_rounded
        : Icons.person_add_alt_1_rounded;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isBusy ? null : _changeFollow,
        icon: isBusy
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: status == null ? AppColors.accentOf(context) : gold,
          foregroundColor: status == null
              ? AppColors.backgroundOf(context)
              : AppColors.deepOf(context),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isPrivate}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final heading = dark ? AppColors.darkTextPrimary : AppColors.deep;
    final lockColor = dark ? Colors.grey.shade500 : Colors.grey.shade600;

    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'PERFIL LITERARIO',
                  style: GoogleFonts.cinzel(
                    color: heading,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 16,
                color: lockColor,
              ),
            ],
          ),
        ),
        const SizedBox(width: 38, height: 36),
      ],
    );
  }

  Widget _buildPrivateNotice(BuildContext context, String username) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.darkSurface : AppColors.surface;
    final primary = dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondary = dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final gold = dark ? AppColors.darkGold : AppColors.gold;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.11),
              shape: BoxShape.circle,
              border: Border.all(color: gold.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.lock_rounded, color: gold, size: 42),
          ),
          const SizedBox(height: 18),
          Text(
            'Este perfil es privado',
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              color: primary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sigue a @$username para descubrir sus libros favoritos, '
            'reseñas, clubes de lectura y publicaciones.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: secondary,
              fontSize: 11,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingContent(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.darkSurface : AppColors.surface;
    final secondary = dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final gold = dark ? AppColors.darkGold : AppColors.gold;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        'La biblioteca, reseñas, clubes y publicaciones de este lector '
        'aparecerán aquí cuando estén disponibles sus datos públicos.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: secondary, fontSize: 10, height: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? AppColors.darkBackground : AppColors.background;
    final primary = dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final gold = dark ? AppColors.darkGold : AppColors.gold;

    return ColoredBox(
      color: background,
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<PublicProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator(color: gold));
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, color: gold, size: 34),
                      const SizedBox(height: 12),
                      Text(
                        'No pudimos cargar este perfil.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.merriweather(color: primary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final profile = snapshot.data!;
            final displayName = profile.displayName?.trim();
            final name = displayName == null || displayName.isEmpty
                ? profile.username
                : displayName;
            // Una respuesta previa no debe mantener desbloqueado un perfil
            // privado si se cancela el seguimiento o cambia la relación.
            final canViewContent =
                profile.canViewContent &&
                (!profile.isPrivate ||
                    (!_loadingFollowStatus &&
                        _followError == null &&
                        _followStatus == FollowStatus.accepted));
            final biography = profile.biography?.trim();

            // Las mismas tarjetas y pestañas que el perfil propio, reutilizadas
            // con datos vacíos y callbacks inertes hasta tener consultas
            // autorizadas de la biblioteca de este propietario.
            if (canViewContent) {
              // La API vuelve a comprobar los permisos de seguimiento en cada
              // lectura. Nunca reutilizamos datos de una cuenta diferente.
              final source = widget.repository;
              if (source is ProfileActivitySource) {
                final ProfileActivitySource activitySource =
                    source as ProfileActivitySource;
                final activityFuture = _activityFuture ??= activitySource
                    .getActivity(profile.username);
                return FutureBuilder<PublicProfileActivity>(
                  future: activityFuture,
                  builder: (context, activitySnapshot) {
                    if (activitySnapshot.connectionState !=
                        ConnectionState.done) {
                      return Center(
                        child: CircularProgressIndicator(color: gold),
                      );
                    }
                    if (activitySnapshot.hasError ||
                        !activitySnapshot.hasData) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No pudimos cargar la actividad de este perfil.',
                              style: GoogleFonts.merriweather(color: primary),
                            ),
                            TextButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }
                    final activity = activitySnapshot.data!;
                    return ProfileScreen(
                      key: ValueKey('reader-${profile.username}'),
                      readOnly: true,
                      verifiedOrganizer: profile.verifiedOrganizer,
                      readingMood: profile.readingMood,
                      visitorIsPrivate: profile.isPrivate,
                      visitorHeader: _buildHeader(
                        context,
                        isPrivate: profile.isPrivate,
                      ),
                      visitorAction: _buildFollowButton(context),
                      visitorFollowersCount: profile.followersCount,
                      visitorFollowingCount: profile.followingCount,
                      followRepository: widget.followRepository,
                      name: name,
                      username: profile.username,
                      biography: biography == null || biography.isEmpty
                          ? 'Sin biografía.'
                          : biography,
                      avatarUrl: profile.avatarUrl,
                      createdAt: profile.createdAt,
                      readingFormat: '',
                      annualGoal: activity.annualGoal,
                      clubs: activity.clubs,
                      joinedClubIds: activity.clubs
                          .map((club) => club.id)
                          .toSet(),
                      onToggleClub: (_) {},
                      books: activity.books,
                      statuses: activity.statuses,
                      progresses: activity.progresses,
                      reviews: const <int, BookReview>{},
                      favorites: activity.favorites,
                      favoriteCommunityStories: const [],
                      onToggleCommunityStoryFavorite: (_) {},
                      onStatusChanged: (_, _) {},
                      onProgressChanged: (_, _) {},
                      onReviewSaved: (_, _) {},
                      onToggleFavorite: (_) {},
                      publishedStories: activity.publishedStories,
                      onOpenSettings: () {},
                    );
                  },
                );
              }
              // Mantener el contrato visual para repositorios existentes en
              // pruebas. La aplicación real usa ProfileActivitySource.
              return ProfileScreen(
                key: ValueKey('reader-${profile.username}'),
                readOnly: true,
                verifiedOrganizer: profile.verifiedOrganizer,
                readingMood: profile.readingMood,
                visitorIsPrivate: profile.isPrivate,
                visitorHeader: _buildHeader(
                  context,
                  isPrivate: profile.isPrivate,
                ),
                visitorAction: _buildFollowButton(context),
                visitorFollowersCount: profile.followersCount,
                visitorFollowingCount: profile.followingCount,
                followRepository: widget.followRepository,
                name: name,
                username: profile.username,
                biography: biography == null || biography.isEmpty
                    ? 'Sin biografía.'
                    : biography,
                avatarUrl: profile.avatarUrl,
                createdAt: profile.createdAt,
                readingFormat: '',
                annualGoal: 0,
                clubs: const [],
                joinedClubIds: const <int>{},
                onToggleClub: (_) {},
                books: const <LibraryBook>[],
                statuses: const <int, BookStatus>{},
                progresses: const <int, int>{},
                reviews: const <int, BookReview>{},
                favorites: const <int>{},
                favoriteCommunityStories: const [],
                onToggleCommunityStoryFavorite: (_) {},
                onStatusChanged: (_, _) {},
                onProgressChanged: (_, _) {},
                onReviewSaved: (_, _) {},
                onToggleFavorite: (_) {},
                publishedStories: const [],
                onOpenSettings: () {},
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
              children: [
                _buildHeader(context, isPrivate: profile.isPrivate),
                const SizedBox(height: 12),
                ProfileMainCard(
                  name: name,
                  username: '@${profile.username}',
                  verifiedOrganizer: profile.verifiedOrganizer,
                  biography: biography == null || biography.isEmpty
                      ? 'Sin biografía.'
                      : biography,
                  avatarUrl: profile.avatarUrl,
                  createdAt: profile.createdAt,
                  moodEmoji: null,
                  readBooksCount: canViewContent ? profile.booksCount : null,
                  followerCount: canViewContent ? profile.followersCount : null,
                  followingCount: canViewContent
                      ? profile.followingCount
                      : null,
                  booksLabel: 'Libros',
                  showStats: canViewContent,
                ),
                if (widget.followRepository != null) ...[
                  const SizedBox(height: 12),
                  _buildFollowButton(context),
                ],
                const SizedBox(height: 12),
                if (!canViewContent)
                  _buildPrivateNotice(context, profile.username)
                else
                  _buildPendingContent(context),
              ],
            );
          },
        ),
      ),
    );
  }
}
