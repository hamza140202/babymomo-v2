import 'package:get/get.dart';
import '../runtime/runtime_engine.dart';
import '../runtime/runtime_registry.dart';
import '../runtime/capability.dart';
import '../multimodal/modality.dart';
import 'inference_request.dart';
import 'inference_result.dart';
import 'inference_policy.dart';

/// MOMO Core — Inference Router.
///
/// The single entry point for all inference requests from the UI/features.
/// Routes requests to the optimal [RuntimeEngine] based on [InferencePolicy].
///
/// Features never talk to runtimes directly — they go through this router.
class InferenceRouter extends GetxService {
  final RuntimeRegistry _registry;
  final InferencePolicy _policy;

  /// Currently active inference request IDs.
  final Map<String, RuntimeEngine> _activeInferences = {};

  InferenceRouter({
    required RuntimeRegistry registry,
    InferencePolicy? policy,
  })  : _registry = registry,
        _policy = policy ?? InferencePolicy();

  /// Route a request to the best available runtime and stream results.
  Stream<InferenceResult> route(InferenceRequest request) async* {
    final capability = _modalityToCapability(request.modality);
    final candidates = _registry.byCapability(capability);

    final runtime = _policy.selectRuntime(
      candidates: candidates,
      requiredCapability: capability,
    );

    if (runtime == null) {
      yield InferenceResult.error(
        requestId: request.id,
        message: 'No runtime available for ${request.modality.name} inference',
      );
      return;
    }

    // Check runtime availability
    final available = await runtime.isAvailable();
    if (!available) {
      yield InferenceResult.error(
        requestId: request.id,
        message: '${runtime.displayName} is not currently available',
      );
      return;
    }

    // Track active inference
    _activeInferences[request.id] = runtime;

    try {
      yield* runtime.infer(request);
    } finally {
      _activeInferences.remove(request.id);
    }
  }

  /// Cancel an active inference.
  Future<void> cancel(String requestId) async {
    final runtime = _activeInferences[requestId];
    if (runtime != null) {
      await runtime.cancelInference(requestId);
      _activeInferences.remove(requestId);
    }
  }

  /// Get all available runtimes for a capability.
  List<RuntimeEngine> availableFor(RuntimeCapability capability) {
    return _registry.byCapability(capability);
  }

  RuntimeCapability _modalityToCapability(Modality modality) {
    switch (modality) {
      case Modality.text:
        return RuntimeCapability.text;
      case Modality.image:
        return RuntimeCapability.image;
      case Modality.voice:
        return RuntimeCapability.voice;
      case Modality.vision:
        return RuntimeCapability.vision;
    }
  }
}
