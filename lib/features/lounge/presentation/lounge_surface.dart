import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../momo_ui/theme/momo_theme.dart';
import '../../../momo_ui/mascot/momo_master_vector.dart';
import '../../../momo_ui/cards/momo_glass_card.dart';
import '../../shell/navigation_controller.dart';

/// Lounge surface — the companion's main living room.
class LoungeSurface extends StatelessWidget {
  const LoungeSurface({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Babymomo',
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Living AI Companion',
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
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: MomoColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: MomoColors.primary.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 14, color: MomoColors.primary),
                          SizedBox(width: 6),
                          Text('Offline Core',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: MomoColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: const MomoMasterVector(size: 200, isWinking: false)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                      begin: -6,
                      end: 6,
                      duration: 2400.ms,
                      curve: Curves.easeInOut),
            ),
            const SizedBox(height: 20),
            Center(
              child: Obx(() {
                final active = controller.activeModel.value;
                return Text(
                  active != null
                      ? 'Ready to think with ${active.name.split('(').first.trim()} ✨'
                      : 'I\'m ready to create with you 💜',
                  style: Theme.of(context).textTheme.titleLarge,
                );
              }),
            ),
            const Spacer(),
            Text('Quick Prompts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MomoGlassCard(
                    onTap: () => controller.changeTab(1),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: MomoColors.amber, size: 20),
                        SizedBox(height: 8),
                        Text('Deep Think',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Brainstorm & chat',
                            style: TextStyle(
                                fontSize: 12,
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
                            color: MomoColors.rose, size: 20),
                        SizedBox(height: 8),
                        Text('Diffuse Art',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Generate images',
                            style: TextStyle(
                                fontSize: 12,
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
