import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';
import 'dart:convert';

/// Noise Protocol XX pattern implementation for mesh peer handshake
/// Based on spec Section 6.2
///
/// Handshake Flow:
/// 1. Initiator → Responder: e
/// 2. Responder → Initiator: e, ee, s, es
/// 3. Initiator → Responder: s, se
///
/// After handshake: Two transport keys for encrypted communication

/// Handshake role
enum NoiseRole {
  initiator,
  responder,
}

/// Handshake state
enum NoiseHandshakeState {
  initial,
  sentMessage1,
  sentMessage2,
  completed,
}

/// Noise Protocol XX handshake manager
class NoiseHandshake {
  final NoiseRole role;
  final SimpleKeyPair staticKeyPair; // X25519 key pair
  final SimpleKeyPair ephemeralKeyPair; // Generated for this handshake

  NoiseHandshakeState state = NoiseHandshakeState.initial;

  // Handshake state
  List<int> _chainingKey = List.filled(32, 0);
  List<int> _handshakeHash = List.filled(32, 0);
  SimplePublicKey? _remoteEphemeralKey;
  SimplePublicKey? _remoteStaticKey;

  // Crypto primitives
  static final _x25519 = X25519();
  static final _hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 64);
  static final _chacha = Chacha20.poly1305Aead();

  NoiseHandshake({
    required this.role,
    required this.staticKeyPair,
    required this.ephemeralKeyPair,
  }) {
    _initialize();
  }

  /// Initialize handshake state with protocol name
  void _initialize() {
    // Noise protocol name: "Noise_XX_25519_ChaChaPoly_SHA256"
    final protocolName = utf8.encode('Noise_XX_25519_ChaChaPoly_SHA256');

    if (protocolName.length <= 32) {
      _handshakeHash = List.from(protocolName)
        ..addAll(List.filled(32 - protocolName.length, 0));
      _chainingKey = List.from(_handshakeHash);
    } else {
      // Hash if longer than 32 bytes (this shouldn't happen for our protocol name)
      final sha256 = Sha256();
      final hash = sha256.hash(protocolName) as Future<Hash>;
      // This is synchronous initialization, so we'll just truncate
      _handshakeHash = protocolName.sublist(0, 32);
      _chainingKey = List.from(_handshakeHash);
    }
  }

  /// Mix key material into chaining key
  Future<void> _mixKey(List<int> inputKeyMaterial) async {
    final output = await _hkdf.deriveKey(
      secretKey: SecretKey(inputKeyMaterial),
      nonce: _chainingKey,
      info: [],
    );

    final outputBytes = await output.extractBytes();
    _chainingKey = outputBytes.sublist(0, 32);
  }

  /// Mix data into handshake hash
  Future<void> _mixHash(List<int> data) async {
    final sha256 = Sha256();
    final combined = [..._handshakeHash, ...data];
    final hash = await sha256.hash(combined);
    _handshakeHash = hash.bytes;
  }

  /// Encrypt and authenticate with current chaining key
  Future<List<int>> _encryptAndHash(List<int> plaintext) async {
    final tempKey = _chainingKey.sublist(0, 32);

    // Encrypt with ChaCha20-Poly1305
    final secretBox = await _chacha.encrypt(
      plaintext,
      secretKey: SecretKey(tempKey),
      nonce: List.filled(12, 0), // Nonce is always zeros in Noise handshake
    );

    // Only include ciphertext + MAC (not nonce, since nonce is always zero)
    final ciphertext = [...secretBox.cipherText, ...secretBox.mac.bytes];
    await _mixHash(ciphertext);

    return ciphertext;
  }

  /// Decrypt and verify with current chaining key
  Future<List<int>> _decryptAndHash(List<int> ciphertext) async {
    final tempKey = _chainingKey.sublist(0, 32);

    // Split ciphertext and MAC (last 16 bytes are MAC)
    if (ciphertext.length < 16) {
      throw NoiseException('Ciphertext too short');
    }

    final actualCiphertext = ciphertext.sublist(0, ciphertext.length - 16);
    final mac = Mac(ciphertext.sublist(ciphertext.length - 16));

    // Construct SecretBox with fixed zero nonce
    final secretBox = SecretBox(
      actualCiphertext,
      nonce: List.filled(12, 0),
      mac: mac,
    );

    try {
      final plaintext = await _chacha.decrypt(
        secretBox,
        secretKey: SecretKey(tempKey),
      );

      await _mixHash(ciphertext);
      return plaintext;
    } catch (e) {
      throw NoiseException('Decryption failed: $e');
    }
  }

  /// Perform Diffie-Hellman and mix into chaining key
  Future<void> _dh(SimpleKeyPair local, SimplePublicKey remote) async {
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: local,
      remotePublicKey: remote,
    );

    final sharedBytes = await sharedSecret.extractBytes();
    await _mixKey(sharedBytes);
  }

  /// Generate message 1 (initiator only): → e
  Future<Uint8List> generateMessage1() async {
    if (role != NoiseRole.initiator) {
      throw NoiseException('Only initiator can generate message 1');
    }
    if (state != NoiseHandshakeState.initial) {
      throw NoiseException('Invalid state for message 1');
    }

    // Send ephemeral public key
    final ephemeralPublic = await ephemeralKeyPair.extractPublicKey();
    final ephemeralBytes = ephemeralPublic.bytes;

    await _mixHash(ephemeralBytes);

    state = NoiseHandshakeState.sentMessage1;
    return Uint8List.fromList(ephemeralBytes);
  }

  /// Process message 1 and generate message 2 (responder only): ← e, ee, s, es
  Future<Uint8List> processMessage1AndGenerateMessage2(
      Uint8List message1) async {
    if (role != NoiseRole.responder) {
      throw NoiseException('Only responder can process message 1');
    }
    if (state != NoiseHandshakeState.initial) {
      throw NoiseException('Invalid state for processing message 1');
    }

    // Parse remote ephemeral key
    if (message1.length != 32) {
      throw NoiseException('Invalid message 1 length');
    }

    _remoteEphemeralKey = SimplePublicKey(message1, type: KeyPairType.x25519);
    await _mixHash(message1);

    // Build message 2: e, ee, s, es
    final buffer = <int>[];

    // e: Our ephemeral key
    final ephemeralPublic = await ephemeralKeyPair.extractPublicKey();
    final ephemeralBytes = ephemeralPublic.bytes;
    buffer.addAll(ephemeralBytes);
    await _mixHash(ephemeralBytes);

    // ee: DH(e, re)
    await _dh(ephemeralKeyPair, _remoteEphemeralKey!);

    // s: Our static key (encrypted)
    final staticPublic = await staticKeyPair.extractPublicKey();
    final staticBytes = staticPublic.bytes;
    final encryptedStatic = await _encryptAndHash(staticBytes);
    buffer.addAll(encryptedStatic);

    // es: DH(s, re)
    await _dh(staticKeyPair, _remoteEphemeralKey!);

    state = NoiseHandshakeState.sentMessage2;
    return Uint8List.fromList(buffer);
  }

  /// Process message 2 and generate message 3 (initiator only): → s, se
  Future<Uint8List> processMessage2AndGenerateMessage3(
      Uint8List message2) async {
    if (role != NoiseRole.initiator) {
      throw NoiseException('Only initiator can process message 2');
    }
    if (state != NoiseHandshakeState.sentMessage1) {
      throw NoiseException('Invalid state for processing message 2');
    }

    // Parse message 2: e (32) + ee + s (32+16) + es
    if (message2.length < 80) {
      // 32 (e) + 48 (encrypted s with MAC)
      throw NoiseException('Invalid message 2 length');
    }

    // e: Remote ephemeral key
    final remoteEphemeralBytes = message2.sublist(0, 32);
    _remoteEphemeralKey =
        SimplePublicKey(remoteEphemeralBytes, type: KeyPairType.x25519);
    await _mixHash(remoteEphemeralBytes);

    // ee: DH(e, re)
    await _dh(ephemeralKeyPair, _remoteEphemeralKey!);

    // s: Remote static key (encrypted)
    final encryptedStatic = message2.sublist(32, 80); // 32 bytes + 16 MAC
    final remoteStaticBytes = await _decryptAndHash(encryptedStatic);
    _remoteStaticKey =
        SimplePublicKey(remoteStaticBytes, type: KeyPairType.x25519);

    // es: DH(e, rs)
    await _dh(ephemeralKeyPair, _remoteStaticKey!);

    // Build message 3: s, se
    final buffer = <int>[];

    // s: Our static key (encrypted)
    final staticPublic = await staticKeyPair.extractPublicKey();
    final staticBytes = staticPublic.bytes;
    final encryptedOurStatic = await _encryptAndHash(staticBytes);
    buffer.addAll(encryptedOurStatic);

    // se: DH(s, re)
    await _dh(staticKeyPair, _remoteEphemeralKey!);

    state = NoiseHandshakeState.completed;
    return Uint8List.fromList(buffer);
  }

  /// Process message 3 (responder only)
  Future<void> processMessage3(Uint8List message3) async {
    if (role != NoiseRole.responder) {
      throw NoiseException('Only responder can process message 3');
    }
    if (state != NoiseHandshakeState.sentMessage2) {
      throw NoiseException('Invalid state for processing message 3');
    }

    // Parse message 3: s (32+16), se
    if (message3.length < 48) {
      // 32 bytes + 16 MAC
      throw NoiseException('Invalid message 3 length');
    }

    // s: Remote static key (encrypted)
    final encryptedStatic = message3.sublist(0, 48);
    final remoteStaticBytes = await _decryptAndHash(encryptedStatic);
    _remoteStaticKey =
        SimplePublicKey(remoteStaticBytes, type: KeyPairType.x25519);

    // se: DH(e, rs)
    await _dh(ephemeralKeyPair, _remoteStaticKey!);

    state = NoiseHandshakeState.completed;
  }

  /// Derive transport keys after handshake completion
  Future<NoiseSession> deriveSession() async {
    if (state != NoiseHandshakeState.completed) {
      throw NoiseException('Handshake not completed');
    }

    // Split chaining key into two transport keys
    final output = await _hkdf.deriveKey(
      secretKey: SecretKey(_chainingKey),
      nonce: List.filled(32, 0),
      info: [],
    );

    final outputBytes = await output.extractBytes();
    final key1 = outputBytes.sublist(0, 32);
    final key2 = outputBytes.sublist(32, 64);

    // Initiator sends with key1, receives with key2
    // Responder sends with key2, receives with key1
    final sendKey = role == NoiseRole.initiator ? key1 : key2;
    final receiveKey = role == NoiseRole.initiator ? key2 : key1;

    return NoiseSession(
      sendKey: SecretKey(sendKey),
      receiveKey: SecretKey(receiveKey),
      remoteStaticKey: _remoteStaticKey!,
    );
  }

  /// Get remote peer's static public key
  SimplePublicKey? get remoteStaticKey => _remoteStaticKey;
}

