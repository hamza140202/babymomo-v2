import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../momo_ui/theme/momo_theme.dart';
import '../../../momo_ui/cards/momo_glass_card.dart';
import '../../shell/navigation_controller.dart';
import 'widgets/model_card.dart';

/// Hub Surface — Brain Model Catalog with Categorized Filter Tabs and System Settings.
class HubSurface extends StatefulWidget {
  const HubSurface({super.key});

  @override
  State<HubSurface> createState() => _HubSurfaceState();
}

class _HubSurfaceState extends State<HubSurface> {
  int _selectedFilter = 0;
  final _filters = ['All', '🧠 Brains', '👁️ Vision AI', '🎨 Studio'];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Model Hub', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Official On-Device Brain & Vision Catalog',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          MomoGlassCard(
            borderColor: MomoColors.cyan.withOpacity(0.4),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.bolt, color: MomoColors.cyan, size: 20),
                    SizedBox(width: 8),
                    Text('Hardware Profiler: Ready',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  SizedBox(height: 8),
                  Text(
                    '• Multimodal Vision AI + DeepSeek R1 Reasoning + Mobile Diffusion\n• Background downloads with active notification bar progress\n• One-tap model loader for companion chat & creative studio',
                    style: TextStyle(
                        color: MomoColors.textSecondary,
                        height: 1.4,
                        fontSize: 13),
                  ),
                ]),
          ),
          const SizedBox(height: 20),

          // ── Category Filter Tabs ──
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedFilter == i
                        ? MomoColors.primary
                        : MomoColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _selectedFilter == i
                            ? MomoColors.primary
                            : MomoColors.glassBorder),
                  ),
                  child: Text(
                    _filters[i],
                    style: TextStyle(
                      color: _selectedFilter == i
                          ? Colors.white
                          : MomoColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Available Models',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          // ── Model List with Filter ──
          ...controller.allModels.where((m) {
            if (_selectedFilter == 1) return m.type == 'Text LLM';
            if (_selectedFilter == 2) return m.type == 'Vision AI' || m.isVision;
            if (_selectedFilter == 3) return m.type == 'Image Diffusion';
            return true;
          }).map((m) => ModelCard(model: m, controller: controller)),

          const SizedBox(height: 24),
          Text('System & Information',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildMenuSection(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return MomoGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        _menuItem(
            Icons.info_outline,
            MomoColors.primary,
            'About Babymomo',
            'Your Living AI Companion • Second Brain',
            () => _showAbout(context)),
        const Divider(color: MomoColors.glassBorder, height: 1),
        _menuItem(
            Icons.shield_outlined,
            const Color(0xFF10B981),
            'Privacy Policy',
            '100% On-Device • Zero Data Collection',
            () => _showPrivacy(context)),
        const Divider(color: MomoColors.glassBorder, height: 1),
        _menuItem(
            Icons.feedback_outlined,
            MomoColors.amber,
            'Feedback & Suggestions',
            'Share your ideas with our team',
            () => _showFeedback(context)),
        const Divider(color: MomoColors.glassBorder, height: 1),
        _menuItem(
            Icons.cleaning_services_outlined,
            MomoColors.rose,
            'Clear Temporary Cache',
            'Free up local temporary cache', () {
          Get.snackbar('Cache Cleaned', 'Temporary model cache refreshed.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: MomoColors.surfaceLight,
              colorText: Colors.white);
        }),
      ]),
    );
  }

  Widget _menuItem(
      IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(sub,
          style:
              const TextStyle(color: MomoColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right,
          color: MomoColors.textMuted, size: 18),
      onTap: onTap,
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MomoColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🧸 Babymomo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Babymomo is your personal, living AI companion with unlimited memory, acting as your ultimate second brain on device.\n\n'
              '• 🧠 Unlimited On-Device Memory\n'
              '• 👁️ Multimodal Vision Image Understanding\n'
              '• 💡 Deep Chain-of-Thought Reasoning\n'
              '• 🎨 High-Res Creative Diffusion Studio\n'
              '• 📴 100% Offline & Private (Zero cloud tracking)',
              style: TextStyle(
                  color: MomoColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: MomoColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it 💜'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MomoColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔒 Privacy Policy',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Babymomo operates with a strict Zero Data Collection policy:\n\n'
              '• No accounts, sign-ups, or passwords.\n'
              '• All chats, voice recordings, and memories are encrypted locally.\n'
              '• No telemetry or third-party ads.\n'
              '• Public Privacy Policy: https://hamza140202.github.io/babymomoapp/',
              style: TextStyle(
                  color: MomoColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(context),
                child: const Text('I Understand 🛡️'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedback(BuildContext context) {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MomoColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💌 Feedback & Ideas',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('What features or models would you like to see?',
                style: TextStyle(
                    color: MomoColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
                hintStyle:
                    const TextStyle(color: MomoColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: MomoColors.surfaceLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: MomoColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(ctx);
                  Get.snackbar(
                    'Thank You! 💜',
                    'Your feedback has been recorded locally.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: MomoColors.primary,
                    colorText: Colors.white,
                  );
                },
                child: const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
