import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../features/shell/navigation_shell.dart';
import 'momo_ui/mascot/momo_master_vector.dart';

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
      duration: const Duration(milliseconds: 2400),
    );

    // Entrance scale & settle
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.05).chain(CurveTween(curve: Curves.easeOutBack)), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.05), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 25),
    ]).animate(_controller);

    // Sweet Head Tilt to the right (12 degrees = 0.21 rad)
    _tiltAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.21).chain(CurveTween(curve: Curves.easeOutBack)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(0.21), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.21, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 25),
    ]).animate(_controller);

    // Flirty Wink timing: opens -> blinks wink -> holds -> opens
    _winkAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 25),
    ]).animate(_controller);

    _controller.forward();

    // After animation finishes in ~2.5s, transition smoothly to NavigationShell
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Get.off(
          () => const NavigationShell(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 400),
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
          // 1. Ambient Background Glow Aura (as in preview_wink_splash.html)
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF6B8B).withOpacity(0.4),
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 0.75],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.9, end: 1.2, duration: 2500.ms, curve: Curves.easeInOut),

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
                          size: 190,
                          isWinking: _winkAnimation.value > 0.5,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Brand Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'Babymomo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                const SizedBox(height: 6),
                const Text(
                  'Living AI Companion',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
