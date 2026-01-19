import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'key_pair.dart';

part 'identity.freezed.dart';
part 'identity.g.dart';

/// Root identity for a MeshLink user
/// Based on Section 6.1 of the specification
///
/// Key Hierarchy:
/// - Ed25519 Signing Key (persistent)
/// - X25519 Key Exchange Key (persistent, derived from Ed25519 seed)
/// - Mesh Peer ID: truncate(SHA256(Ed25519_pub), 8 bytes)
/// - Matrix User ID: @base58(Ed25519_pub[0:10]):server
/// - Relay Key Hash: SHA256(X25519_pub)
@freezed
class Identity with _$Identity {
  const Identity._();

  const factory Identity({
    /// Ed25519 signing key pair for identity verification and message signing
    required Ed25519KeyPair signingKeyPair,

    /// X25519 key exchange key pair for Noise handshakes and session establishment
    required X25519KeyPair exchangeKeyPair,

    /// Mesh Peer ID: truncate(SHA256(Ed25519_pub), 8 bytes)
    @Uint8ListConverter() required Uint8List meshPeerId,

    /// When the identity was created
    required DateTime createdAt,

    /// Optional display name
    String? displayName,

    /// Optional avatar URL or data
    String? avatar,
  }) = _Identity;

  factory Identity.fromJson(Map<String, dynamic> json) =>
      _$IdentityFromJson(json);

  /// Get the public signing key fingerprint (hex encoded)
  String get signingKeyFingerprint =>
      signingKeyPair.publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Get the mesh peer ID as hex string
  String get meshPeerIdHex =>
      meshPeerId.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Identity backup format for export/import
@freezed
class IdentityBackup with _$IdentityBackup {
  const factory IdentityBackup({
    required Identity identity,

    /// Version of the backup format
    @Default(1) int version,

    /// When the backup was created
    required DateTime exportedAt,

    /// Optional password hint (never store the actual password)
    String? passwordHint,
  }) = _IdentityBackup;

  factory IdentityBackup.fromJson(Map<String, dynamic> json) =>
      _$IdentityBackupFromJson(json);
}
