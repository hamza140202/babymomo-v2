import 'package:get/get.dart';
import 'models/memory_entry.dart';
import '../storage/storage_service.dart';

/// MOMO Core — Memory Engine.
///
/// Manages conversation memory and context building.
/// Builds optimized context windows for inference requests.
class MemoryEngine extends GetxService {
  final StorageService _storage;

  MemoryEngine({required StorageService storage}) : _storage = storage;

  /// Store a memory entry.
  Future<void> store(MemoryEntry entry) async {
    await _storage.put(StorageBoxes.memory, entry.id, entry.toMap());
  }

  /// Retrieve memories for a session.
  Future<List<MemoryEntry>> forSession(String sessionId) async {
    final all = await _storage.getAll<Map>(StorageBoxes.memory);
    return all
        .map((m) => MemoryEntry.fromMap(Map<String, dynamic>.from(m)))
        .where((e) => e.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Build a context window from session history, respecting token limits.
  Future<List<MemoryEntry>> buildContext({
    required String sessionId,
    int maxEntries = 20,
  }) async {
    final entries = await forSession(sessionId);
    // Take the most recent entries that fit within the context window
    if (entries.length > maxEntries) {
      return entries.sublist(entries.length - maxEntries);
    }
    return entries;
  }
}
