/// MOMO Core — Runtime capability enumeration.
///
/// Defines what kinds of inference a runtime can perform.
/// Used by [InferenceRouter] to match requests to capable runtimes.
enum RuntimeCapability {
  /// Text generation (LLM inference)
  text,

  /// Image generation (diffusion models)
  image,

  /// Voice synthesis / recognition
  voice,

  /// Embedding generation (vector representations)
  embedding,

  /// Vision / image understanding
  vision,
}
