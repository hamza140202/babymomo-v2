/// MOMO Core — Cloud Provider Configuration.
///
/// Defines supported cloud AI providers and their API configurations.
/// The user never sees provider internals — they see "Cloud Pro", "Cloud Fast".
class CloudProviderConfig {
  /// Provider identifier.
  final CloudProvider provider;

  /// API base URL.
  final String baseUrl;

  /// API key (loaded from secure storage, never hardcoded).
  final String apiKey;

  /// Model identifier for this provider.
  final String modelId;

  /// Optional organization ID (OpenAI).
  final String? organizationId;

  /// Max tokens this model supports.
  final int maxContextLength;

  /// Whether this provider supports streaming.
  final bool supportsStreaming;

  /// Custom headers for this provider.
  final Map<String, String> customHeaders;

  const CloudProviderConfig({
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
    this.organizationId,
    this.maxContextLength = 4096,
    this.supportsStreaming = true,
    this.customHeaders = const {},
  });

  /// Get the full chat completions endpoint URL.
  String get chatCompletionsUrl => '$baseUrl/chat/completions';

  /// Build auth headers for API requests.
  Map<String, String> get headers {
    final map = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      ...customHeaders,
    };
    if (organizationId != null) {
      map['OpenAI-Organization'] = organizationId!;
    }
    return map;
  }
}

/// Supported cloud providers.
/// All use the OpenAI-compatible chat completions API format.
enum CloudProvider {
  openai(
    displayName: 'OpenAI',
    defaultBaseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o-mini',
  ),
  anthropic(
    displayName: 'Anthropic',
    defaultBaseUrl: 'https://api.anthropic.com/v1',
    defaultModel: 'claude-3-5-sonnet-20241022',
  ),
  gemini(
    displayName: 'Gemini',
    defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    defaultModel: 'gemini-2.0-flash',
  ),
  openRouter(
    displayName: 'OpenRouter',
    defaultBaseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'meta-llama/llama-3.1-8b-instruct',
  ),
  nvidiaNim(
    displayName: 'NVIDIA NIM',
    defaultBaseUrl: 'https://integrate.api.nvidia.com/v1',
    defaultModel: 'meta/llama-3.1-8b-instruct',
  ),
  custom(
    displayName: 'Custom',
    defaultBaseUrl: '',
    defaultModel: '',
  );

  final String displayName;
  final String defaultBaseUrl;
  final String defaultModel;

  const CloudProvider({
    required this.displayName,
    required this.defaultBaseUrl,
    required this.defaultModel,
  });
}