/// Active Noise session for encrypted transport
class NoiseSession {
  final SecretKey sendKey;
  final SecretKey receiveKey;
  final SimplePublicKey remoteStaticKey;

  int _sendNonce = 0;
  int _receiveNonce = 0;

  static final _chacha = Chacha20.poly1305Aead();

  NoiseSession({
    required this.sendKey,
    required this.receiveKey,
    required this.remoteStaticKey,
  });

  /// Encrypt a message with transport key
  Future<Uint8List> encrypt(Uint8List plaintext) async {
    // Check for nonce overflow (uint64 max)
    if (_sendNonce < 0 || _sendNonce > 0x7FFFFFFFFFFFFFFF) {
      throw NoiseException('Send nonce exhausted, rekey required');
    }

    final nonce = _nonceFromUint64(_sendNonce);
    _sendNonce++;

    final secretBox = await _chacha.encrypt(
      plaintext,
      secretKey: sendKey,
      nonce: nonce,
    );

    // Return nonce + ciphertext + MAC for transport
    return Uint8List.fromList(secretBox.concatenation());
  }

  /// Decrypt a message with transport key
  Future<Uint8List> decrypt(Uint8List ciphertext) async {
    // Check for nonce overflow (uint64 max)
    if (_receiveNonce < 0 || _receiveNonce > 0x7FFFFFFFFFFFFFFF) {
      throw NoiseException('Receive nonce exhausted, rekey required');
    }

    final nonce = _nonceFromUint64(_receiveNonce);
    _receiveNonce++;

    final secretBox = SecretBox.fromConcatenation(
      ciphertext,
      nonceLength: 12,
      macLength: 16,
    );

    try {
      final plaintext = await _chacha.decrypt(
        secretBox,
        secretKey: receiveKey,
      );

      return Uint8List.fromList(plaintext);
    } catch (e) {
      throw NoiseException('Decryption failed: $e');
    }
  }

