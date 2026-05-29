import 'package:flutter/material.dart';

class AppTheme {
  // Palet warna utama
  static const Color primaryColor = Color(0xFF14B8A6);
  static const Color secondaryColor = Color(0xFFFFB74D);
  static const Color backgroundColor = Color(0xFFF1FBFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F3A38);
  static const Color textSecondary = Color(0xFF5E7B78);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: cardColor,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: textPrimary,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorColor),
      ),
      labelStyle: const TextStyle(color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
  );

  static Color moodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'positive':
        return const Color(0xFFFFD166);

      case 'depressed':
        return const Color(0xFF7B9EE0);

      case 'anxious':
        return const Color(0xFF6DD3C0);

      case 'stressed':
        return const Color(0xFFEF6F6C);

      case 'stable':
        return const Color(0xFFB0BEC5);

      default:
        return primaryColor;
    }
  }

  static String moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'positive':
        return '😊';

      case 'depressed':
        return '😔';

      case 'anxious':
        return '😰';

      case 'stressed':
        return '😫';

      case 'stable':
        return '😐';

      default:
        return '❓';
    }
  }
}