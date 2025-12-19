import 'package:flutter/material.dart';

class AppColors {
  // GymFlow – Modern Color System

  // Brand Colors (Defaults)
  static const Color primary = Color(0xFF2563EB); // Modern Blue (Tailwind Blue-600)
  static const Color primaryDark = Color(0xFF1E40AF); // Blue-800
  static const Color accent = Color(0xFF3B82F6); // Blue-500

  // Semantic Colors (Vivid & Accessible)
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error = Color(0xFFEF4444);   // Red-500
  static const Color info = Color(0xFF0EA5E9);    // Sky-500

  // Neutrals / Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Color(0xFFFFFFFF);    // White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate-100

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);     // Slate-200
  static const Color divider = Color(0xFFCBD5E1);    // Slate-300

  // Text Colors
  static const Color textMain = Color(0xFF0F172A);   // Slate-900 (High Emphasis)
  static const Color textBody = Color(0xFF334155);   // Slate-700 (Medium Emphasis)
  static const Color textSoft = Color(0xFF64748B);   // Slate-500 (Low Emphasis)
  static const Color textInverse = Color(0xFFFFFFFF); // White

  // Shadows
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
