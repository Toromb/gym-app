import 'package:flutter/material.dart';

/// Estilos para texto e íconos que se muestran **directamente sobre la imagen
/// de fondo** (fuera de cualquier Card o panel opaco).
///
/// La sombra oscura garantiza legibilidad sin importar si la imagen de fondo
/// es oscura, clara o cambia en el futuro.
///
/// Uso:
/// ```dart
/// Text('Hola', style: BackgroundStyles.title)
/// Icon(Icons.arrow_back, color: BackgroundStyles.iconColor)
/// Text('Subtítulo', style: BackgroundStyles.fromTheme(theme.textTheme.bodyMedium))
/// ```
class BackgroundStyles {
  BackgroundStyles._();

  /// Sombra base — dos capas: una nítida + una difusa para mayor cobertura.
  static const List<Shadow> shadow = [
    Shadow(
      color: Color(0xCC000000), // Negro 80% opacidad
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
    Shadow(
      color: Color(0x66000000), // Negro 40% opacidad, radio mayor
      blurRadius: 16,
      offset: Offset(0, 2),
    ),
  ];

  /// Título principal sobre el fondo (ej: nombre del alumno, título de pantalla)
  static const TextStyle title = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    shadows: shadow,
  );

  /// Subtítulo / texto secundario sobre el fondo (ej: nombre del gimnasio)
  static const TextStyle subtitle = TextStyle(
    color: Colors.white70,
    shadows: shadow,
  );

  /// Etiqueta pequeña sobre el fondo (ej: rol, chip de paso)
  static const TextStyle label = TextStyle(
    color: Colors.white60,
    fontSize: 12,
    letterSpacing: 1.1,
    fontWeight: FontWeight.w600,
    shadows: shadow,
  );

  /// Color para íconos flotantes sobre el fondo (back button custom, etc.)
  static const Color iconColor = Colors.white;

  /// Aplica color blanco + sombra sobre cualquier TextStyle existente del tema.
  /// Ideal para mantener tamaño/peso del estilo original pero garantizar legibilidad.
  ///
  /// Ejemplo: `BackgroundStyles.fromTheme(theme.textTheme.headlineSmall)`
  static TextStyle fromTheme(TextStyle? base, {Color color = Colors.white}) {
    return (base ?? const TextStyle()).copyWith(
      color: color,
      shadows: shadow,
    );
  }
}
