import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../momo_ui/theme/momo_colors.dart';
import '../../../momo_ui/theme/momo_typography.dart';
import 'sd_model.dart';
import 'sd_model_controller.dart';
import 'sd_runtime_manager.dart';

class SdModelsSheet extends StatelessWidget {
  const SdModelsSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const SdModelsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SdModelController>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: MomoColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ─── Handle + Header ───
          _buildHeader(controller),

          // ─── Scrollable Model Cards ───
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  _buildStatusBanner(controller),
                  const SizedBox(height: 20),

                  // Runtime section
                  _buildRuntimeSection(controller),
                  const SizedBox(height: 20),

                  // Divider
                  Container(
                    height: 1,
                    color: const Color(0xFF252540),
                  ),
                  const SizedBox(height: 20),

                  // Section title
                  Text(
                    'AVAILABLE MODELS',
                    style: MomoTypography.labelSmall.copyWith(
                      color: MomoColors.textMuted,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Model cards
                  ...controller.modelStates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final state = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildModelCard(state, controller)
                          .animate()
                          .fadeIn(delay: (index * 80).ms, duration: 350.ms)
                          .slideY(begin: 0.15),
                    );
                  }),

                  const SizedBox(height: 12),
                  _buildInfoNote(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SdModelController controller) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: MomoColors.surfaceLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: MomoColors.warmGradient,
                  boxShadow: [
                    BoxShadow(
                      color: MomoColors.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local SD Models',
                      style: MomoTypography.displaySmall.copyWith(
                        color: MomoColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Unlimited offline image generation',
                      style: MomoTypography.bodySmall.copyWith(color: MomoColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close_rounded, color: MomoColors.textMuted, size: 22),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFF252540), height: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatusBanner(SdModelController controller) {
    return Obx(() {
      final activeId = controller.activeModelId.value;
      final libAvailable = controller.nativeLibAvailable.value;
      final downloaded = controller.downloadedCount;

      if (activeId != null) {
        final model = controller.activeModel?.model;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MomoColors.primary.withValues(alpha: 0.15),
                MomoColors.accent.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MomoColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: MomoColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active: ${model?.name ?? activeId}',
                      style: MomoTypography.labelLarge.copyWith(
                        color: MomoColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      libAvailable
                          ? '🔒 Full offline inference ready'
                          : '🎨 Offline procedural fallback active (native lib pending)',
                      style: MomoTypography.bodySmall.copyWith(color: MomoColors.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => controller.deactivateModel(),
                child: Text(
                  'Unload',
                  style: MomoTypography.labelSmall.copyWith(color: MomoColors.error),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MomoColors.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MomoColors.surfaceLight.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              downloaded > 0 ? Icons.download_done_rounded : Icons.cloud_outlined,
              color: MomoColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              downloaded > 0
                  ? '$downloaded model${downloaded > 1 ? 's' : ''} downloaded — tap Load to activate'
                  : 'No models downloaded. Download one to generate offline.',
              style: MomoTypography.bodySmall.copyWith(color: MomoColors.textMuted),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildModelCard(SdModelState state, SdModelController controller) {
    return Obx(() {
      final status = state.status.value;
      final isActive = status == SdModelStatus.active;
      final isDownloaded = status == SdModelStatus.downloaded || isActive;
      final isDownloading = status == SdModelStatus.downloading;
      final isLoading = status == SdModelStatus.loading;

      final glowColor = isActive
          ? MomoColors.primary
          : isDownloaded
              ? MomoColors.success
              : MomoColors.surfaceLight;

      return Container(
        decoration: BoxDecoration(
          color: MomoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? MomoColors.primary.withValues(alpha: 0.5)
                : glowColor.withValues(alpha: 0.25),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: MomoColors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Card Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: _modelGradient(state.model.id),
                    ),
                    child: Center(
                      child: Text(
                        _modelEmoji(state.model.id),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.model.name,
                                style: MomoTypography.labelLarge.copyWith(
                                  color: MomoColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: MomoColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: MomoColors.primary.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: MomoColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'ACTIVE',
                                      style: MomoTypography.labelSmall.copyWith(
                                        color: MomoColors.primary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                                    duration: 1800.ms,
                                    color: MomoColors.primaryLight.withValues(alpha: 0.3),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              'v${state.model.version}',
                              style: MomoTypography.bodySmall.copyWith(
                                color: MomoColors.primaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '  ·  ${state.model.baseModel}',
                              style: MomoTypography.bodySmall.copyWith(
                                color: MomoColors.textMuted,
                              ),
                            ),
                            Text(
                              '  ·  ${state.model.sizeGB.toStringAsFixed(1)} GB',
                              style: MomoTypography.bodySmall.copyWith(
                                color: MomoColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                state.model.description,
                style: MomoTypography.bodySmall.copyWith(
                  color: MomoColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Style tags
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: state.model.styleTags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: MomoColors.surfaceLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: MomoTypography.labelSmall.copyWith(
                              color: MomoColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            // Uncensored badge
            if (state.model.isUncensored)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('🔓', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 5),
                        Text(
                          'UNCENSORED',
                          style: MomoTypography.labelSmall.copyWith(
                            color: const Color(0xFFFF6B35),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Recommended settings badge
            if (state.model.isLcm)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: MomoColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MomoColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_rounded, color: MomoColors.warning, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'LCM: Only ${state.model.recommendedSteps} steps needed! Ultra-fast.',
                        style: MomoTypography.labelSmall.copyWith(
                          color: MomoColors.warning,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // Download progress bar (visible when downloading)
            if (isDownloading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Downloading...',
                          style: MomoTypography.labelSmall.copyWith(color: MomoColors.primary),
                        ),
                        Text(
                          state.downloadSpeed.value,
                          style: MomoTypography.labelSmall.copyWith(color: MomoColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: state.downloadProgress.value,
                        minHeight: 6,
                        backgroundColor: MomoColors.surfaceLight,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(MomoColors.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(state.downloadProgress.value * 100).toInt()}% of ${state.model.sizeGB.toStringAsFixed(1)} GB',
                      style: MomoTypography.labelSmall.copyWith(
                        color: MomoColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Error message
            if (state.errorMessage.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  state.errorMessage.value,
                  style: MomoTypography.labelSmall.copyWith(
                    color: MomoColors.warning,
                    fontSize: 10,
                  ),
                ),
              ),

            // ─── Action Buttons ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Primary action
                  Expanded(
                    child: _buildPrimaryButton(state, controller, status, isLoading),
                  ),

                  // Delete button (only if downloaded)
                  if (isDownloaded && !isActive) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _confirmDelete(state, controller),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: MomoColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MomoColors.error.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: MomoColors.error, size: 18),
                      ),
                    ),
                  ],

                  // Pause button (only when downloading)
                  if (isDownloading) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.pauseDownload(state),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: MomoColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MomoColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.pause_rounded,
                            color: MomoColors.warning, size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPrimaryButton(
    SdModelState state,
    SdModelController controller,
    SdModelStatus status,
    bool isLoading,
  ) {
    String label;
    Color bgColor;
    Color textColor = Colors.white;
    VoidCallback? onTap;
    Widget? leadingIcon;

    switch (status) {
      case SdModelStatus.notDownloaded:
        label = 'Download ${state.model.sizeGB.toStringAsFixed(1)} GB';
        bgColor = MomoColors.primary;
        onTap = () => controller.downloadModel(state);
        leadingIcon = const Icon(Icons.download_rounded, color: Colors.white, size: 16);
        break;
      case SdModelStatus.downloading:
      case SdModelStatus.paused:
        label = status == SdModelStatus.paused ? 'Paused — Resume' : 'Downloading...';
        bgColor = MomoColors.primaryDark.withValues(alpha: 0.6);
        onTap = status == SdModelStatus.paused ? () => controller.downloadModel(state) : null;
        break;
      case SdModelStatus.downloaded:
        label = 'Load Model';
        bgColor = MomoColors.success;
        onTap = () => controller.activateModel(state);
        leadingIcon = const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16);
        break;
      case SdModelStatus.loading:
        label = 'Loading...';
        bgColor = MomoColors.primaryDark.withValues(alpha: 0.6);
        onTap = null;
        break;
      case SdModelStatus.active:
        label = 'Active ✓';
        bgColor = MomoColors.primary.withValues(alpha: 0.25);
        textColor = MomoColors.primary;
        onTap = null;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else if (leadingIcon != null) ...[
              leadingIcon,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: MomoTypography.labelMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(SdModelState state, SdModelController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: MomoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete ${state.model.name}?',
          style: MomoTypography.displaySmall.copyWith(color: MomoColors.textPrimary),
        ),
        content: Text(
          'This will remove the ${state.model.sizeGB.toStringAsFixed(1)} GB file from your device. You can re-download it anytime.',
          style: MomoTypography.bodySmall.copyWith(color: MomoColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: MomoTypography.labelMedium.copyWith(color: MomoColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteModel(state);
            },
            child: Text('Delete', style: MomoTypography.labelMedium.copyWith(color: MomoColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuntimeSection(SdModelController controller) {
    final runtimeMgr = Get.isRegistered<SdRuntimeManager>()
        ? Get.find<SdRuntimeManager>()
        : null;

    if (runtimeMgr == null) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final status = runtimeMgr.status.value;
      final isReady = status == SdRuntimeStatus.ready;
      final isDownloading = status == SdRuntimeStatus.downloading;
      final isLoading = status == SdRuntimeStatus.loading;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isReady
              ? MomoColors.success.withValues(alpha: 0.07)
              : MomoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isReady
                ? MomoColors.success.withValues(alpha: 0.3)
                : MomoColors.surfaceLight.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isReady
                        ? MomoColors.success.withValues(alpha: 0.15)
                        : MomoColors.surfaceLight.withValues(alpha: 0.5),
                  ),
                  child: Icon(
                    isReady ? Icons.memory_rounded : Icons.download_for_offline_outlined,
                    color: isReady ? MomoColors.success : MomoColors.textMuted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Inference Runtime',
                        style: MomoTypography.labelLarge.copyWith(
                          color: isReady ? MomoColors.success : MomoColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isReady
                            ? 'Runtime loaded — offline generation enabled'
                            : 'Required once for offline generation (~70 MB)',
                        style: MomoTypography.bodySmall.copyWith(
                          color: MomoColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isReady)
                  const Icon(Icons.check_circle_rounded, color: MomoColors.success, size: 20),
              ],
            ),
            if (isDownloading) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: runtimeMgr.downloadProgress.value,
                  minHeight: 5,
                  backgroundColor: MomoColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(MomoColors.primary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                runtimeMgr.progressLabel,
                style: MomoTypography.labelSmall.copyWith(
                  color: MomoColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
            if (runtimeMgr.errorMessage.value != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${runtimeMgr.errorMessage.value}',
                style: MomoTypography.labelSmall.copyWith(
                  color: MomoColors.error,
                  fontSize: 10,
                ),
              ),
            ],
            if (!isReady && !isDownloading) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => runtimeMgr.downloadRuntime(),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: MomoColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Download AI Runtime',
                            style: MomoTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MomoColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MomoColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: MomoColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Models are downloaded once and stored locally. Once loaded, you can generate unlimited images completely offline — no internet required. Each model is 2–4 GB.',
              style: MomoTypography.bodySmall.copyWith(
                color: MomoColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _modelGradient(String id) {
    switch (id) {
      case 'absolute_reality':
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cyberrealistic':
        return const LinearGradient(
          colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'dreamshaper_lcm':
        return const LinearGradient(
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'realistic_vision':
        return const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return MomoColors.primaryGradient;
    }
  }

  String _modelEmoji(String id) {
    switch (id) {
      case 'absolute_reality':
        return '📸';
      case 'cyberrealistic':
        return '🎬';
      case 'dreamshaper_lcm':
        return '⚡';
      case 'realistic_vision':
        return '🌿';
      default:
        return '🎨';
    }
  }
}
