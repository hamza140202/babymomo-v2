/// MOMO Core — Memory Entry model.
///
/// Represents a single memory unit (message, context, fact).
class MemoryEntry {
  final String id;
  final String sessionId;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const MemoryEntry({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

  factory MemoryEntry.fromMap(Map<String, dynamic> map) => MemoryEntry(
        id: map['id'] as String,
        sessionId: map['sessionId'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        metadata: map['metadata'] as Map<String, dynamic>?,
      );
}
