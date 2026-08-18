import 'package:get/get.dart';
import '../bridge/device_api.g.dart';
import 'device_profile.dart';

/// MOMO Core — Device Engine.
///
/// Profiles device hardware and monitors thermal/battery state.
/// Provides [DeviceProfile] to [InferencePolicy] for runtime selection.
class DeviceEngine extends GetxService implements DeviceFlutterApi {
  final _profile = Rxn<DeviceProfile>();
  final _thermalState = ThermalState.nominal.obs;
  final _batteryLevel = 1.0.obs;
  final _isCharging = false.obs;

  final _deviceHostApi = DeviceHostApi();

  DeviceProfile? get profile => _profile.value;
  ThermalState get thermalState => _thermalState.value;
  double get batteryLevel => _batteryLevel.value;
  bool get isCharging => _isCharging.value;

  RxDouble get rxBatteryLevel => _batteryLevel;
  RxBool get rxIsCharging => _isCharging;
  Rx<ThermalState> get rxThermalState => _thermalState;

  /// Initialize device profiling.
  Future<DeviceEngine> init() async {
    // Register FlutterApi receiver for callbacks from native Android
    DeviceFlutterApi.setUp(this);
    await _profileDevice();
    return this;
  }

  /// Manually trigger a refresh of native telemetry status.
  Future<void> refreshTelemetry() async {
    await _profileDevice();
  }

  Future<void> _profileDevice() async {
    try {
      final nativeProfile = await _deviceHostApi.getDeviceProfile();
      final battery = await _deviceHostApi.getBatteryState();

      _batteryLevel.value = battery.level;
      _isCharging.value = battery.isCharging;

      _profile.value = DeviceProfile(
        totalRamMB: nativeProfile.totalRamMB,
        availableRamMB: nativeProfile.availableRamMB,
        gpuName: nativeProfile.gpuName,
        vulkanSupported: nativeProfile.vulkanSupported,
        cpuCores: nativeProfile.cpuCores,
        cpuArchitecture: nativeProfile.cpuArchitecture,
        sdkVersion: nativeProfile.sdkVersion,
        deviceModel: nativeProfile.deviceModel,
        manufacturer: nativeProfile.manufacturer,
        batteryLevel: battery.level,
        isCharging: battery.isCharging,
        thermalState: _thermalState.value,
      );
    } catch (e) {
      // Fallback in case of simulator or test environments
      _profile.value = const DeviceProfile(
        totalRamMB: 4096,
        availableRamMB: 2048,
        cpuCores: 8,
        sdkVersion: 33,
        deviceModel: 'Android Simulator',
        manufacturer: 'Google',
      );
    }
  }

  /// Update thermal state (called from native thermal listener).
  void updateThermalState(ThermalState state) {
    _thermalState.value = state;
    if (_profile.value != null) {
      _profile.value = DeviceProfile(
        totalRamMB: _profile.value!.totalRamMB,
        availableRamMB: _profile.value!.availableRamMB,
        gpuName: _profile.value!.gpuName,
        vulkanSupported: _profile.value!.vulkanSupported,
        cpuCores: _profile.value!.cpuCores,
        cpuArchitecture: _profile.value!.cpuArchitecture,
        sdkVersion: _profile.value!.sdkVersion,
        deviceModel: _profile.value!.deviceModel,
        manufacturer: _profile.value!.manufacturer,
        batteryLevel: _batteryLevel.value,
        isCharging: _isCharging.value,
        thermalState: state,
      );
    }
  }

  // ─── DeviceFlutterApi Implementation ───

  @override
  void onThermalStateChanged(int thermalState) {
    final state = _mapThermalState(thermalState);
    updateThermalState(state);
  }

  @override
  void onBatteryStateChanged(double level, bool isCharging) {
    _batteryLevel.value = level;
    _isCharging.value = isCharging;
    if (_profile.value != null) {
      _profile.value = DeviceProfile(
        totalRamMB: _profile.value!.totalRamMB,
        availableRamMB: _profile.value!.availableRamMB,
        gpuName: _profile.value!.gpuName,
        vulkanSupported: _profile.value!.vulkanSupported,
        cpuCores: _profile.value!.cpuCores,
        cpuArchitecture: _profile.value!.cpuArchitecture,
        sdkVersion: _profile.value!.sdkVersion,
        deviceModel: _profile.value!.deviceModel,
        manufacturer: _profile.value!.manufacturer,
        batteryLevel: level,
        isCharging: isCharging,
        thermalState: _thermalState.value,
      );
    }
  }

  ThermalState _mapThermalState(int nativeState) {
    switch (nativeState) {
      case 0:
        return ThermalState.nominal;
      case 1:
        return ThermalState.light;
      case 2:
        return ThermalState.moderate;
      case 3:
        return ThermalState.severe;
      case 4:
        return ThermalState.critical;
      case 5:
      default:
        return ThermalState.shutdown;
    }
  }
}
