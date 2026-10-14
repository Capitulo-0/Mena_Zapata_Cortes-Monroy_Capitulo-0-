import 'package:flutter/material.dart';

/// Paleta de colores principal de Capítulo 0.
///
/// Guardamos los colores en un solo lugar para reutilizarlos
/// en todas las pantallas y mantener un diseño consistente.
class AppColors {
  AppColors._();

  // ============================================================
  // TEMA CLARO
  // ============================================================

  /// Fondo crema principal de la aplicación.
  static const Color background = Color(0xFFF7EFE2);

  /// Fondo de tarjetas, formularios y elementos elevados.
  static const Color surface = Color(0xFFFDFAF5);

  /// Fondo secundario más oscuro.
  static const Color surfaceSoft = Color(0xFFE8DDD0);

  /// Marrón principal.
  static const Color deep = Color(0xFF381D14);

  /// Marrón secundario.
  static const Color deepAlt = Color(0xFF4A2A1A);

  /// Color del texto principal.
  static const Color textPrimary = Color(0xFF1F1916);

  /// Color de textos secundarios.
  static const Color textSecondary = Color(0xFF7A6F68);

  /// Dorado característico de Capítulo 0.
  static const Color gold = Color(0xFFC5A059);

  /// Burdeo principal.
  static const Color accent = Color(0xFF8B1E28);

  /// Burdeo más claro para degradados.
  static const Color accentLight = Color(0xFFB02535);

  /// Fondo oscuro utilizado en el Splash.
  static const Color splashBackground = Color(0xFF250D0B);

  // ============================================================
  // TEMA OSCURO
  // ============================================================

  static const Color darkBackground = Color(0xFF1A100D);
  static const Color darkSurface = Color(0xFF241713);
  static const Color darkSurfaceSoft = Color(0xFF2D1C16);

  static const Color darkDeep = Color(0xFF30170F);
  static const Color darkDeepAlt = Color(0xFF3A1D16);

  static const Color darkTextPrimary = Color(0xFFF4EBDD);
  static const Color darkTextSecondary = Color(0xFFB9A99C);

  static const Color darkGold = Color(0xFFB89A63);
  static const Color darkAccent = Color(0xFFA52A38);
}
