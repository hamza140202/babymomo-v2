import 'package:flutter/material.dart';

/// MOMO UI — Motion Engine.
///
/// Centralized animation curves and durations for consistent
/// tactile, premium feel across the app.
/// Per MINDUSAGE.md: soft, cinematic, emotionally warm.
class MomoMotion {
  MomoMotion._();

  // ─── Durations ───
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration cinematic = Duration(milliseconds: 800);

  // ─── Curves (soft, spring-like, organic) ───
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve springCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;

  // ─── Page transitions ───
  static const Curve pageEnter = Curves.easeOutQuart;
  static const Curve pageExit = Curves.easeInQuart;

  // ─── Spacing constants (consistent rhythm) ───
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 999.0;
}
