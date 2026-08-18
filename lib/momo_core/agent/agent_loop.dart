import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../inference/inference_router.dart';
import '../inference/inference_request.dart';
import '../multimodal/modality.dart';
import 'momo_tool.dart';

/// Represents a single discrete step in the agent's ReAct execution loop.
class AgentStep {
  final String type; // 'thought', 'action', 'observation', 'final_answer', 'error'
  final String title; // User-friendly title for UI rendering
  final String content; // Detailed content / text
  final DateTime timestamp;

  AgentStep({
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// MOMO Core — Agent Loop.
///
/// Implements the ReAct (Reason-Act-Observe) autonomous agent execution model.
class AgentLoop {
  final ToolRegistry _toolRegistry;
  final InferenceRouter _router;

  AgentLoop({
    required ToolRegistry toolRegistry,
    required InferenceRouter router,
  })  : _toolRegistry = toolRegistry,
        _router = router;

  /// Runs the ReAct execution loop for a user query.
  /// Streams intermediate thoughts, actions, observations, and the final answer.
  Stream<AgentStep> run(String userQuery, {int maxTurns = 5}) async* {
    yield AgentStep(
      type: 'thought',
      title: 'Initializing Agent Task',
      content: 'Configuring tools and planning execution strategy for query: "$userQuery"',
      timestamp: DateTime.now(),
    );

    final List<Map<String, String>> reactHistory = [];
    int turn = 0;

    while (turn < maxTurns) {
      turn++;

      // 1. Build prompt containing tools, guidelines, and previous ReAct history
      final prompt = _buildReActPrompt(userQuery, reactHistory);

      yield AgentStep(
        type: 'thought',
        title: 'Reasoning (Turn $turn/$maxTurns)',
        content: 'Analyzing state and formulating next step...',
        timestamp: DateTime.now(),
      );

      // 2. Query LLM for the next ReAct block
      String rawLlmResponse = '';
      try {
        final requestId = const Uuid().v4();
        final textStream = _router.route(InferenceRequest(
          id: requestId,
          prompt: prompt,
          modality: Modality.text,
          parameters: const InferenceParameters(
            temperature: 0.1, // Low temperature for high format compliance
            maxTokens: 512,
          ),
        ));

        await for (final chunk in textStream) {
          if (chunk.isError) {
            throw Exception(chunk.content);
          }
          if (chunk.content.isNotEmpty) {
            rawLlmResponse += chunk.content;
          }
        }
      } catch (e) {
        yield AgentStep(
          type: 'error',
          title: 'LLM Reasoning Error',
          content: 'Failed during LLM text generation step: $e',
          timestamp: DateTime.now(),
        );
        return;
      }

      // 3. Parse LLM response for Thought, Action, and Response
      final thought = _parseThought(rawLlmResponse);
      final action = _parseAction(rawLlmResponse);
      final response = _parseResponse(rawLlmResponse);

      if (thought.isNotEmpty) {
        yield AgentStep(
          type: 'thought',
          title: 'Thought',
          content: thought,
          timestamp: DateTime.now(),
        );
      }

      // 4. Handle Action (Tool execution)
      if (action != null) {
        final toolName = action['tool'] as String;
        final toolArgs = action['args'] as Map<String, dynamic>;

        yield AgentStep(
          type: 'action',
          title: 'Invoking Tool: $toolName',
          content: 'Arguments: ${jsonEncode(toolArgs)}',
          timestamp: DateTime.now(),
        );

        final tool = _toolRegistry.getTool(toolName);
        String observation = '';

        if (tool == null) {
          observation = 'Error: Tool "$toolName" is not registered in this agent environment.';
        } else {
          try {
            observation = await tool.execute(toolArgs);
          } catch (e) {
            observation = 'Error executing tool "$toolName": $e';
          }
        }

        yield AgentStep(
          type: 'observation',
          title: 'Observation from $toolName',
          content: observation,
          timestamp: DateTime.now(),
        );

        // Add this round to the history
        reactHistory.add({
          'thought': thought,
          'action': '$toolName with arguments ${jsonEncode(toolArgs)}',
          'observation': observation,
        });

      } else if (response.isNotEmpty) {
        // 5. Final Response received! Emit and terminate loop.
        yield AgentStep(
          type: 'final_answer',
          title: 'Final Answer',
          content: response,
          timestamp: DateTime.now(),
        );
        return;
      } else {
        // Fallback: If model output didn't conform but gave plain text, treat it as final response.
        final cleanText = rawLlmResponse
            .replaceAll(RegExp(r'Thought:'), '')
            .replaceAll(RegExp(r'Response:'), '')
            .trim();
        yield AgentStep(
          type: 'final_answer',
          title: 'Final Answer (Fallback)',
          content: cleanText,
          timestamp: DateTime.now(),
        );
        return;
      }
    }

    // If max turns reached without a Response
    yield AgentStep(
      type: 'final_answer',
      title: 'Final Answer (Max Turns Reached)',
      content: 'I reached the limit of operational turns ($maxTurns) without producing a definitive response. Here is what I gathered: \n\n'
          '${reactHistory.map((h) => '* **Step**: ${h['thought']}\n  * **Result**: ${h['observation']}').join('\n')}',
      timestamp: DateTime.now(),
    );
  }

  String _buildReActPrompt(String userQuery, List<Map<String, String>> history) {
    final toolsDescription = _toolRegistry.tools.map((t) {
      return '- **${t.name}**: ${t.description}\n  Parameter Schema: ${jsonEncode(t.parameterSchema)}';
    }).join('\n');

    final historyBlock = history.isEmpty
        ? 'No historical actions performed yet.'
        : history.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final turn = entry.value;
            return '''
Turn $idx:
Thought: ${turn['thought']}
Action: ${turn['action']}
Observation: ${turn['observation']}
''';
          }).join('\n');

    return '''
You are an autonomous ReAct Agent operating inside the MOMO AI Framework. Your job is to answer the User Query by thinking step-by-step and running specialized tools when necessary.

### Available Tools:
$toolsDescription

### Execution Protocol (ReAct):
You must run in a loop of Thought -> Action -> Observation.
For each turn, you MUST write a single "Thought:" line explaining your reasoning, followed by either:
1. An "Action:" line to invoke one of the available tools.
2. A "Response:" line to provide the final answer to the user.

Strict format rules for invoking tools:
Thought: <explain what you need to find out and which tool to use>
Action: <tool_name> with arguments <valid JSON object mapping parameter names to values>
(Example: Action: web_search with arguments {"query": "weather in Tokyo"})

Strict format rules for the final answer:
Thought: <explain that you have gathered all necessary information>
Response: <your markdown-formatted answer to the user. If you generated an image with stable_diffusion, you MUST include the exact markdown image tag returned in the observation, e.g. ![draw](file:///...) inside the response>

### Previous Turn History:
$historyBlock

### Current Objective:
User Query: "$userQuery"

Analyze the Objective and the Turn History. Write your Thought and either an Action or a Response. Do not add any extra headers or text outside this structure.
''';
  }

  String _parseThought(String output) {
    final match = RegExp(r'Thought:\s*(.*?)(?=Action:|Response:|$)', dotAll: true).firstMatch(output);
    return match?.group(1)?.trim() ?? '';
  }

  Map<String, dynamic>? _parseAction(String output) {
    final match = RegExp(r'Action:\s*(\w+)\s+with arguments\s*(\{.*?\})', dotAll: true).firstMatch(output);
    if (match != null) {
      final name = match.group(1)!.trim();
      final argsStr = match.group(2)!.trim();
      try {
        final args = jsonDecode(argsStr) as Map<String, dynamic>;
        return {'tool': name, 'args': args};
      } catch (_) {
        // If decoding failed, fallback to treating query as arg if it's simple
        return {'tool': name, 'args': <String, dynamic>{}};
      }
    }
    return null;
  }

  String _parseResponse(String output) {
    final match = RegExp(r'Response:\s*(.*)', dotAll: true).firstMatch(output);
    return match?.group(1)?.trim() ?? '';
  }
}
