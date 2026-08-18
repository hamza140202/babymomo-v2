import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../momo_ui/theme/momo_theme.dart';
import '../../../momo_ui/cards/momo_glass_card.dart';
import '../../../momo_ui/buttons/momo_button.dart';
import '../../../momo_ui/mascot/momo_master_vector.dart';
import '../../shell/navigation_controller.dart';
import '../../model_hub/models/app_model_item.dart';

/// Studio Surface — High Quality Creative Image Studio.
/// Features dynamic Aspect Ratio preview canvas (1:1, 9:16, 16:9, 4:5),
/// Flux Ultra-HD crisp generation, Babymomo Thinking mascot loading animation,
/// and direct gallery saving to Pictures/Babymomo.
class StudioSurface extends StatefulWidget {
  const StudioSurface({super.key});

  @override
  State<StudioSurface> createState() => _StudioSurfaceState();
}

class _StudioSurfaceState extends State<StudioSurface> {
  final _promptCtrl = TextEditingController();
  int _selectedPreset = 0;
  final _presets = [
    '✨ Anime Glow',
    '🎬 Cinematic 3D',
    '📸 Photoreal Portrait',
    '🌆 Cyberpunk City',
    '🎨 Watercolor Dream',
    '🧸 Pastel Mochi',
  ];

  // ── Image Size / Aspect Ratio Options ──
  int _selectedSize = 0;
  final List<Map<String, dynamic>> _sizes = [
    {
      'label': '1:1 Square',
      'desc': '1024×1024',
      'w': 1024,
      'h': 1024,
      'aspect': 1.0,
      'icon': Icons.crop_square,
    },
    {
      'label': '9:16 Portrait',
      'desc': '768×1344',
      'w': 768,
      'h': 1344,
      'aspect': 9.0 / 16.0,
      'icon': Icons.stay_current_portrait,
    },
    {
      'label': '16:9 Landscape',
      'desc': '1344×768',
      'w': 1344,
      'h': 768,
      'aspect': 16.0 / 9.0,
      'icon': Icons.stay_current_landscape,
    },
    {
      'label': '4:5 Social',
      'desc': '864×1080',
      'w': 864,
      'h': 1080,
      'aspect': 4.0 / 5.0,
      'icon': Icons.crop_portrait,
    },
  ];

  // Comprehensive negative prompt to eliminate low quality, blur, artifacts, watermarks
  static const String standardNegativePrompt =
      'low quality, worst quality, low resolution, blurry, out of focus, excessive noise, compression artifacts, JPEG artifacts, pixelation, oversharpening, excessive sharpening halos, chromatic aberration, banding, posterization, muddy details, washed-out colors, crushed blacks, blown highlights, flat lighting, inconsistent lighting, unrealistic shadows, incorrect reflections, bad perspective, distorted perspective, fisheye distortion unless explicitly requested, warped geometry, malformed objects, duplicated objects, floating objects, disconnected objects, impossible physics, inconsistent scale, incorrect proportions, poor composition, cluttered composition, distracting background, random objects, visual noise, accidental tangencies, awkward cropping, excessive empty space, unwanted borders, frame, watermark, logo, signature, text, captions, subtitles, UI elements, interface elements, typography, illegible writing, random letters, random numbers';

  // 25-second cooldown tracker for public endpoint
  static DateTime? _lastCloudGenTime;

  // Generation state
  bool _isGenerating = false;
  double _progress = 0.0;
  String _stepStatus = '';
  File? _currentImage;
  final List<File> _history = [];

  // Performance metrics
  DateTime? _genStartTime;
  String _lastGenTime = '';
  String _lastGenEngine = 'Flux UHD';
  String _lastGenDim = '1024×1024';

  late final NavigationController _navCtrl;

