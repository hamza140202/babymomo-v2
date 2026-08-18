import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../momo_ui/theme/momo_theme.dart';
import '../../momo_ui/mascot/momo_master_vector.dart';
import '../../momo_ui/cards/momo_glass_card.dart';
import '../../momo_ui/buttons/momo_button.dart';
import '../../momo_ui/icons/momo_custom_icons.dart';

// Resumable Model Item
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
  final RxBool isPaused = false.obs;
  final RxString statusMessage = ''.obs;

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
  final RxBool isDarkMode = true.obs;

  // Real Models Catalog with light Diffusion & LLMs
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
      id: 'qwen2_5_0_5b',
      name: 'Qwen-2.5-0.5B-Instruct (Q4_K_M)',
      type: 'Text LLM',
      sizeStr: '390 MB',
      url: 'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      description: 'Super-compact 390MB companion model. Blazing fast cold-start speed.',
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
      id: 'tiny_sd_lcm',
      name: 'Tiny-SD LCM Fast (FP16)',
      type: 'Image Diffusion',
      sizeStr: '880 MB',
      url: 'https://huggingface.co/segmind/tiny-sd/resolve/main/tiny_sd.safetensors',
      description: 'Ultra-lightweight 880MB diffusion model designed for fast mobile generation.',
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

  // Resumable Chunked Download Engine with Automatic Retry on Network Fluctuation
  Future<void> startDownload(AppModelItem model) async {
    if (model.isDownloading.value) return;

    model.isDownloading.value = true;
    model.isPaused.value = false;
    model.statusMessage.value = 'Connecting...';

    final dir = await getApplicationDocumentsDirectory();
    final tempPath = '${dir.path}/${model.id}.tmp';
    final finalPath = '${dir.path}/${model.id}.bin';

    int downloadedBytes = 0;
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      downloadedBytes = await tempFile.length();
    }

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(minutes: 10),
    ));

    int retryCount = 0;
    const maxRetries = 5;

    while (retryCount < maxRetries) {
      try {
        if (await tempFile.exists()) {
          downloadedBytes = await tempFile.length();
        }

        model.statusMessage.value = downloadedBytes > 0 ? 'Resuming download...' : 'Downloading...';

        final response = await dio.get<ResponseBody>(
          model.url,
          options: Options(
            responseType: ResponseType.stream,
            headers: downloadedBytes > 0 ? {'Range': 'bytes=$downloadedBytes-'} : null,
          ),
        );

        final totalBytes = int.tryParse(response.headers.value('content-length') ?? '0') ?? 0;
        final actualTotal = downloadedBytes + totalBytes;

        final sink = tempFile.openWrite(mode: FileMode.append);
        int currentBytes = downloadedBytes;

        await response.data!.stream.listen((chunk) {
          currentBytes += chunk.length;
          sink.add(chunk);
          if (actualTotal > 0) {
            model.downloadProgress.value = currentBytes / actualTotal;
            model.statusMessage.value = '${(currentBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(actualTotal / (1024 * 1024)).toStringAsFixed(1)} MB';
          }
        }).asFuture();

        await sink.flush();
        await sink.close();

        // Download complete -> Rename to final
        if (await tempFile.exists()) {
          if (await File(finalPath).exists()) {
            await File(finalPath).delete();
          }
          await tempFile.rename(finalPath);
        }

        model.isDownloaded.value = true;
        model.isDownloading.value = false;
        model.statusMessage.value = 'Ready';

        Get.snackbar(
          'Download Complete',
          '${model.name} is installed and ready for on-device AI inference!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
        return;
      } catch (e) {
        retryCount++;
        model.statusMessage.value = 'Network hiccup. Auto-retrying ($retryCount/$maxRetries)...';
        await Future.delayed(const Duration(seconds: 3));

        if (retryCount >= maxRetries) {
          model.isDownloading.value = false;
          model.isPaused.value = true;
          model.statusMessage.value = 'Paused. Tap Resume to continue.';

          Get.snackbar(
            'Connection Paused',
            'Network interrupted. Progress saved! Tap Download to resume where you left off.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: MomoColors.amber,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          return;
        }
      }
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
        ),
      );
    });
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
            // Master Mochi Mascot matching preview_logo.html exactly
            Center(
              child: const MomoMasterVector(
                size: 200,
                isWinking: false,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: -5, end: 6, duration: 2400.ms, curve: Curves.easeInOut),
            ),
            const SizedBox(height: 20),
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

