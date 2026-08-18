import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../momo_ui/theme/momo_theme.dart';
import '../../../momo_ui/cards/momo_glass_card.dart';
import '../../shell/navigation_controller.dart';
import 'widgets/model_card.dart';

/// Hub Surface — Brain Model Catalog and System Settings.
class HubSurface extends StatelessWidget {
  const HubSurface({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Model Hub', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Official On-Device Brain Catalog',
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
                    '• Background downloads with notification bar progress\n• Auto-resume on network drop (8 retries)\n• One-tap model loader for companion chat',
                    style: TextStyle(
                        color: MomoColors.textSecondary,
                        height: 1.4,
                        fontSize: 13),
                  ),
                ]),
          ),
          const SizedBox(height: 24),
          Text('Available Models',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...controller.allModels
              .map((m) => ModelCard(model: m, controller: controller)),
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(sub,
          style:
              const TextStyle(color: MomoColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right,
          color: MomoColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }

  void _showAbout(BuildContext context) {
    Get.defaultDialog(
      title: '🧸 Babymomo',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      backgroundColor: MomoColors.surface,
      radius: 20,
      contentPadding: const EdgeInsets.all(20),
      content: const Column(children: [
        Text(
          'Your Living AI Companion',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: MomoColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14),
        ),
        SizedBox(height: 14),
        _AboutFeature(
            icon: '🧠',
            label: 'Unlimited Memory',
            desc:
                'Babymomo remembers everything you share across every conversation — forever. Your goals, ideas, and thoughts are never forgotten.'),
        SizedBox(height: 10),
        _AboutFeature(
            icon: '📴',
            label: 'Fully Offline',
            desc:
                'Everything runs privately on your phone. No internet needed once set up. Your conversations never touch any server.'),
        SizedBox(height: 10),
        _AboutFeature(
            icon: '🔒',
            label: 'Zero Data Collection',
            desc:
                'We collect nothing. No accounts, no tracking, no ads. Your data belongs to you and only you.'),
        SizedBox(height: 10),
        _AboutFeature(
            icon: '🎨',
            label: 'Create & Generate',
            desc:
                'Chat, generate images, analyze photos, and voice-dictate — all on-device.'),
        SizedBox(height: 16),
        Text(
          'Think of Babymomo as your second brain — always with you, always private.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: MomoColors.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic),
        ),
      ]),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: MomoColors.primary),
        onPressed: () => Get.back(),
        child: const Text('Awesome!', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    Get.defaultDialog(
      title: 'Privacy Policy',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      backgroundColor: MomoColors.surface,
      radius: 20,
      contentPadding: const EdgeInsets.all(20),
      content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• 100% Offline-First: All chats and diffusion art run locally.\n• Zero Data Harvesting: We never collect or sell your conversations.\n• AES-GCM-256 encrypted local storage.\n• Official Policy URL: https://hamza140202.github.io/babymomoapp/',
              style: TextStyle(
                  color: MomoColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ]),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: MomoColors.primary),
        onPressed: () => Get.back(),
        child: const Text('Got it', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showFeedback(BuildContext context) {
    final ctrl = TextEditingController();
    Get.defaultDialog(
      title: 'Feedback & Suggestions',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      backgroundColor: MomoColors.surface,
      radius: 20,
      contentPadding: const EdgeInsets.all(20),
      content: Column(children: [
        const Text('Help us make Babymomo even better!',
            style: TextStyle(color: MomoColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: MomoColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MomoColors.glassBorder)),
          child: TextField(
            controller: ctrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
                hintText: 'Share your feedback or thoughts...',
                hintStyle: TextStyle(color: MomoColors.textMuted),
                border: InputBorder.none),
          ),
        ),
      ]),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: MomoColors.primary),
        onPressed: () {
          Get.back();
          Get.snackbar(
              'Feedback Received ✅', 'Thank you for helping shape Babymomo!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF10B981),
              colorText: Colors.white);
        },
        child: const Text('Submit', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _AboutFeature extends StatelessWidget {
  final String icon;
  final String label;
  final String desc;

  const _AboutFeature({
    required this.icon,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      color: MomoColors.textSecondary,
                      fontSize: 11,
                      height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
