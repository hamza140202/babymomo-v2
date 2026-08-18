import 'package:pigeon/pigeon.dart';

/// Pigeon API — Device Bridge.
///
/// Type-safe bridge for device hardware profiling from native Android.
/// Provides accurate RAM, GPU, CPU, thermal, and battery information
/// that cannot be obtained from pure Dart.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/momo_core/bridge/device_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/momoai/babymomo/pigeon/device/DeviceApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.momoai.babymomo.pigeon.device'),
))

/// Device hardware profile from native.
class NativeDeviceProfile {
  final int totalRamMB;
  final int availableRamMB;
  final String? gpuName;
  final bool vulkanSupported;
  final int cpuCores;
  final String cpuArchitecture;
  final int sdkVersion;
  final String deviceModel;
  final String manufacturer;

  NativeDeviceProfile({
    required this.totalRamMB,
    required this.availableRamMB,
    this.gpuName,
    required this.vulkanSupported,
    required this.cpuCores,
    required this.cpuArchitecture,
    required this.sdkVersion,
    required this.deviceModel,
    required this.manufacturer,
  });
}

/// Battery state from native.
class NativeBatteryState {
  final double level; // 0.0 - 1.0
  final bool isCharging;

  NativeBatteryState({
    required this.level,
    required this.isCharging,
  });
}

/// Flutter → Native: Device profiling.
@HostApi()
abstract class DeviceHostApi {
  /// Get full device hardware profile.
  @async
  NativeDeviceProfile getDeviceProfile();

  /// Get current battery state.
  @async
  NativeBatteryState getBatteryState();

  /// Get available storage in MB.
  @async
  int getAvailableStorageMB();
}

/// Native → Flutter: Device state change callbacks.
@FlutterApi()
abstract class DeviceFlutterApi {
  /// Called when thermal state changes.
  void onThermalStateChanged(int thermalState);

  /// Called when battery state changes significantly.
  void onBatteryStateChanged(double level, bool isCharging);
}
