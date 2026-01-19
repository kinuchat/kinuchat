/// Transport manager interface
/// Based on Section 3 of the specification
///
/// Handles automatic selection between cloud, mesh, and bridge transports
/// based on network conditions and peer availability.
///
/// This is a placeholder for Phase 2 implementation.
abstract class TransportManager {
  /// Select the optimal transport for a message
  Future<Transport> selectTransport({
    required String recipientId,
    required Map<String, dynamic> message,
  });

  /// Get current transport status
  TransportStatus getStatus();
}

/// Available transport types
enum Transport {
  /// Cloud transport via Matrix
  cloud,

  /// BLE mesh transport
  mesh,

  /// Bridge relay transport
  bridge,
}

/// Transport status information
class TransportStatus {
  const TransportStatus({
    required this.currentTransport,
    required this.isOnline,
    this.meshPeerCount = 0,
    this.isBridgeActive = false,
  });

  final Transport currentTransport;
  final bool isOnline;
  final int meshPeerCount;
  final bool isBridgeActive;
}
