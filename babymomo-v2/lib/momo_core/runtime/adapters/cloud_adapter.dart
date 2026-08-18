import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../runtime_engine.dart';
import '../runtime_config.dart';
import '../capability.dart';
import '../../inference/inference_request.dart';
import '../../inference/inference_result.dart';
import 'cloud_provider_config.dart';

/// MOMO Core — Cloud Runtime Adapter.
///
/// Implements [RuntimeEngine] for all OpenAI-compatible cloud APIs.
/// A single adapter handles OpenAI, Anthropic (via proxy), Gemini,
/// OpenRouter, NVIDIA NIM, and any custom OpenAI-compatible endpoint.
///
/// This is the first working runtime — enables chat before local
/// inference is built in Phase 4.
class CloudAdapter extends RuntimeEngine {
  final CloudProviderConfig _providerConfig;
  late final Dio _dio;
  bool _initialized = false;
  CancelToken? _activeCancelToken;

  CloudAdapter({required CloudProviderConfig providerConfig})
      : _providerConfig = providerConfig;

  @override
  String get id => 'cloud_${_providerConfig.provider.name}';

  @override
  String get displayName => _providerConfig.provider.displayName;

  @override
  Set<RuntimeCapability> get capabilities => {
        RuntimeCapability.text,
        RuntimeCapability.vision,
      };

  @override
  Future<void> initialize(RuntimeConfig config) async {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      headers: _providerConfig.headers,
    ));
    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    _activeCancelToken?.cancel('Runtime disposed');
    _dio.close();
    _initialized = false;
  }

  @override
  Future<bool> isAvailable() async {
    return _initialized && _providerConfig.apiKey.isNotEmpty;
  }

  @override
  Future<RuntimeHealth> healthCheck() async {
    if (!_initialized) {
      return const RuntimeHealth(
        isReady: false,
        errorMessage: 'Not initialized',
      );
    }

    try {
      // Quick ping to verify API key validity
      await _dio.get(
        _providerConfig.baseUrl.replaceAll('/v1', '/v1/models'),
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return const RuntimeHealth(isReady: true);
    } catch (e) {
      return RuntimeHealth(
        isReady: false,
        errorMessage: 'Health check failed: $e',
      );
    }
  }

  @override
  Stream<InferenceResult> infer(InferenceRequest request) async* {
    if (!_initialized) {
      yield InferenceResult.error(
        requestId: request.id,
        message: 'Cloud runtime not initialized',
      );
      return;
    }

    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;

    final stopwatch = Stopwatch()..start();
    int totalTokens = 0;
    int? timeToFirstTokenMs;

    try {
      final body = _buildRequestBody(request);

      final response = await _dio.post<ResponseBody>(
        _providerConfig.chatCompletionsUrl,
        data: jsonEncode(body),
        options: Options(
          responseType: ResponseType.stream,
          headers: _providerConfig.headers,
        ),
        cancelToken: cancelToken,
      );

      final stream = response.data!.stream
          .transform(StreamTransformer<Uint8List, String>.fromHandlers(
        handleData: (data, sink) => sink.add(utf8.decode(data)),
      ));
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        if (cancelToken.isCancelled) break;

        // Parse SSE data lines
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;

          final data = line.substring(6).trim();
          if (data == '[DONE]') {
            stopwatch.stop();
            yield InferenceResult.done(
              requestId: request.id,
              metrics: InferenceMetrics(
                tokensPerSecond: totalTokens > 0
                    ? totalTokens / (stopwatch.elapsedMilliseconds / 1000)
                    : 0,
                totalTokens: totalTokens,
                totalTimeMs: stopwatch.elapsedMilliseconds,
                timeToFirstTokenMs: timeToFirstTokenMs,
              ),
            );
            return;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List?;
            if (choices == null || choices.isEmpty) continue;

            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            if (delta == null) continue;

            final content = delta['content'] as String?;
            if (content != null && content.isNotEmpty) {
              totalTokens++;
              timeToFirstTokenMs ??= stopwatch.elapsedMilliseconds;
              buffer.write(content);

              yield InferenceResult(
                requestId: request.id,
                content: content,
              );
            }
          } catch (_) {
            // Skip malformed JSON chunks
            continue;
          }
        }
      }

      // If we get here without [DONE], emit completion
      stopwatch.stop();
      yield InferenceResult.done(
        requestId: request.id,
        metrics: InferenceMetrics(
          tokensPerSecond: totalTokens > 0
              ? totalTokens / (stopwatch.elapsedMilliseconds / 1000)
              : 0,
          totalTokens: totalTokens,
          totalTimeMs: stopwatch.elapsedMilliseconds,
          timeToFirstTokenMs: timeToFirstTokenMs,
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        yield InferenceResult.done(requestId: request.id);
        return;
      }

      final statusCode = e.response?.statusCode;
      final message = switch (statusCode) {
        401 => 'Invalid API key',
        429 => 'Rate limit exceeded — try again shortly',
        500 || 502 || 503 => 'Server is temporarily unavailable',
        _ => 'Connection error: ${e.message}',
      };

      yield InferenceResult.error(
        requestId: request.id,
        message: message,
      );
    } catch (e) {
      yield InferenceResult.error(
        requestId: request.id,
        message: 'Unexpected error: $e',
      );
    } finally {
      _activeCancelToken = null;
    }
  }

  @override
  Future<void> cancelInference(String requestId) async {
    _activeCancelToken?.cancel('Cancelled by user');
    _activeCancelToken = null;
  }

  /// Build the OpenAI-compatible request body.
  Map<String, dynamic> _buildRequestBody(InferenceRequest request) {
    final messages = <Map<String, dynamic>>[];

    // System prompt
    if (request.systemPrompt != null) {
      messages.add({
        'role': 'system',
        'content': request.systemPrompt,
      });
    }

    // Conversation context
    if (request.context != null) {
      for (final msg in request.context!) {
        messages.add({
          'role': msg.role,
          'content': msg.content,
        });
      }
    }

    // Current user message
    messages.add({
      'role': 'user',
      'content': request.prompt,
    });

    return {
      'model': _providerConfig.modelId,
      'messages': messages,
      'stream': true,
      'temperature': request.parameters.temperature,
      'top_p': request.parameters.topP,
      'max_tokens': request.parameters.maxTokens,
      if (request.parameters.stopSequences != null)
        'stop': request.parameters.stopSequences,
    };
  }
}
