import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/follow_repository.dart';

/// Pantalla de seguidores y seguidos de un lector.
///
/// No modifica relaciones de seguimiento. El callback permite que MainShell
/// abra el perfil seleccionado utilizando su navegación existente.
class FollowListsScreen extends StatefulWidget {
  const FollowListsScreen({
    super.key,
    required this.username,
    required this.repository,
    required this.onOpenProfile,
    this.initialTab = 0,
  }) : assert(initialTab == 0 || initialTab == 1);

  final String username;
  final FollowRepository repository;
  final ValueChanged<String> onOpenProfile;
  final int initialTab;

  @override
  State<FollowListsScreen> createState() => _FollowListsScreenState();
}

class _FollowListsScreenState extends State<FollowListsScreen> {
  late int _selectedTab;
  final Map<int, List<FollowReader>> _readers = {
    0: <FollowReader>[],
    1: <FollowReader>[],
  };
  final Map<int, int> _nextPage = {0: 0, 1: 0};
  final Map<int, bool> _lastPage = {0: false, 1: false};
  final Map<int, bool> _loaded = {0: false, 1: false};
  final Map<int, bool> _loading = {0: false, 1: false};
  final Map<int, bool> _loadingMore = {0: false, 1: false};
  final Map<int, String?> _errors = {0: null, 1: null};
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _fetch(_selectedTab, reset: true);
  }

  @override
  void didUpdateWidget(covariant FollowListsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username ||
        oldWidget.repository != widget.repository) {
      _generation++;
      _readers[0] = <FollowReader>[];
      _readers[1] = <FollowReader>[];
      _nextPage[0] = 0;
      _nextPage[1] = 0;
      _loaded[0] = false;
      _loaded[1] = false;
      _loading[0] = false;
      _loading[1] = false;
      _loadingMore[0] = false;
      _loadingMore[1] = false;
      _lastPage[0] = false;
      _lastPage[1] = false;
      _errors[0] = null;
      _errors[1] = null;
      _selectedTab = widget.initialTab;
      _fetch(_selectedTab, reset: true);
    }
  }

  void _selectTab(int tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    if (!_loaded[tab]! && !_loading[tab]!) {
      _fetch(tab, reset: true);
    }
  }

  Future<void> _fetch(int tab, {required bool reset}) async {
    if (_loading[tab]! || _loadingMore[tab]!) return;
    final generation = _generation;
    final pageNumber = reset ? 0 : _nextPage[tab]!;
    setState(() {
      if (reset) {
        _loading[tab] = true;
        _errors[tab] = null;
      } else {
        _loadingMore[tab] = true;
      }
    });

    try {
      final page = tab == 0
          ? await widget.repository.getFollowers(widget.username, page: pageNumber)
          : await widget.repository.getFollowing(widget.username, page: pageNumber);
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) {
          _readers[tab] = page.readers.toList();
        } else {
          final existing = _readers[tab]!.map((reader) => reader.id).toSet();
          _readers[tab]!.addAll(
            page.readers.where((reader) => !existing.contains(reader.id)),
          );
        }
        _nextPage[tab] = page.page + 1;
        _lastPage[tab] = page.isLast;
        _loaded[tab] = true;
        _errors[tab] = null;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      if (reset) {
        setState(() => _errors[tab] = _errorMessage(error));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(error))),
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() {
          _loading[tab] = false;
          _loadingMore[tab] = false;
        });
      }
    }
  }

  String _errorMessage(Object error) => error is ApiFailure
      ? error.message
      : 'No pudimos cargar la lista. Inténtalo de nuevo.';

  Widget _readerTile(FollowReader reader) {
    final gold = AppColors.goldOf(context);
    final primary = AppColors.textPrimaryOf(context);
    final secondary = AppColors.textSecondaryOf(context);
    final avatar = reader.avatarUrl;
    final avatarValid = avatar != null &&
        (avatar.startsWith('https://') || avatar.startsWith('http://'));
    final name = reader.displayName?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: gold.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onOpenProfile(reader.username),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: gold.withValues(alpha: 0.14),
                backgroundImage: avatarValid ? NetworkImage(avatar) : null,
                child: avatarValid ? null : Icon(Icons.person_outline, color: gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null || name.isEmpty ? reader.username : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${reader.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: secondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: gold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listContent(int tab) {
    final secondary = AppColors.textSecondaryOf(context);
    final primary = AppColors.textPrimaryOf(context);
    if (_loading[tab]! && !_loaded[tab]!) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errors[tab] != null && !_loaded[tab]!) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, color: secondary, size: 36),
              const SizedBox(height: 12),
              Text(_errors[tab]!, textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: primary)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _fetch(tab, reset: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final readers = _readers[tab]!;
    return RefreshIndicator(
      onRefresh: () => _fetch(tab, reset: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          if (readers.isEmpty) ...[
            const SizedBox(height: 100),
            Icon(Icons.people_outline_rounded, size: 54, color: secondary),
            const SizedBox(height: 16),
            Center(
              child: Text(
                tab == 0 ? 'Todavía no hay seguidores' : 'Todavía no sigue a nadie',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: primary, fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            for (final reader in readers) _readerTile(reader),
            if (!_lastPage[tab]!)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _loadingMore[tab]!
                      ? const CircularProgressIndicator()
                      : OutlinedButton(
                          onPressed: () => _fetch(tab, reset: false),
                          child: const Text('Cargar más'),
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.goldOf(context);
    final primary = AppColors.textPrimaryOf(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.deepOf(context),
        foregroundColor: gold,
        title: Text(
          'COMUNIDAD LITERARIA',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '@${widget.username.replaceFirst(RegExp(r'^@'), '')}',
              style: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (var tab = 0; tab < 2; tab++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: tab == 0 ? 6 : 0,
                          left: tab == 1 ? 6 : 0),
                      child: OutlinedButton(
                        onPressed: () => _selectTab(tab),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _selectedTab == tab
                              ? gold.withValues(alpha: 0.18)
                              : AppColors.surfaceOf(context),
                          side: BorderSide(color: gold.withValues(
                              alpha: _selectedTab == tab ? 0.95 : 0.3)),
                        ),
                        child: Text(tab == 0 ? 'Seguidores' : 'Seguidos',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: primary,
                              fontSize: 12,
                            )),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _listContent(_selectedTab)),
        ],
      ),
    );
  }
}
