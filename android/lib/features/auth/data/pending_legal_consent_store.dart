import 'package:shared_preferences/shared_preferences.dart';

/// Solo guarda la decisión afirmativa del usuario durante la verificación
/// de Firebase. La aprobación definitiva la registra el backend en Neon.
class PendingLegalConsentStore {
  static const version = '2026-11-20';
  static String _key(String uid) => 'pending_legal_consent_$uid';

  Future<void> save(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key(uid), version)) {
      throw StateError('No se pudo guardar la aceptación temporal.');
    }
  }

  Future<bool> accepted(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(uid)) == version;
  }

  Future<void> remove(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(uid));
  }
}
