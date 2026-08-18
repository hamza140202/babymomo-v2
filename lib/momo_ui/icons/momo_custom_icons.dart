import 'dart:math';
import 'package:flutter/material.dart';

/// Babymomo v2 — 3D Pastel Mochi Navigation Icon System
/// Implements 1:1 exact vector paths, shapes, gradients, blushes, kawaii eyes, and badges
/// from `assets/branding/preview_custom_icons.html`.
class MomoCustomIcons {
  // 1. Lounge: Mini Master Mochi Mascot Icon
  static Widget lounge({bool isActive = false, double size = 32}) {
    return _buildIconWrapper(
      isActive: isActive,
      size: size,
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B8B), Color(0xFFFFAE33)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: const Color(0xFFFF6B8B).withOpacity(0.4),
      painter: _LoungeMascotPainter(isActive: isActive),
    );
  }

  // 2. Chat: 3D Soft Mochi Speech Pillow
  static Widget chat({bool isActive = false, double size = 32}) {
    return _buildIconWrapper(
      isActive: isActive,
      size: size,
      gradient: const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.4),
      painter: _ChatPillowPainter(isActive: isActive),
    );
  }

  // 3. Studio: 3D Soft Mochi Star / Diffusion Wand
  static Widget studio({bool isActive = false, double size = 32}) {
    return _buildIconWrapper(
      isActive: isActive,
      size: size,
      gradient: const LinearGradient(
        colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: const Color(0xFFF43F5E).withOpacity(0.4),
      painter: _StudioStarPainter(isActive: isActive),
    );
  }

  // 4. Hub: 3D Soft Mochi Neural Chip Companion
  static Widget hub({bool isActive = false, double size = 32}) {
    return _buildIconWrapper(
      isActive: isActive,
      size: size,
      gradient: const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: const Color(0xFF06B6D4).withOpacity(0.4),
      painter: _HubChipPainter(isActive: isActive),
    );
  }

  static Widget _buildIconWrapper({
    required bool isActive,
    required double size,
    required LinearGradient gradient,
    required Color shadowColor,
    required CustomPainter painter,
  }) {
    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: isActive ? gradient : null,
        color: isActive ? null : Colors.white.withOpacity(0.06),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size, size),
          painter: painter,
        ),
      ),
    );
  }
}

// ── 1. Lounge Mascot Painter (Exact SVG from preview_custom_icons.html) ───────
class _LoungeMascotPainter extends CustomPainter {
  final bool isActive;
  _LoungeMascotPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;

    // Ears
    final earOuterPaint = Paint()..color = isActive ? Colors.white : const Color(0xFF64748B);
    final earInnerPaint = Paint()..color = const Color(0xFFFDA4AF);

    // Left Ear
    canvas.save();
    canvas.translate(36 * s, 30 * s);
    canvas.rotate(-15 * pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 16 * s, height: 22 * s), earOuterPaint);
    if (isActive) {
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 9 * s, height: 14 * s), earInnerPaint);
    }
    canvas.restore();

    // Right Ear
    canvas.save();
    canvas.translate(64 * s, 30 * s);
    canvas.rotate(15 * pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 16 * s, height: 22 * s), earOuterPaint);
    if (isActive) {
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 9 * s, height: 14 * s), earInnerPaint);
    }
    canvas.restore();

    // Body
    final bodyPath = Path()
      ..moveTo(50 * s, 28 * s)
      ..cubicTo(70 * s, 28 * s, 77 * s, 38 * s, 77 * s, 56 * s)
      ..cubicTo(77 * s, 72 * s, 68 * s, 76 * s, 50 * s, 76 * s)
      ..cubicTo(32 * s, 76 * s, 23 * s, 72 * s, 23 * s, 56 * s)
      ..cubicTo(23 * s, 38 * s, 30 * s, 28 * s, 50 * s, 28 * s)
      ..close();

    final bodyPaint = Paint()
      ..color = isActive ? Colors.white : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bodyPaint);

    if (isActive) {
      // Rosy Blushes
      final blushPaint = Paint()..color = const Color(0xFFFF4D6D).withOpacity(0.55);
      canvas.drawCircle(Offset(34 * s, 58 * s), 5 * s, blushPaint);
      canvas.drawCircle(Offset(66 * s, 58 * s), 5 * s, blushPaint);
    }

    // Eyes
    final eyePaint = Paint()..color = isActive ? const Color(0xFF18181B) : const Color(0xFF0D0E15);
    final shinePaint = Paint()..color = Colors.white;

    canvas.drawOval(Rect.fromCenter(center: Offset(40 * s, 50 * s), width: 7 * s, height: 10 * s), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(60 * s, 50 * s), width: 7 * s, height: 10 * s), eyePaint);

    if (isActive) {
      canvas.drawCircle(Offset(41 * s, 48 * s), 1.5 * s, shinePaint);
      canvas.drawCircle(Offset(61 * s, 48 * s), 1.5 * s, shinePaint);

      // Smile
      final smilePaint = Paint()
        ..color = const Color(0xFF18181B)
        ..strokeWidth = 1.4 * s
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final smilePath = Path()
        ..moveTo(47 * s, 55 * s)
        ..quadraticBezierTo(50 * s, 58 * s, 53 * s, 55 * s);
      canvas.drawPath(smilePath, smilePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoungeMascotPainter oldDelegate) => oldDelegate.isActive != isActive;
}

