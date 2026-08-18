import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum MascotMood { idle, thinking, listening, generating, joyful, flirtyWink }

class MomoMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  final bool autoPlayWink;

  const MomoMascot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 140,
    this.autoPlayWink = false,
  });

  @override
  State<MomoMascot> createState() => _MomoMascotState();
}

class _MomoMascotState extends State<MomoMascot> with SingleTickerProviderStateMixin {
  late AnimationController _winkController;
  late Animation<double> _tiltAnimation;
  late Animation<double> _winkEyeAnimation;

  @override
  void initState() {
    super.initState();
    _winkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _tiltAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.22).chain(CurveTween(curve: Curves.easeOutBack)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(0.22), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.22, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
    ]).animate(_winkController);

    _winkEyeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
    ]).animate(_winkController);

    if (widget.autoPlayWink || widget.mood == MascotMood.flirtyWink) {
      _winkController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant MomoMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood == MascotMood.flirtyWink && oldWidget.mood != MascotMood.flirtyWink) {
      _winkController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _winkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _winkController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _tiltAnimation.value,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient Reactive Aura
                Container(
                  width: widget.size * 1.35,
                  height: widget.size * 1.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B8B).withOpacity(0.35),
                        blurRadius: 45,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.25),
                        blurRadius: 35,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scaleXY(begin: 0.95, end: 1.15, duration: 2400.ms, curve: Curves.easeInOut),

                // Character Head / Mochi Body
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFFFF1F2),
                        Color(0xFFFED7AA),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB91C1C).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFE4E6),
                      width: 2.0,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Blushes
                      Positioned(
                        left: widget.size * 0.14,
                        top: widget.size * 0.52,
                        child: _buildBlush(),
                      ),
                      Positioned(
                        right: widget.size * 0.14,
                        top: widget.size * 0.52,
                        child: _buildBlush(),
                      ),

                      // Eyes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLeftEye(),
                          SizedBox(width: widget.size * 0.22),
                          _buildRightEye(),
                        ],
                      ),

                      // Smile Mouth
                      Positioned(
                        bottom: widget.size * 0.26,
                        child: _buildMouth(),
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .moveY(begin: -4, end: 5, duration: 2200.ms, curve: Curves.easeInOut),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlush() {
    return Container(
      width: widget.size * 0.18,
      height: widget.size * 0.18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFF4D6D).withOpacity(0.45),
      ),
    );
  }

  Widget _buildLeftEye() {
    return Container(
      width: widget.size * 0.12,
      height: widget.size * 0.18,
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 5,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 3,
            left: 2,
            child: Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightEye() {
    double scale = _winkEyeAnimation.value;
    if (scale < 0.15) {
      return CustomPaint(
        size: Size(widget.size * 0.14, widget.size * 0.1),
        painter: WinkArcPainter(),
      );
    }
    return Transform.scale(
      scaleY: scale,
      child: _buildLeftEye(),
    );
  }

  Widget _buildMouth() {
    return CustomPaint(
      size: const Size(18, 10),
      painter: SmilePainter(),
    );
  }
}

class WinkArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width, size.height * 0.7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width * 0.5, size.height, size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
