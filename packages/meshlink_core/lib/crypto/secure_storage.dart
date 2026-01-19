import 'dart:typed_data';

/// Abstract interface for secure storage
/// Implementation will use flutter_secure_storage in the mobile app
///
/// Security considerations per Section 17.2:
/// - iOS: Use kSecAttrAccessibleAfterFirstUnlock for keys
/// - Keys are NOT available during device boot until first unlock
/// - Handle this gracefully in the identity service
abstract class SecureStorage {
  /// Store a value securely
  Future<void> write({
    required String key,
    required String value,
  });

  /// Read a value from secure storage
  Future<String?> read({required String key});

  /// Delete a value from secure storage
  Future<void> delete({required String key});

  /// Delete all values from secure storage
  Future<void> deleteAll();

  /// Check if a key exists in secure storage
  Future<bool> containsKey({required String key});

  /// Store binary data securely
  Future<void> writeBytes({
    required String key,
    required Uint8List value,
  });

  /// Read binary data from secure storage
  Future<Uint8List?> readBytes({required String key});
}

/// Storage keys used by MeshLink
class SecureStorageKeys {
  SecureStorageKeys._();

  /// Root identity seed (32 bytes)
  static const String identitySeed = 'identity_seed';

  /// Ed25519 signing private key
  static const String ed25519PrivateKey = 'ed25519_private_key';

  /// Ed25519 signing public key
  static const String ed25519PublicKey = 'ed25519_public_key';

  /// X25519 key exchange private key
  static const String x25519PrivateKey = 'x25519_private_key';

  /// X25519 key exchange public key
  static const String x25519PublicKey = 'x25519_public_key';

  /// Identity metadata (JSON)
  static const String identityMetadata = 'identity_metadata';

  /// Database encryption key
  static const String databaseKey = 'database_key';

  /// Matrix access token (for Phase 1)
  static const String matrixAccessToken = 'matrix_access_token';

  /// Matrix device ID (for Phase 1)
  static const String matrixDeviceId = 'matrix_device_id';

  /// Matrix user ID (for Phase 1)
  static const String matrixUserId = 'matrix_user_id';
}

/// Exception thrown when secure storage operations fail
class SecureStorageException implements Exception {
  SecureStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'SecureStorageException: $message${cause != null ? ' (cause: $cause)' : ''}';
}
