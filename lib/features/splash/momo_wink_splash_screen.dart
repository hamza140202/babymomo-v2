import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../shell/navigation_shell.dart';
import '../../momo_ui/mascot/momo_master_vector.dart';

/// Momo Wink Splash Screen — 4.2-second smooth opening sequence.
/// Gives clear visual pacing for the head tilt (12 deg) and flirty wink greeting
/// while the app initializes memory engines, storage, and models.
class MomoWinkSplashScreen extends StatefulWidget {
  const MomoWinkSplashScreen({super.key});

  @override
  State<MomoWinkSplashScreen> createState() => _MomoWinkSplashScreenState();
}

class _MomoWinkSplashScreenState extends State<MomoWinkSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tiltAnimation;
  late Animation<double> _winkAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    // 1. Entrance scale & settle (0 - 4.2s)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.6, end: 1.06)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.06), weight: 55),
      TweenSequenceItem(
          tween: Tween(begin: 1.06, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
    ]).animate(_controller);

    // 2. Sweet Head Tilt to the right (12 degrees = 0.21 rad)
    _tiltAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 0.21)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 25),
      TweenSequenceItem(tween: ConstantTween(0.21), weight: 55),
      TweenSequenceItem(
          tween: Tween(begin: 0.21, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
    ]).animate(_controller);

    // 3. Flirty Wink timing: opens -> blinks wink -> holds wink for clear visibility -> opens
    _winkAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    ]).animate(_controller);

    _controller.forward();

    // After animation finishes in ~4.2s, transition smoothly to NavigationShell
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Get.off(
          () => const NavigationShell(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ambient Background Glow Aura
          Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF6B8B).withOpacity(0.45),
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 0.8],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.9, end: 1.25, duration: 2800.ms, curve: Curves.easeInOut),

          // 2. Animated Head-Tilt & Flirty Wink Mascot
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _tiltAnimation.value,
                        child: MomoMasterVector(
                          size: 200,
                          isWinking: _winkAnimation.value > 0.5,
                          showBackground: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                // Brand Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFFF8E53), Color(0xFFFFAE33)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'Babymomo',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 700.ms),
                const SizedBox(height: 6),
                const Text(
                  'Living AI Companion',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 700.ms),
                const SizedBox(height: 18),
                // Initialization / Indexing pill indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF8E53),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Indexing memory & brain models...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFCBD5E1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
