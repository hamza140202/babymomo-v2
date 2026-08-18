/// MOMO Core — Device Profile model.
///
/// Represents the device's hardware capabilities.
/// Used by [InferencePolicy] to select the best runtime,
/// and by [DeviceEngine] to adapt behavior.
class DeviceProfile {
  /// Total device RAM in MB.
  final int totalRamMB;

  /// Available (free) RAM in MB.
  final int availableRamMB;

  /// GPU name/type (e.g. 'Adreno 740', 'Mali-G720')
  final String? gpuName;

  /// Whether Vulkan GPU acceleration is supported.
  final bool vulkanSupported;

  /// Number of CPU cores.
  final int cpuCores;

  /// CPU architecture (e.g. 'arm64-v8a')
  final String cpuArchitecture;

  /// Android SDK version.
  final int sdkVersion;

  /// Device model name.
  final String deviceModel;

  /// Device manufacturer.
  final String manufacturer;

  /// Current battery level (0.0 - 1.0).
  final double batteryLevel;

  /// Whether device is currently charging.
  final bool isCharging;

  /// Current thermal state.
  final ThermalState thermalState;

  const DeviceProfile({
    required this.totalRamMB,
    required this.availableRamMB,
    this.gpuName,
    this.vulkanSupported = false,
    required this.cpuCores,
    this.cpuArchitecture = 'arm64-v8a',
    required this.sdkVersion,
    required this.deviceModel,
    required this.manufacturer,
    this.batteryLevel = 1.0,
    this.isCharging = false,
    this.thermalState = ThermalState.nominal,
  });

  /// Can this device run local inference at all?
  bool get canRunLocalInference => totalRamMB >= 3072; // 3GB minimum

  /// Suggested thread count based on CPU cores.
  int get suggestedThreadCount => (cpuCores * 0.75).ceil().clamp(2, 8);

  /// Is the device thermally throttled?
  bool get isThrottled =>
      thermalState == ThermalState.severe ||
      thermalState == ThermalState.critical;
}

/// Thermal states — mapped from Android ThermalManager.
enum ThermalState {
  nominal,
  light,
  moderate,
  severe,
  critical,
  shutdown,
}
