import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../writer/models/writer_publication.dart';
import '../../../writer/models/writer_story.dart';
import '../../../writer/services/writer_repository.dart';
import '../../../writer/presentation/screens/published_story_screen.dart';
import '../widgets/community_stories_section.dart';

/// Catálogo de publicaciones reales. Reutiliza las mismas tarjetas de Home.
class CommunityPublicationsScreen extends StatefulWidget {
  const CommunityPublicationsScreen({
    super.key,
    required this.repository,
    required this.currentUsername,
    required this.onAuthorTap,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.savedStoryIds,
    required this.savingStoryIds,
    required this.onSaveStory,
  });

  final CommunityWriterRepository repository;
  final String currentUsername;
  final ValueChanged<WriterPublication> onAuthorTap;
  final Set<String> favoriteIds;
  final ValueChanged<WriterStory> onToggleFavorite;
  final Set<String> savedStoryIds;
  final Set<String> savingStoryIds;
  final Future<bool> Function(WriterPublication) onSaveStory;

  @override
  State<CommunityPublicationsScreen> createState() =>
      _CommunityPublicationsScreenState();
}

class _CommunityPublicationsScreenState
    extends State<CommunityPublicationsScreen> {
  List<WriterPublication> _publications = [];
  bool _loading = true;
  String? _error;
  String? _opening;
  int _request = 0;
  final Set<String> _newlySaved = {};
  final Set<String> _saving = {};

  Future<void> _save(WriterPublication story) async {
    if (_saving.contains(story.id) || widget.savedStoryIds.contains(story.id) || _newlySaved.contains(story.id)) return;
    setState(() => _saving.add(story.id));
    try {
      final success = await widget.onSaveStory(story);
      if (success && mounted) setState(() => _newlySaved.add(story.id));
    } finally {
      if (mounted) setState(() => _saving.remove(story.id));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.repository.getPublications();
      if (mounted && request == _request) {
        setState(() => _publications = items);
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = 'No pudimos cargar las historias.');
      }
    } finally {
      if (mounted && request == _request) {
        setState(() => _loading = false);
      }
    }
  }

  void _openAuthor(WriterPublication publication) {
    // El perfil pertenece a la pestaña principal, no al Navigator del catálogo.
    Navigator.of(context).pop();
    widget.onAuthorTap(publication);
  }

  Future<void> _read(WriterPublication publication) async {
    if (_opening != null) return;
    setState(() => _opening = publication.id);
    try {
      final story = await widget.repository.readPublication(publication.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PublishedStoryScreen(
            story: story,
            currentUsername: widget.currentUsername,
            authorUsername: publication.author,
            initiallyFavorite: widget.favoriteIds.contains(story.id),
            onToggleFavorite: () => widget.onToggleFavorite(story),
          ),
        ),
      );
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta historia ya no está disponible.')),
        );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.deepOf(context),
        foregroundColor: AppColors.goldOf(context),
        title: Text(
          'Comunidad',
          style: GoogleFonts.cinzel(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Text(
              'Historias de la comunidad',
              style: GoogleFonts.cinzel(
                fontSize: 17,
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Descubre las obras publicadas por nuestra comunidad lectora.',
              style: GoogleFonts.merriweather(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 20),
            if (_loading && _publications.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (_error != null && _publications.isEmpty) ...[
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ] else if (_publications.isEmpty)
              const Text('Aún no hay historias publicadas.')
            else
              for (final publication in _publications)
                CommunityStoryCard(
                  key: ValueKey('community-story-${publication.id}'),
                  story: publication,
                  onAuthorTap: () => _openAuthor(publication),
                  onStoryTap: () => _read(publication),
                  loading: _opening == publication.id,
                  saved: widget.savedStoryIds.contains(publication.id) || _newlySaved.contains(publication.id),
                  saving: widget.savingStoryIds.contains(publication.id) || _saving.contains(publication.id),
                  onSave: () => _save(publication),
                ),
          ],
        ),
      ),
    );
  }
}
