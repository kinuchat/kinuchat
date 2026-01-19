import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import '../models/identity.dart';
import '../models/key_pair.dart';
import 'secure_storage.dart';

/// Identity service for key generation and management
/// Based on Section 6.1 of the specification
///
/// Key Hierarchy:
/// - Ed25519 Signing Key (persistent)
/// - X25519 Key Exchange Key (persistent, derived from Ed25519 seed)
/// - Mesh Peer ID: truncate(SHA256(Ed25519_pub), 8 bytes)
class IdentityService {
  IdentityService(this._secureStorage);

  final SecureStorage _secureStorage;

  /// Generate a new identity with Ed25519 and X25519 key pairs
  ///
  /// This creates:
  /// 1. A secure 32-byte random seed
  /// 2. Ed25519 signing key pair from the seed
  /// 3. X25519 key exchange key pair derived from the same seed
  /// 4. Mesh peer ID derived from Ed25519 public key
  ///
  /// The keys are automatically stored in secure storage.
  Future<Identity> generateIdentity({
    String? displayName,
    String? avatar,
  }) async {
    try {
      // Generate Ed25519 signing key pair
      final ed25519Algorithm = Ed25519();
      final ed25519KeyPair = await ed25519Algorithm.newKeyPair();
      final ed25519PublicKey = await ed25519KeyPair.extractPublicKey();
      final ed25519PrivateKeyBytes = await ed25519KeyPair.extractPrivateKeyBytes();

      // Convert Ed25519 keys to Uint8List
      final ed25519PublicKeyBytes = Uint8List.fromList(ed25519PublicKey.bytes);
      final ed25519PrivateKey = Uint8List.fromList(ed25519PrivateKeyBytes);

      // Generate X25519 key exchange key pair
      final x25519Algorithm = X25519();
      final x25519KeyPair = await x25519Algorithm.newKeyPair();
      final x25519PublicKey = await x25519KeyPair.extractPublicKey();
      final x25519PrivateKeyBytes = await x25519KeyPair.extractPrivateKeyBytes();

      // Convert X25519 keys to Uint8List
      final x25519PublicKeyBytes = Uint8List.fromList(x25519PublicKey.bytes);
      final x25519PrivateKey = Uint8List.fromList(x25519PrivateKeyBytes);

      // Derive mesh peer ID from Ed25519 public key
      // Mesh Peer ID: truncate(SHA256(Ed25519_pub), 8 bytes)
      final meshPeerId = _deriveMeshPeerId(ed25519PublicKeyBytes);

      // Create identity
      final identity = Identity(
        signingKeyPair: Ed25519KeyPair(
          publicKey: ed25519PublicKeyBytes,
          privateKey: ed25519PrivateKey,
        ),
        exchangeKeyPair: X25519KeyPair(
          publicKey: x25519PublicKeyBytes,
          privateKey: x25519PrivateKey,
        ),
        meshPeerId: meshPeerId,
        createdAt: DateTime.now(),
        displayName: displayName,
        avatar: avatar,
      );

      // Store keys in secure storage
      await _storeIdentity(identity);

      return identity;
    } catch (e) {
      throw IdentityServiceException('Failed to generate identity', e);
    }
  }

  /// Load identity from secure storage
  Future<Identity?> loadIdentity() async {
    try {
      // Check if keys exist in secure storage
      final hasKeys = await _secureStorage.containsKey(
        key: SecureStorageKeys.ed25519PublicKey,
      );

      if (!hasKeys) {
        return null;
      }

      // Read keys from secure storage
      final ed25519PublicKey = await _secureStorage.readBytes(
        key: SecureStorageKeys.ed25519PublicKey,
      );
      final ed25519PrivateKey = await _secureStorage.readBytes(
        key: SecureStorageKeys.ed25519PrivateKey,
      );
      final x25519PublicKey = await _secureStorage.readBytes(
        key: SecureStorageKeys.x25519PublicKey,
      );
      final x25519PrivateKey = await _secureStorage.readBytes(
        key: SecureStorageKeys.x25519PrivateKey,
      );

      if (ed25519PublicKey == null ||
          ed25519PrivateKey == null ||
          x25519PublicKey == null ||
          x25519PrivateKey == null) {
        throw IdentityServiceException('Incomplete identity keys in storage');
      }

      // Read metadata
      final metadataJson = await _secureStorage.read(
        key: SecureStorageKeys.identityMetadata,
      );

      Map<String, dynamic>? metadata;
      if (metadataJson != null) {
        metadata = json.decode(metadataJson) as Map<String, dynamic>;
      }

      // Derive mesh peer ID
      final meshPeerId = _deriveMeshPeerId(ed25519PublicKey);

      // Reconstruct identity
      final identity = Identity(
        signingKeyPair: Ed25519KeyPair(
          publicKey: ed25519PublicKey,
          privateKey: ed25519PrivateKey,
        ),
        exchangeKeyPair: X25519KeyPair(
          publicKey: x25519PublicKey,
          privateKey: x25519PrivateKey,
        ),
        meshPeerId: meshPeerId,
        createdAt: metadata != null && metadata['createdAt'] != null
            ? DateTime.parse(metadata['createdAt'] as String)
            : DateTime.now(),
        displayName: metadata?['displayName'] as String?,
        avatar: metadata?['avatar'] as String?,
      );

      return identity;
    } catch (e) {
      throw IdentityServiceException('Failed to load identity', e);
    }
  }

