import 'package:get/get.dart';
import 'plugin_interface.dart';

/// MOMO Core — Plugin Manager.
///
/// Manages the lifecycle of all registered plugins.
/// Handles registration, discovery, and orderly shutdown.
class PluginManager extends GetxService {
  final List<MomoPlugin> _plugins = [];
  late final PluginContext _context;

  /// Initialize with plugin context.
  void configure(PluginContext context) {
    _context = context;
  }

  /// Register a plugin. Calls [MomoPlugin.onRegister].
  Future<void> register(MomoPlugin plugin) async {
    // Prevent duplicate registration
    if (_plugins.any((p) => p.id == plugin.id)) {
      throw StateError('Plugin "${plugin.id}" is already registered');
    }

    await plugin.onRegister(_context);
    _plugins.add(plugin);
  }

  /// Unregister a plugin by ID. Calls [MomoPlugin.onUnregister].
  Future<void> unregister(String pluginId) async {
    final plugin = _plugins.firstWhereOrNull((p) => p.id == pluginId);
    if (plugin != null) {
      await plugin.onUnregister();
      _plugins.remove(plugin);
    }
  }

  /// Get all plugins of a specific type.
  List<MomoPlugin> byType(PluginType type) {
    return _plugins.where((p) => p.type == type).toList();
  }

  /// Get all registered plugins.
  List<MomoPlugin> get all => List.unmodifiable(_plugins);

  /// Shutdown all plugins in reverse registration order.
  Future<void> shutdownAll() async {
    for (final plugin in _plugins.reversed) {
      await plugin.onUnregister();
    }
    _plugins.clear();
  }
}
