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
        primary: brightness == Brightness.light ? primaryColor : null, // Only force in Light Mode
        secondary: brightness == Brightness.light ? secondaryColor : null,
      ),
      useMaterial3: true,
    );
  }
}