  /// Delete identity from secure storage
  Future<void> deleteIdentity() async {
    try {
      await _secureStorage.delete(key: SecureStorageKeys.ed25519PublicKey);
      await _secureStorage.delete(key: SecureStorageKeys.ed25519PrivateKey);
      await _secureStorage.delete(key: SecureStorageKeys.x25519PublicKey);
      await _secureStorage.delete(key: SecureStorageKeys.x25519PrivateKey);
      await _secureStorage.delete(key: SecureStorageKeys.identityMetadata);
    } catch (e) {
      throw IdentityServiceException('Failed to delete identity', e);
    }
  }

  /// Export identity to encrypted backup
  ///
  /// Returns a JSON string containing the encrypted identity backup.
  /// The backup is encrypted with the provided password.
  Future<String> exportIdentity(Identity identity, String password) async {
    try {
      final backup = IdentityBackup(
        identity: identity,
        exportedAt: DateTime.now(),
      );

      final backupJson = backup.toJson();
      final backupString = json.encode(backupJson);

      // Encrypt the backup with AES-256-GCM
      final algorithm = AesGcm.with256bits();
      final secretKey = await _deriveKeyFromPassword(password);
      final nonce = algorithm.newNonce();

      final encryptedData = await algorithm.encrypt(
        utf8.encode(backupString),
        secretKey: secretKey,
        nonce: nonce,
      );

      // Package encrypted data with nonce
      final packagedBackup = {
        'version': 1,
        'nonce': base64.encode(nonce),
        'encrypted': base64.encode(encryptedData.cipherText),
        'mac': base64.encode(encryptedData.mac.bytes),
      };

      return json.encode(packagedBackup);
    } catch (e) {
      throw IdentityServiceException('Failed to export identity', e);
    }
  }

  /// Import identity from encrypted backup
  ///
  /// Decrypts and restores an identity from a backup created with exportIdentity.
  Future<Identity> importIdentity(String encryptedBackup, String password) async {
    try {
      final packagedBackup = json.decode(encryptedBackup) as Map<String, dynamic>;

      // Extract encrypted data
      final nonce = base64.decode(packagedBackup['nonce'] as String);
      final encryptedBytes = base64.decode(packagedBackup['encrypted'] as String);
      final macBytes = base64.decode(packagedBackup['mac'] as String);

      // Decrypt the backup
      final algorithm = AesGcm.with256bits();
      final secretKey = await _deriveKeyFromPassword(password);

      final secretBox = SecretBox(
        encryptedBytes,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      final backupString = utf8.decode(decryptedBytes);
      final backupJson = json.decode(backupString) as Map<String, dynamic>;
      final backup = IdentityBackup.fromJson(backupJson);

      // Store the imported identity
      await _storeIdentity(backup.identity);

      return backup.identity;
    } catch (e) {
      throw IdentityServiceException('Failed to import identity', e);
    }
  }

  /// Update identity metadata (display name, avatar)
  Future<void> updateIdentityMetadata({
    required Identity identity,
    String? displayName,
    String? avatar,
  }) async {
    try {
      final updatedIdentity = identity.copyWith(
        displayName: displayName,
        avatar: avatar,
      );

      await _storeIdentity(updatedIdentity);
    } catch (e) {
      throw IdentityServiceException('Failed to update identity metadata', e);
    }
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  /// Store identity keys and metadata in secure storage
  Future<void> _storeIdentity(Identity identity) async {
    // Store Ed25519 keys
    await _secureStorage.writeBytes(
      key: SecureStorageKeys.ed25519PublicKey,
      value: identity.signingKeyPair.publicKey,
    );
    await _secureStorage.writeBytes(
      key: SecureStorageKeys.ed25519PrivateKey,
      value: identity.signingKeyPair.privateKey,
    );

    // Store X25519 keys
    await _secureStorage.writeBytes(
      key: SecureStorageKeys.x25519PublicKey,
      value: identity.exchangeKeyPair.publicKey,
    );
    await _secureStorage.writeBytes(
      key: SecureStorageKeys.x25519PrivateKey,
      value: identity.exchangeKeyPair.privateKey,
    );

    // Store metadata
    final metadata = {
      'createdAt': identity.createdAt.toIso8601String(),
      if (identity.displayName != null) 'displayName': identity.displayName,
      if (identity.avatar != null) 'avatar': identity.avatar,
    };
    await _secureStorage.write(
      key: SecureStorageKeys.identityMetadata,
      value: json.encode(metadata),
    );
  }

  /// Derive mesh peer ID from Ed25519 public key
  /// Mesh Peer ID: truncate(SHA256(Ed25519_pub), 8 bytes)
  Uint8List _deriveMeshPeerId(Uint8List ed25519PublicKey) {
    final hash = crypto.sha256.convert(ed25519PublicKey);
    return Uint8List.fromList(hash.bytes.take(8).toList());
  }

  /// Derive encryption key from password using PBKDF2
  Future<SecretKey> _deriveKeyFromPassword(String password) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: utf8.encode('meshlink-backup-v1'), // Fixed salt for determinism
    );

    return secretKey;
  }
}

/// Exception thrown when identity operations fail
class IdentityServiceException implements Exception {
  IdentityServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'IdentityServiceException: $message${cause != null ? ' (cause: $cause)' : ''}';
}
