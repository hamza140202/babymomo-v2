import '../runtime/runtime_config.dart';

/// MOMO Core — Performance Tier mapping.
///
/// Maps consumer-friendly tiers to technical parameters.
/// The user sees "Fast / Balanced / Quality" — never GPU settings.

class PerformanceTierConfig {
  /// Get technical config adjustments for a performance tier.
  static Map<String, dynamic> configFor(PerformanceTier tier) {
    switch (tier) {
      case PerformanceTier.fast:
        return {
          'temperature': 0.6,
          'max_tokens': 512,
          'context_length': 1024,
          'prefer_quantized': true,
        };
      case PerformanceTier.balanced:
        return {
          'temperature': 0.7,
          'max_tokens': 1024,
          'context_length': 2048,
          'prefer_quantized': false,
        };
      case PerformanceTier.quality:
        return {
          'temperature': 0.8,
          'max_tokens': 2048,
          'context_length': 4096,
          'prefer_quantized': false,
        };
    }
  }
}
