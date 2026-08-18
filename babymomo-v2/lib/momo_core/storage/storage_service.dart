/// MOMO Core — Storage Service abstraction.
///
/// Wraps Hive CE behind an interface so the storage implementation
/// can be swapped without touching any feature code.
abstract class StorageService {
  /// Initialize storage (open boxes, register adapters).
  Future<void> init();

  /// Get a value by key from a named box.
  Future<T?> get<T>(String box, String key);

  /// Put a value by key into a named box.
  Future<void> put<T>(String box, String key, T value);

  /// Delete a key from a named box.
  Future<void> delete(String box, String key);

  /// Get all values from a named box.
  Future<List<T>> getAll<T>(String box);

  /// Clear all entries in a named box.
  Future<void> clearBox(String box);

  /// Check if a key exists in a named box.
  Future<bool> containsKey(String box, String key);

  /// Listen to changes in a box (reactive).
  Stream<T?> watch<T>(String box, String key);

  /// Close all open boxes and release resources.
  Future<void> dispose();
}

/// Box name constants — single source of truth for box naming.
class StorageBoxes {
  static const String chats = 'chats';
  static const String sessions = 'sessions';
  static const String models = 'models';
  static const String memory = 'memory';
  static const String settings = 'settings';
  static const String downloads = 'downloads';

  StorageBoxes._();
}
