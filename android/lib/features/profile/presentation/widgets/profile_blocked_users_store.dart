import 'package:flutter/foundation.dart';

/// Estado temporal compartido de usuarios bloqueados.
///
/// Mantiene sincronizados Profile y Configuración durante la sesión.
/// Más adelante este estado puede ser reemplazado por el backend sin cambiar
/// la intención de las vistas.
class ProfileBlockedUsersStore {
  ProfileBlockedUsersStore._();

  static final ValueNotifier<List<Map<String, String>>> blockedUsers =
      ValueNotifier<List<Map<String, String>>>(<Map<String, String>>[]);

  static Set<String> get usernames => blockedUsers.value
      .map((user) => user['username'])
      .whereType<String>()
      .toSet();

  static bool isBlocked(String? username) {
    if (username == null || username.isEmpty) return false;
    return usernames.contains(username);
  }

  static void block(Map<String, String> user) {
    final username = user['user'] ?? user['username'];
    if (username == null || username.isEmpty || isBlocked(username)) return;

    blockedUsers.value = <Map<String, String>>[
      ...blockedUsers.value,
      <String, String>{
        'name': user['name'] ?? username,
        'username': username,
      },
    ];
  }

  static void unblock(String username) {
    blockedUsers.value = blockedUsers.value
        .where((user) => user['username'] != username)
        .toList(growable: false);
  }
}