  /// Convert uint64 nonce to 12-byte nonce (4 bytes zeros + 8 bytes LE nonce)
  List<int> _nonceFromUint64(int value) {
    final nonce = List.filled(12, 0);
    final byteData = ByteData(8);
    byteData.setUint64(0, value, Endian.little);

    for (int i = 0; i < 8; i++) {
      nonce[i + 4] = byteData.getUint8(i);
    }

    return nonce;
  }

  /// Serialize session state for storage
  Future<Map<String, dynamic>> toJson() async {
    final remoteStaticBytes = remoteStaticKey.bytes;

    return {
      'sendKey': hex.encode(await sendKey.extractBytes()),
      'receiveKey': hex.encode(await receiveKey.extractBytes()),
      'remoteStaticKey': hex.encode(remoteStaticBytes),
      'sendNonce': _sendNonce,
      'receiveNonce': _receiveNonce,
    };
  }

  /// Deserialize session state from storage
  static NoiseSession fromJson(Map<String, dynamic> json) {
    return NoiseSession(
      sendKey: SecretKey(hex.decode(json['sendKey'] as String)),
      receiveKey: SecretKey(hex.decode(json['receiveKey'] as String)),
      remoteStaticKey: SimplePublicKey(
        hex.decode(json['remoteStaticKey'] as String),
        type: KeyPairType.x25519,
      ),
    )
      .._sendNonce = json['sendNonce'] as int
      .._receiveNonce = json['receiveNonce'] as int;
  }
}

/// Noise protocol exception
class NoiseException implements Exception {
  final String message;

  NoiseException(this.message);

  @override
  String toString() => 'NoiseException: $message';
}
