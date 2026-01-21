/// Spec Reference for E2E Tests
///
/// This file contains constants and references to the MeshLink specification
/// located at: .claude/context/SPEC.md
///
/// Version: 1.0.0-draft
/// Last Updated: January 2026

/// Protocol Constants from Spec Section 6
class SpecProtocol {
  // 6.1 Identity and Keys
  static const String signingKeyAlgorithm = 'Ed25519';
  static const String keyExchangeAlgorithm = 'X25519';
  static const int meshPeerIdLength = 8; // bytes, truncated from SHA256

  // 6.2 Noise Protocol Handshake
  static const String noisePattern = 'XX';
  static const String noiseCipher = 'ChaChaPoly';
  static const String noiseHash = 'SHA256';
  static const String noiseDH = 'X25519';

  // 6.3 Message Packet Format
  static const int protocolVersion = 0x01;
  static const int maxTTL = 7;
  static const int messageIdLength = 16;
  static const int recipientIdLength = 8;

  // Message Types (Spec 6.3)
  static const int msgTypeText = 0x01;
  static const int msgTypeMediaHeader = 0x02;
  static const int msgTypeMediaChunk = 0x03;
  static const int msgTypeAck = 0x04;
  static const int msgTypeHandshakeInit = 0x05;
  static const int msgTypeHandshakeResp = 0x06;
  static const int msgTypePeerAnnounce = 0x07;
  static const int msgTypeRelayRequest = 0x08;
  static const int msgTypeRallyBroadcast = 0x09;

  // Flags (Spec 6.3)
  static const int flagHasRecipient = 0x01;
  static const int flagHasSignature = 0x02;
  static const int flagIsCompressed = 0x04;
  static const int flagIsFragmented = 0x08;
  static const int flagRequiresAck = 0x10;

  // Padding buckets (Spec 6.3 - resist traffic analysis)
  static const List<int> paddingBuckets = [256, 512, 1024, 2048];
}

/// Relay Server Protocol from Spec Section 6.4
class SpecRelay {
  // Envelope format
  static const int defaultTtlHours = 4;
  static const List<String> priorities = ['normal', 'urgent', 'emergency'];

  // Endpoints
  static const String uploadEndpoint = '/relay/upload';
  static const String pollEndpoint = '/relay/poll';
  static const String wsEndpoint = '/ws';

  // Privacy guarantees (from spec)
  static const String privacyGuarantee1 =
      'Bridge node cannot read payload (E2E encrypted)';
  static const String privacyGuarantee2 =
      'Bridge node cannot identify sender (not in envelope)';
  static const String privacyGuarantee3 =
      'Relay server only sees key hash (not full key)';
  static const String privacyGuarantee4 = 'TTL prevents indefinite storage';
}

/// Rally Channel Protocol from Spec Section 6.5
class SpecRally {
  // Channel ID derivation
  static const int geohashPrecision = 6; // ~1.2km cell
  static const int timeBucketHours = 4;
  static const int channelIdLength = 16;

  // Encryption
  static const String hkdfSalt = 'meshlink-rally-v1';
  static const int channelKeyLength = 32;

  // Identity
  static const String anonymousNamePattern = r'^[a-z]+-[a-z]+-\d{1,2}$';
}

/// Core Features from Spec Section 5
class SpecFeatures {
  // 5.1 Private Messaging
  static const int maxTextLength = -1; // unlimited, chunked
  static const int voiceNoteMaxMinutes = 5;
  static const int cloudFileMaxMb = 25;
  static const int meshFileMaxMb = 1;

  // Delivery states
  static const String statusPending = 'pending';
  static const String statusSent = 'sent';
  static const String statusDelivered = 'delivered';
  static const String statusRead = 'read';
  static const String statusFailed = 'failed';

  // 5.2 Group Chats
  static const int cloudGroupMaxMembers = 256;
  static const int meshGroupMaxMembers = 32;

  // 5.3 Mesh Mode
  static const int meshAutoActivatePeerThreshold = 5;

  // 5.4 Rally Mode
  static const int rallyMinAge = 16;

  // 5.5 Bridge Mode
  static const int bridgeDefaultBandwidthMbPerHour = 5;
  static const int bridgePauseBatteryPercent = 30;
}

/// Transport Decision Matrix from Spec Section 3
class SpecTransport {
  /// Decision matrix for transport selection
  ///
  /// | Condition        | Transport     | Fallback              |
  /// |------------------|---------------|-----------------------|
  /// | Strong internet  | Cloud         | None                  |
  /// | Weak internet    | Cloud         | Mesh (if peer nearby) |
  /// | No internet      | Mesh          | Bridge relay          |
  /// | Peer in BLE      | Mesh (faster) | Cloud                 |
  /// | Rally mode       | Mesh broadcast| None                  |
  /// | Bridge enabled   | Cloud         | Relay server          |
  static String selectTransport({
    required bool hasInternet,
    required bool isInternetStrong,
    required bool hasMeshPeer,
    required bool isRallyMode,
    required bool isBridgeEnabled,
  }) {
    if (isRallyMode) return 'mesh_broadcast';
    if (!hasInternet) {
      if (hasMeshPeer) return 'mesh';
      if (isBridgeEnabled) return 'bridge';
      return 'queued';
    }
    if (hasMeshPeer && !isInternetStrong) return 'mesh';
    return 'cloud';
  }
}

/// UI Constants from Spec Section 7
class SpecUI {
  // Colors (light mode)
  static const int colorBackground = 0xFFFAFAFA;
  static const int colorPrimary = 0xFF1B7F6E;
  static const int colorMeshActive = 0xFF00BCD4;
  static const int colorBridgeActive = 0xFFFFB300;
  static const int colorRallyMode = 0xFF7C4DFF;

  // Transport indicators
  static const String indicatorCloud = '\u2601\ufe0f'; // cloud emoji
  static const String indicatorMesh = '\ud83d\udce1'; // satellite antenna
  static const String indicatorBridge = '\ud83c\udf09'; // bridge at night
  static const String indicatorQueued = '\u23f3'; // hourglass

  // Message status symbols
  static const String statusSymbolPending = '\u25cb'; // circle
  static const String statusSymbolSent = '\u2713'; // checkmark
  static const String statusSymbolDelivered = '\u2713\u2713'; // double check
  static const String statusSymbolFailed = '!';
}
