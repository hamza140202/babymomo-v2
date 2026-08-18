import 'capability.dart';
import 'runtime_config.dart';
import '../inference/inference_request.dart';
import '../inference/inference_result.dart';

/// MOMO Core — Runtime health status.
class RuntimeHealth {
  final bool isReady;
  final String? errorMessage;
  final int? memoryUsageMB;
  final double? tokensPerSecond;

  const RuntimeHealth({
    required this.isReady,
    this.errorMessage,
    this.memoryUsageMB,
    this.tokensPerSecond,
  });
}

/// MOMO Core — Abstract Runtime Engine interface.
///
/// The fundamental contract that every AI backend must implement.
/// The UI and features never interact with provider-specific code,
/// only this interface.
abstract class RuntimeEngine {
  /// Unique identifier (e.g. 'llama_cpp', 'openai')
  String get id;

  /// Consumer-facing display name (e.g. 'Local Fast', 'Cloud Pro')
  String get displayName;

  /// Set of capabilities this runtime supports
  Set<RuntimeCapability> get capabilities;

  /// Initialize with configuration. Called once before inference.
  Future<void> initialize(RuntimeConfig config);

  /// Release all resources.
  Future<void> dispose();

  /// Can this runtime accept requests right now?
  Future<bool> isAvailable();

  /// Detailed health check.
  Future<RuntimeHealth> healthCheck();

  /// Execute inference and stream results token-by-token.
  Stream<InferenceResult> infer(InferenceRequest request);

  /// Cancel in-progress inference.
  Future<void> cancelInference(String requestId);
}
