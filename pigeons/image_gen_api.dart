import 'package:pigeon/pigeon.dart';

/// Pigeon API — Image Generation Bridge.
///
/// Defines the type-safe communication contract between Flutter (Dart)
/// and Android (Kotlin) for Stable Diffusion operations.
/// Generated code will be placed in:
///   - Dart: lib/momo_core/bridge/image_gen_api.g.dart
///   - Kotlin: android/app/.../pigeon/ImageGenApi.g.kt
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/momo_core/bridge/image_gen_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/momoai/babymomo/pigeon/imagegen/ImageGenApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.momoai.babymomo.pigeon.imagegen'),
))

/// Image generation request sent from Flutter to native.
class NativeImageRequest {
  final String prompt;
  final String negativePrompt;
  final int steps;
  final double cfgScale;
  final int width;
  final int height;
  final int seed;

  NativeImageRequest({
    required this.prompt,
    required this.negativePrompt,
    required this.steps,
    required this.cfgScale,
    required this.width,
    required this.height,
    required this.seed,
  });
}

/// Image generation response returned from native.
class NativeImageResponse {
  final String imagePath;
  final int generationTimeMs;
  final bool success;
  final String? errorMessage;

  NativeImageResponse({
    required this.imagePath,
    required this.generationTimeMs,
    required this.success,
    this.errorMessage,
  });
}

/// Flutter → Native: Image Generation operations.
@HostApi()
abstract class ImageGenHostApi {
  /// Generate a high-fidelity image based on the prompt.
  @async
  NativeImageResponse generateImage(NativeImageRequest request);
}
