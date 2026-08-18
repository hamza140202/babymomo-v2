import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MomoColors {
  // Backgrounds
  static const Color background = Color(0xFF0D0E15);
  static const Color surface = Color(0xFF161824);
  static const Color surfaceLight = Color(0xFF202336);
  static const Color card = Color(0xFF1C1F30);

  // Accents & Glows
  static const Color primary = Color(0xFF8B5CF6);      // Electric Violet
  static const Color primaryGlow = Color(0x338B5CF6);
  static const Color amber = Color(0xFFF59E0B);        // Warm Amber
  static const Color amberGlow = Color(0x33F59E0B);
  static const Color cyan = Color(0xFF06B6D4);         // Cyber Cyan
  static const Color rose = Color(0xFFF43F5E);         // Companion Rose

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Borders & Glass
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const Color glassSurface = Color(0x0FFFFFFF);
}

class MomoTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MomoColors.background,
      primaryColor: MomoColors.primary,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: MomoColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: MomoColors.textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MomoColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: MomoColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: MomoColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}
