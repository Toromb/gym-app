import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData createTheme({
    required Color primaryColor,
    required Color secondaryColor,
    required Brightness brightness,
  }) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor, // Always force gym primary color in both modes
        secondary: secondaryColor,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        // Tinte suave del color primario del gym para ambos modos.
        color: brightness == Brightness.light
            ? Color.alphaBlend(
                primaryColor.withValues(alpha: 0.30),
                Colors.white,
              )
            : Color.alphaBlend(
                primaryColor.withValues(alpha: 0.45),
                const Color(0xFF1E1E2A),
              ).withValues(alpha: 0.78),
        elevation: brightness == Brightness.light ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: brightness == Brightness.light
            ? primaryColor.withValues(alpha: 0.15)
            : Colors.black54,
      ),
    );
  }
}
