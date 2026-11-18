import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Device-local recovery, scoped to the signed-in account. Never uploads itself.
/// Plain text app storage, not a credential store or an encrypted backup.
class WriterDraftStore {
  WriterDraftStore({
    required this.ownerUid,
    required this.storyId,
    required this.chapterId,
  });
  final String ownerUid, storyId;
  final String? chapterId;
  String get key =>
      'writer_pending_v1_${jsonEncode([ownerUid, storyId, chapterId])}';
  static Future<void>? _queue;
  Future<void> _write(Future<void> Function() action) {
    final previous = _queue;
    late final Future<void> next;
    next = () async {
      try {
        if (previous != null) await previous.catchError((Object _) {});
        await action();
      } finally {
        if (identical(_queue, next)) _queue = null;
      }
    }();
    _queue = next;
    return next;
  }

  Future<Map<String, dynamic>?> load() async {
    final pending = _queue;
    if (pending != null) await pending.catchError((Object _) {});
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return null;
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['title'] is! String ||
        data['content'] is! String ||
        data['revision'] is! int ||
        data['chapterId'] is! String ||
        data['order'] is! int) {
      throw const FormatException('Copia local no válida');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<void> save(Map<String, dynamic> snapshot) => _write(() async {
    final ok = await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode(snapshot),
    );
    if (!ok) throw StateError('No se pudo guardar la copia local');
  });
  Future<void> clear() => _write(() async {
    final ok = await (await SharedPreferences.getInstance()).remove(key);
    if (!ok) throw StateError('No se pudo eliminar la copia local');
  });
}
