import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../momo_ui/theme/momo_colors.dart';
import '../../../momo_ui/theme/momo_typography.dart';
import '../../../momo_core/momo_core.dart';
import 'model_hub_controller.dart';

/// A premium, glassmorphic space to manage on-device LLMs.
/// Displays physical RAM gauges, thermal states, and real-time JNI console logs.
class ModelHubPage extends GetView<ModelHubController> {
  final bool isTab;
  const ModelHubPage({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    // We instantiate a ScrollController for the logs console
    final logScrollController = ScrollController();

    // Auto-scroll log feed to the bottom whenever logs update
    ever(controller.systemLogs, (_) {
      if (logScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 50), () {
          logScrollController.animateTo(
            logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        });
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: MomoColors.surfaceGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Premium Header ───
              _buildHeader(context),

              // ─── Main Content ───
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      
                      // 1. Live Hardware Telemetry
                      _buildHardwareTelemetry(context),
                      
                      const SizedBox(height: 24),
                      
                      // Section Title
                      Text(
                        'On-Device Brains',
                        style: MomoTypography.displaySmall.copyWith(
                          color: MomoColors.textPrimary,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 12),

                      // 2. Model Cards list
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.models.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (c, idx) {
                          final model = controller.models[idx];
                          return _buildModelCard(context, model);
                        },
                      ),
                      
                      const SizedBox(height: 28),

                      // 3. JNI Native Platform Console
                      _buildConsoleLogs(context, logScrollController),

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

  // ─── Header Component ───
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
      child: Row(
        children: [
          if (!isTab) ...[
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: MomoColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Model Hub',
                style: MomoTypography.displayMedium.copyWith(
                  color: MomoColors.textPrimary,
                ),
              ),
              Text(
                'Swap brains, download models, go offline',
                style: MomoTypography.bodySmall.copyWith(
                  color: MomoColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Native Bridge Status indicator & Cloud Hybrid Interactive Toggle
          Obx(() {
            final activeModel = controller.models.firstWhereOrNull((m) => m.isActive.value);
            final hasActive = activeModel != null;
            
            final String label;
            final Color indicatorColor;
            final Color bgCol;
            final Color borderCol;
            final List<BoxShadow>? shadow;

            if (hasActive) {
              label = 'Local Active';
              indicatorColor = MomoColors.success;
              bgCol = MomoColors.success.withValues(alpha: 0.1);
              borderCol = MomoColors.success.withValues(alpha: 0.3);
              shadow = [
                BoxShadow(
                  color: MomoColors.success.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ];
            } else if (controller.isCloudHybrid.value) {
              label = 'Cloud Hybrid';
              indicatorColor = MomoColors.primary;
              bgCol = MomoColors.primary.withValues(alpha: 0.1);
              borderCol = MomoColors.primary.withValues(alpha: 0.3);
              shadow = [
                BoxShadow(
                  color: MomoColors.primary.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ];
            } else {
              label = 'Local Only';
              indicatorColor = MomoColors.error;
              bgCol = MomoColors.error.withValues(alpha: 0.08);
              borderCol = MomoColors.error.withValues(alpha: 0.3);
              shadow = null;
            }

            return GestureDetector(
              onTap: () {
                controller.toggleCloudHybrid();
                Get.snackbar(
                  'Inference Mode Updated',
                  controller.isCloudHybrid.value
                      ? 'Cloud Hybrid mode enabled. Momo will fall back to cloud intelligence if local brains are offline. 🌐'
                      : 'Local Only mode enabled. Momo will only operate on-device. 🔒',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: MomoColors.surface.withValues(alpha: 0.9),
                  colorText: MomoColors.textPrimary,
                  duration: const Duration(seconds: 3),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bgCol,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderCol,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: indicatorColor,
                        boxShadow: shadow,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: MomoTypography.labelSmall.copyWith(
                        color: indicatorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Hardware Telemetry Panel ───
  Widget _buildHardwareTelemetry(BuildContext context) {
    return Obx(() {
      final profile = controller.deviceProfile;
      if (profile == null) {
        return const Center(child: CircularProgressIndicator(color: MomoColors.primary));
      }

      final ramTotalGB = profile.totalRamMB / 1024.0;
      final ramAvailableGB = profile.availableRamMB / 1024.0;
      final ramUsedGB = ramTotalGB - ramAvailableGB;
      final ramPercentage = ramTotalGB > 0 ? (ramUsedGB / ramTotalGB) : 0.0;

      // Thermal states styling
      Color thermalColor = MomoColors.success;
      String thermalLabel = 'Nominal';
      switch (controller.thermalState) {
        case ThermalState.light:
          thermalColor = MomoColors.warning;
          thermalLabel = 'Light Warm';
          break;
        case ThermalState.moderate:
          thermalColor = MomoColors.warning;
          thermalLabel = 'Moderate';
          break;
        case ThermalState.severe:
          thermalColor = MomoColors.error;
          thermalLabel = 'Severe';
          break;
        case ThermalState.critical:
          thermalColor = MomoColors.error;
          thermalLabel = 'Critical';
          break;
        case ThermalState.shutdown:
          thermalColor = MomoColors.error;
          thermalLabel = 'Shutdown';
          break;
        case ThermalState.nominal:
          thermalColor = MomoColors.success;
          thermalLabel = 'Cool';
          break;
      }

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: MomoColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: MomoColors.surfaceLight,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.developer_board_rounded,
                  color: MomoColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hardware Diagnostics',
                  style: MomoTypography.labelLarge.copyWith(
                    color: MomoColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            
            // RAM Usage Gauge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Memory (RAM)',
                  style: MomoTypography.bodySmall.copyWith(
                    color: MomoColors.textSecondary,
                  ),
                ),
                Text(
                  '${ramUsedGB.toStringAsFixed(1)} / ${ramTotalGB.toStringAsFixed(1)} GB (${(ramPercentage * 100).toInt()}%)',
                  style: MomoTypography.labelMedium.copyWith(
                    color: MomoColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ramPercentage,
                minHeight: 8,
                backgroundColor: MomoColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ramPercentage > 0.85
                      ? MomoColors.error
                      : (ramPercentage > 0.7 ? MomoColors.warning : MomoColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Secondary Stats Row
            Row(
              children: [
                // CPU Cores Chip
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: MomoColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.memory_rounded, color: MomoColors.textSecondary, size: 16),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cores', style: MomoTypography.labelSmall.copyWith(color: MomoColors.textMuted)),
                            Text('${profile.cpuCores} Threads', style: MomoTypography.labelMedium.copyWith(color: MomoColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Thermals Chip
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: MomoColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.thermostat_rounded, color: thermalColor, size: 16),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Thermal', style: MomoTypography.labelSmall.copyWith(color: MomoColors.textMuted)),
                            Text(
                              thermalLabel,
                              style: MomoTypography.labelMedium.copyWith(color: thermalColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Power/Battery Chip
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: MomoColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          controller.isCharging ? Icons.battery_charging_full_rounded : Icons.battery_std_rounded,
                          color: controller.batteryLevel > 0.2 ? MomoColors.success : MomoColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Battery', style: MomoTypography.labelSmall.copyWith(color: MomoColors.textMuted)),
                            Text(
                              '${(controller.batteryLevel * 100).toInt()}%',
                              style: MomoTypography.labelMedium.copyWith(color: MomoColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.1);
    });
  }

  // ─── Dynamic Model Card Builder ───
  Widget _buildModelCard(BuildContext context, LocalModelUiModel model) {
    final isLocked = controller.isLockedDueToRAM(model);

    return Obx(() {
      final isActive = model.isActive.value;
      final isLoading = model.isLoading.value;

      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: MomoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? MomoColors.primary.withValues(alpha: 0.5)
                : MomoColors.surfaceLight,
            width: isActive ? 1.5 : 1.0,
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
        child: Stack(
          children: [
            // Card Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Specs Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.name,
                            style: MomoTypography.displaySmall.copyWith(
                              color: isLocked ? MomoColors.textMuted : MomoColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Parameter Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: MomoColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  model.quantization,
                                  style: MomoTypography.labelSmall.copyWith(
                                    color: MomoColors.textSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // File Size
                              Text(
                                model.size,
                                style: MomoTypography.bodySmall.copyWith(
                                  color: MomoColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Tier Chip
                      _buildTierChip(model.tierName),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    model.description,
                    style: MomoTypography.bodyMedium.copyWith(
                      color: isLocked ? MomoColors.textMuted.withValues(alpha: 0.6) : MomoColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // System requirement info
                  Row(
                    children: [
                      Icon(
                        Icons.memory_rounded,
                        color: isLocked ? MomoColors.error : MomoColors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Requires ${model.ramRequiredGB.toStringAsFixed(1)} GB System RAM',
                        style: MomoTypography.bodySmall.copyWith(
                          color: isLocked ? MomoColors.error : MomoColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ─── Actions & Progress Area ───
                  (() {
                    final status = controller.getModelDownloadStatus(model.id);

                    if (status == DownloadStatus.downloading) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Streaming from HuggingFace...',
                                style: MomoTypography.bodySmall.copyWith(color: MomoColors.textSecondary),
                              ),
                              Text(
                                '${(controller.downloadProgress.value * 100).toInt()}%',
                                style: MomoTypography.labelMedium.copyWith(color: MomoColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: MomoColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: controller.downloadProgress.value,
                                minHeight: 8,
                                backgroundColor: MomoColors.surfaceLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(MomoColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                controller.downloadSpeed.value,
                                style: MomoTypography.bodySmall.copyWith(color: MomoColors.textMuted),
                              ),
                              Text(
                                controller.downloadEta.value,
                                style: MomoTypography.bodySmall.copyWith(color: MomoColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => controller.pauseDownload(model),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MomoColors.surfaceLight,
                                    foregroundColor: MomoColors.textPrimary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.pause_rounded, size: 18),
                                  label: Text(
                                    'Pause Download',
                                    style: MomoTypography.labelMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    if (status == DownloadStatus.hashing) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: MomoColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: MomoColors.warning.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: MomoColors.warning.withValues(alpha: 0.15),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.security_rounded,
                              color: MomoColors.warning,
                              size: 20,
                            ).animate(onPlay: (c) => c.repeat(reverse: true))
                             .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 600.ms),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SHA-256 Verifying...',
                                    style: MomoTypography.labelMedium.copyWith(
                                      color: MomoColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Asynchronous Kotlin coroutine validating GGUF integrity.',
                                    style: MomoTypography.bodySmall.copyWith(
                                      color: MomoColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(controller.downloadProgress.value * 100).toInt()}%',
                              style: MomoTypography.labelLarge.copyWith(
                                color: MomoColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .shimmer(duration: 2000.ms, color: MomoColors.warning.withValues(alpha: 0.2));
                    }

                    if (status == DownloadStatus.pending) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: MomoColors.surfaceLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: MomoColors.primary.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(MomoColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'QUEUED (FIFO Queue)',
                                    style: MomoTypography.labelMedium.copyWith(
                                      color: MomoColors.primaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Waiting for active tasks to yield bandwidth.',
                                    style: MomoTypography.bodySmall.copyWith(
                                      color: MomoColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => controller.deleteModel(model),
                              icon: const Icon(Icons.close_rounded, color: MomoColors.textSecondary, size: 18),
                            ),
                          ],
                        ),
                      );
                    }

                    if (status == DownloadStatus.paused) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: MomoColors.surfaceLight.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.pause_circle_filled_rounded, color: MomoColors.textSecondary, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Download Suspended',
                                  style: MomoTypography.labelSmall.copyWith(color: MomoColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isLocked ? null : () => controller.downloadModel(model),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MomoColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                  label: Text(
                                    'Resume Download',
                                    style: MomoTypography.labelMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => controller.deleteModel(model),
                                style: IconButton.styleFrom(
                                  backgroundColor: MomoColors.surfaceLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: MomoColors.error,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    if (status == DownloadStatus.failed) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: MomoColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: MomoColors.error.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: MomoColors.error, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'INTEGRITY VERIFICATION FAILED',
                                        style: MomoTypography.labelSmall.copyWith(
                                          color: MomoColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        controller.getModelDownloadError(model.id) ?? 'Corrupted weight file detected.',
                                        style: MomoTypography.bodySmall.copyWith(
                                          color: MomoColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isLocked ? null : () => controller.downloadModel(model),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MomoColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.replay_rounded, size: 18),
                                  label: Text(
                                    'Retry Download',
                                    style: MomoTypography.labelMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => controller.deleteModel(model),
                                style: IconButton.styleFrom(
                                  backgroundColor: MomoColors.surfaceLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: MomoColors.error,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // Default Not-Downloaded / Standard States
                    return Row(
                      children: [
                        if (!model.isDownloaded.value) ...[
                          // Action: Download / Queue
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLocked
                                  ? null
                                  : () => controller.downloadModel(model),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: controller.isDownloading.value ? MomoColors.surfaceLight : MomoColors.primary,
                                foregroundColor: controller.isDownloading.value ? MomoColors.textPrimary : Colors.white,
                                disabledBackgroundColor: MomoColors.surfaceLight,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: Icon(
                                controller.isDownloading.value ? Icons.queue_play_next_rounded : Icons.download_rounded,
                                size: 18,
                                color: controller.isDownloading.value ? MomoColors.primary : Colors.white,
                              ),
                              label: Text(
                                isLocked
                                    ? 'Hardware Locked'
                                    : (controller.isDownloading.value ? 'Queue Download' : 'Download Local Package'),
                                style: MomoTypography.labelMedium.copyWith(
                                  color: isLocked
                                      ? MomoColors.textMuted
                                      : (controller.isDownloading.value ? MomoColors.textPrimary : Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Action: Load / Active toggle
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (isActive) {
                                        controller.unloadModel(model);
                                      } else {
                                        controller.loadModel(model);
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isActive ? MomoColors.accent : MomoColors.primary,
                                  width: 1,
                                ),
                                foregroundColor: isActive ? MomoColors.accent : MomoColors.primary,
                                disabledForegroundColor: MomoColors.textMuted,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: MomoColors.primary,
                                      ),
                                    )
                                  : Icon(
                                      isActive ? Icons.power_settings_new_rounded : Icons.bolt_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                isLoading
                                    ? 'Connecting...'
                                    : (isActive ? 'Unload Weight' : 'Mount Local Companion'),
                                style: MomoTypography.labelMedium,
                              ),
                            ),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 8),
                            // Small delete icon button
                            IconButton(
                              onPressed: isLoading ? null : () => controller.deleteModel(model),
                              style: IconButton.styleFrom(
                                backgroundColor: MomoColors.surfaceLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(12),
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: MomoColors.error,
                                size: 20,
                              ),
                            ),
                          ],
                        ]
                      ],
                    );
                  })(),
                ],
              ),
            ),
            
            // Lock Overlay if not enough RAM
            if (isLocked)
              Positioned.fill(
                child: Container(
                  color: MomoColors.background.withValues(alpha: 0.55),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: MomoColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: MomoColors.error.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            color: MomoColors.error,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Needs ${model.ramRequiredGB}GB RAM',
                            style: MomoTypography.labelSmall.copyWith(
                              color: MomoColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Loading state glowing border overlay
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: MomoColors.surface.withValues(alpha: 0.6),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: MomoColors.primary,
                        ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1000.ms),
                        const SizedBox(height: 12),
                        Text(
                          isActive ? 'Freeing Physical Memory...' : 'Mounting Native Arena...',
                          style: MomoTypography.labelSmall.copyWith(
                            color: MomoColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  // Tier Chip display styling (Fast/Balanced/Quality)
  Widget _buildTierChip(String tier) {
    Color chipBg = MomoColors.surfaceLight;
    Color chipText = MomoColors.textSecondary;

    switch (tier) {
      case 'Fast':
        chipBg = MomoColors.info.withValues(alpha: 0.1);
        chipText = MomoColors.info;
        break;
      case 'Balanced':
        chipBg = MomoColors.primary.withValues(alpha: 0.1);
        chipText = MomoColors.primary;
        break;
      case 'High Quality':
        chipBg = MomoColors.accent.withValues(alpha: 0.1);
        chipText = MomoColors.accent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tier,
        style: MomoTypography.labelSmall.copyWith(
          color: chipText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── JNI System Terminal Logs Component ───
  Widget _buildConsoleLogs(BuildContext context, ScrollController scrollController) {
    return Obx(() {
      final logs = controller.systemLogs;

      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF070710), // Ultra dark console back
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MomoColors.surfaceLight,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Console Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0F0F1F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.terminal_rounded,
                    color: MomoColors.success,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Native LLM Telemetry (JNI Link)',
                    style: MomoTypography.code.copyWith(
                      color: MomoColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Glowing green active pulse
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: MomoColors.success,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.5, 1.5),
                        duration: 800.ms,
                      ),
                ],
              ),
            ),
            
            // Console logs feed list
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'Telemetry quiet...',
                        style: MomoTypography.code.copyWith(color: MomoColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: logs.length,
                      itemBuilder: (c, idx) {
                        final logText = logs[idx];
                        // Highlight JNI system warnings in gold or errors in red
                        Color textColor = MomoColors.textSecondary;
                        if (logText.contains('Allocating') || logText.contains('Mounting')) {
                          textColor = MomoColors.primaryLight;
                        } else if (logText.contains('complete') || logText.contains('mounted')) {
                          textColor = MomoColors.success;
                        } else if (logText.contains('Error') || logText.contains('Failed')) {
                          textColor = MomoColors.error;
                        } else if (logText.contains('Warning')) {
                          textColor = MomoColors.warning;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            logText,
                            style: MomoTypography.code.copyWith(
                              color: textColor,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.15);
    });
  }
}
