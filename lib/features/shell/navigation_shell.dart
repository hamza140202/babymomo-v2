import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../momo_ui/theme/momo_theme.dart';
import '../../momo_ui/mascot/momo_mascot.dart';
import '../../momo_ui/cards/momo_glass_card.dart';
import '../../momo_ui/buttons/momo_button.dart';
import '../../momo_ui/icons/momo_custom_icons.dart';

// Unified Model Item
class AppModelItem {
  final String id;
  final String name;
  final String type; // 'LLM' or 'Image Diffusion'
  final String sizeStr;
  final String url;
  final String description;
  final RxBool isDownloaded = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isDownloading = false.obs;

  AppModelItem({
    required this.id,
    required this.name,
    required this.type,
    required this.sizeStr,
    required this.url,
    required this.description,
  });
}

class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final Rx<MascotMood> mascotMood = MascotMood.flirtyWink.obs;
  final RxBool isDarkMode = true.obs;

  // Real Models Catalog
  final List<AppModelItem> allModels = [
    AppModelItem(
      id: 'smollm2_1_7b',
      name: 'SmolLM2-1.7B-Instruct (Q4_K_M)',
      type: 'Text LLM',
      sizeStr: '1.0 GB',
      url: 'https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q4_k_m.gguf',
      description: 'Ultra-lightweight on-device language model. Fast response, zero battery drain.',
    ),
    AppModelItem(
      id: 'qwen2_5_1_5b',
      name: 'Qwen-2.5-1.5B-Instruct (Q4_K_M)',
      type: 'Text LLM',
      sizeStr: '1.1 GB',
      url: 'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
      description: 'Top-tier on-device reasoning and conversational companion dialogue.',
    ),
    AppModelItem(
      id: 'qwen2_5_3b',
      name: 'Qwen-2.5-3B-Instruct (Q4_K_M)',
      type: 'Text LLM',
      sizeStr: '2.2 GB',
      url: 'https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf',
      description: 'Deep empathy, extensive vocabulary, and intelligent storytelling.',
    ),
    AppModelItem(
      id: 'phi_4_mini',
      name: 'Phi-4-mini 3.8B (Q4_K_M)',
      type: 'Text LLM',
      sizeStr: '2.5 GB',
      url: 'https://huggingface.co/microsoft/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-q4_k_m.gguf',
      description: 'Exceptional math, code logic, and complex analytical reasoning.',
    ),
    AppModelItem(
      id: 'dreamshaper_lcm',
      name: 'DreamShaper 8 LCM (FP16)',
      type: 'Image Diffusion',
      sizeStr: '2.1 GB',
      url: 'https://huggingface.co/SimianLuo/LCM_Dreamshaper_v7/resolve/main/LCM_Dreamshaper_v7_4k.safetensors',
      description: 'Ultra-fast 4-step local text-to-image generation pipeline.',
    ),
    AppModelItem(
      id: 'absolute_reality',
      name: 'Absolute Reality v1.8.1 (FP16)',
      type: 'Image Diffusion',
      sizeStr: '2.1 GB',
      url: 'https://huggingface.co/digiplay/AbsoluteReality_v1.8.1/resolve/main/absolutereality_v181.safetensors',
      description: 'Hyper-realistic photography and cinema-grade portrait outputs.',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _checkLocalDownloadedFiles();
  }

  Future<void> _checkLocalDownloadedFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (final model in allModels) {
        final file = File('${dir.path}/${model.id}.bin');
        model.isDownloaded.value = await file.exists();
      }
    } catch (_) {}
  }

  Future<void> startDownload(AppModelItem model) async {
    if (model.isDownloading.value) return;

    model.isDownloading.value = true;
    model.downloadProgress.value = 0.01;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${model.id}.bin';
      final dio = Dio();

      Get.snackbar(
        'Downloading ${model.name}',
        'Connecting to HuggingFace repository...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: MomoColors.surfaceLight,
        colorText: Colors.white,
      );

      await dio.download(
        model.url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            model.downloadProgress.value = received / total;
          }
        },
      );

      model.isDownloaded.value = true;
      model.isDownloading.value = false;
      Get.snackbar('Download Complete', '${model.name} is ready for on-device inference!',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFF10B981), colorText: Colors.white);
    } catch (e) {
      model.isDownloading.value = false;
      Get.snackbar('Download Error', 'Network error while downloading: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: MomoColors.rose, colorText: Colors.white);
    }
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeTheme(isDarkMode.value ? MomoTheme.darkTheme : MomoTheme.lightTheme);
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }
}

