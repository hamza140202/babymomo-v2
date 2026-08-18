import 'dart:math';
import 'package:flutter/material.dart';

/// Momo Master Vector Widget — renders the pixel-perfect master SVG mascot icon.
/// Matches `assets/branding/babymomo_master_icon.svg` and `preview_wink_splash.html` exactly
/// with squircle gradient background, ambient glow rings, drop shadow, organic porcelain mochi body,
/// rosy cheeks, big sparkling kawaii eyes, and magic AI sparkle star.
class MomoMasterVector extends StatelessWidget {
  final double size;
  final bool isWinking;
  final bool showBackground;

  const MomoMasterVector({
    super.key,
    this.size = 180,
    this.isWinking = false,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _MomoMasterSvgPainter(
          isWinking: isWinking,
          showBackground: showBackground,
        ),
      ),
    );
  }
}

class _MomoMasterSvgPainter extends CustomPainter {
  final bool isWinking;
  final bool showBackground;

  _MomoMasterSvgPainter({
    this.isWinking = false,
    this.showBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;

    // ── 1. Squircle Background & Glow (when showBackground == true) ──
    if (showBackground) {
      final bgRect = Rect.fromLTWH(0, 0, 512 * s, 512 * s);
      final bgRRect = RRect.fromRectAndRadius(bgRect, Radius.circular(118 * s));

      // Background Coral-Peach Sunset Gradient (#FF6B8B -> #FF8E53 -> #FFAE33)
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B8B),
            Color(0xFFFF8E53),
            Color(0xFFFFAE33),
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(bgRect);
      canvas.drawRRect(bgRRect, bgPaint);

      // Inner White Border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * s;
      final innerRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(2 * s, 2 * s, 508 * s, 508 * s),
        Radius.circular(116 * s),
      );
      canvas.drawRRect(innerRRect, borderPaint);

      // Ambient Glow Rings on Background for Depth
      final glow1 = Paint()..color = Colors.white.withOpacity(0.12);
      final glow2 = Paint()..color = Colors.white.withOpacity(0.08);
      canvas.drawCircle(Offset(256 * s, 270 * s), 175 * s, glow1);
      canvas.drawCircle(Offset(256 * s, 270 * s), 145 * s, glow2);

      // Bottom Soft Shadow inside squircle
      final botShadowPaint = Paint()
        ..color = const Color(0xFFC2410C).withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(256 * s, 425 * s),
          width: 270 * s,
          height: 48 * s,
        ),
        botShadowPaint,
      );
    } else {
      // Free-standing bottom shadow
      final floorShadow = Paint()
        ..color = const Color(0xFF000000).withOpacity(0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * s);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(256 * s, 430 * s),
          width: 280 * s,
          height: 50 * s,
        ),
        floorShadow,
      );
    }

    // ── 2. Mascot Drop Shadow ──
    final shadowPaint = Paint()
      ..color = const Color(0xFFB91C1C).withOpacity(0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * s);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(256 * s, 290 * s),
        width: 290 * s,
        height: 265 * s,
      ),
      shadowPaint,
    );

    // ── 3. Cute Ears ──
    // Left Ear
    canvas.save();
    canvas.translate(178 * s, 162 * s);
    canvas.rotate(-18 * pi / 180);
    final earOuterPaint = Paint()..color = Colors.white;
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 76 * s, height: 100 * s), earOuterPaint);
    final earInnerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFDA4AF), Color(0xFFF43F5E)],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: 46 * s, height: 68 * s));
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 46 * s, height: 68 * s), earInnerPaint);
    canvas.restore();

    // Right Ear
    canvas.save();
    canvas.translate(334 * s, 162 * s);
    canvas.rotate(18 * pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 76 * s, height: 100 * s), earOuterPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 46 * s, height: 68 * s), earInnerPaint);
    canvas.restore();

    // ── 4. Main Character Body (Crisp Organic Porcelain Mochi) ──
    final bodyPath = Path()
      ..moveTo(256 * s, 148 * s)
      ..cubicTo(362 * s, 148 * s, 396 * s, 208 * s, 396 * s, 295 * s)
      ..cubicTo(396 * s, 385 * s, 348 * s, 406 * s, 256 * s, 406 * s)
      ..cubicTo(164 * s, 406 * s, 116 * s, 385 * s, 116 * s, 295 * s)
      ..cubicTo(116 * s, 208 * s, 150 * s, 148 * s, 256 * s, 148 * s)
      ..close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFFFFFFFF), Color(0xFFFFF5F5), Color(0xFFFED7AA)],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(116 * s, 148 * s, 280 * s, 258 * s));
    canvas.drawPath(bodyPath, bodyPaint);

    final mochiBorderPaint = Paint()
      ..color = const Color(0xFFFFE4E6)
      ..strokeWidth = 2 * s
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bodyPath, mochiBorderPaint);

    // ── 5. Rosy Cheeks ──
    final blushPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFF4D6D).withOpacity(0.6), const Color(0xFFFF4D6D).withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: Offset(175 * s, 305 * s), radius: 28 * s));
    canvas.drawCircle(Offset(175 * s, 305 * s), 28 * s, blushPaint);

    final blushPaintR = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFF4D6D).withOpacity(0.6), const Color(0xFFFF4D6D).withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: Offset(337 * s, 305 * s), radius: 28 * s));
    canvas.drawCircle(Offset(337 * s, 305 * s), 28 * s, blushPaintR);

    // ── 6. Big Kawaii Shiny Eyes ──
    final eyePaint = Paint()..color = const Color(0xFF18181B);
    final whitePaint = Paint()..color = Colors.white;
    final transWhitePaint = Paint()..color = Colors.white.withOpacity(0.8);

    // Left Eye (Always Open, Big & Sparkly)
    canvas.drawOval(Rect.fromCenter(center: Offset(205 * s, 265 * s), width: 40 * s, height: 54 * s), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(213 * s, 253 * s), width: 16 * s, height: 22 * s), whitePaint);
    canvas.drawCircle(Offset(199 * s, 277 * s), 4.5 * s, whitePaint);
    canvas.drawCircle(Offset(218 * s, 275 * s), 2.5 * s, transWhitePaint);

    // Right Eye (Open vs Flirty Wink Arc)
    if (!isWinking) {
      canvas.drawOval(Rect.fromCenter(center: Offset(307 * s, 265 * s), width: 40 * s, height: 54 * s), eyePaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(315 * s, 253 * s), width: 16 * s, height: 22 * s), whitePaint);
      canvas.drawCircle(Offset(301 * s, 277 * s), 4.5 * s, whitePaint);
      canvas.drawCircle(Offset(320 * s, 275 * s), 2.5 * s, transWhitePaint);
    } else {
      final winkPaint = Paint()
        ..color = const Color(0xFF18181B)
        ..strokeWidth = 6.0 * s
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final winkPath = Path()
        ..moveTo(288 * s, 266 * s)
        ..quadraticBezierTo(307 * s, 252 * s, 326 * s, 266 * s);
      canvas.drawPath(winkPath, winkPaint);

      // Cute eyelash flick
      final lashPaint = Paint()
        ..color = const Color(0xFF18181B)
        ..strokeWidth = 4.5 * s
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(324 * s, 263 * s), Offset(332 * s, 258 * s), lashPaint);
    }

    // ── 7. Happy Smiling Mouth & Cute Tongue ──
    final mouthPaint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 5.0 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final mouthPath = Path()
      ..moveTo(242 * s, 290 * s)
      ..quadraticBezierTo(256 * s, 306 * s, 270 * s, 290 * s);
    canvas.drawPath(mouthPath, mouthPaint);

    final tonguePaint = Paint()..color = const Color(0xFFFB7185);
    final tonguePath = Path()
      ..moveTo(249 * s, 297 * s)
      ..quadraticBezierTo(256 * s, 308 * s, 263 * s, 297 * s)
      ..close();
    canvas.drawPath(tonguePath, tonguePaint);

    // ── 8. Magical AI Sparkle Star (Floating Top Right at cx=370, cy=144) ──
    final starPaint = Paint()..color = const Color(0xFFFFFBEB);
    final starPath = Path()
      ..moveTo(370 * s, 120 * s)
      ..quadraticBezierTo(376 * s, 138 * s, 394 * s, 144 * s)
      ..quadraticBezierTo(376 * s, 150 * s, 370 * s, 168 * s)
      ..quadraticBezierTo(364 * s, 150 * s, 346 * s, 144 * s)
      ..quadraticBezierTo(364 * s, 138 * s, 370 * s, 120 * s)
      ..close();
    canvas.drawPath(starPath, starPaint);
    canvas.drawCircle(Offset(370 * s, 144 * s), 5 * s, whitePaint);
  }

  @override
  bool shouldRepaint(covariant _MomoMasterSvgPainter oldDelegate) =>
      oldDelegate.isWinking != isWinking || oldDelegate.showBackground != showBackground;
}
