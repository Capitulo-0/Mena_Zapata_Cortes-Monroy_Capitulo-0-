import 'package:flutter/material.dart';

import '../../models/writer_story.dart';
import '../../services/writer_local_service.dart';

/// Read-only access. Never deletes, uploads or claims legacy documents.
class WriterLegacyScreen extends StatefulWidget {
  const WriterLegacyScreen({super.key, this.ownerUid});
  final String? ownerUid;
  @override
  State<WriterLegacyScreen> createState() => _WriterLegacyScreenState();
}

class _WriterLegacyScreenState extends State<WriterLegacyScreen> {
  late final Future<List<WriterStory>> _stories = _load();
  Future<List<WriterStory>> _load() async {
    final uid = widget.ownerUid;
    if (uid == null) {
      return []; // Unscoped legacy data has no provable account owner.
    }
    return WriterLocalService(scope: uid).getStories();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Borradores anteriores')),
    body: FutureBuilder<List<WriterStory>>(
      future: _stories,
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Copia local anterior de esta cuenta en este dispositivo. No está sincronizada. Puedes copiar el texto y crear una historia nueva en Writer; no se importa ni elimina automáticamente.',
          ),
          const SizedBox(height: 16),
          if (snapshot.hasError)
            const Text(
              'No se pudo abrir el almacenamiento local. No se han borrado sus datos.',
            )
          else if (!snapshot.hasData)
            const Center(child: CircularProgressIndicator())
          else if (snapshot.data!.isEmpty)
            const Text('No hay historias locales anteriores para esta cuenta.')
          else
            ...snapshot.data!.map(
              (story) => ExpansionTile(
                title: Text(story.title),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(story.synopsis),
                  ),
                  ...story.chapters.map(
                    (c) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText('${c.title}\n\n${c.content}'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
