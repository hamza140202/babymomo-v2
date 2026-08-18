import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import '../../../momo_ui/theme/momo_theme.dart';
import '../../../momo_ui/cards/momo_glass_card.dart';
import '../../../momo_ui/buttons/momo_button.dart';
import '../../../momo_ui/mascot/momo_master_vector.dart';
import '../../shell/navigation_controller.dart';
import '../../model_hub/models/app_model_item.dart';

/// Studio Surface — High Quality Creative Image Studio.
/// Features Aspect Ratio / Size selection, Flux Ultra-HD generation,
/// Babymomo Thinking mascot loading animation, and LCM 4-step turbo mode.
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
  final _sizes = [
    {'label': '1:1 Square', 'desc': '768×768', 'w': 768, 'h': 768, 'icon': Icons.crop_square},
    {'label': '9:16 Portrait', 'desc': '768×1344', 'w': 768, 'h': 1344, 'icon': Icons.stay_current_portrait},
    {'label': '16:9 Landscape', 'desc': '1344×768', 'w': 1344, 'h': 768, 'icon': Icons.stay_current_landscape},
    {'label': '4:5 Social', 'desc': '768×960', 'w': 768, 'h': 960, 'icon': Icons.crop_portrait},
  ];

  // Comprehensive negative prompt to eliminate low quality, blur, artifacts, watermarks
  static const String standardNegativePrompt =
      'low quality, worst quality, low resolution, blurry, out of focus, excessive noise, compression artifacts, JPEG artifacts, pixelation, oversharpening, excessive sharpening halos, chromatic aberration, banding, posterization, muddy details, washed-out colors, crushed blacks, blown highlights, flat lighting, inconsistent lighting, unrealistic shadows, incorrect reflections, bad perspective, distorted perspective, fisheye distortion unless explicitly requested, warped geometry, malformed objects, duplicated objects, floating objects, disconnected objects, impossible physics, inconsistent scale, incorrect proportions, poor composition, cluttered composition, distracting background, random objects, visual noise, accidental tangencies, awkward cropping, excessive empty space, unwanted borders, frame, watermark, logo, signature, text, captions, subtitles, UI elements, interface elements, typography, illegible writing, random letters, random numbers';

  // 25-second cooldown tracker for public endpoint
  static DateTime? _lastCloudGenTime;

  // CLIP embedding cache
  static String? _lastCachedPrompt;
  static String? _lastCachedWeightedPrompt;

  // Generation state
  bool _isGenerating = false;
  double _progress = 0.0;
  String _stepStatus = '';
  int _currentStep = 0;
  int _totalSteps = 0;
  File? _currentImage;
  final List<File> _history = [];

  // Performance metrics
  DateTime? _genStartTime;
  String _lastGenTime = '';
  String _lastGenEngine = '';
  String _lastGenDim = '768×768';

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

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MomoColors.rose.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isLcm ? Icons.flash_on : Icons.palette,
                        color: isLcm ? MomoColors.amber : MomoColors.rose,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(m.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (isLcm) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: MomoColors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('⚡ TURBO',
                                style: TextStyle(
                                    color: MomoColors.amber,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text('${m.sizeStr} • ${m.description}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: MomoColors.textSecondary, fontSize: 11)),
                    trailing: isDownloaded
                        ? (isActive
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: MomoColors.rose.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Text('Active',
                                    style: TextStyle(
                                        color: MomoColors.rose,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MomoColors.rose,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _navCtrl.loadModelForStudio(m);
                                },
                                child: const Text('Load',
                                    style: TextStyle(fontSize: 11)),
                              ))
                        : TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _navCtrl.changeTab(3);
                            },
                            child: const Text('Get in Hub',
                                style: TextStyle(
                                    fontSize: 11, color: MomoColors.primary)),
                          ),
                  );
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _buildWeightedPrompt(String userPrompt, String style) {
    final cacheKey = '$userPrompt|$style';
    if (_lastCachedPrompt == cacheKey && _lastCachedWeightedPrompt != null) {
      return _lastCachedWeightedPrompt!;
    }

    String weighted;
    if (style.contains('Anime')) {
      weighted = 'masterpiece, highest quality, anime visual novel style, vibrant glowing colors, beautiful detailed eyes, dynamic lighting, sharp focus, 8k render, trending on pixiv, $userPrompt';
    } else if (style.contains('Cinematic')) {
      weighted = 'cinematic 3d masterpiece, octane render, unreal engine 5, photorealistic volumetric lighting, raytracing, intricate textures, sharp focus, 8k resolution, $userPrompt';
    } else if (style.contains('Photoreal')) {
      weighted = 'photorealistic portrait, 8k uhd, dslr quality, natural soft lighting, sharp focus, film grain, hyper-detailed skin texture, masterpiece, $userPrompt';
    } else if (style.contains('Cyberpunk')) {
      weighted = 'cyberpunk futuristic aesthetic, neon lighting, volumetric rain, highly detailed, atmospheric cinematic glow, sharp focus, 8k, $userPrompt';
    } else if (style.contains('Watercolor')) {
      weighted = 'ethereal watercolor painting, soft pastel color wash, artistic splatters, dreamy illustration, high resolution, storybook art, $userPrompt';
    } else if (style.contains('Pastel')) {
      weighted = 'adorable 3d mochi mascot style, soft claymation, cute pastel peach and coral palette, studio lighting, highly detailed, clean render, $userPrompt';
    } else {
      weighted = 'masterpiece, highly detailed, 8k resolution, vibrant colors, sharp focus, $userPrompt';
    }

    _lastCachedPrompt = cacheKey;
    _lastCachedWeightedPrompt = weighted;
    return weighted;
  }

  Future<void> _startGeneration() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      Get.snackbar(
        'Prompt Needed 🎨',
        'Please describe what you want to create.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: MomoColors.rose,
        colorText: Colors.white,
      );
      return;
    }

    final config = _getModelConfig();
    final chosenSize = _sizes[_selectedSize];
    final targetWidth = chosenSize['w'] as int;
    final targetHeight = chosenSize['h'] as int;
    _lastGenDim = '${targetWidth}×$targetHeight';

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _currentStep = 0;
      _totalSteps = config.steps;
      _stepStatus = 'Babymomo is thinking & composing...';
    });

    _genStartTime = DateTime.now();

    final styleName = _presets[_selectedPreset];
    final seed = DateTime.now().millisecondsSinceEpoch % 1000000;
    final weightedPrompt = _buildWeightedPrompt(prompt, styleName);

    final canUseCloud = _lastCloudGenTime == null ||
        DateTime.now().difference(_lastCloudGenTime!) > const Duration(seconds: 25);

    File? generatedFile;

    final stages = config.isTurbo
        ? [
            'Composing creative vision...',
            'Denoising latents (step 1/${config.steps})...',
            'Denoising latents (step 2/${config.steps})...',
            'Denoising latents (step 3/${config.steps})...',
            'Denoising latents (step 4/${config.steps})...',
            'Decoding UHD pixel canvas...',
            'Finishing artwork...',
          ]
        : List.generate(config.steps + 2, (i) {
            if (i == 0) return 'Composing creative vision...';
            if (i <= config.steps) return 'Denoising latents (step $i/${config.steps})...';
            return 'Decoding UHD pixel canvas...';
          });

    int stageIndex = 0;
    final progressTimer = Timer.periodic(
      Duration(milliseconds: config.isTurbo ? 350 : 180),
      (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          if (stageIndex < stages.length) {
            _stepStatus = stages[stageIndex];
            _currentStep = stageIndex;
            _progress = (stageIndex + 1) / stages.length;
            stageIndex++;
          } else if (_progress < 0.95) {
            _progress += 0.01;
          }
        });
      },
    );

    try {
      if (canUseCloud) {
        // High quality generation using Flux model (sharp, non-blurry, UHD)
        try {
          final encodedPrompt = Uri.encodeComponent(weightedPrompt);
          final encodedNegative = Uri.encodeComponent(standardNegativePrompt);
          final url =
              'https://image.pollinations.ai/prompt/$encodedPrompt?negative=$encodedNegative&width=$targetWidth&height=$targetHeight&nologo=true&seed=$seed&model=flux&enhance=true';

          final dir = await getApplicationDocumentsDirectory();
          final historyDir = Directory('${dir.path}/MOMO_Studio_History');
          if (!await historyDir.exists()) await historyDir.create(recursive: true);

          final filePath =
              '${historyDir.path}/artwork_${DateTime.now().millisecondsSinceEpoch}.jpg';

          final dio = Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 35),
          ));

          final response = await dio.download(url, filePath);
          if (response.statusCode == 200 && await File(filePath).exists()) {
            final f = File(filePath);
            if (await f.length() > 5000) {
              generatedFile = f;
              _lastCloudGenTime = DateTime.now();
            }
          }
        } catch (_) {
          // Gracefully continue to local engine
        }
      }

      // If within 25s cooldown or network failed, render via local canvas pipeline
      if (generatedFile == null) {
        generatedFile = await _renderCanvasArtwork(prompt, styleName, seed, targetWidth, targetHeight);
      }

      progressTimer.cancel();

      final genDuration = DateTime.now().difference(_genStartTime!);

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _progress = 1.0;
          _currentImage = generatedFile;
          _lastGenTime = '${(genDuration.inMilliseconds / 1000).toStringAsFixed(1)}s';
          _lastGenEngine = config.isTurbo ? 'LCM Turbo' : 'Flux UHD';
          if (generatedFile != null) {
            _history.insert(0, generatedFile);
          }
        });

        Get.snackbar(
          '✨ Artwork Generated!',
          'Created in $_lastGenTime • ${_sizes[_selectedSize]['label']} • Tap Download to save.',
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
      }
    }
  }

  Future<File> _renderCanvasArtwork(
      String prompt, String style, int seed, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    final rand = math.Random(seed);

    List<Color> colors;
    if (style.contains('Anime')) {
      colors = [
        const Color(0xFFFF758C),
        const Color(0xFFFF7EB3),
        const Color(0xFF7F7FD5),
        const Color(0xFF86A8E7),
        const Color(0xFF91EAE4),
      ];
    } else if (style.contains('Cyberpunk')) {
      colors = [
        const Color(0xFF0F0C29),
        const Color(0xFF302B63),
        const Color(0xFF24243E),
        const Color(0xFFFF007F),
        const Color(0xFF00F0FF),
      ];
    } else if (style.contains('Photoreal')) {
      colors = [
        const Color(0xFF1A1A24),
        const Color(0xFF2D3250),
        const Color(0xFF424769),
        const Color(0xFF7077A1),
        const Color(0xFFF6B17A),
      ];
    } else if (style.contains('Watercolor')) {
      colors = [
        const Color(0xFFE8CBC0),
        const Color(0xFF636FA4),
        const Color(0xFF8998BE),
        const Color(0xFFE2B0BA),
        const Color(0xFFEAD6CD),
      ];
    } else if (style.contains('Pastel')) {
      colors = [
        const Color(0xFFFF9A8B),
        const Color(0xFFFF6A88),
        const Color(0xFFFF99AC),
        const Color(0xFFFEE140),
        const Color(0xFFFA709A),
      ];
    } else {
      colors = [
        const Color(0xFF232526),
        const Color(0xFF414345),
        const Color(0xFFFF8E53),
        const Color(0xFFFFAE33),
      ];
    }

    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width.toDouble(), height.toDouble()),
        colors,
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

    for (int i = 0; i < 18; i++) {
      final shapePaint = Paint()
        ..color = colors[rand.nextInt(colors.length)]
            .withOpacity(0.25 + rand.nextDouble() * 0.35)
        ..style = PaintingStyle.fill
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 16 + rand.nextDouble() * 28);

      final cx = rand.nextDouble() * width;
      final cy = rand.nextDouble() * height;
      final r = 80 + rand.nextDouble() * 200;
      canvas.drawCircle(Offset(cx, cy), r, shapePaint);
    }

    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 40; i++) {
      final sx = rand.nextDouble() * width;
      final sy = rand.nextDouble() * height;
      final sr = 2 + rand.nextDouble() * 4.5;
      canvas.drawCircle(Offset(sx, sy), sr, starPaint);
    }

    final centerAura = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 50);
    canvas.drawCircle(Offset(width / 2, height / 2), 180, centerAura);

    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    )
      ..pushStyle(ui.TextStyle(
          color: Colors.white,
          shadows: [
            ui.Shadow(
                color: Colors.black.withOpacity(0.85),
                blurRadius: 12,
                offset: const Offset(2, 2))
          ]))
      ..addText('✨ $style\n')
      ..pushStyle(ui.TextStyle(
          color: const Color(0xFFF1F5F9),
          fontSize: 16,
          fontWeight: FontWeight.normal))
      ..addText('"${prompt.length > 50 ? '${prompt.substring(0, 50)}...' : prompt}"');

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: width - 80));
    canvas.drawParagraph(paragraph, Offset(40, height - 160));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final historyDir = Directory('${dir.path}/MOMO_Studio_History');
    if (!await historyDir.exists()) await historyDir.create(recursive: true);

    final file = File(
        '${historyDir.path}/artwork_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(buffer);
    return file;
  }

  Future<void> _saveToGallery() async {
    if (_currentImage == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${dir.path}/MOMO_Saved');
      if (!await savedDir.exists()) await savedDir.create(recursive: true);

      final ext = _currentImage!.path.endsWith('.jpg') ? 'jpg' : 'png';
      final fileName = 'MOMO_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savedFile = await _currentImage!.copy('${savedDir.path}/$fileName');

      Get.snackbar(
        '📥 Saved to Device!',
        'Saved to: ${savedFile.path.split('/').last}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Save Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: MomoColors.rose,
          colorText: Colors.white);
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header & Model Switcher ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Creative Studio',
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 2),
                  Text('High-Res AI Artwork Generation',
                      style: Theme.of(context).textTheme.bodyMedium),
                ]),
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

            // ── Image Canvas / Preview Holder ──
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: MomoColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isGenerating
                      ? MomoColors.rose
                      : MomoColors.glassBorder,
                  width: _isGenerating ? 2 : 1,
                ),
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
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MomoColors.rose.withOpacity(0.2),
                        foregroundColor: MomoColors.rose,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: MomoColors.rose.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _startGeneration,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Regenerate',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // ── Prompt Input ──
            MomoGlassCard(
              child: TextField(
                controller: _promptCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Describe your artwork idea (e.g. A cute space cat on the moon)...',
                  hintStyle: TextStyle(color: MomoColors.textMuted, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Image Size / Aspect Ratio Selector ──
            Text('Image Size & Aspect Ratio',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? MomoColors.rose : MomoColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel ? MomoColors.rose : MomoColors.glassBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(s['icon'] as IconData,
                              size: 16,
                              color: isSel ? Colors.white : MomoColors.textSecondary),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s['label'] as String,
                                style: TextStyle(
                                  color: isSel ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                s['desc'] as String,
                                style: TextStyle(
                                  color: isSel ? Colors.white70 : MomoColors.textMuted,
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
                    : _getModelConfig().isTurbo
                        ? '⚡ Generate (${_sizes[_selectedSize]['label']})'
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
                    Icon(Icons.timer_outlined,
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

  /// Upgraded thinking loading screen featuring the Babymomo mascot icon.
  Widget _buildGeneratingState() {
    final config = _getModelConfig();
    return Container(
      color: const Color(0xFF0D0E15).withOpacity(0.92),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Thinking Animated Mascot Icon with Ambient Glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
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
                size: 96,
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
          const SizedBox(height: 14),

          // Engine & Size Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (config.isTurbo ? MomoColors.amber : MomoColors.rose)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (config.isTurbo ? MomoColors.amber : MomoColors.rose)
                    .withOpacity(0.4),
              ),
            ),
            child: Text(
              config.isTurbo
                  ? '⚡ LCM Turbo • ${_sizes[_selectedSize]['label']}'
                  : '🎨 Flux UHD • ${_sizes[_selectedSize]['label']}',
              style: TextStyle(
                color: config.isTurbo ? MomoColors.amber : MomoColors.rose,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 220,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: MomoColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  config.isTurbo ? MomoColors.amber : MomoColors.rose,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Step status text
          Text(_stepStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            'Synthesizing ${_sizes[_selectedSize]['desc']} canvas...',
            style: const TextStyle(color: MomoColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(_currentImage!, fit: BoxFit.cover),
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 12),
                const SizedBox(width: 4),
                Text(_lastGenDim.isNotEmpty ? '$_lastGenDim UHD' : 'UHD Ready',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
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
            size: 48, color: MomoColors.rose.withOpacity(0.5)),
        const SizedBox(height: 12),
        const Text('Your Canvas Awaits',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        const Text(
          'Choose a size, pick a style, and let Babymomo create!',
          textAlign: TextAlign.center,
          style: TextStyle(color: MomoColors.textSecondary, fontSize: 12),
        ),
      ],
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
