import 'package:shared_preferences/shared_preferences.dart';

class PendingUsernameStore {
  static String _key(String uid) => 'pending_username_$uid';

  Future<void> save(String uid, String username) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _key(uid),
      username,
    );
  }

  Future<String?> get(String uid) async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_key(uid));
  }

  Future<void> remove(String uid) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_key(uid));
  }
}