import 'dart:typed_data';
import 'ble_constants.dart';

/// Message types for MeshLink packets
/// Based on spec Section 6.3
enum PacketType {
  text(0x01),
  mediaHeader(0x02),
  mediaChunk(0x03),
  ack(0x04),
  handshakeInit(0x05),
  handshakeResp(0x06),
  handshakeComplete(0x07),
  peerAnnounce(0x08),
  relayRequest(0x09),
  rallyBroadcast(0x0A);

  const PacketType(this.value);
  final int value;

  static PacketType fromValue(int value) {
    return PacketType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown packet type: $value'),
    );
  }
}

/// Packet flags (bitmask)
/// Based on spec Section 6.3
class PacketFlags {
  // Prevent instantiation
  PacketFlags._();

  /// Packet has specific recipient (not broadcast)
  static const int hasRecipient = 0x01;

  /// Packet includes Ed25519 signature
  static const int hasSignature = 0x02;

  /// Payload is compressed
  static const int isCompressed = 0x04;

  /// Message is fragmented (multi-packet)
  static const int isFragmented = 0x08;

  /// Sender requests ACK
  static const int requiresAck = 0x10;

  /// Check if flag is set
  static bool hasFlag(int flags, int flag) => (flags & flag) != 0;

  /// Set flag
  static int setFlag(int flags, int flag) => flags | flag;

  /// Clear flag
  static int clearFlag(int flags, int flag) => flags & ~flag;
}

/// MeshLink packet structure
/// Per spec Section 6.3: Fixed 64-byte header + variable payload
class MeshPacket {
  /// Protocol version (always 0x01 for now)
  final int version;

  /// Message type
  final PacketType type;

  /// Time-to-live (hop limit, decremented each hop)
  final int ttl;

  /// Flags bitmask
  final int flags;

  /// Unix timestamp in milliseconds
  final DateTime timestamp;

  /// Message ID (16 bytes, SHA256 truncated)
  final Uint8List messageId;

  /// Recipient mesh peer ID (8 bytes, null for broadcast)
  final Uint8List? recipientId;

  /// Encrypted payload
  final Uint8List payload;

  /// Optional Ed25519 signature (64 bytes)
  final Uint8List? signature;

  MeshPacket({
    this.version = 1,
    required this.type,
    required this.ttl,
    required this.flags,
    required this.timestamp,
    required this.messageId,
    this.recipientId,
    required this.payload,
    this.signature,
  }) {
    // Validation
    if (messageId.length != BleConstants.messageIdLength) {
      throw ArgumentError(
        'Message ID must be ${BleConstants.messageIdLength} bytes',
      );
    }
    if (recipientId != null &&
        recipientId!.length != BleConstants.meshPeerIdLength) {
      throw ArgumentError(
        'Recipient ID must be ${BleConstants.meshPeerIdLength} bytes',
      );
    }
    if (signature != null && signature!.length != 64) {
      throw ArgumentError('Signature must be 64 bytes');
    }
    if (ttl < 0 || ttl > BleConstants.maxHops) {
      throw ArgumentError('TTL must be between 0 and ${BleConstants.maxHops}');
    }
  }

  /// Copy with modifications
  MeshPacket copyWith({
    int? version,
    PacketType? type,
    int? ttl,
    int? flags,
    DateTime? timestamp,
    Uint8List? messageId,
    Uint8List? recipientId,
    Uint8List? payload,
    Uint8List? signature,
  }) {
    return MeshPacket(
      version: version ?? this.version,
      type: type ?? this.type,
      ttl: ttl ?? this.ttl,
      flags: flags ?? this.flags,
      timestamp: timestamp ?? this.timestamp,
      messageId: messageId ?? this.messageId,
      recipientId: recipientId ?? this.recipientId,
      payload: payload ?? this.payload,
      signature: signature ?? this.signature,
    );
  }

