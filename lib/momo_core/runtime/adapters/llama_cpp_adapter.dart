import 'dart:async';
import '../../bridge/inference_api.g.dart';
import '../runtime_engine.dart';
import '../runtime_config.dart';
import '../capability.dart';
import '../../inference/inference_request.dart';
import '../../inference/inference_result.dart';

/// MOMO Core — llama.cpp Runtime Adapter.
///
/// Implements [RuntimeEngine] and [InferenceFlutterApi] to execute local LLM inference
/// using our high-performance native Pigeon/JNI bridges on Android.
class LlamaCppAdapter extends RuntimeEngine implements InferenceFlutterApi {
  final _hostApi = InferenceHostApi();
  final _controllers = <String, StreamController<InferenceResult>>{};
  
  bool _isInitialized = false;
  String? _loadedModelPath;

  @override
  String get id => 'llama_cpp';

  @override
  String get displayName => 'Local AI';

  @override
  Set<RuntimeCapability> get capabilities => {
        RuntimeCapability.text,
        RuntimeCapability.embedding,
      };

  bool get hasLoadedModel => _isInitialized && _loadedModelPath != null;
  String? get loadedModelPath => _loadedModelPath;

  @override
  Future<void> initialize(RuntimeConfig config) async {
    if (_isInitialized) return;

    // Register this instance as the global Flutter receiver for callbacks from native
    InferenceFlutterApi.setUp(this);

    // If a model path is specified in the config, load it now
    if (config.modelPath != null) {
      final success = await _hostApi.loadModel(NativeModelRequest(
        modelPath: config.modelPath!,
        contextLength: config.contextLength,
        threadCount: config.threadCount,
        useGPU: config.useGPU,
      ));
      if (success) {
        _loadedModelPath = config.modelPath;
      }
    }
    
    _isInitialized = true;
  }

  /// Dynamically load a model at runtime.
  Future<bool> loadModel(
    String path, {
    int contextLength = 2048,
    int threadCount = 4,
    bool useGPU = true,
  }) async {
    if (!_isInitialized) {
      await initialize(RuntimeConfig(
        modelPath: path,
        contextLength: contextLength,
        threadCount: threadCount,
        useGPU: useGPU,
      ));
      return _loadedModelPath == path;
    }

    final success = await _hostApi.loadModel(NativeModelRequest(
      modelPath: path,
      contextLength: contextLength,
      threadCount: threadCount,
      useGPU: useGPU,
    ));
    if (success) {
      _loadedModelPath = path;
    }
    return success;
  }

  /// Unload the currently loaded model.
  Future<void> unloadModel() async {
    await _hostApi.unloadModel();
    _loadedModelPath = null;
  }

  @override
  Future<void> dispose() async {
    InferenceFlutterApi.setUp(null);
    await unloadModel();
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
    _isInitialized = false;
  }

  @override
  Future<bool> isAvailable() async {
    // Local AI is available if initialized and a model is loaded in the native core
    return _isInitialized && await _hostApi.isModelLoaded();
  }

  @override
  Future<RuntimeHealth> healthCheck() async {
    try {
      final isLoaded = await _hostApi.isModelLoaded();
      if (!isLoaded) {
        return const RuntimeHealth(
          isReady: false,
          errorMessage: 'No local model loaded. Open Model Manager to load one.',
        );
      }
      final info = await _hostApi.getModelInfo();
      return RuntimeHealth(
        isReady: true,
        memoryUsageMB: info != null ? 256 : null, // Fallback placeholder
      );
    } catch (e) {
      return RuntimeHealth(
        isReady: false,
        errorMessage: 'Native bridge error: $e',
      );
    }
  }

  @override
  Stream<InferenceResult> infer(InferenceRequest request) {
    final controller = StreamController<InferenceResult>();
    _controllers[request.id] = controller;

    // Convert request structures safely checking for null context
    final contextList = request.context ?? [];

    final systemPrompt = contextList.firstWhere(
      (m) => m.role == 'system',
      orElse: () => ContextMessage(
        role: 'system',
        content: '',
        timestamp: DateTime.now(),
      ),
    ).content;

    // Fetch the primary prompt (the latest user message)
    final userPrompt = contextList.lastWhere(
      (m) => m.role == 'user',
      orElse: () => ContextMessage(
        role: 'user',
        content: '',
        timestamp: DateTime.now(),
      ),
    ).content;

    _hostApi.startInference(NativeInferenceRequest(
      requestId: request.id,
      prompt: request.prompt.isNotEmpty ? request.prompt : userPrompt,
      systemPrompt: request.systemPrompt.isNotEmpty ? request.systemPrompt : systemPrompt,
      temperature: request.parameters.temperature,
      topP: request.parameters.topP,
      maxTokens: request.parameters.maxTokens,
    )).catchError((error) {
      controller.add(InferenceResult.error(
        requestId: request.id,
        message: 'Failed to initiate native inference: $error',
      ));
      controller.close();
      _controllers.remove(request.id);
    });

    return controller.stream;
  }

  @override
  Future<void> cancelInference(String requestId) async {
    await _hostApi.cancelInference(requestId);
    final controller = _controllers[requestId];
    if (controller != null && !controller.isClosed) {
      controller.add(InferenceResult(
        requestId: requestId,
        content: ' [Generation Cancelled]',
        isDone: true,
      ));
      await controller.close();
    }
    _controllers.remove(requestId);
  }

  // ─── InferenceFlutterApi Implementation ───

  @override
  void onToken(String requestId, String token) {
    final controller = _controllers[requestId];
    if (controller != null && !controller.isClosed) {
      controller.add(InferenceResult(
        requestId: requestId,
        content: token,
        isDone: false,
      ));
    }
  }

  @override
  void onComplete(String requestId, int totalTokens, double tokensPerSecond) {
    final controller = _controllers[requestId];
    if (controller != null && !controller.isClosed) {
      controller.add(InferenceResult.done(
        requestId: requestId,
        metrics: InferenceMetrics(
          tokensPerSecond: tokensPerSecond,
          totalTokens: totalTokens,
          totalTimeMs: ((totalTokens / tokensPerSecond) * 1000).toInt(),
        ),
      ));
      controller.close();
    }
    _controllers.remove(requestId);
  }

  @override
  void onError(String requestId, String errorMessage) {
    final controller = _controllers[requestId];
    if (controller != null && !controller.isClosed) {
      controller.add(InferenceResult.error(
        requestId: requestId,
        message: errorMessage,
      ));
      controller.close();
    }
    _controllers.remove(requestId);
  }
}
