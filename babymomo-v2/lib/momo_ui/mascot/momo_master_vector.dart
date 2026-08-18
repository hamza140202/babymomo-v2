import 'dart:math';
import 'package:flutter/material.dart';

class MomoMasterVector extends StatelessWidget {
  final double size;
  final bool isWinking;

  const MomoMasterVector({
    super.key,
    this.size = 180,
    this.isWinking = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _MomoMasterSvgPainter(isWinking: isWinking),
      ),
    );
  }
}

class _MomoMasterSvgPainter extends CustomPainter {
  final bool isWinking;

  _MomoMasterSvgPainter({this.isWinking = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;

    // 1. Bottom Soft Shadow
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

    // 2. Mascot Drop Shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFFB91C1C).withOpacity(0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * s);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(256 * s, 285 * s),
        width: 284 * s,
        height: 260 * s,
      ),
      shadowPaint,
    );

    // 3. Cute Ears
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

    // 4. Main Character Body (Crisp, High-Contrast White Mochi)
    final bodyRect = Rect.fromCenter(center: Offset(256 * s, 280 * s), width: 280 * s, height: 258 * s);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFFFF5F5), Color(0xFFFED7AA)],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFFE4E6)
      ..strokeWidth = 2 * s
      ..style = PaintingStyle.stroke;
    canvas.drawOval(bodyRect, borderPaint);

    // 5. Rosy Cheeks
    final blushPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFF4D6D).withOpacity(0.65), const Color(0xFFFF4D6D).withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: Offset(175 * s, 305 * s), radius: 28 * s));
    canvas.drawCircle(Offset(175 * s, 305 * s), 28 * s, blushPaint);

    final blushPaintR = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFF4D6D).withOpacity(0.65), const Color(0xFFFF4D6D).withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: Offset(337 * s, 305 * s), radius: 28 * s));
    canvas.drawCircle(Offset(337 * s, 305 * s), 28 * s, blushPaintR);

    // 6. Big Kawaii Shiny Eyes
    final eyePaint = Paint()..color = const Color(0xFF18181B);
    final whitePaint = Paint()..color = Colors.white;
    final transWhitePaint = Paint()..color = Colors.white.withOpacity(0.85);

    // Left Eye
    canvas.drawOval(Rect.fromCenter(center: Offset(205 * s, 265 * s), width: 40 * s, height: 54 * s), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(213 * s, 253 * s), width: 16 * s, height: 22 * s), whitePaint);
    canvas.drawCircle(Offset(199 * s, 277 * s), 4.5 * s, whitePaint);
    canvas.drawCircle(Offset(218 * s, 275 * s), 2.5 * s, transWhitePaint);

    // Right Eye (Open vs Wink Arc)
    if (!isWinking) {
      canvas.drawOval(Rect.fromCenter(center: Offset(307 * s, 265 * s), width: 40 * s, height: 54 * s), eyePaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(315 * s, 253 * s), width: 16 * s, height: 22 * s), whitePaint);
      canvas.drawCircle(Offset(301 * s, 277 * s), 4.5 * s, whitePaint);
      canvas.drawCircle(Offset(320 * s, 275 * s), 2.5 * s, transWhitePaint);
    } else {
      // Flirty Wink Arc
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

    // 7. Happy Smiling Mouth & Tongue
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

    // 8. Magical AI Sparkle Star (Top Right at cx=370, cy=144)
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
  bool shouldRepaint(covariant _MomoMasterSvgPainter oldDelegate) => oldDelegate.isWinking != isWinking;
}