// ── 2. Chat Speech Pillow Painter (Exact SVG from preview_custom_icons.html) ──
class _ChatPillowPainter extends CustomPainter {
  final bool isActive;
  _ChatPillowPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;

    // Speech Pillow Body
    final bodyPath = Path()
      ..moveTo(28 * s, 32 * s)
      ..cubicTo(28 * s, 22 * s, 38 * s, 18 * s, 50 * s, 18 * s)
      ..cubicTo(68 * s, 18 * s, 76 * s, 25 * s, 76 * s, 42 * s)
      ..cubicTo(76 * s, 56 * s, 66 * s, 64 * s, 50 * s, 64 * s)
      ..cubicTo(44 * s, 64 * s, 38 * s, 67 * s, 28 * s, 72 * s)
      ..cubicTo(30 * s, 65 * s, 28 * s, 58 * s, 28 * s, 52 * s)
      ..close();

    final bodyPaint = Paint()
      ..color = isActive ? Colors.white : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bodyPaint);

    if (isActive) {
      // Rosy Blushes
      final blushPaint = Paint()..color = const Color(0xFFA78BFA).withOpacity(0.45);
      canvas.drawCircle(Offset(38 * s, 46 * s), 4.5 * s, blushPaint);
      canvas.drawCircle(Offset(66 * s, 46 * s), 4.5 * s, blushPaint);
    }

    // Eyes
    final eyePaint = Paint()..color = isActive ? const Color(0xFF18181B) : const Color(0xFF0D0E15);
    final shinePaint = Paint()..color = Colors.white;

    canvas.drawOval(Rect.fromCenter(center: Offset(44 * s, 38 * s), width: 6 * s, height: 9 * s), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(60 * s, 38 * s), width: 6 * s, height: 9 * s), eyePaint);

    if (isActive) {
      canvas.drawCircle(Offset(45 * s, 36 * s), 1.3 * s, shinePaint);
      canvas.drawCircle(Offset(61 * s, 36 * s), 1.3 * s, shinePaint);

      // Smile
      final smilePaint = Paint()
        ..color = const Color(0xFF18181B)
        ..strokeWidth = 1.3 * s
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final smilePath = Path()
        ..moveTo(50 * s, 43 * s)
        ..quadraticBezierTo(52 * s, 46 * s, 54 * s, 43 * s);
      canvas.drawPath(smilePath, smilePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChatPillowPainter oldDelegate) => oldDelegate.isActive != isActive;
}

// ── 3. Studio Star Painter (Exact SVG from preview_custom_icons.html) ─────────
class _StudioStarPainter extends CustomPainter {
  final bool isActive;
  _StudioStarPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;

    // Magic Star Body
    final starPath = Path()
      ..moveTo(50 * s, 20 * s)
      ..cubicTo(53 * s, 34 * s, 66 * s, 47 * s, 80 * s, 50 * s)
      ..cubicTo(66 * s, 53 * s, 53 * s, 66 * s, 50 * s, 80 * s)
      ..cubicTo(47 * s, 66 * s, 34 * s, 53 * s, 20 * s, 50 * s)
      ..cubicTo(34 * s, 47 * s, 47 * s, 34 * s, 50 * s, 20 * s)
      ..close();

