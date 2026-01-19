/// Cloud transport implementation using Matrix protocol
///
/// This is a placeholder for Phase 1 implementation.
abstract class CloudTransport {
  /// Send a message via cloud transport
  Future<void> sendMessage({
    required String recipientId,
    required Map<String, dynamic> message,
  });

  /// Check if cloud transport is available
  Future<bool> isAvailable();
}
