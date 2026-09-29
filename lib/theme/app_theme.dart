import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de Colores de Alto Contraste (según especificación Radio-Mesh)
  static const Color navy = Color(0xFF0A1F44);
  static const Color navyLight = Color(0xFF122960);
  static const Color navyDark = Color(0xFF06132D);
  static const Color lime = Color(0xFF4CD137);
  static const Color limeLight = Color(0xFFE8FADC);
  static const Color orange = Color(0xFFFF6B00);
  static const Color orangeLight = Color(0xFFFFF0E6);
  static const Color redAlert = Color(0xFFE53E3E);
  static const Color redAlertLight = Color(0xFFFFF5F5);
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1A202C);
  static const Color textMuted = Color(0xFF718096);
  static const Color textLight = Colors.white;
  static const Color borderSubtle = Color(0xFFE2E8F0);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        primary: navy,
        secondary: orange,
        tertiary: lime,
        surface: bgLight,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
          elevation: 4,
          shadowColor: orange.withAlpha(100),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
    );
  }
}
