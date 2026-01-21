import 'dart:typed_data';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Bridge relay encryption using ECIES-style one-way encryption
///
/// For asynchronous store-and-forward via bridge relay, we use:
/// 1. Sender creates ephemeral X25519 key pair
/// 2. ECDH with recipient's static X25519 public key
/// 3. HKDF to derive encryption key
/// 4. ChaCha20-Poly1305 encryption
///
/// Message format: ephemeral_public (32 bytes) + nonce (12 bytes) + ciphertext + MAC (16 bytes)
class BridgeEncryption {
  static final _x25519 = X25519();
  static final _hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 32);
  static final _chacha = Chacha20.poly1305Aead();

  /// Encrypt a message for a recipient using their X25519 public key
  ///
  /// [plaintext] - The message to encrypt
  /// [recipientPublicKey] - Recipient's X25519 public key (32 bytes)
  ///
  /// Returns encrypted envelope: ephemeral_public (32) + nonce (12) + ciphertext + MAC (16)
  static Future<Uint8List> encrypt({
    required Uint8List plaintext,
    required Uint8List recipientPublicKey,
  }) async {
    if (recipientPublicKey.length != 32) {
      throw BridgeEncryptionException(
        'Invalid recipient public key length: ${recipientPublicKey.length}',
      );
    }

    // Generate ephemeral key pair
    final ephemeralKeyPair = await _x25519.newKeyPair();
    final ephemeralPublic = await ephemeralKeyPair.extractPublicKey();

    // ECDH to derive shared secret
    final recipientKey = SimplePublicKey(
      recipientPublicKey,
      type: KeyPairType.x25519,
    );
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: recipientKey,
    );

    // HKDF to derive encryption key
    final encryptionKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode('bridge-relay-v1'),
      info: [],
    );

    // Generate random nonce
    final nonce = Uint8List(12);
    for (int i = 0; i < 12; i++) {
      nonce[i] = (DateTime.now().microsecondsSinceEpoch + i) % 256;
    }

    // Encrypt with ChaCha20-Poly1305
    final secretBox = await _chacha.encrypt(
      plaintext,
      secretKey: encryptionKey,
      nonce: nonce,
    );

    // Build output: ephemeral_public (32) + nonce (12) + ciphertext + MAC (16)
    final result = BytesBuilder();
    result.add(ephemeralPublic.bytes);
    result.add(nonce);
    result.add(secretBox.cipherText);
    result.add(secretBox.mac.bytes);

    return result.toBytes();
  }

  /// Decrypt a message using recipient's X25519 private key
  ///
  /// [ciphertext] - The encrypted envelope from [encrypt]
  /// [recipientKeyPair] - Recipient's X25519 key pair
  ///
  /// Returns decrypted plaintext
  static Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required SimpleKeyPair recipientKeyPair,
  }) async {
    // Minimum size: ephemeral_public (32) + nonce (12) + MAC (16) = 60
    if (ciphertext.length < 60) {
      throw BridgeEncryptionException(
        'Ciphertext too short: ${ciphertext.length}',
      );
    }

    // Parse envelope
    final ephemeralPublicBytes = ciphertext.sublist(0, 32);
    final nonce = ciphertext.sublist(32, 44);
    final encryptedData = ciphertext.sublist(44, ciphertext.length - 16);
    final macBytes = ciphertext.sublist(ciphertext.length - 16);

    // Reconstruct ephemeral public key
    final ephemeralPublic = SimplePublicKey(
      ephemeralPublicBytes,
      type: KeyPairType.x25519,
    );

    // ECDH to derive shared secret
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: recipientKeyPair,
      remotePublicKey: ephemeralPublic,
    );

    // HKDF to derive decryption key
    final decryptionKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode('bridge-relay-v1'),
      info: [],
    );

    // Decrypt with ChaCha20-Poly1305
    final secretBox = SecretBox(
      encryptedData,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    try {
      final plaintext = await _chacha.decrypt(
        secretBox,
        secretKey: decryptionKey,
      );
      return Uint8List.fromList(plaintext);
    } catch (e) {
      throw BridgeEncryptionException('Decryption failed: $e');
    }
  }

  /// Encrypt a text message for bridge relay
  static Future<String> encryptText({
    required String message,
    required Uint8List recipientPublicKey,
  }) async {
    final plaintext = Uint8List.fromList(utf8.encode(message));
    final encrypted = await encrypt(
      plaintext: plaintext,
      recipientPublicKey: recipientPublicKey,
    );
    return base64.encode(encrypted);
  }

  /// Decrypt a text message from bridge relay
  static Future<String> decryptText({
    required String encryptedBase64,
    required SimpleKeyPair recipientKeyPair,
  }) async {
    final encrypted = base64.decode(encryptedBase64);
    final decrypted = await decrypt(
      ciphertext: Uint8List.fromList(encrypted),
      recipientKeyPair: recipientKeyPair,
    );
    return utf8.decode(decrypted);
  }
}

/// Exception for bridge encryption errors
class BridgeEncryptionException implements Exception {
  final String message;

  BridgeEncryptionException(this.message);

  @override
  String toString() => 'BridgeEncryptionException: $message';
}
