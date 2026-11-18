import '../widgets/writer_cover.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/writer_publication.dart';
import '../../services/writer_repository.dart';
import 'published_story_screen.dart';

class WriterCommunityScreen extends StatefulWidget {
  const WriterCommunityScreen({
    super.key,
    required this.repository,
    required this.currentUsername,
  });
  final CommunityWriterRepository repository;
  final String currentUsername;
  @override
  State<WriterCommunityScreen> createState() => _WriterCommunityScreenState();
}

class _WriterCommunityScreenState extends State<WriterCommunityScreen> {
  List<WriterPublication> _publications = [];
  bool _loading = true;
  String? _error, _opening;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final publications = await widget.repository.getPublications();
      if (mounted) setState(() => _publications = publications);
    } catch (error) {
      if (mounted) setState(() => _error = writerError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _read(WriterPublication publication) async {
    if (_opening != null) return;
    setState(() => _opening = publication.id);
    try {
      // Fetch again: a withdrawn work must not open from a stale catalogue snapshot.
      final story = await widget.repository.readPublication(publication.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PublishedStoryScreen(
            story: story,
            currentUsername: widget.currentUsername,
            authorUsername: publication.author,
          ),
        ),
      );
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(writerError(error))));
        await _load();
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.deepOf(context),
      foregroundColor: AppColors.goldOf(context),
      elevation: 0,
      toolbarHeight: 68,
      title: Text(
        'Obras de la comunidad',
        style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Actualizar obras',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Historias originales de otros autores de Capítulo 0.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null) ...[
            Text(_error!, key: const ValueKey('writer-community-error')),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ] else if (_publications.isEmpty)
            const Text('Aún no hay obras de otros autores publicadas.')
          else
            ..._publications.map(
              (publication) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.gold),
                ),
                child: InkWell(
                  key: ValueKey('writer-read-${publication.id}'),
                  onTap: _opening == null ? () => _read(publication) : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        WriterCover(
                          storyId: publication.id,
                          coverPath: publication.coverPath,
                          title: publication.title,
                          author: publication.author,
                          width: 64,
                          height: 92,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                publication.title,
                                style: GoogleFonts.merriweather(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: AppColors.textPrimaryOf(context),
                                ),
                              ),
                              Text(
                                'por ${publication.author}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                publication.synopsis,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${publication.genre} · ${publication.chapterCount} capítulos',
                              ),
                              if (_opening == publication.id)
                                const LinearProgressIndicator(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
