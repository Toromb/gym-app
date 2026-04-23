import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

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
        primary: brightness == Brightness.light
            ? primaryColor
            : null, // Only force in Light Mode
        secondary: brightness == Brightness.light ? secondaryColor : null,
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
        // Pastel teal-green in light mode; keep Material3 surface in dark mode
        color: brightness == Brightness.light ? AppColors.cardSurface : null,
        elevation: brightness == Brightness.light ? 0 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: brightness == Brightness.light
            ? const Color(0xFF5B8C98).withValues(alpha: 0.15)
            : null,
      ),
    );
  }
}
