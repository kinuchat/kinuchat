import 'dart:typed_data';
import 'dart:convert';
import '../models/identity.dart';
import 'ble_constants.dart';

/// Peer announcement for BLE advertising
/// Broadcasts mesh peer ID and public keys to nearby devices
///
/// Format:
/// - meshPeerId (8 bytes) - SHA256(Ed25519_pub) truncated
/// - displayName length (2 bytes, big-endian)
/// - displayName (variable, UTF-8)
/// - Ed25519 public key (32 bytes)
/// - X25519 public key (32 bytes)
class PeerAnnouncement {
  final String meshPeerId;
  final String displayName;
  final Uint8List ed25519PublicKey;
  final Uint8List x25519PublicKey;

  PeerAnnouncement({
    required this.meshPeerId,
    required this.displayName,
    required this.ed25519PublicKey,
    required this.x25519PublicKey,
  }) {
    // Validation
    final meshPeerIdBytes = _hexToBytes(meshPeerId);
    if (meshPeerIdBytes.length != BleConstants.meshPeerIdLength) {
      throw ArgumentError(
        'Mesh peer ID must be ${BleConstants.meshPeerIdLength} bytes',
      );
    }
    if (ed25519PublicKey.length != 32) {
      throw ArgumentError('Ed25519 public key must be 32 bytes');
    }
    if (x25519PublicKey.length != 32) {
      throw ArgumentError('X25519 public key must be 32 bytes');
    }
  }

  /// Create announcement from Identity
  factory PeerAnnouncement.fromIdentity(Identity identity) {
    return PeerAnnouncement(
      meshPeerId: identity.meshPeerIdHex,
      displayName: identity.displayName ?? '',
      ed25519PublicKey: identity.signingKeyPair.publicKey,
      x25519PublicKey: identity.exchangeKeyPair.publicKey,
    );
  }

  /// Encode announcement to binary for BLE characteristic
  Uint8List encode() {
    final displayNameBytes = utf8.encode(displayName);

    // Calculate total size
    final size = 8 + // meshPeerId
        2 + // displayName length
        displayNameBytes.length +
        32 + // ed25519PublicKey
        32; // x25519PublicKey

    final buffer = ByteData(size);
    int offset = 0;

    // Mesh peer ID (8 bytes)
    final meshPeerIdBytes = _hexToBytes(meshPeerId);
    final bytes = buffer.buffer.asUint8List();
    bytes.setRange(offset, offset + 8, meshPeerIdBytes);
    offset += 8;

    // Display name length (2 bytes, big-endian)
    buffer.setUint16(offset, displayNameBytes.length);
    offset += 2;

    // Display name (variable)
    bytes.setRange(
      offset,
      offset + displayNameBytes.length,
      displayNameBytes,
    );
    offset += displayNameBytes.length;

    // Ed25519 public key (32 bytes)
    bytes.setRange(offset, offset + 32, ed25519PublicKey);
    offset += 32;

    // X25519 public key (32 bytes)
    bytes.setRange(offset, offset + 32, x25519PublicKey);

    return Uint8List.fromList(bytes);
  }

  /// Decode announcement from binary
  static PeerAnnouncement decode(Uint8List data) {
    if (data.length < 74) {
      // Minimum: 8 + 2 + 0 + 32 + 32
      throw ArgumentError('Announcement data too short');
    }

    final buffer = ByteData.sublistView(data);
    int offset = 0;

    // Mesh peer ID (8 bytes)
    final meshPeerIdBytes = Uint8List(8);
    meshPeerIdBytes.setRange(0, 8, data, offset);
    offset += 8;
    final meshPeerId = _bytesToHex(meshPeerIdBytes);

    // Display name length (2 bytes)
    final displayNameLength = buffer.getUint16(offset);
    offset += 2;

    if (data.length < 74 + displayNameLength) {
      throw ArgumentError('Announcement data incomplete');
    }

    // Display name (variable)
    final displayNameBytes = data.sublist(offset, offset + displayNameLength);
    offset += displayNameLength;
    final displayName = utf8.decode(displayNameBytes);

    // Ed25519 public key (32 bytes)
    final ed25519PublicKey = Uint8List(32);
    ed25519PublicKey.setRange(0, 32, data, offset);
    offset += 32;

    // X25519 public key (32 bytes)
    final x25519PublicKey = Uint8List(32);
    x25519PublicKey.setRange(0, 32, data, offset);

    return PeerAnnouncement(
      meshPeerId: meshPeerId,
      displayName: displayName,
      ed25519PublicKey: ed25519PublicKey,
      x25519PublicKey: x25519PublicKey,
    );
  }

  /// Convert hex string to bytes
  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  /// Convert bytes to hex string
  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  @override
  String toString() {
    return 'PeerAnnouncement('
        'meshPeerId=$meshPeerId, '
        'displayName=$displayName, '
        'ed25519=${_bytesToHex(ed25519PublicKey).substring(0, 8)}..., '
        'x25519=${_bytesToHex(x25519PublicKey).substring(0, 8)}...'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PeerAnnouncement &&
        other.meshPeerId == meshPeerId &&
        other.displayName == displayName &&
        _bytesEqual(other.ed25519PublicKey, ed25519PublicKey) &&
        _bytesEqual(other.x25519PublicKey, x25519PublicKey);
  }

  @override
  int get hashCode {
    return meshPeerId.hashCode ^
        displayName.hashCode ^
        ed25519PublicKey.hashCode ^
        x25519PublicKey.hashCode;
  }

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Exception for peer announcement errors
class PeerAnnouncementException implements Exception {
  final String message;

  PeerAnnouncementException(this.message);

  @override
  String toString() => 'PeerAnnouncementException: $message';
}
