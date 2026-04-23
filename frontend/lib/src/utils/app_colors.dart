import 'package:flutter/material.dart';

/// # TuGymFlow – Design Token System
///
/// ## Arquitectura de Temas por Gimnasio (GYM-PER-THEME)
///
/// Todos los colores marcados con `[GYM-CONFIGURABLE]` son tokens que en el
/// futuro se cargarán dinámicamente desde la configuración del admin de cada
/// gimnasio (DB → API → GymThemeProvider).
///
/// ### Pasos para implementar la feature de tema por gym:
/// 1. Crear `GymThemeProvider` que cargue los tokens desde la API al login.
/// 2. Reemplazar los `static const Color` marcados por `static Color get`
///    que lean del provider (usando un singleton o InheritedWidget).
/// 3. En el `AdminProfile`, agregar una pantalla "Personalización" con color picker.
/// 4. Guardar en backend: `POST /gym-config { cardColor, primaryColor, ... }`.
///
/// Por ahora todos los tokens son `const`. El cambio futuro es mínimo
/// porque todas las pantallas ya referencian estos nombres — no hex directos.
class AppColors {
  AppColors._(); // No instances

  // ─────────────────────────────────────────────────────────────────
  // [GYM-CONFIGURABLE] Brand / Primary Colors
  // ─────────────────────────────────────────────────────────────────

  /// Color principal del gimnasio. Usado en botones, íconos activos, etc.
  static const Color primary = Color(0xFF2563EB); // Blue-600
  static const Color primaryDark = Color(0xFF1E40AF); // Blue-800
  static const Color accent = Color(0xFF3B82F6); // Blue-500

  // ─────────────────────────────────────────────────────────────────
  // Semantic Colors (NOT gym-configurable)
  // ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color info = Color(0xFF0EA5E9); // Sky-500

  // ─────────────────────────────────────────────────────────────────
  // Neutrals / Backgrounds (NOT gym-configurable)
  // ─────────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate-100

  // ─────────────────────────────────────────────────────────────────
  // [GYM-CONFIGURABLE] Card Surface — TOKEN CENTRAL DEL TEMA
  // ─────────────────────────────────────────────────────────────────
  /// Color de fondo de las cards en modo claro.
  ///
  /// **[GYM-CONFIGURABLE]**: Token central de identidad visual del gimnasio.
  /// Todas las `Card` y contenedores de datos usan este valor vía:
  ///   - `CardThemeData` global (app_theme.dart) → aplica automáticamente a Card()
  ///   - Referencia directa `AppColors.cardSurface` → en Container/custom widgets
  ///
  /// Para cambiar el color de toda la app → cambiar SOLO este valor.
  /// En el futuro: leer desde `GymThemeProvider.cardColor` (cargado del backend).
  static const Color cardSurface = Color(0xFFB8D4F5); // [GYM-CONFIGURABLE]

  // ─────────────────────────────────────────────────────────────────
  // Borders & Dividers
  // ─────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0); // Slate-200
  static const Color divider = Color(0xFFCBD5E1); // Slate-300

  // ─────────────────────────────────────────────────────────────────
  // Text Colors (NOT gym-configurable)
  // ─────────────────────────────────────────────────────────────────
  static const Color textMain = Color(0xFF0F172A); // Slate-900
  static const Color textBody = Color(0xFF334155); // Slate-700
  static const Color textSoft = Color(0xFF64748B); // Slate-500
  static const Color textInverse = Color(0xFFFFFFFF); // White

  // ─────────────────────────────────────────────────────────────────
  // Shadows
  // ─────────────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))
  ];

  // Backward Compatibility
  static ColorScheme get lightScheme => const ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textMain,
        outline: border,
      );
}
