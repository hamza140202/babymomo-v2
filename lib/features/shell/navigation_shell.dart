import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../momo_ui/theme/momo_theme.dart';
import '../../momo_ui/mascot/momo_mascot.dart';
import '../../momo_ui/cards/momo_glass_card.dart';
import '../../momo_ui/buttons/momo_button.dart';
import '../../momo_ui/icons/momo_custom_icons.dart';

class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final Rx<MascotMood> mascotMood = MascotMood.flirtyWink.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }
}

class NavigationShell extends StatelessWidget {
  const NavigationShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShellController());

    return Scaffold(
      body: Obx(() {
        return IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            LoungeSurface(),
            ChatSurface(),
            StudioSurface(),
            HubSurface(),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final currentIdx = controller.currentIndex.value;

        return Container(
          decoration: BoxDecoration(
            color: MomoColors.surface.withOpacity(0.92),
            border: const Border(
              top: BorderSide(color: MomoColors.glassBorder, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                currentIdx: currentIdx,
                label: 'Lounge',
                icon: MomoCustomIcons.lounge(isActive: currentIdx == 0),
                onTap: () => controller.changeTab(0),
              ),
              _buildNavItem(
                index: 1,
                currentIdx: currentIdx,
                label: 'Chat',
                icon: MomoCustomIcons.chat(isActive: currentIdx == 1),
                onTap: () => controller.changeTab(1),
              ),
              _buildNavItem(
                index: 2,
                currentIdx: currentIdx,
                label: 'Studio',
                icon: MomoCustomIcons.studio(isActive: currentIdx == 2),
                onTap: () => controller.changeTab(2),
              ),
              _buildNavItem(
                index: 3,
                currentIdx: currentIdx,
                label: 'Hub',
                icon: MomoCustomIcons.hub(isActive: currentIdx == 3),
                onTap: () => controller.changeTab(3),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIdx,
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIdx;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : MomoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// 1. Companion Lounge Surface
class LoungeSurface extends StatelessWidget {
  const LoungeSurface({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShellController>();

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
                    Text('Babymomo', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Living AI Companion', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MomoColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: MomoColors.primary.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: MomoColors.primary),
                      SizedBox(width: 6),
                      Text('Offline Core', style: TextStyle(fontSize: 12, color: MomoColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Obx(() => MomoMascot(mood: controller.mascotMood.value, size: 150, autoPlayWink: true)),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'I\'m ready to create with you.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                        Icon(Icons.auto_awesome, color: MomoColors.amber, size: 20),
                        SizedBox(height: 8),
                        Text('Deep Think', style: TextStyle(fontWeight: FontWeight.bold, color: MomoColors.textPrimary)),
                        SizedBox(height: 4),
                        Text('Brainstorm & chat', style: TextStyle(fontSize: 12, color: MomoColors.textSecondary)),
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
                        Icon(Icons.palette_outlined, color: MomoColors.rose, size: 20),
                        SizedBox(height: 8),
                        Text('Diffuse Art', style: TextStyle(fontWeight: FontWeight.bold, color: MomoColors.textPrimary)),
                        SizedBox(height: 4),
                        Text('Generate images', style: TextStyle(fontSize: 12, color: MomoColors.textSecondary)),
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

// 2. Chat Surface
class ChatSurface extends StatefulWidget {
  const ChatSurface({super.key});

  @override
  State<ChatSurface> createState() => _ChatSurfaceState();
}

class _ChatSurfaceState extends State<ChatSurface> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': 'Hello! I am Babymomo. Your private, on-device AI companion. How can I assist your creative workflow today?'}
  ];

  void _send() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': _textController.text.trim()});
      _messages.add({'role': 'assistant', 'content': 'Running local inference on mounted GGUF core... (Hardware profile: Optimal)'});
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chat', style: Theme.of(context).textTheme.displayMedium),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: MomoColors.textSecondary),
                  onPressed: () => setState(() => _messages.clear()),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? MomoColors.primary : MomoColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MomoColors.glassBorder),
                    ),
                    child: Text(
                      msg['content']!,
                      style: const TextStyle(color: MomoColors.textPrimary, fontSize: 14, height: 1.4),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: MomoColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: MomoColors.glassBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: MomoColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything...',
                        hintStyle: TextStyle(color: MomoColors.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.arrow_upward),
                  style: IconButton.styleFrom(backgroundColor: MomoColors.primary),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 3. Creative Studio Surface
class StudioSurface extends StatefulWidget {
  const StudioSurface({super.key});

  @override
  State<StudioSurface> createState() => _StudioSurfaceState();
}

class _StudioSurfaceState extends State<StudioSurface> {
  final TextEditingController _promptController = TextEditingController();
  int _selectedPreset = 0;
  final List<String> _presets = ['Cinematic 3D', 'Anime Glow', 'Photoreal', 'Cyberpunk', 'Watercolor'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Creative Studio', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text('Stable Diffusion on-device generation', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            MomoGlassCard(
              child: TextField(
                controller: _promptController,
                maxLines: 3,
                style: const TextStyle(color: MomoColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Describe your vision in detail...',
                  hintStyle: TextStyle(color: MomoColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Style Presets', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedPreset == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPreset = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? MomoColors.rose : MomoColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: MomoColors.glassBorder),
                      ),
                      child: Center(
                        child: Text(
                          _presets[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : MomoColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: MomoButton(
                label: 'Generate Artwork (LCM 4-Step)',
                icon: Icons.auto_awesome,
                color: MomoColors.rose,
                onPressed: () {
                  Get.snackbar('Studio', 'Initiating NDK Stable Diffusion pipeline...',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: MomoColors.surfaceLight,
                      colorText: MomoColors.textPrimary);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. Model Hub & Diagnostics
class HubSurface extends StatelessWidget {
  const HubSurface({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Model Hub', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Local Weights & Hardware Diagnostics', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          MomoGlassCard(
            borderColor: MomoColors.cyan.withOpacity(0.4),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: MomoColors.cyan, size: 20),
                    SizedBox(width: 8),
                    Text('Hardware Profile: Tier High', style: TextStyle(fontWeight: FontWeight.bold, color: MomoColors.textPrimary)),
                  ],
                ),
                SizedBox(height: 8),
                Text('Vulkan Compute: Supported\nAvailable RAM: 8.4 GB / 12 GB\nThermal State: Nominal',
                    style: TextStyle(color: MomoColors.textSecondary, height: 1.4, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Installed Models', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildModelItem(context, 'Llama-3.2-1B-Instruct-Q4_K_M', '1.1 GB', true),
          const SizedBox(height: 12),
          _buildModelItem(context, 'Stable-Diffusion-v1.5-LCM-FP16', '1.8 GB', true),
          const SizedBox(height: 12),
          _buildModelItem(context, 'Qwen-2.5-3B-Instruct-Q4_K_M', '2.2 GB', false),
        ],
      ),
    );
  }

  Widget _buildModelItem(BuildContext context, String name, String size, bool isDownloaded) {
    return MomoGlassCard(
      child: Row(
        children: [
          Icon(isDownloaded ? Icons.check_circle : Icons.cloud_download_outlined,
              color: isDownloaded ? const Color(0xFF10B981) : MomoColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: MomoColors.textPrimary, fontSize: 13)),
                const SizedBox(height: 2),
                Text(size, style: const TextStyle(color: MomoColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (!isDownloaded)
            TextButton(
              onPressed: () {
                Get.snackbar('Download Engine', 'Starting background chunked download...',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: MomoColors.surfaceLight,
                    colorText: MomoColors.textPrimary);
              },
              child: const Text('Download', style: TextStyle(color: MomoColors.primary)),
            )
          else
            const Text('Mounted', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
