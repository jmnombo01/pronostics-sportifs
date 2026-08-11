import 'package:flutter/material.dart';

class AppTheme {
  // Palette officielle Frogazz Sport Analyse : Vert Grenouille & Blanc
  static const Color black = Color(0xFF060907);
  static const Color darkCard = Color(0xFF0F1711);
  static const Color white = Color(0xFFFFFFFF);
  static const Color frogGreen = Color(0xFF00E676);
  static const Color frogGreenDark = Color(0xFF00B248);
  static const Color frogGreenLight = Color(0xFF66FFA6);
  static const Color red = Color(0xFFFF5252);
  static const Color grey = Color(0xFF8EAE96);
  static const Color darkBorder = Color(0xFF1F3325);

  // Alias de rétrocompatibilité pour assurer 100% de compilation dans tous les widgets
  static const Color green = frogGreen;
  static const Color gold = frogGreen;
  static const Color goldLight = frogGreenLight;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      primaryColor: frogGreen,
      colorScheme: const ColorScheme.dark(
        primary: frogGreen,
        secondary: frogGreenLight,
        surface: darkCard,
        error: red,
        onPrimary: black,
        onSecondary: black,
        onSurface: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: frogGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          inherit: true,
        ),
        iconTheme: IconThemeData(color: frogGreen),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: darkBorder, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: frogGreen,
          foregroundColor: black,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            inherit: true,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        hintStyle: const TextStyle(color: grey, inherit: true),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: frogGreen, width: 2),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4FAF6),
      primaryColor: frogGreen,
      colorScheme: const ColorScheme.light(
        primary: frogGreen,
        secondary: frogGreenDark,
        surface: white,
        error: red,
        onPrimary: black,
        onSecondary: white,
        onSurface: black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          inherit: true,
        ),
        iconTheme: IconThemeData(color: black),
      ),
    );
  }
}
