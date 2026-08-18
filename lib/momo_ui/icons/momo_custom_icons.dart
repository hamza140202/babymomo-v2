import 'package:flutter/material.dart';
import '../mascot/momo_master_vector.dart';

class MomoCustomIcons {
  // 1. Lounge: Mini Master Mochi Mascot Icon
  static Widget lounge({bool isActive = false, double size = 28}) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFFFF6B8B), Color(0xFFFFAE33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.white.withOpacity(0.06),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6B8B).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Center(
        child: MomoMasterVector(
          size: size * 0.85,
          isWinking: false,
          showBackground: false,
        ),
      ),
    );
  }

  // 2. Chat: 3D Mochi Speech Pillow
  static Widget chat({bool isActive = false, double size = 28}) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.white.withOpacity(0.06),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.8, size * 0.8),
          painter: _MochiChatPainter(isActive: isActive),
        ),
      ),
    );
  }

  // 3. Studio: 3D Mochi Magic Star
  static Widget studio({bool isActive = false, double size = 28}) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.white.withOpacity(0.06),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFF43F5E).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.8, size * 0.8),
          painter: _MochiStarPainter(isActive: isActive),
        ),
      ),
    );
  }

  // 4. Hub: 3D Mochi Neural Chip Companion
  static Widget hub({bool isActive = false, double size = 28}) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.white.withOpacity(0.06),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.8, size * 0.8),
          painter: _MochiChipPainter(isActive: isActive),
        ),
      ),
    );
  }
}

// Painters for crisp vector rendering matching master SVG
class _MochiMascotPainter extends CustomPainter {
  final bool isActive;
  _MochiMascotPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;

    // Ears
    final earPaint = Paint()..color = isActive ? Colors.white : const Color(0xFF94A3B8);
    final earInner = Paint()..color = const Color(0xFFFDA4AF);
    
    // Left Ear
    canvas.save();
    canvas.translate(178 * s, 162 * s);
    canvas.rotate(-18 * 3.14159 / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 76 * s, height: 100 * s), earPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 46 * s, height: 68 * s), earInner);
    canvas.restore();

    // Right Ear
    canvas.save();
    canvas.translate(334 * s, 162 * s);
    canvas.rotate(18 * 3.14159 / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 76 * s, height: 100 * s), earPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 46 * s, height: 68 * s), earInner);
    canvas.restore();

    // Body
    final bodyRect = Rect.fromCenter(center: Offset(256 * s, 280 * s), width: 280 * s, height: 258 * s);
    final bodyPaint = Paint()..color = isActive ? Colors.white : const Color(0xFF94A3B8);
    canvas.drawOval(bodyRect, bodyPaint);

    // Blushes
    final blushPaint = Paint()..color = const Color(0xFFFF4D6D).withOpacity(isActive ? 0.8 : 0.4);
    canvas.drawCircle(Offset(175 * s, 305 * s), 28 * s, blushPaint);
    canvas.drawCircle(Offset(337 * s, 305 * s), 28 * s, blushPaint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF18181B);
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawOval(Rect.fromCenter(center: Offset(205 * s, 265 * s), width: 40 * s, height: 54 * s), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(213 * s, 253 * s), width: 16 * s, height: 22 * s), whitePaint);

    canvas.drawOval(Rect.fromCenter(center: Offset(307 * s, 265 * s), width: 40 * s, height: 54 * s), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(315 * s, 253 * s), width: 16 * s, height: 22 * s), whitePaint);

    // Smile
    final mouthPaint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 6.0 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final mouthPath = Path()
      ..moveTo(242 * s, 290 * s)
      ..quadraticBezierTo(256 * s, 306 * s, 270 * s, 290 * s);
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MochiChatPainter extends CustomPainter {
  final bool isActive;
  _MochiChatPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = isActive ? Colors.white : const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    final eyePaint = Paint()
      ..color = isActive ? const Color(0xFF18181B) : const Color(0xFF0D0E15)
      ..style = PaintingStyle.fill;

    // Pillow Bubble
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.48), width: size.width * 0.8, height: size.height * 0.65),
        const Radius.circular(8),
      ),
      bodyPaint,
    );

    // Little tail
    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.7)
      ..lineTo(size.width * 0.15, size.height * 0.9)
      ..lineTo(size.width * 0.45, size.height * 0.78)
      ..close();
    canvas.drawPath(path, bodyPaint);

    // Eyes
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.4, size.height * 0.45), width: 3, height: 4.5), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.6, size.height * 0.45), width: 3, height: 4.5), eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MochiStarPainter extends CustomPainter {
  final bool isActive;
  _MochiStarPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = isActive ? Colors.white : const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    final eyePaint = Paint()
      ..color = isActive ? const Color(0xFF18181B) : const Color(0xFF0D0E15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.52, size.height * 0.48, size.width * 0.9, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.52, size.height * 0.52, size.width * 0.5, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.48, size.height * 0.52, size.width * 0.1, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.48, size.height * 0.48, size.width * 0.5, size.height * 0.1)
      ..close();

    canvas.drawPath(path, bodyPaint);

    // Eyes
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.44, size.height * 0.5), width: 2.5, height: 3.5), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.56, size.height * 0.5), width: 2.5, height: 3.5), eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MochiChipPainter extends CustomPainter {
  final bool isActive;
  _MochiChipPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = isActive ? Colors.white : const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    final eyePaint = Paint()
      ..color = isActive ? const Color(0xFF18181B) : const Color(0xFF0D0E15)
      ..style = PaintingStyle.fill;

    // Chip Box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.5), width: size.width * 0.65, height: size.height * 0.65),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Pins
    final pinPaint = Paint()
      ..color = isActive ? const Color(0xFF06B6D4) : const Color(0xFF64748B)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.1), Offset(size.width * 0.35, size.height * 0.18), pinPaint);
    canvas.drawLine(Offset(size.width * 0.65, size.height * 0.1), Offset(size.width * 0.65, size.height * 0.18), pinPaint);
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.82), Offset(size.width * 0.35, size.height * 0.9), pinPaint);
    canvas.drawLine(Offset(size.width * 0.65, size.height * 0.82), Offset(size.width * 0.65, size.height * 0.9), pinPaint);

    // Eyes
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.42, size.height * 0.48), width: 3, height: 4), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.58, size.height * 0.48), width: 3, height: 4), eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
