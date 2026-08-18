import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../momo_ui/theme/momo_colors.dart';
import '../../../momo_ui/theme/momo_typography.dart';
import 'image_gen_controller.dart';
import '../sd_models/sd_model_controller.dart';
import '../sd_models/sd_models_sheet.dart';

class ImageGenPage extends GetView<ImageGenController> {
  final bool isTab;
  const ImageGenPage({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: MomoColors.surfaceGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Header ───
              _buildHeader(),

              // ─── Main Content ───
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      
                      // ─── Main Generation Preview Frame ───
                      _buildPreviewFrame(),

                      const SizedBox(height: 24),

                      // ─── Aspect Ratio Selector ───
                      Text(
                        'ASPECT RATIO',
                        style: MomoTypography.labelMedium.copyWith(
                          color: MomoColors.textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAspectSelector(),

                      const SizedBox(height: 24),

                      // ─── Prompt Input Area ───
                      _buildPromptInput(),

                      const SizedBox(height: 16),

                      // ─── Advanced Settings (Collapsible) ───
                      _buildAdvancedSettings(),

                      const SizedBox(height: 24),

                      // ─── History Grid ───
                      _buildHistorySection(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: Row(
        children: [
          if (!isTab) ...[
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: MomoColors.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Image Creator',
                style: MomoTypography.displaySmall.copyWith(
                  color: MomoColors.textPrimary,
                ),
              ),
              Builder(builder: (_) {
                final sdCtrl = Get.find<SdModelController>();
                return Obx(() {
                  final activeId = sdCtrl.activeModelId.value;
                  final activeModel = sdCtrl.activeModel?.model;
                  if (activeId != null && activeModel != null) {
                    return Text(
                      '🔒 ${activeModel.name} — Offline',
                      style: MomoTypography.bodySmall.copyWith(
                        color: MomoColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
                   return Text(
                    'On-Device · 100% Offline',
                    style: MomoTypography.bodySmall.copyWith(
                      color: MomoColors.textMuted,
                    ),
                  );
                });
              }),
            ],
          ),
          const Spacer(),
          // Local SD Model selector button
          Builder(builder: (_) {
            final sdCtrl = Get.find<SdModelController>();
            return Obx(() {
              final activeId = sdCtrl.activeModelId.value;
              final hasActive = activeId != null;
              return GestureDetector(
                onTap: () => SdModelsSheet.show(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: hasActive
                        ? const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                          )
                        : null,
                    color: hasActive ? null : MomoColors.surfaceLight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasActive
                          ? MomoColors.primary.withValues(alpha: 0.5)
                          : MomoColors.surfaceLight,
                    ),
                    boxShadow: hasActive
                        ? [
                            BoxShadow(
                              color: MomoColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasActive ? Icons.memory_rounded : Icons.auto_awesome_outlined,
                        color: hasActive ? Colors.white : MomoColors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasActive ? 'Local SD' : 'SD Models',
                        style: MomoTypography.labelSmall.copyWith(
                          color: hasActive ? Colors.white : MomoColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          }),
          const SizedBox(width: 4),
          Obx(() {
            if (controller.history.isNotEmpty) {
              return IconButton(
                onPressed: controller.clearHistory,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: MomoColors.textMuted,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildPreviewFrame() {
    return Obx(() {
      final status = controller.status.value;
      final imagePath = controller.generatedImagePath.value;

      double frameHeight = 280;

      return Container(
        width: double.infinity,
        height: frameHeight,
        decoration: BoxDecoration(
          color: MomoColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: status == ImageGenStatus.success
                ? MomoColors.primary.withValues(alpha: 0.3)
                : MomoColors.surfaceLight,
            width: 1.5,
          ),
          boxShadow: [
            if (status == ImageGenStatus.success)
              BoxShadow(
                color: MomoColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background grid pattern
            Opacity(
              opacity: 0.05,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                ),
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 0.5),
                  ),
                ),
              ),
            ),

            if (status == ImageGenStatus.idle)
              _buildIdlePlaceholder(),

            if (status == ImageGenStatus.generating)
              _buildGeneratingIndicator(),

            if (status == ImageGenStatus.success && imagePath != null)
              _buildSuccessView(imagePath),

            if (status == ImageGenStatus.error)
              _buildErrorView(),
          ],
        ),
      );
    });
  }

  Widget _buildIdlePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MomoColors.accent.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.brush_outlined,
            color: MomoColors.accent,
            size: 32,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        Text(
          'Your canvas awaits.',
          style: MomoTypography.displaySmall.copyWith(
            color: MomoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Describe what you see in your mind — Momo will paint it on-device.',
            textAlign: TextAlign.center,
            style: MomoTypography.bodySmall.copyWith(
              color: MomoColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingIndicator() {
    return Obx(() {
      final prog = controller.progress.value;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing radial loader dial
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: prog,
                  strokeWidth: 6,
                  backgroundColor: MomoColors.surfaceLight,
                  color: MomoColors.primary,
                ),
                Text(
                  '${(prog * 100).toInt()}%',
                  style: MomoTypography.labelLarge.copyWith(
                    color: MomoColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.04, 1.04), duration: 1500.ms),
          const SizedBox(height: 20),
          Text(
            'Rendering on-device…',
            style: MomoTypography.bodyMedium.copyWith(
              color: MomoColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your GPU is doing the heavy lifting — no cloud needed',
            style: MomoTypography.bodySmall.copyWith(
              color: MomoColors.textMuted,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSuccessView(String path) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(path),
          fit: BoxFit.contain,
        ).animate().fadeIn(duration: 400.ms),

        // Action controls overlay (Bottom Bar)
        Positioned(
          bottom: 12,
          right: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: MomoColors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MomoColors.surfaceLight.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.promptController.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MomoTypography.bodySmall.copyWith(
                      color: MomoColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: controller.saveToGallery,
                  tooltip: 'Save to Gallery',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.download_for_offline_rounded,
                    color: MomoColors.success,
                    size: 26,
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.3, duration: 300.ms),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: MomoColors.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Generation Failed',
            style: MomoTypography.displaySmall.copyWith(
              color: MomoColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.errorMessage.value,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: MomoTypography.bodySmall.copyWith(
              color: MomoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectSelector() {
    final aspectOptions = [
      {'id': 'square', 'label': '1:1 Square', 'icon': Icons.crop_square_rounded},
      {'id': 'landscape', 'label': '16:9 Landscape', 'icon': Icons.crop_16_9_rounded},
      {'id': 'portrait', 'label': '9:16 Portrait', 'icon': Icons.crop_portrait_rounded},
    ];

    return Obx(() {
      final selected = controller.selectedAspect.value;

      return Row(
        children: aspectOptions.map((opt) {
          final isSelected = opt['id'] == selected;
          final id = opt['id'] as String;

          return Expanded(
            child: GestureDetector(
              onTap: () => controller.selectAspect(id),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? MomoColors.surfaceLight : MomoColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? MomoColors.primary.withValues(alpha: 0.6)
                        : MomoColors.surfaceLight,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      opt['icon'] as IconData,
                      color: isSelected ? MomoColors.primary : MomoColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      opt['label'] as String,
                      style: MomoTypography.labelSmall.copyWith(
                        color: isSelected ? MomoColors.textPrimary : MomoColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildPromptInput() {
    return Container(
      decoration: BoxDecoration(
        color: MomoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MomoColors.surfaceLight,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        children: [
          TextField(
            controller: controller.promptController,
            maxLines: 3,
            style: MomoTypography.bodyMedium.copyWith(color: MomoColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'A cinematic portrait in golden hour light, dramatic shadows, film grain…',
              hintStyle: MomoTypography.bodySmall.copyWith(color: MomoColors.textMuted),
              border: InputBorder.none,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Obx(() {
                final isGenerating = controller.status.value == ImageGenStatus.generating;

                return GestureDetector(
                  onTap: isGenerating ? null : controller.generateImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isGenerating ? null : MomoColors.primaryGradient,
                      color: isGenerating ? MomoColors.surfaceLight : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        if (isGenerating) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: MomoColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Drawing...',
                            style: MomoTypography.labelMedium.copyWith(
                              color: MomoColors.textMuted,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Create',
                            style: MomoTypography.labelMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    final isExpanded = false.obs;

    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: MomoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: MomoColors.surfaceLight,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            GestureDetector(
              onTap: () => isExpanded.toggle(),
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.transparent,
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: MomoColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Advanced Parameters',
                      style: MomoTypography.labelMedium.copyWith(
                        color: MomoColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isExpanded.value ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: MomoColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded.value)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: MomoColors.surfaceLight, height: 1),
                    const SizedBox(height: 16),

                    // Negative Prompt
                    Text(
                      'NEGATIVE PROMPT',
                      style: MomoTypography.labelSmall.copyWith(
                        color: MomoColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: MomoColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: controller.negativePromptController,
                        maxLines: 1,
                        style: MomoTypography.bodySmall.copyWith(color: MomoColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Items to avoid (e.g. text, blurry, worst quality)',
                          hintStyle: MomoTypography.bodySmall.copyWith(color: MomoColors.textMuted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Steps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DENOISING STEPS',
                          style: MomoTypography.labelSmall.copyWith(
                            color: MomoColors.textMuted,
                          ),
                        ),
                        Text(
                          '${controller.steps.value}',
                          style: MomoTypography.labelSmall.copyWith(
                            color: MomoColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: controller.steps.value.toDouble(),
                      min: 5,
                      max: 50,
                      divisions: 9,
                      activeColor: MomoColors.primary,
                      inactiveColor: MomoColors.surfaceLight,
                      onChanged: (val) => controller.steps.value = val.toInt(),
                    ),

                    // CFG Scale
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CFG SCALE',
                          style: MomoTypography.labelSmall.copyWith(
                            color: MomoColors.textMuted,
                          ),
                        ),
                        Text(
                          controller.cfgScale.value.toStringAsFixed(1),
                          style: MomoTypography.labelSmall.copyWith(
                            color: MomoColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: controller.cfgScale.value,
                      min: 1.0,
                      max: 20.0,
                      divisions: 38,
                      activeColor: MomoColors.primary,
                      inactiveColor: MomoColors.surfaceLight,
                      onChanged: (val) => controller.cfgScale.value = val,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildHistorySection() {
    return Obx(() {
      if (controller.history.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENT CREATIONS',
            style: MomoTypography.labelMedium.copyWith(
              color: MomoColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: controller.history.length,
            itemBuilder: (context, index) {
              final item = controller.history[index];
              final path = item['path']!;
              final prompt = item['prompt']!;

              return GestureDetector(
                onTap: () {
                  controller.promptController.text = prompt;
                  controller.selectedAspect.value = item['aspect'] ?? 'square';
                  controller.generatedImagePath.value = path;
                  controller.status.value = ImageGenStatus.success;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: MomoColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: MomoColors.surfaceLight,
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(path),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          child: Text(
                            prompt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MomoTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }
}
