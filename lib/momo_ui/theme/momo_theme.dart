import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MomoColors {
  // Dark Backgrounds
  static const Color background = Color(0xFF0D0E15);
  static const Color surface = Color(0xFF161824);
  static const Color surfaceLight = Color(0xFF202336);
  static const Color card = Color(0xFF1C1F30);

  // Light / Pastel Day Theme Backgrounds
  static const Color lightBackground = Color(0xFFFFF7ED);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFFFEDD5);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Accents & Glows
  static const Color primary = Color(0xFFFF6B8B);      // Vibrant Sunset Peach-Coral
  static const Color primaryGlow = Color(0x33FF6B8B);
  static const Color violet = Color(0xFF8B5CF6);       // Electric Violet
  static const Color amber = Color(0xFFFFAE33);        // Warm Golden Amber
  static const Color cyan = Color(0xFF06B6D4);         // Cyber Cyan
  static const Color rose = Color(0xFFF43F5E);         // Companion Rose

  // Dark Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Light Text
  static const Color lightTextPrimary = Color(0xFF1E1B2E);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Borders & Glass
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const Color glassSurface = Color(0x0FFFFFFF);
  static const Color lightGlassBorder = Color(0x1F000000);
}

class MomoTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MomoColors.background,
      primaryColor: MomoColors.primary,
      cardColor: MomoColors.card,
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

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: MomoColors.lightBackground,
      primaryColor: MomoColors.primary,
      cardColor: MomoColors.lightCard,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: MomoColors.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: MomoColors.lightTextPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MomoColors.lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: MomoColors.lightTextPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: MomoColors.lightTextSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}
