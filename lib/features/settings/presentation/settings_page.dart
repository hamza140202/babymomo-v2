import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../momo_ui/theme/momo_colors.dart';
import '../../../momo_ui/theme/momo_typography.dart';
import 'settings_controller.dart';
import '../../image_gen/sd_models/sd_model_controller.dart';
import '../../image_gen/sd_models/sd_models_sheet.dart';

class SettingsPage extends GetView<SettingsController> {
  final bool isTab;
  const SettingsPage({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: MomoColors.surfaceGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              // Scrollable settings list
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      
                      // 1. Tycoon Developer Profile Card
                      _buildProfileCard(),

                      const SizedBox(height: 20),

                      // 2. Hardware Live Telemetry Card
                      _buildTelemetryCard(),

                      const SizedBox(height: 20),

                      // Visual Engine Specifications Card
                      _buildVisualEngineCard(),

                      const SizedBox(height: 20),

                      // 3. Sandbox Paths
                      _buildSandboxPathsCard(),

                      const SizedBox(height: 20),

                      // 4. Accent Theme Selector
                      _buildThemeSelector(),

                      const SizedBox(height: 20),

                      // 5. Keystore Reset & Destruction Zone
                      _buildSecurityCard(),

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
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
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
                'Settings',
                style: MomoTypography.displayMedium.copyWith(
                  color: MomoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              Text(
                'Fine-tune your experience',
                style: MomoTypography.bodySmall.copyWith(
                  color: MomoColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MomoColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: MomoColors.surfaceLight.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Elegant Tycoon Avatar with leaf sprout indicator
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: MomoColors.warmGradient,
                  boxShadow: [
                    BoxShadow(
                      color: MomoColors.accent.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.face_retouching_natural_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              // Cute sprout leaf
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: MomoColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.15, 1.15),
                    duration: 1000.ms,
                  ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      controller.developerName.value,
                      style: MomoTypography.displaySmall.copyWith(
                        color: MomoColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                const SizedBox(height: 4),
                Obx(() => Text(
                      controller.developerRole.value,
                      style: MomoTypography.bodySmall.copyWith(
                        color: MomoColors.primaryLight,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MomoColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: MomoColors.warning, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Runs On-Device · No Cloud',
                        style: MomoTypography.labelSmall.copyWith(
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
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildTelemetryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MomoColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: MomoColors.surfaceLight.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: MomoColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Live Environment Telemetry',
                style: MomoTypography.displaySmall.copyWith(
                  color: MomoColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // RAM Usage Indicator
          Obx(() {
            final usedPercent = controller.ramUsagePercentage.value;
            final usedMB = controller.totalRam.value - controller.availableRam.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DEVICE RAM ALLOCATION',
                      style: MomoTypography.labelSmall.copyWith(
                        color: MomoColors.textMuted,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      '${usedMB}MB / ${controller.totalRam.value}MB',
                      style: MomoTypography.labelSmall.copyWith(
                        color: MomoColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: usedPercent,
                    minHeight: 8,
                    backgroundColor: MomoColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(MomoColors.primary),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 16),

          // Battery and Thermal details
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  final isChg = controller.isCharging.value;
                  final level = (controller.batteryLevel.value * 100).toInt();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MomoColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isChg ? Icons.battery_charging_full_rounded : Icons.battery_std_rounded,
                          color: MomoColors.success,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BATTERY',
                              style: MomoTypography.labelSmall.copyWith(
                                color: MomoColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              '$level% ${isChg ? 'Charging' : 'On Battery'}',
                              style: MomoTypography.labelMedium.copyWith(
                                color: MomoColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() {
                  final state = controller.thermalState.value;
                  Color thermalColor = MomoColors.success;
                  if (state == "SEVERE" || state == "CRITICAL") {
                    thermalColor = MomoColors.error;
                  } else if (state == "MODERATE" || state == "LIGHT") {
                    thermalColor = MomoColors.warning;
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MomoColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.thermostat_rounded,
                          color: thermalColor,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'THERMAL STATE',
                              style: MomoTypography.labelSmall.copyWith(
                                color: MomoColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              state,
                              style: MomoTypography.labelMedium.copyWith(
                                color: MomoColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: MomoColors.surfaceLight.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: MomoColors.textMuted, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Virtualized settings can cause dynamic sensor drift. Tap CALIBRATE to force resync.',
                  style: MomoTypography.labelSmall.copyWith(
                    color: MomoColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => controller.recalibrateTelemetry(),
                style: TextButton.styleFrom(
                  backgroundColor: MomoColors.primary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'CALIBRATE',
                  style: MomoTypography.labelSmall.copyWith(
                    color: MomoColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildVisualEngineCard() {
    return Builder(builder: (context) {
      // SdModelController may not be registered if user hasn't opened ImageGen yet
      final sdCtrl = Get.isRegistered<SdModelController>()
          ? Get.find<SdModelController>()
          : null;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MomoColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: MomoColors.surfaceLight.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette_rounded, color: MomoColors.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Visual Engine',
                    style: MomoTypography.displaySmall.copyWith(
                      color: MomoColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => SdModelsSheet.show(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: MomoColors.warmGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Manage Models',
                      style: MomoTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Active SD model (reactive)
            if (sdCtrl != null)
              Obx(() {
                final activeId = sdCtrl.activeModelId.value;
                final activeModel = sdCtrl.activeModel?.model;
                final downloaded = sdCtrl.downloadedCount;
                final totalGB = sdCtrl.totalDownloadedGB;
                final libAvailable = sdCtrl.nativeLibAvailable.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpecRow(
                      'ACTIVE LOCAL MODEL',
                      activeId != null && activeModel != null
                          ? '${activeModel.name} v${activeModel.version}'
                          : 'None (Using online fallback)',
                    ),
                    const SizedBox(height: 12),
                    _buildSpecRow(
                      'INFERENCE MODE',
                      activeId != null && libAvailable
                          ? '🔒 Fully Offline (stable-diffusion.cpp)'
                          : activeId != null
                              ? '🌐 Online Fallback (native lib pending)'
                              : '🌐 Pollinations AI (Cloud)',
                    ),
                    const SizedBox(height: 12),
                    _buildSpecRow(
                      'DOWNLOADED MODELS',
                      '$downloaded / ${sdCtrl.modelStates.length} models  (${totalGB.toStringAsFixed(1)} GB)',
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              })
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpecRow('ACTIVE LOCAL MODEL', 'Open Image Creator to configure'),
                  const SizedBox(height: 12),
                ],
              ),

            _buildSpecRow('ENGINE RUNTIME', 'stable-diffusion.cpp · 100% On-Device'),
            const SizedBox(height: 12),
            _buildSpecRow('CANVAS FALLBACK', 'Android Hardware Canvas Renderer'),
            const SizedBox(height: 12),
            _buildSpecRow('OUTPUT RESOLUTION', '432×768 / 512×512 / 768×432'),
            const SizedBox(height: 12),
            _buildSpecRow('SUPPORTED MODELS', 'SD 1.5 / SDXL / LCM safetensors'),
          ],
        ),
      ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1);
    });
  }


  Widget _buildSpecRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: MomoTypography.labelSmall.copyWith(
            color: MomoColors.textMuted,
            letterSpacing: 1.1,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: MomoTypography.bodyMedium.copyWith(
            color: MomoColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSandboxPathsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MomoColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: MomoColors.surfaceLight.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open_rounded, color: MomoColors.info, size: 22),
              const SizedBox(width: 10),
              Text(
                'Sandbox Engine Directories',
                style: MomoTypography.displaySmall.copyWith(
                  color: MomoColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildPathRow('APP DATA SANDBOX', controller.appDocsPath),
          const SizedBox(height: 14),
          _buildPathRow('ON-DEVICE BRAINS STORE', controller.modelsPath),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildPathRow(String label, RxString pathObs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: MomoTypography.labelSmall.copyWith(
            color: MomoColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Obx(() {
          final p = pathObs.value;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: MomoColors.surfaceLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MomoColors.surfaceLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chevron_right_rounded, color: MomoColors.info, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.isEmpty ? 'Loading path...' : p,
                    style: MomoTypography.code.copyWith(
                      color: MomoColors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildThemeSelector() {
    final themes = [
      {"name": "Cosmic Obsidian", "desc": "Premium glass dark obsidian", "icon": Icons.nightlight_round_rounded, "color": MomoColors.primary},
      {"name": "Neon Cyberpunk", "desc": "Glowing fluorescent purples and pinks", "icon": Icons.bolt_rounded, "color": MomoColors.accent},
      {"name": "Warm Amber Sunset", "desc": "Warm gold and sunset amber tone", "icon": Icons.wb_sunny_rounded, "color": MomoColors.warning},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MomoColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: MomoColors.surfaceLight.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_rounded, color: MomoColors.accent, size: 22),
              const SizedBox(width: 10),
              Text(
                'Theme Visual Accents',
                style: MomoTypography.displaySmall.copyWith(
                  color: MomoColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Column(
            children: themes.map((theme) {
              final name = theme['name'] as String;
              final desc = theme['desc'] as String;
              final icon = theme['icon'] as IconData;
              final accentColor = theme['color'] as Color;

              return Obx(() {
                final isSelected = controller.activeTheme.value == name;
                return GestureDetector(
                  onTap: () => controller.changeThemeAccent(name),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MomoColors.surfaceLight.withValues(alpha: 0.8)
                          : MomoColors.surfaceLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.6)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: MomoTypography.labelMedium.copyWith(
                                  color: MomoColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                desc,
                                style: MomoTypography.bodySmall.copyWith(
                                  color: MomoColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              });
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MomoColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: MomoColors.error.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gpp_maybe_rounded, color: MomoColors.error, size: 22),
              const SizedBox(width: 10),
              Text(
                'Security & Cryptographic Wipe',
                style: MomoTypography.displaySmall.copyWith(
                  color: MomoColors.error,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            'This zone triggers high-level storage clearing. Clicking the wipe button resets your secure keys stored under the physical Android KeyStore system, rendering all old encrypted databases useless. Proceed with caution.',
            style: MomoTypography.bodySmall.copyWith(
              color: MomoColors.textSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // Destruction Action Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.dialog(
                  AlertDialog(
                    backgroundColor: MomoColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: MomoColors.error, width: 1.5),
                    ),
                    title: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: MomoColors.error),
                        const SizedBox(width: 10),
                        Text(
                          'Confirm Master Wipe',
                          style: MomoTypography.displaySmall.copyWith(color: MomoColors.textPrimary),
                        ),
                      ],
                    ),
                    content: Text(
                      'Are you absolutely sure you want to wipe Android secure Keystore? This cannot be undone and will render current local chats and memory unreadable.',
                      style: MomoTypography.bodyMedium.copyWith(color: MomoColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'CANCEL',
                          style: MomoTypography.labelMedium.copyWith(color: MomoColors.textSecondary),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                          controller.triggerKeystoreWipe();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MomoColors.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'WIPE EVERYTHING',
                          style: MomoTypography.labelMedium.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MomoColors.error, Color(0xFFC94F7C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: MomoColors.error.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'WIPE SECURE STORAGE & KEYSTORE',
                        style: MomoTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1);
  }
}