    final bodyPaint = Paint()
      ..color = isActive ? Colors.white : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, bodyPaint);

    if (isActive) {
      // Blushes
      final blushPaint = Paint()..color = const Color(0xFFFDA4AF).withOpacity(0.7);
      canvas.drawCircle(Offset(40 * s, 52 * s), 3.5 * s, blushPaint);
      canvas.drawCircle(Offset(60 * s, 52 * s), 3.5 * s, blushPaint);
    }

    // Eyes
    final eyePaint = Paint()..color = isActive ? const Color(0xFF18181B) : const Color(0xFF0D0E15);
    final shinePaint = Paint()..color = Colors.white;

    canvas.drawOval(Rect.fromCenter(center: Offset(44 * s, 48 * s), width: 5 * s, height: 7 * s), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(56 * s, 48 * s), width: 5 * s, height: 7 * s), eyePaint);

    if (isActive) {
      canvas.drawCircle(Offset(45 * s, 47 * s), 1.0 * s, shinePaint);
      canvas.drawCircle(Offset(57 * s, 47 * s), 1.0 * s, shinePaint);

      // Tiny Wand Spark (cx=74, cy=26, r=3.5)
      final sparkPaint = Paint()..color = const Color(0xFFFFFBEB);
      canvas.drawCircle(Offset(74 * s, 26 * s), 3.5 * s, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StudioStarPainter oldDelegate) => oldDelegate.isActive != isActive;
}

// ── 4. Hub Chip Painter (Exact SVG from preview_custom_icons.html) ────────────
class _HubChipPainter extends CustomPainter {
  final bool isActive;
  _HubChipPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;

    final bodyPaint = Paint()
      ..color = isActive ? Colors.white : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    // Chip Pins / Legs
    final pinPaint = Paint()
      ..color = isActive ? Colors.white.withOpacity(0.9) : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(44 * s, 16 * s, 4 * s, 10 * s), Radius.circular(2 * s)), pinPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(52 * s, 16 * s, 4 * s, 10 * s), Radius.circular(2 * s)), pinPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(44 * s, 74 * s, 4 * s, 10 * s), Radius.circular(2 * s)), pinPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(52 * s, 74 * s, 4 * s, 10 * s), Radius.circular(2 * s)), pinPaint);

    // Neural Microchip Puffy Box (x=26, y=26, w=48, h=48, rx=16)
    final chipRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(26 * s, 26 * s, 48 * s, 48 * s),
      Radius.circular(16 * s),
    );
    canvas.drawRRect(chipRRect, bodyPaint);

    if (isActive) {
      // Blushes
      final blushPaint = Paint()..color = const Color(0xFF67E8F9).withOpacity(0.45);
      canvas.drawCircle(Offset(38 * s, 54 * s), 4 * s, blushPaint);
      canvas.drawCircle(Offset(62 * s, 54 * s), 4 * s, blushPaint);
    }

    // Eyes
    final eyePaint = Paint()..color = isActive ? const Color(0xFF18181B) : const Color(0xFF0D0E15);
    final shinePaint = Paint()..color = Colors.white;

    canvas.drawOval(Rect.fromCenter(center: Offset(43 * s, 48 * s), width: 6 * s, height: 8 * s), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(57 * s, 48 * s), width: 6 * s, height: 8 * s), eyePaint);

    if (isActive) {
      canvas.drawCircle(Offset(44 * s, 46 * s), 1.2 * s, shinePaint);
      canvas.drawCircle(Offset(58 * s, 46 * s), 1.2 * s, shinePaint);

      // Smile
      final smilePaint = Paint()
        ..color = const Color(0xFF18181B)
        ..strokeWidth = 1.3 * s
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final smilePath = Path()
        ..moveTo(48 * s, 53 * s)
        ..quadraticBezierTo(50 * s, 56 * s, 52 * s, 53 * s);
      canvas.drawPath(smilePath, smilePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HubChipPainter oldDelegate) => oldDelegate.isActive != isActive;
}
