/// BLE service and characteristic UUIDs for MeshLink
/// Based on Phase 2 spec requirements
class BleConstants {
  // Prevent instantiation
  BleConstants._();

  // ============================================================================
  // Service and Characteristic UUIDs
  // ============================================================================

  /// MeshLink BLE Service UUID
  /// Randomly generated UUID unique to MeshLink application
  static const String meshLinkServiceUuid =
      '6d65736c-696e-6b00-0000-000000000000';

  /// Peer Announcement Characteristic (readable)
  /// Used to advertise mesh peer ID and basic info
  static const String peerAnnouncementCharUuid =
      '6d65736c-696e-6b01-0000-000000000000';

  /// Message Packet Characteristic (write/notify)
  /// Used to send/receive message packets
  static const String messagePacketCharUuid =
      '6d65736c-696e-6b02-0000-000000000000';

  /// Handshake Characteristic (write/notify)
  /// Used for Noise Protocol XX handshake messages
  static const String handshakeCharUuid =
      '6d65736c-696e-6b03-0000-000000000000';

  // ============================================================================
  // Protocol Parameters
  // ============================================================================

  /// Maximum BLE packet size (conservative for compatibility)
  /// Accounts for MTU overhead and ensures wide device support
  static const int maxPacketSize = 512;

  /// Maximum hops a message can travel (TTL limit)
  static const int maxHops = 7;

  /// Mesh peer ID length in bytes (SHA256 truncated)
  static const int meshPeerIdLength = 8;

  /// Message ID length in bytes (SHA256 truncated)
  static const int messageIdLength = 16;

  // ============================================================================
  // Timing Parameters
  // ============================================================================

  /// How often to perform BLE scan
  static const Duration scanInterval = Duration(seconds: 30);

  /// Duration of each scan cycle
  static const Duration scanDuration = Duration(seconds: 10);

  /// BLE connection timeout
  static const Duration connectionTimeout = Duration(seconds: 15);

  /// Peer announcement interval (how often to re-broadcast presence)
  static const Duration peerAnnouncementInterval = Duration(seconds: 60);

  /// Route expiration time (if not refreshed)
  static const Duration routeExpiration = Duration(minutes: 10);

  /// Store-and-forward queue expiration (max time in queue)
  static const Duration storeAndForwardTtl = Duration(hours: 24);

  /// Seen message deduplication TTL
  static const Duration messageDeduplicationTtl = Duration(hours: 1);

  // ============================================================================
  // Signal Strength Parameters
  // ============================================================================

  /// Minimum RSSI (signal strength) to attempt connection (in dBm)
  /// Weaker signals are ignored to save battery
  static const int minRssiForConnection = -80;

  /// Excellent signal strength threshold (in dBm)
  static const int excellentRssi = -50;

  /// Good signal strength threshold (in dBm)
  static const int goodRssi = -65;

  /// Fair signal strength threshold (in dBm)
  static const int fairRssi = -75;

  // Poor/weak below this threshold

  // ============================================================================
  // Connection Management
  // ============================================================================

  /// Maximum number of concurrent BLE connections
  /// Balances connectivity vs battery/memory
  static const int maxConcurrentConnections = 5;

  /// Maximum peers to discover before pausing scan
  static const int maxDiscoveredPeers = 50;

  /// Idle disconnect timeout (disconnect if no traffic)
  static const Duration idleDisconnectTimeout = Duration(minutes: 5);

  // ============================================================================
  // Quality Score Parameters
  // ============================================================================

  /// Base quality score for new routes
  static const double baseQualityScore = 1.0;

  /// Quality score decay per hop
  static const double qualityDecayPerHop = 0.15;

  /// Quality score bonus for recent successful delivery
  static const double successBonus = 0.2;

  /// Quality score penalty for failed delivery
  static const double failurePenalty = 0.3;
}
