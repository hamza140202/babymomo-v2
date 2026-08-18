import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/momo_theme.dart';

enum MascotMood { idle, thinking, listening, generating, joyful }

class MomoMascot extends StatelessWidget {
  final MascotMood mood;
  final double size;

  const MomoMascot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 130,
  });

  @override
  Widget build(BuildContext context) {
    Color glowColor = switch (mood) {
      MascotMood.idle => MomoColors.primary,
      MascotMood.thinking => MomoColors.cyan,
      MascotMood.listening => MomoColors.amber,
      MascotMood.generating => MomoColors.rose,
      MascotMood.joyful => const Color(0xFF10B981),
    };

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Reactive Aura
          Container(
            width: size * 1.3,
            height: size * 1.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.35),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.9, end: 1.15, duration: 2500.ms, curve: Curves.easeInOut),

          // Main Companion Body
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MomoColors.surfaceLight,
                  MomoColors.surface,
                  glowColor.withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: glowColor.withOpacity(0.6),
                width: 2.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Mascot Eyes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildEye(glowColor),
                    const SizedBox(width: 24),
                    _buildEye(glowColor),
                  ],
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: -4, end: 6, duration: 2000.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }

  Widget _buildEye(Color color) {
    if (mood == MascotMood.joyful) {
      return Icon(Icons.favorite, size: 20, color: color);
    }
    return Container(
      width: 14,
      height: mood == MascotMood.thinking ? 6 : 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.8),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
