/// Bridge relay transport implementation
///
/// This is a placeholder for Phase 4 implementation.
abstract class BridgeTransport {
  /// Send a message via bridge relay
  Future<void> sendMessage({
    required String recipientId,
    required Map<String, dynamic> message,
  });

  /// Check if bridge transport is available
  Future<bool> isAvailable();

  /// Poll for messages from relay server
  Future<List<Map<String, dynamic>>> pollMessages();
}
