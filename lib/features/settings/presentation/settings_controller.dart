import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../momo_core/momo_core.dart';
import '../../../momo_ui/theme/momo_colors.dart';

class SettingsController extends GetxController {
  final SecurityEngine _securityEngine = Get.find<SecurityEngine>();
  final DeviceEngine _deviceEngine = Get.find<DeviceEngine>();

  final developerName = "MomoAI User".obs;
  final developerRole = "Local AI Explorer".obs;

  // Sandbox paths
  final appDocsPath = "".obs;
  final modelsPath = "".obs;

  // Real-time telemetry observables mapping from DeviceEngine
  final batteryLevel = 1.0.obs;
  final isCharging = false.obs;
  final thermalState = "COOL".obs;

  // RAM availability
  final totalRam = 0.obs;
  final availableRam = 0.obs;
  final ramUsagePercentage = 0.0.obs;

  // Theme settings
  final activeTheme = "Cosmic Obsidian".obs;

  @override
  void onInit() {
    super.onInit();
    _loadSandboxPaths();
    _loadDeviceRamInfo();
    
    // Bind dynamic physical sensors reactively
    batteryLevel.value = _deviceEngine.batteryLevel;
    isCharging.value = _deviceEngine.isCharging;
    thermalState.value = _deviceEngine.thermalState.name.toUpperCase();

    ever(_deviceEngine.rxBatteryLevel, (val) => batteryLevel.value = val);
    ever(_deviceEngine.rxIsCharging, (val) => isCharging.value = val);
    ever(_deviceEngine.rxThermalState, (val) => thermalState.value = val.name.toUpperCase());
    
    // Periodically refresh RAM info
    interval(
      _deviceEngine.rxBatteryLevel,
      (_) => _loadDeviceRamInfo(),
      time: const Duration(seconds: 5),
    );
  }

  Future<void> _loadSandboxPaths() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      appDocsPath.value = docsDir.path;
      modelsPath.value = "${docsDir.path}/babymomo/models";
    } catch (e) {
      appDocsPath.value = "Unavailable";
      modelsPath.value = "Unavailable";
    }
  }

  void _loadDeviceRamInfo() {
    final profile = _deviceEngine.profile;
    if (profile != null) {
      totalRam.value = profile.totalRamMB;
      availableRam.value = profile.availableRamMB;
      if (profile.totalRamMB > 0) {
        ramUsagePercentage.value = 1.0 - (profile.availableRamMB / profile.totalRamMB);
      }
    } else {
      totalRam.value = 4096;
      availableRam.value = 2048;
      ramUsagePercentage.value = 0.5;
    }
  }

  Future<void> triggerKeystoreWipe() async {
    try {
      await _securityEngine.wipeSecureStorage();
      Get.snackbar(
        "Security Reset",
        "Android Keystore keys and all secure local settings wiped successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFC94F7C).withValues(alpha: 0.9),
        colorText: const Color(0xFFF5F5FA),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        "Reset Error",
        "Failed to wipe secure Keystore: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF5252).withValues(alpha: 0.9),
        colorText: const Color(0xFFF5F5FA),
      );
    }
  }

  void changeThemeAccent(String themeName) {
    activeTheme.value = themeName;
    Get.snackbar(
      "Theme Switched",
      "Accent palette set to $themeName.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF7C4DFF).withValues(alpha: 0.9),
      colorText: const Color(0xFFF5F5FA),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> recalibrateTelemetry() async {
    // Invoke native profiling to refresh battery and environment states
    await _deviceEngine.refreshTelemetry();

    // Refresh RAM info
    _loadDeviceRamInfo();
    
    // Read reactive fields directly from DeviceEngine to force refresh
    batteryLevel.value = _deviceEngine.batteryLevel;
    isCharging.value = _deviceEngine.isCharging;
    thermalState.value = _deviceEngine.thermalState.name.toUpperCase();
    
    Get.snackbar(
      "Telemetry Calibrated",
      "Native sensor states re-aligned successfully. Current core: ${thermalState.value} at ${(batteryLevel.value * 100).toInt()}% battery.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: MomoColors.surface.withValues(alpha: 0.9),
      colorText: MomoColors.textPrimary,
      icon: const Icon(Icons.tune_rounded, color: MomoColors.success),
      duration: const Duration(seconds: 3),
    );
  }
}

