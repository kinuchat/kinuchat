/// BLE mesh transport implementation
///
/// This is a placeholder for Phase 2 implementation.
abstract class MeshTransport {
  /// Send a message via mesh transport
  Future<void> sendMessage({
    required String recipientId,
    required Map<String, dynamic> message,
  });

  /// Check if mesh transport is available
  Future<bool> isAvailable();

  /// Get count of nearby mesh peers
  Future<int> getPeerCount();
}