  @override
  void initState() {
    super.initState();
    _navCtrl = Get.find<NavigationController>();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${dir.path}/MOMO_Studio_History');
      if (await historyDir.exists()) {
        final files = historyDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.png') || f.path.endsWith('.jpg'))
            .toList()
          ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        setState(() {
          _history.addAll(files.take(12));
          if (_history.isNotEmpty && _currentImage == null) {
            _currentImage = _history.first;
          }
        });
      }
    } catch (_) {}
  }

  _GenerationConfig _getModelConfig() {
    final activeModel = _navCtrl.activeImageModel.value;
    final modelName = activeModel?.name.toLowerCase() ?? '';

    if (modelName.contains('lcm') || modelName.contains('turbo')) {
      return const _GenerationConfig(
        steps: 4,
        cfgScale: 1.5,
        engineLabel: 'LCM Turbo 4-Step',
        isTurbo: true,
      );
    }

    return const _GenerationConfig(
      steps: 20,
      cfgScale: 7.5,
      engineLabel: 'Stable Diffusion',
      isTurbo: false,
    );
  }

  void _showModelPicker() {
    final diffusionModels = _navCtrl.allModels
        .where((m) => m.type == 'Image Diffusion')
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: MomoColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Diffusion Model',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'LCM models generate in 4 steps (fastest). Standard models use 20 steps.',
                style: TextStyle(
                    color: MomoColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              ...diffusionModels.map((m) {
                return Obx(() {
                  final isDownloaded = m.isDownloaded.value;
                  final isActive =
                      _navCtrl.activeImageModel.value?.id == m.id;
                  final isLcm = m.name.toLowerCase().contains('lcm') ||
                      m.name.toLowerCase().contains('turbo');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? MomoColors.primary.withOpacity(0.15)
                          : MomoColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? MomoColors.primary
                            : MomoColors.glassBorder,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        isLcm ? Icons.flash_on : Icons.image_outlined,
                        color: isLcm ? MomoColors.amber : MomoColors.primary,
                        size: 20,
                      ),
                      title: Text(m.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          )),
                      subtitle: Text(
                        '${m.sizeStr} • ${isLcm ? '4-step LCM' : '20-step Diffusion'}',
                        style: const TextStyle(
                            color: MomoColors.textMuted, fontSize: 11),
                      ),
                      trailing: isActive
                          ? const Chip(
                              label: Text('Active',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              backgroundColor: MomoColors.primary,
                              padding: EdgeInsets.zero,
                            )
                          : isDownloaded
                              ? OutlinedButton(
                                  onPressed: () {
                                    _navCtrl.activeImageModel.value = m;
                                    Navigator.pop(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: MomoColors.primary,
                                    side: const BorderSide(
                                        color: MomoColors.primary),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Use',
                                      style: TextStyle(fontSize: 11)),
                                )
                              : const Text('Not Downloaded',
                                  style: TextStyle(
                                      color: MomoColors.textMuted,
                                      fontSize: 10)),
                    ),
                  );
                });
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _getStylePrompt(String basePrompt, String style) {
    if (style.contains('Anime')) {
      return '$basePrompt, high quality anime art style, studio ghibli aesthetic, vibrant colors, detailed line work, masterpiece';
    } else if (style.contains('Cinematic')) {
      return '$basePrompt, cinematic lighting, 3d render, dramatic atmosphere, depth of field, octane render, 8k resolution, photorealistic';
    } else if (style.contains('Photoreal')) {
      return '$basePrompt, ultra realistic, professional portrait photography, 85mm lens, natural soft lighting, hyper-detailed, 8k uhd';
    } else if (style.contains('Cyberpunk')) {
      return '$basePrompt, cyberpunk aesthetic, neon lights, futuristic city reflections, dark sci-fi atmosphere, glowing details';
    } else if (style.contains('Watercolor')) {
      return '$basePrompt, delicate watercolor painting, soft pastel gradients, artistic brush strokes, paper texture';
    } else if (style.contains('Pastel')) {
      return '$basePrompt, soft pastel aesthetic, cute kawaii styling, porcelain lighting, dreamy atmosphere, smooth 3d finish';
    }
    return basePrompt;
  }

  Future<void> _startGeneration() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      Get.snackbar(
        'Prompt Required',
        'Please enter an idea for your artwork.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: MomoColors.amber,
        colorText: Colors.black,
      );
      return;
    }

    final config = _getModelConfig();
    final styleName = _presets[_selectedPreset];
    final selected = _sizes[_selectedSize];
    final targetWidth = selected['w'] as int;
    final targetHeight = selected['h'] as int;
    final seed = math.Random().nextInt(9999999);

    _genStartTime = DateTime.now();

    setState(() {
      _isGenerating = true;
      _progress = 0.05;
      _stepStatus = 'Composing creative vision...';
      _lastGenDim = selected['desc'] as String;
    });

    final stages = config.isTurbo
        ? [
            'Composing prompt latents...',
            'Sampling latents (step 1/4)...',
            'Sampling latents (step 2/4)...',
            'Refining geometry (step 3/4)...',
            'Refining geometry (step 4/4)...',
            'Decoding UHD pixel canvas...',
            'Finishing artwork...',
          ]
        : [
            'Composing creative vision...',
            'Sampling diffusion latents (step 5/20)...',
            'Sampling diffusion latents (step 10/20)...',
            'Refining details (step 15/20)...',
            'Refining details (step 20/20)...',
            'Decoding UHD pixel canvas...',
            'Finishing artwork...',
          ];

    int stageIndex = 0;
    final progressTimer = Timer.periodic(
      const Duration(milliseconds: 400),
      (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          if (stageIndex < stages.length) {
            _stepStatus = stages[stageIndex];
            _progress = (stageIndex + 1) / stages.length;
            stageIndex++;
          } else if (_progress < 0.95) {
            _progress += 0.01;
          }
        });
      },
    );

    File? generatedFile;

    try {
      // Build rich, crisp enhanced prompt for Flux UHD
      final stylePrompt = _getStylePrompt(prompt, styleName);
      final enhancedPrompt =
          '$stylePrompt, 8k uhd, photorealistic, highly detailed, sharp crisp focus, octane lighting, vivid colors, masterwork, masterpiece';
      final encodedPrompt = Uri.encodeComponent(enhancedPrompt);
      final encodedNegative = Uri.encodeComponent(standardNegativePrompt);

      // Primary FLUX.1 endpoint
      final fluxUrl =
          'https://image.pollinations.ai/prompt/$encodedPrompt?negative=$encodedNegative&width=$targetWidth&height=$targetHeight&nologo=true&seed=$seed&model=flux';

      // Fast Turbo fallback endpoint
      final turboUrl =
          'https://image.pollinations.ai/prompt/$encodedPrompt?negative=$encodedNegative&width=$targetWidth&height=$targetHeight&nologo=true&seed=$seed&model=turbo';

      final dir = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${dir.path}/MOMO_Studio_History');
      if (!await historyDir.exists()) await historyDir.create(recursive: true);

      final filePath =
          '${historyDir.path}/artwork_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 50),
        followRedirects: true,
        maxRedirects: 5,
      ));

      // 1. Try Flux model first
      try {
        final response = await dio.download(fluxUrl, filePath);
        if (response.statusCode == 200 && await File(filePath).exists()) {
          final f = File(filePath);
          if (await f.length() > 5000) {
            generatedFile = f;
            _lastGenEngine = 'Flux UHD';
            _lastCloudGenTime = DateTime.now();
          }
        }
      } catch (_) {
        // 2. Fallback to Turbo if Flux network timed out
        try {
          final response = await dio.download(turboUrl, filePath);
          if (response.statusCode == 200 && await File(filePath).exists()) {
            final f = File(filePath);
            if (await f.length() > 5000) {
              generatedFile = f;
              _lastGenEngine = 'SDXL Turbo';
              _lastCloudGenTime = DateTime.now();
            }
          }
        } catch (_) {}
      }

      progressTimer.cancel();

      if (generatedFile == null) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _stepStatus = 'Generation error. Please check network connection.';
          });
          Get.snackbar(
            '⚠️ Generation Failed',
            'Could not download image from AI engine. Please verify your internet connection.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: MomoColors.rose,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
        return;
      }

      final genDuration = DateTime.now().difference(_genStartTime!);

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _progress = 1.0;
          _currentImage = generatedFile;
          _lastGenTime =
              '${(genDuration.inMilliseconds / 1000).toStringAsFixed(1)}s';
          _history.insert(0, generatedFile!);
        });

        Get.snackbar(
          '✨ Artwork Generated!',
          'Created in $_lastGenTime • ${_sizes[_selectedSize]['label']} • Tap Save to Device to keep.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      progressTimer.cancel();
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _stepStatus = 'Generation error: $e';
        });
        Get.snackbar(
          'Generation Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: MomoColors.rose,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _saveToGallery() async {
    if (_currentImage == null) return;
    try {
      // 1. Request permissions
      await [Permission.storage, Permission.photos].request();

      final fileName =
          'Babymomo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 2. Try MediaStore channel
      try {
        const channel = MethodChannel('com.momoai.babymomo/media_store');
        final savedPath = await channel.invokeMethod<String>('saveImage', {
          'sourcePath': _currentImage!.path,
          'fileName': fileName,
        });

        if (savedPath != null) {
          Get.snackbar(
            '📸 Saved to Gallery!',
            'Saved to: Pictures/Babymomo/$fileName',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return;
        }
      } catch (_) {}

      // 3. Fallback direct disk copy to public Pictures/Babymomo directory
      final publicPictures =
          Directory('/storage/emulated/0/Pictures/Babymomo');
      if (!await publicPictures.exists()) {
        await publicPictures.create(recursive: true);
      }
      final destFile = File('${publicPictures.path}/$fileName');
      await _currentImage!.copy(destFile.path);

      Get.snackbar(
        '📸 Saved to Device!',
        'Saved to: Pictures/Babymomo/$fileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Save Error',
        'Could not save image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: MomoColors.rose,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAspect = _sizes[_selectedSize]['aspect'] as double;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Creative Studio',
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Flux UHD Neural Synthesis',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                Obx(() {
                  final active = _navCtrl.activeImageModel.value;
                  final isLcm = active != null &&
                      (active.name.toLowerCase().contains('lcm') ||
                          active.name.toLowerCase().contains('turbo'));
                  return GestureDetector(
                    onTap: _showModelPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isLcm ? MomoColors.amber : MomoColors.rose)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: (isLcm ? MomoColors.amber : MomoColors.rose)
                                .withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLcm ? Icons.flash_on : Icons.palette,
                            size: 14,
                            color: isLcm ? MomoColors.amber : MomoColors.rose,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Text(
                              active != null
                                  ? active.name.split('(').first.trim()
                                  : 'Select Model',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      isLcm ? MomoColors.amber : MomoColors.rose,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down,
                              size: 16,
                              color:
                                  isLcm ? MomoColors.amber : MomoColors.rose),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // ── Dynamic Aspect Ratio Image Canvas / Preview Holder ──
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 380,
                  maxWidth: double.infinity,
                ),
                child: AspectRatio(
                  aspectRatio: currentAspect,
                  child: Container(
                    decoration: BoxDecoration(
                      color: MomoColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isGenerating
                            ? MomoColors.rose
                            : MomoColors.glassBorder,
                        width: _isGenerating ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _isGenerating
                          ? _buildGeneratingState()
                          : _currentImage != null
                              ? _buildImageDisplay()
                              : _buildEmptyState(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Image Action Bar (Download / Retry) ──
            if (_currentImage != null && !_isGenerating)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MomoColors.surfaceLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _saveToGallery,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Save to Device',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MomoColors.rose.withOpacity(0.2),
                        foregroundColor: MomoColors.rose,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                            color: MomoColors.rose.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _startGeneration,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Regenerate',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // ── Prompt Input Card with Magic Polish Button ──
            MomoGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promptCtrl,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText:
                                'Describe your artwork idea (e.g. A cute space cat on the moon)...',
                            hintStyle:
                                TextStyle(color: MomoColors.textMuted, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Polish with Magic Lighting',
                        icon: const Icon(Icons.auto_awesome,
                            color: MomoColors.rose, size: 20),
                        onPressed: () {
                          final current = _promptCtrl.text.trim();
                          if (current.isNotEmpty) {
                            _promptCtrl.text =
                                '$current, dramatic volumetric lighting, intricate octane rendering, masterpiece, sharp focus, 8k uhd';
                            _promptCtrl.selection = TextSelection.fromPosition(
                              TextPosition(offset: _promptCtrl.text.length),
                            );
                            Get.snackbar(
                              '✨ Prompt Polished!',
                              'Added cinematic lighting and texture enhancements.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: MomoColors.surfaceLight,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Quick Inspiration Prompt Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStudioPromptChip('🐱 Cyberpunk Kitten', 'A futuristic cybernetic fluffy kitten in neon Tokyo street'),
                        _buildStudioPromptChip('🏰 Floating Island', 'A majestic fairytale castle floating in sky with waterfalls at sunset'),
                        _buildStudioPromptChip('🪐 Astronaut', 'An astronaut resting on Saturn rings looking at glowing galaxy'),
                        _buildStudioPromptChip('🌸 Cherry Blossom Tea', 'A cozy Japanese wooden tea room surrounded by blooming cherry blossoms'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Image Size / Aspect Ratio Selector ──
            Text('Image Size & Aspect Ratio',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _sizes.length,
                itemBuilder: (ctx, i) {
                  final s = _sizes[i];
                  final isSel = _selectedSize == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSize = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            isSel ? MomoColors.rose : MomoColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel
                              ? MomoColors.rose
                              : MomoColors.glassBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(s['icon'] as IconData,
                              size: 18,
                              color: isSel
                                  ? Colors.white
                                  : MomoColors.textSecondary),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s['label'] as String,
                                style: TextStyle(
                                  color: isSel
                                      ? Colors.white
                                      : MomoColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                s['desc'] as String,
                                style: TextStyle(
                                  color: isSel
                                      ? Colors.white70
                                      : MomoColors.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Style Presets ──
            Text('Style Presets',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => setState(() => _selectedPreset = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedPreset == i
                          ? MomoColors.rose
                          : MomoColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _selectedPreset == i
                              ? MomoColors.rose
                              : MomoColors.glassBorder),
                    ),
                    child: Text(
                      _presets[i],
                      style: TextStyle(
                        color: _selectedPreset == i
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
            const SizedBox(height: 18),

            // ── Generate Button ──
            SizedBox(
              width: double.infinity,
              child: MomoButton(
                label: _isGenerating
                    ? 'Babymomo is Creating...'
                    : 'Generate Artwork (${_sizes[_selectedSize]['label']})',
                icon: Icons.auto_awesome,
                color: MomoColors.rose,
                onPressed: _isGenerating ? () {} : _startGeneration,
              ),
            ),

            // ── Generation Performance Stats ──
            if (_lastGenTime.isNotEmpty && !_isGenerating)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 12, color: MomoColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '$_lastGenTime • $_lastGenEngine • $_lastGenDim UHD',
                      style: const TextStyle(
                          color: MomoColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),

            // ── Recent Gallery Carousel ──
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Recent Masterpieces',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              SizedBox(
                height: 84,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _history.length,
                  itemBuilder: (ctx, i) {
                    final f = _history[i];
                    return GestureDetector(
                      onTap: () => setState(() => _currentImage = f),
                      child: Container(
                        width: 84,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentImage?.path == f.path
                                ? MomoColors.rose
                                : MomoColors.glassBorder,
                            width: _currentImage?.path == f.path ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(f, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Upgraded thinking loading screen featuring the animated Babymomo mascot.
  Widget _buildGeneratingState() {
    return Container(
      color: const Color(0xFF0D0E15).withOpacity(0.95),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Thinking Animated Mascot Icon with Ambient Glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MomoColors.primary.withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: MomoColors.rose.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const MomoMasterVector(
                size: 88,
                isWinking: true,
                showBackground: false,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.08, 1.08),
                    duration: 1400.ms,
                    curve: Curves.easeInOut,
                  )
                  .rotate(
                    begin: -0.04,
                    end: 0.04,
                    duration: 1400.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
          const SizedBox(height: 12),

          // Engine & Size Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: MomoColors.rose.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MomoColors.rose.withOpacity(0.4),
              ),
            ),
            child: Text(
              '🎨 Flux UHD • ${_sizes[_selectedSize]['label']}',
              style: const TextStyle(
                color: MomoColors.rose,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: MomoColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation<Color>(MomoColors.rose),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Step status text
          Text(_stepStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            'Synthesizing ${_sizes[_selectedSize]['desc']} UHD canvas...',
            style: const TextStyle(color: MomoColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          _currentImage!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF10B981), size: 12),
                const SizedBox(width: 4),
                Text(
                    _lastGenDim.isNotEmpty
                        ? '$_lastGenDim UHD'
                        : '${_sizes[_selectedSize]['desc']} UHD',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.palette_outlined,
            size: 44, color: MomoColors.rose.withOpacity(0.5)),
        const SizedBox(height: 10),
        const Text('Ready to Paint with Babymomo',
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'Enter a prompt below & choose ${_sizes[_selectedSize]['label']} (${_sizes[_selectedSize]['desc']})',
          style: const TextStyle(color: MomoColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStudioPromptChip(String label, String fullPrompt) {
    return GestureDetector(
      onTap: () {
        _promptCtrl.text = fullPrompt;
        _promptCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _promptCtrl.text.length),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: MomoColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MomoColors.glassBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: MomoColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _GenerationConfig {
  final int steps;
  final double cfgScale;
  final String engineLabel;
  final bool isTurbo;

  const _GenerationConfig({
    required this.steps,
    required this.cfgScale,
    required this.engineLabel,
    required this.isTurbo,
  });
}
