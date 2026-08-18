import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MOMO UI — Typography System.
///
/// Modern, premium typography. Uses Google Fonts (Inter for body, Outfit for display).
/// Per MINDUSAGE.md: futuristic, premium feel.
class MomoTypography {
  MomoTypography._();

  // ─── Display (Headlines, Hero text) ───
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  static TextStyle displaySmall = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // ─── Body (Content, Messages) ───
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  // ─── Labels (Buttons, Chips, Tags) ───
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // ─── Code (Monospace for code blocks) ───
  static TextStyle code = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}
