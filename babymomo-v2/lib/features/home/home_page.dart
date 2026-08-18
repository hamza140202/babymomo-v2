import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../momo_ui/theme/momo_colors.dart';
import '../../momo_ui/theme/momo_typography.dart';
import '../chat/chat_page.dart';
import '../image_gen/presentation/image_gen_page.dart';
import '../model_hub/presentation/model_hub_page.dart';
import '../settings/presentation/settings_page.dart';
import 'home_controller.dart';

/// BabyMomo — Home Page (Main Application Shell).
///
/// Houses the main application tabs under an IndexedStack to preserve state.
/// Employs a stunning, floating glassmorphic bottom navigation system
/// with BackdropFilter blur and scale hover micro-animations.
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Tabs matching HomeController indices
    final List<Widget> tabs = [
      _buildHomeTab(context),
      const ChatPage(isTab: true),
      const ImageGenPage(isTab: true),
      const ModelHubPage(isTab: true),
      const SettingsPage(isTab: true),
    ];

    return Scaffold(
      backgroundColor: MomoColors.background,
      extendBody: true, // Crucial for floating bottom navigation blur overlay
      body: Container(
        decoration: const BoxDecoration(
          gradient: MomoColors.surfaceGradient,
        ),
        child: SafeArea(
          bottom: false, // Let IndexedStack bleed under bottom navigation
          child: Obx(() {
            return IndexedStack(
              index: controller.currentIndex.value,
              children: tabs,
            );
          }),
        ),
      ),
      bottomNavigationBar: _buildGlassmorphicNavBar(),
    );
  }

  /// ─── Tab 0: Home Welcome Dashboard ───
  Widget _buildHomeTab(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              // Aligned Mascot Logo Image Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: MomoColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ).animate().scale(
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BabyMomo',
                    style: MomoTypography.displayMedium.copyWith(
                      color: MomoColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    'Always by your side 🌟',
                    style: MomoTypography.bodySmall.copyWith(
                      color: MomoColors.textMuted,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideX(
                    begin: -0.1,
                    duration: 400.ms,
                  ),
              const Spacer(),
              // Quick jump to settings icon
              IconButton(
                onPressed: () => controller.changePage(4),
                icon: const Icon(
                  Icons.tune_rounded,
                  color: MomoColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Main Dashboard Body
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100), // Avoid overlap with nav bar
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Expressive animated gradient orb — visual focal point
                  GestureDetector(
                    onTap: () {
                      Get.snackbar(
                        "✨ Hey!",
                        "Momo's neural sparks are tingling!",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: MomoColors.primary.withValues(alpha: 0.85),
                        colorText: MomoColors.textPrimary,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: Hero(
                      tag: 'momo_mascot',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              MomoColors.primaryLight.withValues(alpha: 0.9),
                              MomoColors.primary.withValues(alpha: 0.6),
                              MomoColors.accent.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.35, 0.65, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: MomoColors.primary.withValues(alpha: 0.4),
                              blurRadius: 50,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1.1, 1.1),
                        duration: 2200.ms,
                        curve: Curves.easeInOut,
                      )
                      .shimmer(
                        duration: 3000.ms,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),

                  const SizedBox(height: 36),

                  Text(
                    'What shall we create today? ✨',
                    style: MomoTypography.displayLarge.copyWith(
                      color: MomoColors.textPrimary,
                      fontSize: 26,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                  const SizedBox(height: 6),

                  Text(
                    'Your offline AI is warmed up and ready to go.',
                    style: MomoTypography.bodyMedium.copyWith(
                      color: MomoColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 600.ms),

                  const SizedBox(height: 42),

                  // High-fidelity Dashboard Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Chat Arena',
                                desc: 'Conversations that think',
                                gradient: MomoColors.primaryGradient,
                                onTap: () => controller.changePage(1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.brush_outlined,
                                label: 'Create Studio',
                                desc: 'Imagine anything, locally',
                                gradient: MomoColors.warmGradient,
                                onTap: () => controller.changePage(2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.psychology_outlined,
                                label: 'Brain Hub',
                                desc: 'Swap & tune AI brains',
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF64B5F6),
                                    Color(0xFF0D47A1),
                                  ],
                                ),
                                onTap: () => controller.changePage(3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.tune_rounded,
                                label: 'Settings',
                                desc: 'Under the hood',
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFB2DD),
                                    Color(0xFFC94F7C),
                                  ],
                                ),
                                onTap: () => controller.changePage(4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(
                        begin: 0.15,
                        delay: 500.ms,
                        duration: 600.ms,
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ─── Premium Glassmorphic Bottom Navigation Bar ───
  Widget _buildGlassmorphicNavBar() {
    final navItems = [
      {"icon": Icons.home_rounded, "label": "Dashboard"},
      {"icon": Icons.chat_bubble_rounded, "label": "Chat"},
      {"icon": Icons.palette_rounded, "label": "Create"},
      {"icon": Icons.psychology_rounded, "label": "Brains"},
      {"icon": Icons.settings_suggest_rounded, "label": "Settings"},
    ];

    return Obx(() {
      final selectedIdx = controller.currentIndex.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: MomoColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: MomoColors.primary.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(navItems.length, (idx) {
                    final item = navItems[idx];
                    final isSelected = selectedIdx == idx;
                    final icon = item['icon'] as IconData;
                    final label = item['label'] as String;

                    return GestureDetector(
                      onTap: () => controller.changePage(idx),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon with bounce animation when selected
                            Icon(
                              icon,
                              color: isSelected
                                  ? MomoColors.primaryLight
                                  : MomoColors.textMuted,
                              size: isSelected ? 26 : 22,
                            )
                                .animate(target: isSelected ? 1 : 0)
                                .scale(
                                  begin: const Offset(1.0, 1.0),
                                  end: const Offset(1.15, 1.15),
                                  duration: 300.ms,
                                  curve: Curves.elasticOut,
                                )
                                .custom(
                                  duration: 300.ms,
                                  builder: (context, val, child) {
                                    return Transform.translate(
                                      offset: Offset(0, -val * 2),
                                      child: child,
                                    );
                                  },
                                ),
                            const SizedBox(height: 4),
                            // Text Label
                            Text(
                              label,
                              style: MomoTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? MomoColors.textPrimary
                                    : MomoColors.textMuted,
                                fontSize: 9,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Quick action card widget — premium, tactile tycoon feel.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: MomoColors.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: MomoColors.surfaceLight.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floating icon with rounded colorful frame
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: MomoTypography.labelMedium.copyWith(
                color: MomoColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: MomoTypography.bodySmall.copyWith(
                color: MomoColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
