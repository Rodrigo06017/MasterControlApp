import 'package:flutter/material.dart';

class XboxTheme {
  // Brand Colors
  static const Color background = Color(0xFF0C0D0E);
  static const Color surface = Color(0xFF16181C);
  static const Color surfaceBright = Color(0xFF22262B);
  static const Color card = Color(0xFF1B1E22);

  // Xbox Accent Greens
  static const Color xboxGreen = Color(0xFF107C10);
  static const Color neonGreen = Color(0xFF00FF5E);
  static const Color xboxGreenGlow = Color(0x66107C10);

  // Controller Action Button Colors
  static const Color btnA = Color(0xFF107C10); // Green
  static const Color btnB = Color(0xFFE81123); // Red
  static const Color btnX = Color(0xFF0078D7); // Blue
  static const Color btnY = Color(0xFFFFB900); // Yellow

  // Neutral tones
  static const Color textPrimary = Color(0xFFF5F6F8);
  static const Color textSecondary = Color(0xFF8A9099);
  static const Color divider = Color(0xFF2A2E35);
  static const Color dpadBody = Color(0xFF1C1E23);
  static const Color dpadBorder = Color(0xFF333842);

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: xboxGreen,
      colorScheme: const ColorScheme.dark(
        primary: xboxGreen,
        secondary: neonGreen,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      fontFamily: 'Segoe UI',
    );
  }
}
