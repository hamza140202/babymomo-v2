import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../momo_ui/theme/momo_colors.dart';
import '../../../momo_ui/theme/momo_typography.dart';
import 'splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MomoColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Background Cinematic Tycoon Glow ───
          Container(
            decoration: const BoxDecoration(
              gradient: MomoColors.surfaceGradient,
            ),
          ),
          
          // Soft radial neon gradients in background
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MomoColors.primary.withValues(alpha: 0.12),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.15, 1.15),
                  duration: 4000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MomoColors.accent.withValues(alpha: 0.12),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                  duration: 3500.ms,
                  curve: Curves.easeInOut,
                ),
          ),

          // ─── Floating Tycoon Gold Coins & Sparkles ───
          ...List.generate(6, (index) {
            final double startX = (index * 60) + 30;
            final double delayMs = index * 300.0;
            return Positioned(
              bottom: 120,
              left: startX,
              child: const Icon(
                Icons.monetization_on_rounded,
                color: MomoColors.warning,
                size: 16,
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(delay: delayMs.ms, duration: 600.ms)
                  .slideY(
                    begin: 1.0,
                    end: -6.0,
                    delay: delayMs.ms,
                    duration: 2500.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeOut(delay: (delayMs + 1800).ms, duration: 600.ms),
            );
          }),

          // ─── Central Animated Mascot & Text ───
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Perfect Squircle Mascot Container (Textless mascot occupies 80%)
                Container(
                  width: 146,
                  height: 146,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: MomoColors.primary.withValues(alpha: 0.4),
                        blurRadius: 35,
                        spreadRadius: 4,
                      ),
                    ],
                    border: Border.all(
                      color: MomoColors.primaryLight,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.06, 1.06),
                      duration: 1500.ms,
                      curve: Curves.easeInOut,
                    ),

                const SizedBox(height: 32),

                // Bubble-style "BabyMomo" logo text with purple/pink warm gradient
                ShaderMask(
                  shaderCallback: (bounds) => MomoColors.warmGradient.createShader(bounds),
                  child: Text(
                    'BabyMomo',
                    style: MomoTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.2, delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Always by your side 🌟',
                  style: MomoTypography.bodySmall.copyWith(
                    color: MomoColors.textSecondary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms),
              ],
            ),
          ),

          // ─── Real-time Progress Diagnostics Loader (Bottom) ───
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Obx(() {
              final progress = controller.initProgress.value;
              final text = controller.statusText.value;

              return Column(
                children: [
                  // Progress Loading bar
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MomoColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        width: MediaQuery.of(context).size.width * 0.8 * progress,
                        decoration: BoxDecoration(
                          gradient: MomoColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: MomoColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress details status text
                  Text(
                    text,
                    style: MomoTypography.bodySmall.copyWith(
                      color: MomoColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }),
          ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
        ],
      ),
    );
  }
}
