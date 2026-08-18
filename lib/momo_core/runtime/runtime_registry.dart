import 'runtime_engine.dart';
import 'capability.dart';

/// MOMO Core — Runtime Registry.
///
/// Central registry for all available runtime engines.
/// The [InferenceRouter] queries this to find capable runtimes.
/// Plugins register new runtimes here via [PluginContext].
class RuntimeRegistry {
  final Map<String, RuntimeEngine> _runtimes = {};

  /// Register a runtime engine. Overwrites if ID already exists.
  void register(RuntimeEngine engine) {
    _runtimes[engine.id] = engine;
  }

  /// Unregister a runtime by ID.
  void unregister(String id) {
    _runtimes.remove(id);
  }

  /// Resolve a runtime by its unique ID.
  RuntimeEngine? resolve(String id) => _runtimes[id];

  /// Get all runtimes that support a given capability.
  List<RuntimeEngine> byCapability(RuntimeCapability capability) {
    return _runtimes.values
        .where((e) => e.capabilities.contains(capability))
        .toList();
  }

  /// Get all registered runtime IDs.
  List<String> get registeredIds => _runtimes.keys.toList();

  /// Get all registered runtimes.
  List<RuntimeEngine> get all => _runtimes.values.toList();

  /// Check if any runtime is registered.
  bool get isEmpty => _runtimes.isEmpty;

  /// Total count of registered runtimes.
  int get count => _runtimes.length;
}
