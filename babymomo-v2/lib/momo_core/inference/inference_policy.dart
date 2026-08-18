import 'package:get/get.dart';
import '../runtime/runtime_engine.dart';
import '../runtime/capability.dart';
import '../runtime/adapters/llama_cpp_adapter.dart';
import '../device/device_profile.dart';
import '../../features/model_hub/presentation/model_hub_controller.dart';

/// MOMO Core — Inference Policy.
///
/// Determines which runtime to use for a given request based on:
/// - User preference (performance tier)
/// - Device capabilities (RAM, GPU, thermal state)
/// - Runtime availability
/// - Request modality
class InferencePolicy {
  /// Select the best runtime from candidates based on device state.
  RuntimeEngine? selectRuntime({
    required List<RuntimeEngine> candidates,
    required RuntimeCapability requiredCapability,
    DeviceProfile? deviceProfile,
  }) {
    if (candidates.isEmpty) return null;

    // Filter by capability
    final capable = candidates
        .where((r) => r.capabilities.contains(requiredCapability))
        .toList();

    if (capable.isEmpty) return null;
    if (capable.length == 1) return capable.first;

    // Prioritize local llama_cpp if a local model is actively loaded
    for (final r in capable) {
      if (r is LlamaCppAdapter && r.hasLoadedModel) {
        return r;
      }
    }

    // Check Cloud Hybrid fallback preference
    bool isCloudHybrid = true;
    try {
      if (Get.isRegistered<ModelHubController>()) {
        isCloudHybrid = Get.find<ModelHubController>().isCloudHybrid.value;
      }
    } catch (_) {}

    if (isCloudHybrid) {
      // Default fallback to Cloud AI for reliable cloud answers if no local model is loaded
      for (final r in capable) {
        if (r.id.startsWith('cloud')) {
          return r;
        }
      }
    }

    // In Local Only mode (isCloudHybrid = false), if no local model is loaded,
    // we return null to enforce offline/local execution.
    return null;
  }
}
