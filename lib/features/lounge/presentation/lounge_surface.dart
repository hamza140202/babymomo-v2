import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../momo_ui/theme/momo_theme.dart';
import '../../../momo_ui/mascot/momo_master_vector.dart';
import '../../../momo_ui/cards/momo_glass_card.dart';
import '../../shell/navigation_controller.dart';

/// Lounge surface — the living companion's interactive living room.
/// Features interactive mascot tap reactions, companion thought bubbles,
/// memory core metrics, and quick action cards.
class LoungeSurface extends StatefulWidget {
  const LoungeSurface({super.key});

  @override
  State<LoungeSurface> createState() => _LoungeSurfaceState();
}

class _LoungeSurfaceState extends State<LoungeSurface> {
  bool _isWinking = false;
  String _currentThought = "I'm ready to create with you 💜";
  final List<String> _thoughts = [
    "I'm ready to create with you 💜",
    "✨ You're doing amazing today!",
    "🧠 All my memory engines are running privately on your device!",
    "🎨 Tap Studio to synthesize 8k UHD artwork with me!",
    "💬 Ask me anything in Chat — I'm your offline second brain!",
    "🧸 *boop!* Hehe, that tickles!",
    "🌟 Ready for deep brainstorming or creative writing!",
  ];

  void _interactWithMomo() {
    final rand = Random();
    setState(() {
      _isWinking = true;
      _currentThought = _thoughts[rand.nextInt(_thoughts.length)];
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _isWinking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Babymomo',
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 2),
                    Text('Living AI Companion • Second Brain',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Obx(() => Icon(
                            controller.isDarkMode.value
                                ? Icons.wb_sunny_outlined
                                : Icons.nightlight_round_outlined,
                            color: MomoColors.amber,
                          )),
                      onPressed: controller.toggleTheme,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 13, color: Color(0xFF10B981)),
                          SizedBox(width: 5),
                          Text('100% Private',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Interactive Mascot Character ──
            Center(
              child: GestureDetector(
                onTap: _interactWithMomo,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient warm glow aura
                    Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MomoColors.primary.withOpacity(0.25),
                            blurRadius: 55,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: MomoColors.rose.withOpacity(0.2),
                            blurRadius: 35,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    MomoMasterVector(
                      size: 210,
                      isWinking: _isWinking,
                      showBackground: false,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                            begin: -6,
                            end: 6,
                            duration: 2600.ms,
                            curve: Curves.easeInOut),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Companion Thought / Status Bubble ──
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_currentThought),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: MomoColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: MomoColors.glassBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _currentThought,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Active Brain Status Card ──
            MomoGlassCard(
              borderColor: MomoColors.primary.withOpacity(0.35),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: MomoColors.primary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: MomoColors.primary.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.psychology_outlined,
                        color: MomoColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          final active = controller.activeModel.value;
                          return Text(
                            active != null
                                ? active.name.split('(').first.trim()
                                : 'Momo Core Engine',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          );
                        }),
                        const SizedBox(height: 2),
                        const Text(
                          'Local Memory Core • Unlimited Cross-Session Retention',
                          style: TextStyle(
                              fontSize: 10, color: MomoColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.changeTab(3),
                    style: TextButton.styleFrom(
                      foregroundColor: MomoColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Hub ⚡',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick Action Tiles ──
            Text('Quick Launch', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MomoGlassCard(
                    onTap: () => controller.changeTab(1),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: MomoColors.primary, size: 22),
                        SizedBox(height: 8),
                        Text('Deep Think',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 4),
                        Text('Brainstorm & talk',
                            style: TextStyle(
                                fontSize: 11,
                                color: MomoColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MomoGlassCard(
                    onTap: () => controller.changeTab(2),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.palette_outlined,
                            color: MomoColors.rose, size: 22),
                        SizedBox(height: 8),
                        Text('Diffuse Art',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 4),
                        Text('Flux UHD studio',
                            style: TextStyle(
                                fontSize: 11,
                                color: MomoColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
