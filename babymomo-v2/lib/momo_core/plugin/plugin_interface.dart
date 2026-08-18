import '../runtime/runtime_registry.dart';
import '../storage/storage_service.dart';
import '../agent/momo_tool.dart';

/// MOMO Core — Plugin Interface.
///
/// Every plugin must implement this contract.
/// Plugins extend MOMO's capabilities without modifying core code.
abstract class MomoPlugin {
  /// Unique plugin identifier.
  String get id;

  /// Human-readable plugin name.
  String get name;

  /// Semantic version string.
  String get version;

  /// What kind of plugin this is.
  PluginType get type;

  /// Called when the plugin is registered with the system.
  /// Use [context] to register runtimes, tools, etc.
  Future<void> onRegister(PluginContext context);

  /// Called when the plugin is being removed.
  Future<void> onUnregister();
}

/// Plugin type classification.
///
/// Note: Make sure to keep the elements in line with the MOMO system.
enum PluginType {
  /// New inference backends (llama.cpp, Whisper, etc.)
  runtime,

  /// Agent tools (web search, calculator, file I/O)
  tool,

  /// Custom UI components (AI cards, surfaces)
  uiExtension,

  /// Autonomous task executors
  agent,
}

/// Sandboxed context given to plugins.
/// Plugins cannot access UI directly — they are headless.
class PluginContext {
  final RuntimeRegistry runtimeRegistry;
  final StorageService storage;
  final ToolRegistry toolRegistry;

  const PluginContext({
    required this.runtimeRegistry,
    required this.storage,
    required this.toolRegistry,
  });
}
