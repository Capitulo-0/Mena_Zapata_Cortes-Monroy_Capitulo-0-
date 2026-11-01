part of '../screens/published_story_screen.dart';

extension _PublishedStoryPersistence on _PublishedStoryScreenState {
  Future<void> _loadPersistedReplies() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_repliesStorageKey);

    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return;
      }

      for (final comments in _commentsByChapter.values) {
        for (final comment in comments) {
          final storedReplies = decoded[comment.id];

          if (storedReplies is List) {
            final parsedReplies = <Map<String, dynamic>>[];

            for (final storedReply in storedReplies) {
              if (storedReply is String && storedReply.trim().isNotEmpty) {
                // Compatibilidad con respuestas guardadas antes de añadir privacidad.
                parsedReplies.add({
                  'text': storedReply.trim(),
                  'isPublic': true,
                });
                continue;
              }

              if (storedReply is Map) {
                final replyText =
                    storedReply['text']?.toString().trim() ?? '';

                if (replyText.isEmpty) continue;

                parsedReplies.add({
                  'text': replyText,
                  'isPublic': storedReply['isPublic'] as bool? ?? true,
                });
              }
            }

            comment.replies
              ..clear()
              ..addAll(parsedReplies);
          }
        }
      }

      if (!mounted) {
        return;
      }

      _updateState(() {});
    } catch (_) {
      // Si los datos locales están dañados, simplemente mantenemos
      // los comentarios mock sin respuestas persistidas.
    }
  }

  Future<void> _savePersistedReplies() async {
    final preferences = await SharedPreferences.getInstance();

    final data = <String, List<Map<String, dynamic>>>{};

    for (final comments in _commentsByChapter.values) {
      for (final comment in comments) {
        if (comment.replies.isNotEmpty) {
          data[comment.id] = comment.replies
              .map((reply) => Map<String, dynamic>.from(reply))
              .toList();
        }
      }
    }

    await preferences.setString(
      _repliesStorageKey,
      jsonEncode(data),
    );
  }
}
