import 'package:flutter/foundation.dart';

/// Estado compartido de privacidad del perfil.
///
/// Por ahora vive en memoria para simular la persistencia que más adelante
/// vendrá desde el backend/base de datos. Se conserva aunque se cierre y
/// vuelva a abrir la pantalla de Configuración durante la sesión de la app.
class ProfilePrivacyStore {
  ProfilePrivacyStore._();

  static final ValueNotifier<bool> isPrivate = ValueNotifier<bool>(false);
}
