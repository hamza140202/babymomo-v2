import 'package:get/get.dart';
import '../../momo_core/momo_core.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  final InferenceRouter _router = Get.find<InferenceRouter>();
  final MemoryEngine _memoryEngine = Get.find<MemoryEngine>();
  final _uuid = const Uuid();

  // State
  final RxList<MemoryEntry> messages = <MemoryEntry>[].obs;
  final RxBool isGenerating = false.obs;
  final RxString currentStreamContent = ''.obs;

  // Agent State
  final RxBool isAgentMode = false.obs;
  final RxBool isThinking = false.obs;
  final RxList<AgentStep> agentSteps = <AgentStep>[].obs;
  late final AgentLoop _agentLoop;

  String? _activeRequestId;

  @override
  void onInit() {
    super.onInit();
    _agentLoop = AgentLoop(
      toolRegistry: Get.find<ToolRegistry>(),
      router: _router,
    );
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // In Phase 3, we just load recent context
    final history = await _memoryEngine.buildContext(sessionId: 'default_session', maxEntries: 20);
    messages.assignAll(history);
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty || isGenerating.value) return;

    final requestId = _uuid.v4();
    _activeRequestId = requestId;

    // 1. Add User Message to Memory & UI
    final userMessage = MemoryEntry(
      id: _uuid.v4(),
      sessionId: 'default_session',
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    await _memoryEngine.store(userMessage);
    messages.add(userMessage);

    // If agent mode is enabled, run ReAct loop autonomously
    if (isAgentMode.value) {
      isGenerating.value = true;
      isThinking.value = true;
      agentSteps.clear();

      try {
        final stream = _agentLoop.run(text);
        await for (final step in stream) {
          agentSteps.add(step);
          if (step.type == 'final_answer') {
            isGenerating.value = false;
            isThinking.value = false;

            // Save final assistant message to Memory
            final assistantMessage = MemoryEntry(
              id: _uuid.v4(),
              sessionId: 'default_session',
              role: 'assistant',
              content: step.content,
              timestamp: DateTime.now(),
            );
            await _memoryEngine.store(assistantMessage);
            messages.add(assistantMessage);
            return;
          }
        }
      } catch (e) {
        isGenerating.value = false;
        isThinking.value = false;
        messages.add(MemoryEntry(
          id: _uuid.v4(),
          sessionId: 'default_session',
          role: 'system',
          content: 'Agent Loop Error: $e',
          timestamp: DateTime.now(),
        ));
      }
      isGenerating.value = false;
      isThinking.value = false;
      return;
    }

    // 2. Prepare Context for Inference
    final history = await _memoryEngine.buildContext(sessionId: 'default_session', maxEntries: 10);
    final contextMessages = history.map((e) => ContextMessage(
          role: e.role,
          content: e.content,
          timestamp: e.timestamp,
        )).toList();

    final request = InferenceRequest(
      id: requestId,
      prompt: text,
      systemPrompt:
          "You are Momo, a helpful, warm, and emotionally intelligent AI companion. Keep answers concise and friendly.",
      context: contextMessages,
      modality: Modality.text,
      parameters: const InferenceParameters(
        temperature: 0.7,
        maxTokens: 512,
      ),
    );

    // 3. Start Generation
    isGenerating.value = true;
    currentStreamContent.value = '';

    final stream = _router.route(request);

    stream.listen(
      (result) {
        if (result.isError) {
          isGenerating.value = false;
          _activeRequestId = null;
          
          final errorText = result.error ?? 'Unknown inference error';
          final isApiKeyError = errorText.contains('YOUR_GEMINI_API_KEY') || 
                               errorText.contains('API_KEY_INVALID') || 
                               errorText.contains('API key') || 
                               errorText.contains('api_key') || 
                               errorText.contains('API Key');

          final msgContent = isApiKeyError 
              ? "Momo is currently disconnected from the cloud network. Please verify your internet connection or update your API Key under settings! If you have downloaded a local brain model, you can load and chat with Momo completely offline! 🌐✨"
              : 'Error: $errorText';

          messages.add(MemoryEntry(
            id: _uuid.v4(),
            sessionId: 'default_session',
            role: isApiKeyError ? 'assistant' : 'system',
            content: msgContent,
            timestamp: DateTime.now(),
          ));
          return;
        }

        if (result.isDone) {
          isGenerating.value = false;
          _activeRequestId = null;

          // Save final assistant message to Memory
          if (currentStreamContent.value.isNotEmpty) {
            final assistantMessage = MemoryEntry(
              id: _uuid.v4(),
              sessionId: 'default_session',
              role: 'assistant',
              content: currentStreamContent.value,
              timestamp: DateTime.now(),
            );
            _memoryEngine.store(assistantMessage);
            messages.add(assistantMessage);
          }
          currentStreamContent.value = ''; // Clear stream buffer
          return;
        }

        // Append to stream buffer
        currentStreamContent.value += result.content;
      },
      onError: (e) {
        isGenerating.value = false;
        _activeRequestId = null;
      },
      cancelOnError: true,
    );
  }

  void cancelGeneration() {
    if (_activeRequestId != null) {
      _router.cancel(_activeRequestId!);
      isGenerating.value = false;
      _activeRequestId = null;

      // Save whatever was generated so far
      if (currentStreamContent.value.isNotEmpty) {
        final partialMessage = MemoryEntry(
          id: _uuid.v4(),
          sessionId: 'default_session',
          role: 'assistant',
          content: '${currentStreamContent.value} [Cancelled]',
          timestamp: DateTime.now(),
        );
        _memoryEngine.store(partialMessage);
        messages.add(partialMessage);
      }
      currentStreamContent.value = '';
    }
  }
}