  /// Encode packet to binary format
  /// Header format (64 bytes fixed):
  /// - version (1 byte)
  /// - type (1 byte)
  /// - ttl (1 byte)
  /// - flags (1 byte)
  /// - timestamp (8 bytes, big-endian)
  /// - messageId (16 bytes)
  /// - recipientId (8 bytes, or zeros if null)
  /// - padding (28 bytes reserved)
  /// Followed by variable-length payload
  Uint8List encode() {
    final buffer = ByteData(64); // Fixed header size
    int offset = 0;

    // Version
    buffer.setUint8(offset++, version);

    // Type
    buffer.setUint8(offset++, type.value);

    // TTL
    buffer.setUint8(offset++, ttl);

    // Flags
    buffer.setUint8(offset++, flags);

    // Timestamp (8 bytes, big-endian)
    buffer.setUint64(offset, timestamp.millisecondsSinceEpoch);
    offset += 8;

    // Message ID (16 bytes)
    final headerBytes = buffer.buffer.asUint8List();
    headerBytes.setRange(offset, offset + 16, messageId);
    offset += 16;

    // Recipient ID (8 bytes, or zeros if broadcast)
    if (recipientId != null) {
      headerBytes.setRange(offset, offset + 8, recipientId!);
    }
    // else: zeros already initialized
    offset += 8;

    // Padding (28 bytes) - already zeros

    // Combine header + payload
    final result = Uint8List(64 + payload.length);
    result.setRange(0, 64, headerBytes);
    result.setRange(64, 64 + payload.length, payload);

    return result;
  }

  /// Decode packet from binary format
  static MeshPacket decode(Uint8List bytes) {
    if (bytes.length < 64) {
      throw ArgumentError('Packet too small: ${bytes.length} bytes');
    }

    final buffer = ByteData.sublistView(bytes);
    int offset = 0;

    // Version
    final version = buffer.getUint8(offset++);
    if (version != 1) {
      throw ArgumentError('Unsupported protocol version: $version');
    }

    // Type
    final typeValue = buffer.getUint8(offset++);
    final type = PacketType.fromValue(typeValue);

    // TTL
    final ttl = buffer.getUint8(offset++);

    // Flags
    final flags = buffer.getUint8(offset++);

    // Timestamp
    final timestampMs = buffer.getUint64(offset);
    offset += 8;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);

    // Message ID (16 bytes)
    final messageId = Uint8List(16);
    messageId.setRange(0, 16, bytes, offset);
    offset += 16;

    // Recipient ID (8 bytes, or null if all zeros)
    final recipientIdBytes = Uint8List(8);
    recipientIdBytes.setRange(0, 8, bytes, offset);
    offset += 8;

    final recipientId = recipientIdBytes.every((b) => b == 0)
        ? null
        : recipientIdBytes;

    // Skip padding (28 bytes)
    offset = 64;

    // Payload (rest of bytes)
    final payload = Uint8List.sublistView(bytes, offset);

    return MeshPacket(
      version: version,
      type: type,
      ttl: ttl,
      flags: flags,
      timestamp: timestamp,
      messageId: messageId,
      recipientId: recipientId,
      payload: payload,
    );
  }

  /// Apply PKCS#7 padding to payload for traffic analysis resistance
  /// Pads to nearest power-of-2 bucket size
  static Uint8List applyPadding(Uint8List data) {
    // Find next power of 2
    int paddedSize = 64; // Minimum
    while (paddedSize < data.length) {
      paddedSize *= 2;
    }

    // Apply PKCS#7 padding
    final padLength = paddedSize - data.length;
    final padded = Uint8List(paddedSize);
    padded.setRange(0, data.length, data);

    // Fill padding with pad length value
    for (int i = data.length; i < paddedSize; i++) {
      padded[i] = padLength;
    }

    return padded;
  }

  /// Remove PKCS#7 padding
  static Uint8List removePadding(Uint8List data) {
    if (data.isEmpty) {
      return data;
    }

    // Last byte indicates padding length
    final padLength = data.last;

    // Validate padding
    if (padLength > data.length || padLength == 0) {
      // Invalid padding, return as-is
      return data;
    }

    // Check all padding bytes are same
    for (int i = data.length - padLength; i < data.length; i++) {
      if (data[i] != padLength) {
        // Invalid padding
        return data;
      }
    }

    // Remove padding
    return Uint8List.sublistView(data, 0, data.length - padLength);
  }

  @override
  String toString() {
    return 'MeshPacket('
        'version=$version, '
        'type=$type, '
        'ttl=$ttl, '
        'flags=0x${flags.toRadixString(16)}, '
        'timestamp=$timestamp, '
        'messageId=${_hexEncode(messageId)}, '
        'recipientId=${recipientId != null ? _hexEncode(recipientId!) : 'broadcast'}, '
        'payloadSize=${payload.length}'
        ')';
  }

  /// Helper to hex encode bytes
  static String _hexEncode(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
}