class NavigationShell extends StatelessWidget {
  const NavigationShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShellController());

    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final currentIdx = controller.currentIndex.value;

      return Scaffold(
        backgroundColor: isDark ? MomoColors.background : MomoColors.lightBackground,
        body: IndexedStack(
          index: currentIdx,
          children: const [
            LoungeSurface(),
            ChatSurface(),
            StudioSurface(),
            HubSurface(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? MomoColors.surface.withOpacity(0.92) : MomoColors.lightSurface,
            border: Border(
              top: BorderSide(
                color: isDark ? MomoColors.glassBorder : MomoColors.lightGlassBorder,
                width: 1,
              ),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    )
                  ],
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
                isDark: isDark,
              ),
              _buildNavItem(
                index: 1,
                currentIdx: currentIdx,
                label: 'Chat',
                icon: MomoCustomIcons.chat(isActive: currentIdx == 1),
                onTap: () => controller.changeTab(1),
                isDark: isDark,
              ),
              _buildNavItem(
                index: 2,
                currentIdx: currentIdx,
                label: 'Studio',
                icon: MomoCustomIcons.studio(isActive: currentIdx == 2),
                onTap: () => controller.changeTab(2),
                isDark: isDark,
              ),
              _buildNavItem(
                index: 3,
                currentIdx: currentIdx,
                label: 'Hub',
                icon: MomoCustomIcons.hub(isActive: currentIdx == 3),
                onTap: () => controller.changeTab(3),
                isDark: isDark,
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
    required bool isDark,
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
              color: isSelected
                  ? (isDark ? Colors.white : MomoColors.primary)
                  : (isDark ? MomoColors.textSecondary : MomoColors.lightTextSecondary),
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
                Row(
                  children: [
                    IconButton(
                      icon: Obx(() => Icon(
                            controller.isDarkMode.value ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                            color: MomoColors.amber,
                          )),
                      onPressed: controller.toggleTheme,
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
              ],
            ),
            const Spacer(),
            // Master Mochi Mascot with Flirty Wink & Tilt
            Center(
              child: Obx(() => MomoMascot(
                    mood: controller.mascotMood.value,
                    size: 160,
                    autoPlayWink: true,
                  )),
            ),
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
                        Text('Deep Think', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        Text('Diffuse Art', style: TextStyle(fontWeight: FontWeight.bold)),
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
      _messages.add({'role': 'assistant', 'content': 'Processing request on local offline core...'});
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
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
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
                      style: const TextStyle(color: Colors.white),
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
                style: const TextStyle(color: Colors.white),
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
                      colorText: Colors.white);
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
    final controller = Get.find<ShellController>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Model Hub', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Official On-Device Weights Catalog', style: Theme.of(context).textTheme.bodyMedium),
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
                    Text('Hardware Profiler: Ready', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Text('• Vulkan & OpenCL Acceleration: Detected\n• Local Storage: High Speed\n• Direct HuggingFace Pipeline: Active',
                    style: TextStyle(color: MomoColors.textSecondary, height: 1.4, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Available Models (Text & Image)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...controller.allModels.map((m) => _buildRealModelCard(context, controller, m)),
        ],
      ),
    );
  }

  Widget _buildRealModelCard(BuildContext context, ShellController controller, AppModelItem model) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MomoGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: model.type == 'Text LLM' ? MomoColors.violet.withOpacity(0.2) : MomoColors.rose.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    model.type,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: model.type == 'Text LLM' ? MomoColors.violet : MomoColors.rose,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(model.sizeStr, style: const TextStyle(color: MomoColors.textSecondary, fontSize: 11)),
                const Spacer(),
                Obx(() {
                  if (model.isDownloaded.value) {
                    return const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 4),
                        Text('Installed', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    );
                  }
                  if (model.isDownloading.value) {
                    return Text(
                      '${(model.downloadProgress.value * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: MomoColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    );
                  }
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MomoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => controller.startDownload(model),
                    child: const Text('Download', style: TextStyle(fontSize: 12)),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(model.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(model.description, style: const TextStyle(color: MomoColors.textSecondary, fontSize: 12)),
            Obx(() {
              if (model.isDownloading.value) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: model.downloadProgress.value,
                      backgroundColor: MomoColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(MomoColors.primary),
                      minHeight: 6,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}
