import 'package:firebase_core/firebase_core.dart';

/// Only externally supplied client configuration, never Admin credentials.
class FirebaseConfigurationException implements Exception {
  const FirebaseConfigurationException(this.message);
  final String message;
}

class FirebaseWebConfiguration {
  const FirebaseWebConfiguration({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.authDomain,
  });

  const FirebaseWebConfiguration.fromEnvironment()
    : apiKey = const String.fromEnvironment('FIREBASE_WEB_API_KEY'),
      appId = const String.fromEnvironment('FIREBASE_WEB_APP_ID'),
      messagingSenderId = const String.fromEnvironment(
        'FIREBASE_WEB_MESSAGING_SENDER_ID',
      ),
      projectId = const String.fromEnvironment('FIREBASE_WEB_PROJECT_ID'),
      authDomain = const String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String authDomain;

  FirebaseOptions toOptions() {
    final fields = <String, String>{
      'FIREBASE_WEB_API_KEY': apiKey,
      'FIREBASE_WEB_APP_ID': appId,
      'FIREBASE_WEB_MESSAGING_SENDER_ID': messagingSenderId,
      'FIREBASE_WEB_PROJECT_ID': projectId,
      'FIREBASE_WEB_AUTH_DOMAIN': authDomain,
    };
    final missing = fields.entries
        .where((entry) => entry.value.trim().isEmpty)
        .map((entry) => entry.key)
        .toList();
    if (missing.isNotEmpty) {
      throw FirebaseConfigurationException(
        'Falta la configuración Firebase Web: ${missing.join(', ')}. '
        'Obtén los valores de la app Web del mismo proyecto que Android y '
        'ejecuta con --dart-define-from-file=config/firebase_web.local.json.',
      );
    }
    if (fields.values.any((value) => value != value.trim())) {
      throw const FirebaseConfigurationException(
        'La configuración Firebase Web contiene espacios adicionales. Revisa el archivo local.',
      );
    }
    final webApp = RegExp(r'^1:([0-9]+):web:[A-Za-z0-9]+$').firstMatch(appId);
    if (webApp == null || webApp.group(1) != messagingSenderId) {
      throw const FirebaseConfigurationException(
        'La configuración debe corresponder a una app Firebase Web y su mismo messagingSenderId. '
        'No uses el appId Android.',
      );
    }
    final domain = Uri.tryParse('https://$authDomain');
    if (domain == null ||
        domain.host.isEmpty ||
        domain.host != authDomain ||
        domain.userInfo.isNotEmpty ||
        domain.hasPort ||
        domain.path.isNotEmpty ||
        domain.hasQuery ||
        domain.hasFragment) {
      throw const FirebaseConfigurationException(
        'FIREBASE_WEB_AUTH_DOMAIN debe ser solo el dominio indicado por Firebase, sin protocolo, ruta ni puerto.',
      );
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain,
    );
  }

  static FirebaseOptions? optionsForPlatform({
    required bool isWeb,
    FirebaseWebConfiguration web =
        const FirebaseWebConfiguration.fromEnvironment(),
  }) => isWeb ? web.toOptions() : null;
}
