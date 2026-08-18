import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../momo_ui/theme/momo_theme.dart';
import '../../../../momo_ui/cards/momo_glass_card.dart';
import '../../models/app_model_item.dart';
import '../../../shell/navigation_controller.dart';

/// Reusable model card widget for Hub surface.
class ModelCard extends StatelessWidget {
  final AppModelItem model;
  final NavigationController controller;

  const ModelCard({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MomoGlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: model.type == 'Text LLM'
                    ? MomoColors.violet.withOpacity(0.2)
                    : MomoColors.rose.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                model.type,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: model.type == 'Text LLM'
                      ? MomoColors.violet
                      : MomoColors.rose,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(model.sizeStr,
                style: const TextStyle(
                    color: MomoColors.textSecondary, fontSize: 11)),
            const Spacer(),
            // ── Action Buttons & Status ──
            Obx(() {
              // 1. Downloaded State
              if (model.isDownloaded.value) {
                final isText = model.type == 'Text LLM';
                final isActive = isText
                    ? controller.activeModel.value?.id == model.id
                    : controller.activeImageModel.value?.id == model.id;

                if (isActive) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isText ? const Color(0xFF10B981) : MomoColors.rose)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: (isText
                                  ? const Color(0xFF10B981)
                                  : MomoColors.rose)
                              .withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            color: isText
                                ? const Color(0xFF10B981)
                                : MomoColors.rose,
                            size: 14),
                        const SizedBox(width: 4),
                        Text(
                          isText ? 'Active Brain' : 'Active Studio',
                          style: TextStyle(
                              color: isText
                                  ? const Color(0xFF10B981)
                                  : MomoColors.rose,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                // Downloaded but not active -> Show "Load" button
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isText
                        ? const Color(0xFF10B981)
                        : MomoColors.rose,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => isText
                      ? controller.loadModelForChat(model)
                      : controller.loadModelForStudio(model),
                  child: Text(
                    isText ? '⚡ Load for Chat' : '🎨 Use in Studio',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                );
              }

              // 2. Downloading State
              if (model.isDownloading.value) {
                return Row(
                  children: [
                    _iconBtn(
                        Icons.pause_circle_outline,
                        MomoColors.amber,
                        () => controller.pauseDownload(model)),
                    const SizedBox(width: 6),
                    _iconBtn(
                        Icons.stop_circle_outlined,
                        MomoColors.rose,
                        () => controller.stopDownload(model)),
                    const SizedBox(width: 6),
                    Text(
                      '${(model.downloadProgress.value * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: MomoColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }

              // 3. Paused / Not Started State
              return Row(
                children: [
                  if (model.isPaused.value) ...[
                    _iconBtn(
                        Icons.stop_circle_outlined,
                        MomoColors.rose,
                        () => controller.stopDownload(model)),
                    const SizedBox(width: 6),
                  ],
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: model.isPaused.value
                          ? MomoColors.amber
                          : MomoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => controller.startDownload(model),
                    child: Text(
                      model.isPaused.value ? '▶ Resume' : 'Download',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            }),
          ]),
          const SizedBox(height: 8),
          Text(model.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(model.description,
              style: const TextStyle(
                  color: MomoColors.textSecondary, fontSize: 12)),

          // ── Progress Bar & Status Text ──
          Obx(() {
            if (!model.isDownloading.value && !model.isPaused.value) {
              return const SizedBox.shrink();
            }
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          model.isPaused.value
                              ? MomoColors.amber
                              : MomoColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      model.statusMessage.value,
                      style: TextStyle(
                        fontSize: 11,
                        color: model.isPaused.value
                            ? MomoColors.amber
                            : MomoColors.textSecondary,
                      ),
                    ),
                  ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 24),
    );
  }
}
