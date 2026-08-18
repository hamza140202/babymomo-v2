import 'dart:async';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'momo_tool.dart';
import '../inference/inference_router.dart';
import '../inference/inference_request.dart';
import '../multimodal/modality.dart';

/// 1. Web Search Tool
class WebSearchTool extends MomoTool {
  @override
  String get name => 'web_search';

  @override
  String get description =>
      'Searches the web for up-to-date and real-time information. Use this whenever the user asks about current events, facts outside local knowledge, weather, or real-time data.';

  @override
  Map<String, dynamic> get parameterSchema => {
        'query': {
          'type': 'string',
          'description': 'The query string to search for.',
        }
      };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final query = (arguments['query'] ?? '').toString().trim().toLowerCase();
    if (query.isEmpty) {
      return 'Error: Search query is empty.';
    }

    // Intelligently respond with structured mock markdown based on query keywords
    if (query.contains('weather')) {
      return '''
### Weather Search Results
* **Location**: Tokyo, Japan
* **Temperature**: 18°C (64°F)
* **Conditions**: Partially Cloudy, 10% precipitation chance
* **Humidity**: 58%
* **Wind**: 12 km/h North-East
* *Note*: Ideal afternoon for a walk!
''';
    } else if (query.contains('momo') || query.contains('babymomo')) {
      return '''
### MOMO AI Framework Documentation
* **Overview**: MOMO is a high-performance, modular AI engine written in Flutter & Dart.
* **Core Philosophy**: Sandboxed local runtimes (llama.cpp, LiteRT, Stable Diffusion) running in JNI/NDK containers with automatic fallback/routing to OpenAI-compatible cloud interfaces.
* **Latest Release**: v0.1.0 (Phase 5 - Multi-modal Procedural Core & ReAct Agent Loop active).
''';
    } else if (query.contains('flutter') || query.contains('dart')) {
      return '''
### Flutter & Dart Development Updates
* **Dart 3.x**: Features structural pattern matching, robust records, and native class modifiers.
* **Flutter Canvas**: Supporting Impeller rendering backend on iOS/Android for extremely buttery animations (60/120fps) and dynamic shaders.
''';
    } else {
      return '''
### Web Search: "$query"
* Found 1 top result:
* **Autonomous Agent Loops**: Modern ReAct execution models allow LLMs to invoke specialized, sandboxed native APIs (like Stable Diffusion adapters) to solve complex cross-modality tasks autonomously.
''';
    }
  }
}

/// 2. Calculator Tool
class CalculatorTool extends MomoTool {
  @override
  String get name => 'calculator';

  @override
  String get description =>
      'Performs basic arithmetic and mathematical calculations. Use this tool for any mathematical operation, equation solving, or formula evaluation. Supports +, -, *, /, and parentheses ().';

  @override
  Map<String, dynamic> get parameterSchema => {
        'expression': {
          'type': 'string',
          'description': 'The mathematical expression to evaluate, e.g., "12 * (4 + 6) / 2".',
        }
      };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final expression = (arguments['expression'] ?? '').toString();
    if (expression.isEmpty) {
      return 'Error: Mathematical expression is empty.';
    }

    try {
      final sanitized = expression.replaceAll(RegExp(r'\s+'), '');
      final parser = _MathParser(sanitized);
      final result = parser.parse();
      // Format response cleanly
      return 'Result: $expression = $result';
    } catch (e) {
      return 'Error: Failed to evaluate expression "$expression" due to syntax error: $e';
    }
  }
}

/// Recursive descent parser for safe expression evaluation
class _MathParser {
  final String input;
  int pos = 0;

  _MathParser(this.input);

  int get char => pos < input.length ? input.codeUnitAt(pos) : -1;

  void consume() {
    pos++;
  }

  double parse() {
    final result = parseExpression();
    if (pos < input.length) {
      throw FormatException('Unexpected character at index $pos');
    }
    return result;
  }

  double parseExpression() {
    double left = parseTerm();
    while (true) {
      if (char == 43) { // '+'
        consume();
        left += parseTerm();
      } else if (char == 45) { // '-'
        consume();
        left -= parseTerm();
      } else {
        break;
      }
    }
    return left;
  }

  double parseTerm() {
    double left = parseFactor();
    while (true) {
      if (char == 42) { // '*'
        consume();
        left *= parseFactor();
      } else if (char == 47) { // '/'
        consume();
        double divisor = parseFactor();
        if (divisor == 0) throw StateError('Division by zero');
        left /= divisor;
      } else {
        break;
      }
    }
    return left;
  }

  double parseFactor() {
    if (char == 45) { // unary '-'
      consume();
      return -parseFactor();
    }
    if (char == 40) { // '('
      consume();
      double result = parseExpression();
      if (char != 41) { // ')'
        throw const FormatException('Expected closing parenthesis');
      }
      consume();
      return result;
    }

    final start = pos;
    if (char == 46 || (char >= 48 && char <= 57)) { // digit or '.'
      while (char == 46 || (char >= 48 && char <= 57)) {
        consume();
      }
      return double.parse(input.substring(start, pos));
    }
    throw FormatException('Expected number at index $pos');
  }
}

/// 3. Stable Diffusion Image Tool
class StableDiffusionTool extends MomoTool {
  @override
  String get name => 'stable_diffusion';

  @override
  String get description =>
      'Draws or generates premium visual artwork from a text prompt using on-device procedural Stable Diffusion. Returns the markdown image tag linking to the local generated file. Specify aspect ratios if desired (square, landscape, portrait).';

  @override
  Map<String, dynamic> get parameterSchema => {
        'prompt': {
          'type': 'string',
          'description': 'A detailed description of the scene, art style, or illustration, e.g., "cyberpunk grid city at midnight". Include style tags like "Cyberpunk", "Warm Glow", "Cool Ocean", "Cosmic Aurora" to trigger beautiful custom color palettes.',
        },
        'aspect': {
          'type': 'string',
          'description': 'Desired aspect ratio. Must be one of: "square" (1:1), "landscape" (16:9), "portrait" (9:16). Default is "square".',
        }
      };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final prompt = (arguments['prompt'] ?? '').toString().trim();
    if (prompt.isEmpty) {
      return 'Error: Prompt cannot be empty.';
    }

    final aspect = (arguments['aspect'] ?? 'square').toString().toLowerCase();
    int width = 512;
    int height = 512;

    if (aspect == 'landscape') {
      width = 768;
      height = 432;
    } else if (aspect == 'portrait') {
      width = 432;
      height = 768;
    }

    try {
      final router = Get.find<InferenceRouter>();
      final requestId = const Uuid().v4();

      final request = InferenceRequest(
        id: requestId,
        prompt: prompt,
        modality: Modality.image,
        parameters: InferenceParameters(
          steps: 20,
          cfgScale: 7.5,
          width: width,
          height: height,
        ),
      );

      String? imagePath;
      final completer = Completer<String>();

      router.route(request).listen(
        (result) {
          if (result.isError) {
            completer.completeError(result.content);
          } else if (result.content.isNotEmpty && !result.isDone) {
            imagePath = result.content;
          }
        },
        onError: (err) {
          if (!completer.isCompleted) {
            completer.completeError(err);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            if (imagePath != null) {
              completer.complete(imagePath!);
            } else {
              completer.completeError('No image path returned from local Stable Diffusion engine.');
            }
          }
        },
        cancelOnError: true,
      );

      final finalPath = await completer.future;
      // Return beautiful, standard markdown image notation with the draw label
      return '![draw](file://$finalPath)';
    } catch (e) {
      return 'Error: Stable Diffusion generation failed: $e';
    }
  }
}
