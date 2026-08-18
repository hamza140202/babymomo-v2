import 'dart:async';
import '../../bridge/image_gen_api.g.dart';
import '../runtime_engine.dart';
import '../runtime_config.dart';
import '../capability.dart';
import '../../inference/inference_request.dart';
import '../../inference/inference_result.dart';

/// MOMO Core — Stable Diffusion Adapter.
///
/// Implements [RuntimeEngine] for on-device local image generation
/// via our high-performance JNI procedural canvas bridge on Android.
class StableDiffusionAdapter extends RuntimeEngine {
  final _imageGenHostApi = ImageGenHostApi();
  bool _isInitialized = false;

  @override
  String get id => 'stable_diffusion';

  @override
  String get displayName => 'Image Creator';

  @override
  Set<RuntimeCapability> get capabilities => {RuntimeCapability.image};

  @override
  Future<void> initialize(RuntimeConfig config) async {
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }

  @override
  Future<bool> isAvailable() async {
    return _isInitialized;
  }

  @override
  Future<RuntimeHealth> healthCheck() async {
    if (!_isInitialized) {
      return const RuntimeHealth(
        isReady: false,
        errorMessage: 'Stable Diffusion Adapter not initialized',
      );
    }
    return const RuntimeHealth(isReady: true);
  }

  @override
  Stream<InferenceResult> infer(InferenceRequest request) async* {
    if (!_isInitialized) {
      yield InferenceResult.error(
        requestId: request.id,
        message: 'Stable Diffusion runtime is not initialized',
      );
      return;
    }

    try {
      // 1. Map request parameters safely
      final steps = request.parameters.steps ?? 20;
      final cfgScale = request.parameters.cfgScale ?? 7.5;
      final width = request.parameters.width ?? 512;
      final height = request.parameters.height ?? 512;
      final seed = request.parameters.seed ?? DateTime.now().millisecondsSinceEpoch % 100000;

      // 2. Perform native Pigeon call
      final response = await _imageGenHostApi.generateImage(
        NativeImageRequest(
          prompt: request.prompt,
          negativePrompt: request.parameters.negativePrompt ?? '',
          steps: steps,
          cfgScale: cfgScale,
          width: width,
          height: height,
          seed: seed,
        ),
      );

      if (response.success) {
        // 3. Emit the local file path as content and finish
        yield InferenceResult(
          requestId: request.id,
          content: response.imagePath,
          isDone: false,
        );

        yield InferenceResult.done(
          requestId: request.id,
          metrics: InferenceMetrics(
            tokensPerSecond: 1.0,
            totalTokens: 1,
            totalTimeMs: response.generationTimeMs,
          ),
        );
      } else {
        yield InferenceResult.error(
          requestId: request.id,
          message: response.errorMessage ?? 'Native image generation failed',
        );
      }
    } catch (e) {
      yield InferenceResult.error(
        requestId: request.id,
        message: 'Failed to execute image generation bridge: $e',
      );
    }
  }

  @override
  Future<void> cancelInference(String requestId) async {
    // Canvas generation completes instantly or in a single thread,
    // cancellation can be a stub for now.
  }
}
