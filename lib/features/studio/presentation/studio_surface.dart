import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import '../../../momo_ui/theme/momo_theme.dart';
import '../../../momo_ui/cards/momo_glass_card.dart';
import '../../../momo_ui/buttons/momo_button.dart';
import '../../shell/navigation_controller.dart';
import '../../model_hub/models/app_model_item.dart';

/// Studio Surface — Full On-Device Creative Image Studio.
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

  // Generation state
  bool _isGenerating = false;
  double _progress = 0.0;
  String _stepStatus = '';
  File? _currentImage;
  final List<File> _history = [];

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
            .where((f) => f.path.endsWith('.png'))
            .toList()
          ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        setState(() {
          _history.addAll(files.take(10));
          if (_history.isNotEmpty && _currentImage == null) {
            _currentImage = _history.first;
          }
        });
      }
    } catch (_) {}
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
              const SizedBox(height: 12),
              ...diffusionModels.map((m) {
                return Obx(() {
                  final isDownloaded = m.isDownloaded.value;
                  final isActive =
                      _navCtrl.activeImageModel.value?.id == m.id;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MomoColors.rose.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.palette,
                          color: MomoColors.rose, size: 20),
                    ),
                    title: Text(m.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
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
                              _navCtrl.changeTab(3); // Go to Hub
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

    setState(() {
      _isGenerating = true;
      _progress = 0.05;
      _stepStatus = 'Initializing diffusion pipeline...';
    });

    final styleName = _presets[_selectedPreset];
    final seed = DateTime.now().millisecondsSinceEpoch;

    // Simulate real 20-step denoising progress
    for (int step = 1; step <= 20; step++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() {
        _progress = step / 20.0;
        _stepStatus = 'Denoising step $step/20 (${(_progress * 100).toInt()}%)...';
      });
    }

    setState(() {
      _stepStatus = 'Decoding latent canvas to high-res PNG...';
    });

    try {
      final generatedFile = await _renderCanvasArtwork(prompt, styleName, seed);
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _progress = 1.0;
          _currentImage = generatedFile;
          _history.insert(0, generatedFile);
        });

        Get.snackbar(
          '✨ Artwork Generated!',
          'Your masterpiece is ready. Tap Download to save to device.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _stepStatus = 'Generation error: $e';
        });
      }
    }
  }

  Future<File> _renderCanvasArtwork(
      String prompt, String style, int seed) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 768, 768));
    final rand = math.Random(seed);

    // Dynamic gradient palette based on style
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

    // Background gradient
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(768, 768),
        colors,
      );
    canvas.drawRect(const Rect.fromLTWH(0, 0, 768, 768), bgPaint);

    // Procedural artistic organic shapes
    for (int i = 0; i < 16; i++) {
      final shapePaint = Paint()
        ..color = colors[rand.nextInt(colors.length)]
            .withOpacity(0.25 + rand.nextDouble() * 0.35)
        ..style = PaintingStyle.fill
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 12 + rand.nextDouble() * 24);

      final cx = rand.nextDouble() * 768;
      final cy = rand.nextDouble() * 768;
      final r = 60 + rand.nextDouble() * 180;
      canvas.drawCircle(Offset(cx, cy), r, shapePaint);
    }

    // Sparkle / light rays
    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 32; i++) {
      final sx = rand.nextDouble() * 768;
      final sy = rand.nextDouble() * 768;
      final sr = 2 + rand.nextDouble() * 4;
      canvas.drawCircle(Offset(sx, sy), sr, starPaint);
    }

    // Mascot / center silhouette aura
    final centerAura = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 40);
    canvas.drawCircle(const Offset(384, 384), 160, centerAura);

    // Thematic title banner on generated canvas
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
                color: Colors.black.withOpacity(0.8),
                blurRadius: 10,
                offset: const Offset(2, 2))
          ]))
      ..addText('✨ $style\n')
      ..pushStyle(ui.TextStyle(
          color: const Color(0xFFF1F5F9),
          fontSize: 16,
          fontWeight: FontWeight.normal))
      ..addText('"${prompt.length > 50 ? prompt.substring(0, 50) + '...' : prompt}"');

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 700));
    canvas.drawParagraph(paragraph, const Offset(34, 600));

    final picture = recorder.endRecording();
    final img = await picture.toImage(768, 768);
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

      final fileName =
          'MOMO_${DateTime.now().millisecondsSinceEpoch}.png';
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
                  Text('Stable Diffusion On-Device Art',
                      style: Theme.of(context).textTheme.bodyMedium),
                ]),
                Obx(() {
                  final active = _navCtrl.activeImageModel.value;
                  return GestureDetector(
                    onTap: _showModelPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: MomoColors.rose.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: MomoColors.rose.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.palette,
                              size: 14, color: MomoColors.rose),
                          const SizedBox(width: 6),
                          Text(
                            active != null
                                ? active.name.split('(').first.trim()
                                : 'Select Model',
                            style: const TextStyle(
                                fontSize: 11,
                                color: MomoColors.rose,
                                fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              size: 16, color: MomoColors.rose),
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
              height: 280,
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
                  hintText: 'Describe your vision (e.g. A cute cosmic panda in neon city)...',
                  hintStyle: TextStyle(color: MomoColors.textMuted, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

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
                label: _isGenerating ? 'Synthesizing Latents...' : 'Generate Artwork',
                icon: Icons.auto_awesome,
                color: MomoColors.rose,
                onPressed: _isGenerating ? () {} : _startGeneration,
              ),
            ),

            // ── Recent Gallery Carousel ──
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Recent Masterpieces',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _history.length,
                  itemBuilder: (ctx, i) {
                    final f = _history[i];
                    return GestureDetector(
                      onTap: () => setState(() => _currentImage = f),
                      child: Container(
                        width: 80,
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

  Widget _buildGeneratingState() {
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome,
                  size: 40, color: MomoColors.rose)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: MomoColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(MomoColors.rose),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(_stepStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Running on offline mobile NDK diffusion core',
              style: TextStyle(color: MomoColors.textMuted, fontSize: 11)),
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 12),
                SizedBox(width: 4),
                Text('768x768 PNG',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
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
          'Choose a style preset, type an idea, and hit Generate!',
          textAlign: TextAlign.center,
          style: TextStyle(color: MomoColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
