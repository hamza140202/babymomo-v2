import 'package:flutter/material.dart';

/// MOMO UI — Color System.
///
/// Per MINDUSAGE.md: soft, cinematic, emotionally warm, futuristic.
/// NO terminal aesthetics. NO enterprise dashboards.
class MomoColors {
  MomoColors._();

  // ─── Primary Palette (warm, emotionally intelligent) ───
  static const Color primary = Color(0xFFB388FF);       // Soft lavender
  static const Color primaryLight = Color(0xFFE7B9FF);
  static const Color primaryDark = Color(0xFF7C4DFF);

  // ─── Accent ───
  static const Color accent = Color(0xFFFF80AB);         // Warm rose
  static const Color accentLight = Color(0xFFFFB2DD);
  static const Color accentDark = Color(0xFFC94F7C);

  // ─── Surface (Dark Mode — cinematic, premium) ───
  static const Color background = Color(0xFF0D0D1A);     // Deep space
  static const Color surface = Color(0xFF1A1A2E);        // Card surface
  static const Color surfaceLight = Color(0xFF252540);    // Elevated surface
  static const Color surfaceBright = Color(0xFF30304D);   // Highlighted surface

  // ─── Text ───
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color textMuted = Color(0xFF6E6E8A);

  // ─── Semantic ───
  static const Color success = Color(0xFF69F0AE);
  static const Color warning = Color(0xFFFFD54F);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF64B5F6);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFB388FF), Color(0xFF7C4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF80AB), Color(0xFFB388FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
