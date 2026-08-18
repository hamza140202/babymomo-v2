/// MOMO Core — Runtime configuration model.
///
/// Immutable config passed to a [RuntimeEngine] during initialization.
/// Abstracts away provider-specific details behind consumer-friendly tiers.
class RuntimeConfig {
  /// Absolute path to the model file on device storage.
  final String? modelPath;

  /// Maximum context length in tokens.
  final int contextLength;

  /// Number of CPU threads for inference.
  final int threadCount;

  /// Whether to attempt GPU acceleration (Vulkan/OpenCL).
  final bool useGPU;

  /// Consumer-facing performance tier.
  final PerformanceTier tier;

  /// Provider-specific overrides (temp, top_p, api key, etc.)
  final Map<String, dynamic> extra;

  const RuntimeConfig({
    this.modelPath,
    this.contextLength = 2048,
    this.threadCount = 4,
    this.useGPU = false,
    this.tier = PerformanceTier.balanced,
    this.extra = const {},
  });

  RuntimeConfig copyWith({
    String? modelPath,
    int? contextLength,
    int? threadCount,
    bool? useGPU,
    PerformanceTier? tier,
    Map<String, dynamic>? extra,
  }) {
    return RuntimeConfig(
      modelPath: modelPath ?? this.modelPath,
      contextLength: contextLength ?? this.contextLength,
      threadCount: threadCount ?? this.threadCount,
      useGPU: useGPU ?? this.useGPU,
      tier: tier ?? this.tier,
      extra: extra ?? this.extra,
    );
  }
}

/// Consumer-facing performance tiers.
/// Maps to MINDUSAGE.md: "Fast / Balanced / High Quality" — no jargon.
enum PerformanceTier {
  /// Fastest inference, lower quality (smaller models, more quantization)
  fast,

  /// Default balance of speed and quality
  balanced,

  /// Highest quality, slower (larger models, less quantization)
  quality,
}