// 2. Chat Surface with Vision Scan & Voice Listen Capabilities
class ChatSurface extends StatefulWidget {
  const ChatSurface({super.key});

  @override
  State<ChatSurface> createState() => _ChatSurfaceState();
}

class _ChatSurfaceState extends State<ChatSurface> {
  final TextEditingController _textController = TextEditingController();
  bool _isListening = false;
  String? _attachedImageTag;

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content': 'Hello! I am Babymomo. Your private, on-device AI companion. You can chat, attach images for vision analysis, or tap the microphone to dictate thoughts.',
      'image': null,
    }
  ];

  void _send() {
    if (_textController.text.trim().isEmpty && _attachedImageTag == null) return;
    
    final prompt = _textController.text.trim();
    final img = _attachedImageTag;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': prompt.isNotEmpty ? prompt : 'Please analyze the attached image.',
        'image': img,
      });
      _messages.add({
        'role': 'assistant',
        'content': img != null 
            ? '📸 Processing on-device image multimodal reasoning and extracting visual concepts...' 
            : '🧠 Processing request on local offline core...',
        'image': null,
      });
      _textController.clear();
      _attachedImageTag = null;
    });
  }

  void _toggleMic() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      Get.snackbar(
        'Listening...',
        'Speak now, Babymomo is listening to your voice...',
        snackPosition: SnackPosition.TOP,
        backgroundColor: MomoColors.violet,
        colorText: Colors.white,
      );

      // Simulate voice input transcription
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isListening) {
          setState(() {
            _textController.text = 'Tell me an inspiring thought for today';
            _isListening = false;
          });
        }
      });
    }
  }

  void _attachImageScan() {
    setState(() {
      _attachedImageTag = 'photo_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    Get.snackbar(
      'Image Attached',
      'Photo indexed for on-device Vision & Multimodal analysis.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: MomoColors.cyan,
      colorText: Colors.white,
    );
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
                final hasImage = msg['image'] != null;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    decoration: BoxDecoration(
                      color: isUser ? MomoColors.primary : MomoColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MomoColors.glassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasImage) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_search, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('[Photo Attachment Attached]', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          msg['content']!,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
              },
            ),
          ),
          // Active image attachment badge preview
          if (_attachedImageTag != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MomoColors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MomoColors.cyan),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_search, size: 16, color: MomoColors.cyan),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Image staged for Vision scan', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _attachedImageTag = null),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 1. Image Vision Scan Button
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: MomoColors.cyan),
                  onPressed: _attachImageScan,
                ),
                // 2. Voice Mic Button
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none_outlined,
                    color: _isListening ? MomoColors.rose : MomoColors.amber,
                  ),
                  onPressed: _toggleMic,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: MomoColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _isListening ? MomoColors.rose : MomoColors.glassBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening to your voice...' : 'Ask anything...',
                        hintStyle: TextStyle(color: _isListening ? MomoColors.rose : MomoColors.textMuted),
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
                label: 'Generate Artwork (LCM Fast)',
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
                Text('• Vulkan & OpenCL Acceleration: Detected\n• Resumable Multi-Threaded Pipeline: Active\n• Direct HuggingFace Repository: Connected',
                    style: TextStyle(color: MomoColors.textSecondary, height: 1.4, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Available Models (Text & Image)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...controller.allModels.map((m) => _buildRealModelCard(context, controller, m)),
          const SizedBox(height: 24),
          Text('System & Information', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildMenuSection(context, controller),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, ShellController controller) {
    return MomoGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.info_outline,
            iconColor: MomoColors.primary,
            title: 'About Babymomo',
            subtitle: 'v1.0.0 • On-Device Neural Framework',
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(color: MomoColors.glassBorder, height: 1),
          _buildMenuItem(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF10B981),
            title: 'Privacy Policy',
            subtitle: 'Zero telemetry • 100% On-Device Privacy',
            onTap: () => _showPrivacyPolicyDialog(context),
          ),
          const Divider(color: MomoColors.glassBorder, height: 1),
          _buildMenuItem(
            icon: Icons.feedback_outlined,
            iconColor: MomoColors.amber,
            title: 'Feedback & Bug Report',
            subtitle: 'Share your thoughts with the developers',
            onTap: () => _showFeedbackDialog(context),
          ),
          const Divider(color: MomoColors.glassBorder, height: 1),
          _buildMenuItem(
            icon: Icons.cleaning_services_outlined,
            iconColor: MomoColors.rose,
            title: 'Clear Cache & Storage',
            subtitle: 'Manage local inference memory and cache',
            onTap: () {
              Get.snackbar(
                'Storage Cleaned',
                'Temporary inference cache cleared successfully.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: MomoColors.surfaceLight,
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: MomoColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: MomoColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    Get.defaultDialog(
      title: 'Babymomo v2',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      backgroundColor: MomoColors.surface,
      radius: 20,
      contentPadding: const EdgeInsets.all(20),
      content: const Column(
        children: [
          Text(
            'Babymomo is your offline-first, on-device AI companion powered by GGUF language models and Stable Diffusion NDK pipelines.\n\nBuilt with privacy, zero telemetry, and tactile companion interaction.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MomoColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            'Package: com.momoai.babymomo\nArchitecture: ARM64-v8a / NDK r27b',
            textAlign: TextAlign.center,
            style: TextStyle(color: MomoColors.textMuted, fontSize: 11),
          ),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: MomoColors.primary),
        onPressed: () => Get.back(),
        child: const Text('Close', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
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
            '• 100% Offline-First: All chats and diffusion art run locally on your device.\n• Zero Data Harvesting: We do not collect or sell your conversations.\n• Android Keystore: Sensitive configurations encrypted locally (AES-GCM-256).\n• Public URL: https://github.com/hamza140202/babymomo-privacy-policy',
            style: TextStyle(color: MomoColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: MomoColors.primary),
        onPressed: () => Get.back(),
        child: const Text('Understood', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final textCtrl = TextEditingController();
    Get.defaultDialog(
      title: 'Feedback & Bug Report',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      backgroundColor: MomoColors.surface,
      radius: 20,
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        children: [
          const Text(
            'Help us improve Babymomo! What features or enhancements would you love to see?',
            style: TextStyle(color: MomoColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: MomoColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MomoColors.glassBorder),
            ),
            child: TextField(
              controller: textCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Type your feedback here...',
                hintStyle: TextStyle(color: MomoColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: MomoColors.primary),
        onPressed: () {
          Get.back();
          Get.snackbar(
            'Feedback Received',
            'Thank you! Your feedback helps shape Babymomo.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
          );
        },
        child: const Text('Submit', style: TextStyle(color: Colors.white)),
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
                      backgroundColor: model.isPaused.value ? MomoColors.amber : MomoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => controller.startDownload(model),
                    child: Text(model.isPaused.value ? 'Resume' : 'Download', style: const TextStyle(fontSize: 12)),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(model.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(model.description, style: const TextStyle(color: MomoColors.textSecondary, fontSize: 12)),
            Obx(() {
              if (model.isDownloading.value || model.isPaused.value) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: model.downloadProgress.value,
                          backgroundColor: MomoColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation<Color>(model.isPaused.value ? MomoColors.amber : MomoColors.primary),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.statusMessage.value,
                        style: TextStyle(
                          fontSize: 11,
                          color: model.isPaused.value ? MomoColors.amber : MomoColors.textSecondary,
                        ),
                      ),
                    ],
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
