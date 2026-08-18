import 'package:pigeon/pigeon.dart';

/// Pigeon API — Inference Bridge.
///
/// Defines the type-safe communication contract between Flutter (Dart)
/// and Android (Kotlin) for inference operations.
/// Generated code will be placed in:
///   - Dart: lib/momo_core/bridge/inference_api.g.dart
///   - Kotlin: android/app/.../pigeon/InferenceApi.g.kt
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/momo_core/bridge/inference_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/momoai/babymomo/pigeon/inference/InferenceApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.momoai.babymomo.pigeon.inference'),
))

/// Model loading request sent from Flutter to native.
class NativeModelRequest {
  final String modelPath;
  final int contextLength;
  final int threadCount;
  final bool useGPU;

  NativeModelRequest({
    required this.modelPath,
    required this.contextLength,
    required this.threadCount,
    required this.useGPU,
  });
}

/// Inference request sent from Flutter to native.
class NativeInferenceRequest {
  final String requestId;
  final String prompt;
  final String? systemPrompt;
  final double temperature;
  final double topP;
  final int maxTokens;

  NativeInferenceRequest({
    required this.requestId,
    required this.prompt,
    this.systemPrompt,
    required this.temperature,
    required this.topP,
    required this.maxTokens,
  });
}

/// Model info returned from native.
class NativeModelInfo {
  final String modelPath;
  final int parameterCount;
  final int contextLength;
  final String quantization;
  final bool isLoaded;

  NativeModelInfo({
    required this.modelPath,
    required this.parameterCount,
    required this.contextLength,
    required this.quantization,
    required this.isLoaded,
  });
}

/// Flutter → Native: Inference operations.
@HostApi()
abstract class InferenceHostApi {
  /// Load a model into memory.
  @async
  bool loadModel(NativeModelRequest request);

  /// Unload the currently loaded model.
  @async
  void unloadModel();

  /// Start inference (tokens streamed back via [InferenceFlutterApi]).
  @async
  void startInference(NativeInferenceRequest request);

  /// Cancel the currently running inference.
  @async
  void cancelInference(String requestId);

  /// Get info about the currently loaded model.
  @async
  NativeModelInfo? getModelInfo();

  /// Check if a model is currently loaded.
  @async
  bool isModelLoaded();
}

/// Native → Flutter: Token streaming callbacks.
@FlutterApi()
abstract class InferenceFlutterApi {
  /// Called for each generated token.
  void onToken(String requestId, String token);

  /// Called when inference completes.
  void onComplete(
      String requestId, int totalTokens, double tokensPerSecond);

  /// Called when inference encounters an error.
  void onError(String requestId, String errorMessage);
}
