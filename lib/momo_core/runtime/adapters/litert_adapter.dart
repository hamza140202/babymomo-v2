import '../runtime_engine.dart';
import '../runtime_config.dart';
import '../capability.dart';
import '../../inference/inference_request.dart';
import '../../inference/inference_result.dart';

/// MOMO Core — LiteRT-LM Adapter (Stub).
///
/// Will implement [RuntimeEngine] for Google's LiteRT-LM runtime.
/// Optimized for low-RAM Android devices.
/// Phase 4+ implementation.
class LiteRTAdapter extends RuntimeEngine {
  @override
  String get id => 'litert_lm';

  @override
  String get displayName => 'Lightweight AI';

  @override
  Set<RuntimeCapability> get capabilities => {RuntimeCapability.text};

  @override
  Future<void> initialize(RuntimeConfig config) async {
    throw UnimplementedError('LiteRT adapter not yet implemented');
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<RuntimeHealth> healthCheck() async {
    return const RuntimeHealth(
      isReady: false,
      errorMessage: 'Not implemented — future phase',
    );
  }

  @override
  Stream<InferenceResult> infer(InferenceRequest request) {
    return Stream.value(InferenceResult.error(
      requestId: request.id,
      message: 'Lightweight AI not yet available',
    ));
  }

  @override
  Future<void> cancelInference(String requestId) async {}
}
