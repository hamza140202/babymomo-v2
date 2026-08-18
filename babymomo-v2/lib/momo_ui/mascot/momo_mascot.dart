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
    this.mood = MascotMood.flirtyWink,
    this.size = 180,
    this.autoPlayWink = true,
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
      duration: const Duration(milliseconds: 3000),
    );

    // Playful head-tilt sequence (tilts right 14 degrees, pauses flirty, returns)
    _tiltAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.24).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.24),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.24, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_winkController);

    // Eye wink sequence (wide open -> fast flirty blink close -> hold -> open sparkle)
    _winkEyeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 12),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 28),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 18),
    ]).animate(_winkController);

    // Auto-loop the playful wink periodically
    _winkController.forward();
    _winkController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            _winkController.forward(from: 0);
          }
        });
      }
    });
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
          child: SizedBox(
            width: widget.size * 1.3,
            height: widget.size * 1.25,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. Warm Glowing Sunset Ambient Aura (Matches App Gradient)
                Container(
                  width: widget.size * 1.15,
                  height: widget.size * 1.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0x66FF6B8B),
                        Color(0x33FF8E53),
                        Color(0x00FFAE33),
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.95, end: 1.1, duration: 2500.ms, curve: Curves.easeInOut),

                // 2. Soft Drop Shadow
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: widget.size * 0.75,
                    height: widget.size * 0.12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.elliptical(widget.size * 0.75, widget.size * 0.12)),
                      color: const Color(0xFFC2410C).withOpacity(0.2),
                    ),
                  ),
                ),

                // 3. Cute Mascot Left & Right Ears
                Positioned(
                  top: widget.size * 0.08,
                  left: widget.size * 0.22,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: _buildEar(),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.08,
                  right: widget.size * 0.22,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: _buildEar(),
                  ),
                ),

                // 4. Master Porcelain Mochi Mascot Body
                Container(
                  width: widget.size * 0.85,
                  height: widget.size * 0.75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(widget.size * 0.85, widget.size * 0.75)),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFFFF5F5),
                        Color(0xFFFED7AA),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB91C1C).withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
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
                      // Rosy Blushes
                      Positioned(
                        left: widget.size * 0.08,
                        top: widget.size * 0.42,
                        child: _buildBlush(),
                      ),
                      Positioned(
                        right: widget.size * 0.08,
                        top: widget.size * 0.42,
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

                      // Smiling Mouth & Tongue
                      Positioned(
                        bottom: widget.size * 0.18,
                        child: _buildMouth(),
                      ),
                    ],
                  ),
                ),

                // 5. Floating AI Sparkle Star (Top Right)
                Positioned(
                  top: widget.size * 0.06,
                  right: widget.size * 0.12,
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFFAE33),
                    size: 24,
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 0.85, end: 1.15, duration: 1800.ms)
                      .rotate(begin: -0.05, end: 0.05),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEar() {
    return Container(
      width: widget.size * 0.18,
      height: widget.size * 0.26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.elliptical(widget.size * 0.18, widget.size * 0.26)),
        border: Border.all(color: const Color(0xFFFFE4E6), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: widget.size * 0.11,
          height: widget.size * 0.18,
          decoration: BoxDecoration(
            color: const Color(0xFFFDA4AF),
            borderRadius: BorderRadius.all(Radius.elliptical(widget.size * 0.11, widget.size * 0.18)),
          ),
        ),
      ),
    );
  }

  Widget _buildBlush() {
    return Container(
      width: widget.size * 0.18,
      height: widget.size * 0.18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFF4D6D).withOpacity(0.65),
            const Color(0xFFFF4D6D).withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftEye() {
    return Container(
      width: widget.size * 0.11,
      height: widget.size * 0.16,
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: widget.size * 0.045,
              height: widget.size * 0.065,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            left: 2,
            child: Container(
              width: widget.size * 0.025,
              height: widget.size * 0.035,
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
    if (scale < 0.2) {
      return CustomPaint(
        size: Size(widget.size * 0.12, widget.size * 0.08),
        painter: WinkPainter(),
      );
    }
    return Transform.scale(
      scaleY: scale,
      child: _buildLeftEye(),
    );
  }

  Widget _buildMouth() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(22, 10),
          painter: MouthPainter(),
        ),
        Container(
          width: 8,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFFB7185),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}

class WinkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width, size.height * 0.6);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MouthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF18181B)
      ..strokeWidth = 3.2
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
