import '../multimodal/modality.dart';

/// MOMO Core — Inference Request model.
///
/// Runtime-agnostic request that any [RuntimeEngine] can process.
/// The UI builds this without knowing which backend will handle it.
class InferenceRequest {
  /// Unique request ID for tracking and cancellation.
  final String id;

  /// The user's prompt / input text.
  final String prompt;

  /// Optional system prompt for persona/behavior setup.
  final String? systemPrompt;

  /// Conversation history for context.
  final List<ContextMessage>? context;

  /// Generation parameters (temperature, top_p, max_tokens, etc.)
  final InferenceParameters parameters;

  /// Target modality for this request.
  final Modality modality;

  /// Optional image bytes for vision requests.
  final List<int>? imageBytes;

  const InferenceRequest({
    required this.id,
    required this.prompt,
    this.systemPrompt,
    this.context,
    this.parameters = const InferenceParameters(),
    this.modality = Modality.text,
    this.imageBytes,
  });
}

/// A single message in the conversation context.
class ContextMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;

  const ContextMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

/// Generation parameters — abstracted from provider-specific params.
class InferenceParameters {
  final double temperature;
  final double topP;
  final int maxTokens;
  final double repeatPenalty;
  final List<String>? stopSequences;

  // Image Generation Specific Parameters
  final int? steps;
  final double? cfgScale;
  final int? width;
  final int? height;
  final String? negativePrompt;
  final int? seed;

  const InferenceParameters({
    this.temperature = 0.7,
    this.topP = 0.9,
    this.maxTokens = 1024,
    this.repeatPenalty = 1.1,
    this.stopSequences,
    this.steps,
    this.cfgScale,
    this.width,
    this.height,
    this.negativePrompt,
    this.seed,
  });

  Map<String, dynamic> toMap() => {
        'temperature': temperature,
        'top_p': topP,
        'max_tokens': maxTokens,
        'repeat_penalty': repeatPenalty,
        if (stopSequences != null) 'stop': stopSequences,
        if (steps != null) 'steps': steps,
        if (cfgScale != null) 'cfg_scale': cfgScale,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (negativePrompt != null) 'negative_prompt': negativePrompt,
        if (seed != null) 'seed': seed,
      };
}
