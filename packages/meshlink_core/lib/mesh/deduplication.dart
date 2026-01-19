import '../database/app_database.dart';
import 'ble_constants.dart';

/// Message deduplication engine
/// Tracks seen message IDs to prevent forwarding loops in mesh network
class DeduplicationEngine {
  final AppDatabase _db;

  DeduplicationEngine(this._db);

  /// Check if we've seen this message before
  /// Returns true if message has been seen and not yet expired
  Future<bool> hasSeenMessage(String messageId) async {
    final seen = await _db.getMeshSeenMessage(messageId);

    if (seen == null) {
      return false;
    }

    // Check if expired
    if (seen.expiresAt.isBefore(DateTime.now())) {
      // Expired, treat as not seen
      return false;
    }

    return true;
  }

  /// Mark a message as seen
  /// Stores message ID with expiration time
  Future<void> markMessageSeen(String messageId) async {
    final now = DateTime.now();
    final expiresAt = now.add(BleConstants.messageDeduplicationTtl);

    await _db.insertMeshSeenMessage(
      messageId: messageId,
      seenAt: now,
      expiresAt: expiresAt,
    );
  }

  /// Cleanup expired seen messages
  /// Should be called periodically to prevent database bloat
  Future<void> cleanup() async {
    await _db.deleteExpiredMeshSeenMessages();
  }

  /// Get count of currently tracked message IDs (for debugging/monitoring)
  Future<int> getSeenMessageCount() async {
    // This would require adding a count query to AppDatabase
    // For now, return 0 as placeholder
    // TODO: Add count query to AppDatabase
    return 0;
  }
}
