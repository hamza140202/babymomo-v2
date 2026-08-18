/// MOMO Core — Agent Tool interface and registry.
///
/// Every action an autonomous agent can perform is wrapped in a [MomoTool].
abstract class MomoTool {
  /// Unique name of the tool, matching standard identifier rules (e.g. "web_search", "calculator").
  String get name;

  /// Clear, detailed description of when and how to use the tool,
  /// formatted for LLM understanding.
  String get description;

  /// Schema describing the expected input arguments.
  Map<String, dynamic> get parameterSchema;

  /// Executes the tool with parsed [arguments] and returns a string observation/result.
  Future<String> execute(Map<String, dynamic> arguments);
}

/// Registry for managing active agent tools.
class ToolRegistry {
  final Map<String, MomoTool> _tools = {};

  /// Registers a tool.
  void register(MomoTool tool) {
    _tools[tool.name] = tool;
  }

  /// Unregisters a tool by name.
  void unregister(String name) {
    _tools.remove(name);
  }

  /// Retrieves a tool by name.
  MomoTool? getTool(String name) {
    return _tools[name];
  }

  /// Returns all registered tools.
  List<MomoTool> get tools => _tools.values.toList();
}
