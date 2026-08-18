/// MOMO Core — Inference Result model.
///
/// Streamed from [RuntimeEngine.infer]. Each instance represents
/// a token/chunk of the response. The UI renders these incrementally.
class InferenceResult {
  /// Matches the [InferenceRequest.id] this result belongs to.
  final String requestId;

  /// The content chunk (token text, or base64 image data reference).
  final String content;

  /// Whether this is the final chunk in the stream.
  final bool isDone;

  /// Optional performance metrics (populated on final chunk).
  final InferenceMetrics? metrics;

  /// Optional error if inference failed.
  final String? error;

  const InferenceResult({
    required this.requestId,
    required this.content,
    this.isDone = false,
    this.metrics,
    this.error,
  });

  /// Convenience: check if this result is an error.
  bool get isError => error != null;

  /// Create an error result.
  factory InferenceResult.error({
    required String requestId,
    required String message,
  }) {
    return InferenceResult(
      requestId: requestId,
      content: '',
      isDone: true,
      error: message,
    );
  }

  /// Create a completion result with metrics.
  factory InferenceResult.done({
    required String requestId,
    InferenceMetrics? metrics,
  }) {
    return InferenceResult(
      requestId: requestId,
      content: '',
      isDone: true,
      metrics: metrics,
    );
  }
}

/// Performance metrics for an inference run.
class InferenceMetrics {
  /// Tokens generated per second.
  final double tokensPerSecond;

  /// Total tokens generated.
  final int totalTokens;

  /// Total time in milliseconds.
  final int totalTimeMs;

  /// Time to first token in milliseconds.
  final int? timeToFirstTokenMs;

  const InferenceMetrics({
    required this.tokensPerSecond,
    required this.totalTokens,
    required this.totalTimeMs,
    this.timeToFirstTokenMs,
  });
}
