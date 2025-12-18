import 'package:flutter/material.dart';

class AppColors {
  // GymFlow – Color System (Light Mode v1)

  // Primary
  static const Color primary = Color(0xFF2563EB); // #2563EB
  
  // Semantic Colors
  static const Color success = Color(0xFF22C55E); // #22C55E
  static const Color warning = Color(0xFFF59E0B); // #F59E0B
  static const Color error = Color(0xFFEF4444);   // #EF4444
  static const Color info = Color(0xFF38BDF8);    // #38BDF8

  // Neutrals / Backgrounds
  static const Color background = Color(0xFFF5F7FA); // #F5F7FA
  static const Color surface = Color(0xFFFFFFFF);    // #FFFFFF
  static const Color border = Color(0xFFE5E7EB);     // #E5E7EB

  // Text
  static const Color textMain = Color(0xFF111827); // #111827
  static const Color textSoft = Color(0xFF6B7280); // #6B7280

  // Material 3 Color Scheme
  static ColorScheme get lightScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: primary, // Using primary as secondary for now if not specified
    onSecondary: Colors.white,
    error: error,
    onError: Colors.white,
    surface: surface,
    onSurface: textMain,
    outline: border,
  );
}
