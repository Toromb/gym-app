import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppTheme {
  /// Generates the app theme based on dynamic brand colors.
  static ThemeData createTheme({
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    // Text Theme
    final textTheme = const TextTheme(
      displayLarge: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, letterSpacing: -1.0),
      displayMedium: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      headlineLarge: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: AppColors.textBody, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: AppColors.textBody, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.textBody, fontSize: 14),
      labelLarge: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600), // Button text
      labelMedium: TextStyle(color: AppColors.textSoft),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      fontFamily: 'Roboto',
      
      // Input Decoration (Forms)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSoft),
        hintStyle: TextStyle(color: AppColors.textSoft.withOpacity(0.7)),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      textTheme: textTheme,
    );
  }
}
