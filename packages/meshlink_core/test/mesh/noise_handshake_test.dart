import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:meshlink_core/mesh/noise_handshake.dart';

void main() {
  late SimpleKeyPair aliceStatic;
  late SimpleKeyPair aliceEphemeral;
  late SimpleKeyPair bobStatic;
  late SimpleKeyPair bobEphemeral;

  setUp(() async {
    final x25519 = X25519();

    // Generate key pairs for Alice and Bob
    aliceStatic = await x25519.newKeyPair();
    aliceEphemeral = await x25519.newKeyPair();
    bobStatic = await x25519.newKeyPair();
    bobEphemeral = await x25519.newKeyPair();
  });

  group('NoiseHandshake', () {
    test('initialization sets correct role', () {
      final initiator = NoiseHandshake(
        role: NoiseRole.initiator,
        staticKeyPair: aliceStatic,
        ephemeralKeyPair: aliceEphemeral,
      );

      final responder = NoiseHandshake(
        role: NoiseRole.responder,
        staticKeyPair: bobStatic,
        ephemeralKeyPair: bobEphemeral,
      );

      expect(initiator.role, NoiseRole.initiator);
      expect(responder.role, NoiseRole.responder);
      expect(initiator.state, NoiseHandshakeState.initial);
      expect(responder.state, NoiseHandshakeState.initial);
    });

    test('completes XX handshake successfully', () async {
      // Alice (initiator) and Bob (responder)
      final alice = NoiseHandshake(
        role: NoiseRole.initiator,
        staticKeyPair: aliceStatic,
        ephemeralKeyPair: aliceEphemeral,
      );

      final bob = NoiseHandshake(
        role: NoiseRole.responder,
        staticKeyPair: bobStatic,
        ephemeralKeyPair: bobEphemeral,
      );

      // Message 1: Alice → Bob (e)
      final message1 = await alice.generateMessage1();
      expect(message1.length, 32); // Just ephemeral key
      expect(alice.state, NoiseHandshakeState.sentMessage1);

      // Message 2: Bob → Alice (e, ee, s, es)
      final message2 = await bob.processMessage1AndGenerateMessage2(message1);
      expect(message2.length, 80); // 32 (e) + 48 (encrypted s with MAC)
      expect(bob.state, NoiseHandshakeState.sentMessage2);

      // Message 3: Alice → Bob (s, se)
      final message3 =
          await alice.processMessage2AndGenerateMessage3(message2);
      expect(message3.length, 48); // 48 (encrypted s with MAC)
      expect(alice.state, NoiseHandshakeState.completed);

      // Bob processes message 3
      await bob.processMessage3(message3);
      expect(bob.state, NoiseHandshakeState.completed);

      // Both should now have each other's static keys
      expect(alice.remoteStaticKey, isNotNull);
      expect(bob.remoteStaticKey, isNotNull);

      // Verify they have the correct remote keys
      final aliceStaticPublic = await aliceStatic.extractPublicKey();
      final bobStaticPublic = await bobStatic.extractPublicKey();

      final aliceStaticBytes = aliceStaticPublic.bytes;
      final bobStaticBytes = bobStaticPublic.bytes;

      final aliceRemoteBytes = alice.remoteStaticKey!.bytes;
      final bobRemoteBytes = bob.remoteStaticKey!.bytes;

      expect(bobRemoteBytes, aliceStaticBytes);
      expect(aliceRemoteBytes, bobStaticBytes);
    });

    test('rejects wrong role for message generation', () async {
      final responder = NoiseHandshake(
        role: NoiseRole.responder,
        staticKeyPair: bobStatic,
        ephemeralKeyPair: bobEphemeral,
      );

      expect(
        () => responder.generateMessage1(),
        throwsA(isA<NoiseException>()),
      );
    });

    test('rejects invalid state transitions', () async {
      final initiator = NoiseHandshake(
        role: NoiseRole.initiator,
        staticKeyPair: aliceStatic,
        ephemeralKeyPair: aliceEphemeral,
      );

      // Can't process message 2 before sending message 1
      expect(
        () => initiator.processMessage2AndGenerateMessage3(Uint8List(80)),
        throwsA(isA<NoiseException>()),
      );
    });

    test('rejects invalid message lengths', () async {
      final alice = NoiseHandshake(
        role: NoiseRole.initiator,
        staticKeyPair: aliceStatic,
        ephemeralKeyPair: aliceEphemeral,
      );

      final bob = NoiseHandshake(
        role: NoiseRole.responder,
        staticKeyPair: bobStatic,
        ephemeralKeyPair: bobEphemeral,
      );

      await alice.generateMessage1();

      // Message 1 must be exactly 32 bytes
      expect(
        () => bob.processMessage1AndGenerateMessage2(Uint8List(16)),
        throwsA(isA<NoiseException>()),
      );

      expect(
        () => bob.processMessage1AndGenerateMessage2(Uint8List(64)),
        throwsA(isA<NoiseException>()),
      );
    });

    test('derives session correctly', () async {
      final alice = NoiseHandshake(
        role: NoiseRole.initiator,
        staticKeyPair: aliceStatic,
        ephemeralKeyPair: aliceEphemeral,
      );

      final bob = NoiseHandshake(
        role: NoiseRole.responder,
        staticKeyPair: bobStatic,
        ephemeralKeyPair: bobEphemeral,
      );

      // Complete handshake
      final message1 = await alice.generateMessage1();
      final message2 = await bob.processMessage1AndGenerateMessage2(message1);
      final message3 =
          await alice.processMessage2AndGenerateMessage3(message2);
      await bob.processMessage3(message3);

      // Derive sessions
      final aliceSession = await alice.deriveSession();
      final bobSession = await bob.deriveSession();

      expect(aliceSession, isNotNull);
      expect(bobSession, isNotNull);
      expect(aliceSession.remoteStaticKey, isNotNull);
      expect(bobSession.remoteStaticKey, isNotNull);
    });

    test('rejects deriving session before handshake complete', () async {
      final alice = NoiseHandshake(
        role: NoiseRole.initiator,
        staticKeyPair: aliceStatic,
        ephemeralKeyPair: aliceEphemeral,
      );

      expect(
        () => alice.deriveSession(),
        throwsA(isA<NoiseException>()),
      );
    });
  });

  group('NoiseSession', () {
    late NoiseSession aliceSession;
    late NoiseSession bobSession;

    setUp(() async {
      // Complete handshake and get sessions
      final alice = NoiseHandshake(
        role: NoiseRole.initiator,
        staticKeyPair: aliceStatic,
        ephemeralKeyPair: aliceEphemeral,
      );

      final bob = NoiseHandshake(
        role: NoiseRole.responder,
        staticKeyPair: bobStatic,
        ephemeralKeyPair: bobEphemeral,
      );

      final message1 = await alice.generateMessage1();
      final message2 = await bob.processMessage1AndGenerateMessage2(message1);
      final message3 =
          await alice.processMessage2AndGenerateMessage3(message2);
      await bob.processMessage3(message3);

      aliceSession = await alice.deriveSession();
      bobSession = await bob.deriveSession();
    });

    test('encrypts and decrypts messages correctly', () async {
      final plaintext = Uint8List.fromList('Hello, Bob!'.codeUnits);

      // Alice encrypts
      final ciphertext = await aliceSession.encrypt(plaintext);
      expect(ciphertext.length, greaterThan(plaintext.length)); // Has MAC

      // Bob decrypts
      final decrypted = await bobSession.decrypt(ciphertext);
      expect(decrypted, plaintext);
    });

    test('bidirectional communication works', () async {
      final aliceMessage = Uint8List.fromList('Hello from Alice'.codeUnits);
      final bobMessage = Uint8List.fromList('Hello from Bob'.codeUnits);

      // Alice → Bob
      final aliceCiphertext = await aliceSession.encrypt(aliceMessage);
      final aliceDecrypted = await bobSession.decrypt(aliceCiphertext);
      expect(aliceDecrypted, aliceMessage);

      // Bob → Alice
      final bobCiphertext = await bobSession.encrypt(bobMessage);
      final bobDecrypted = await aliceSession.decrypt(bobCiphertext);
      expect(bobDecrypted, bobMessage);
    });

    test('handles multiple messages with nonce increment', () async {
      final messages = [
        'Message 1',
        'Message 2',
        'Message 3',
      ];

      for (final msg in messages) {
        final plaintext = Uint8List.fromList(msg.codeUnits);
        final ciphertext = await aliceSession.encrypt(plaintext);
        final decrypted = await bobSession.decrypt(ciphertext);

        expect(decrypted, plaintext);
      }
    });

    test('different messages produce different ciphertexts', () async {
      final plaintext1 = Uint8List.fromList('Message 1'.codeUnits);
      final plaintext2 = Uint8List.fromList('Message 1'.codeUnits);

      final ciphertext1 = await aliceSession.encrypt(plaintext1);
      final ciphertext2 = await aliceSession.encrypt(plaintext2);

      // Same plaintext should produce different ciphertext (due to nonce)
      expect(ciphertext1, isNot(equals(ciphertext2)));
    });

    test('detects tampered ciphertext', () async {
      final plaintext = Uint8List.fromList('Secret message'.codeUnits);
      final ciphertext = await aliceSession.encrypt(plaintext);

      // Tamper with ciphertext
      final tampered = Uint8List.fromList(ciphertext);
      tampered[5] ^= 0xFF; // Flip bits

      // Should throw on decryption
      expect(
        () => bobSession.decrypt(tampered),
        throwsA(isA<NoiseException>()),
      );
    });

    test('session serialization roundtrip', () async {
      // Serialize
      final json = await aliceSession.toJson();

      expect(json, contains('sendKey'));
      expect(json, contains('receiveKey'));
      expect(json, contains('remoteStaticKey'));
      expect(json, contains('sendNonce'));
      expect(json, contains('receiveNonce'));

      // Deserialize
      final restored = NoiseSession.fromJson(json);

      // Test restored session works
      final plaintext = Uint8List.fromList('Test after restore'.codeUnits);
      final ciphertext = await restored.encrypt(plaintext);
      final decrypted = await bobSession.decrypt(ciphertext);

      expect(decrypted, plaintext);
    });

    test('handles empty messages', () async {
      final empty = Uint8List(0);

      final ciphertext = await aliceSession.encrypt(empty);
      // Empty message: nonce (12) + ciphertext (0) + MAC (16) = 28 bytes
      expect(ciphertext.length, 28);

      final decrypted = await bobSession.decrypt(ciphertext);
      expect(decrypted, empty);
    });

    test('handles large messages', () async {
      // 10KB message
      final large = Uint8List.fromList(List.generate(10240, (i) => i % 256));

      final ciphertext = await aliceSession.encrypt(large);
      final decrypted = await bobSession.decrypt(ciphertext);

      expect(decrypted, large);
    });
  });

  group('Noise Protocol Compliance', () {
    test('handshake messages have correct sizes', () async {
      final alice = NoiseHandshake(
        role: NoiseRole.initiator,
        staticKeyPair: aliceStatic,
        ephemeralKeyPair: aliceEphemeral,
      );

      final bob = NoiseHandshake(
        role: NoiseRole.responder,
        staticKeyPair: bobStatic,
        ephemeralKeyPair: bobEphemeral,
      );

      // Message 1: e (32 bytes)
      final msg1 = await alice.generateMessage1();
      expect(msg1.length, 32);

      // Message 2: e (32) + encrypted s (48)
      final msg2 = await bob.processMessage1AndGenerateMessage2(msg1);
      expect(msg2.length, 80);

      // Message 3: encrypted s (48)
      final msg3 = await alice.processMessage2AndGenerateMessage3(msg2);
      expect(msg3.length, 48);
    });

    test('transport keys are different for each direction', () async {
      final alice = NoiseHandshake(
        role: NoiseRole.initiator,
        staticKeyPair: aliceStatic,
        ephemeralKeyPair: aliceEphemeral,
      );

      final bob = NoiseHandshake(
        role: NoiseRole.responder,
        staticKeyPair: bobStatic,
        ephemeralKeyPair: bobEphemeral,
      );

      // Complete handshake
      final msg1 = await alice.generateMessage1();
      final msg2 = await bob.processMessage1AndGenerateMessage2(msg1);
      final msg3 = await alice.processMessage2AndGenerateMessage3(msg2);
      await bob.processMessage3(msg3);

      final aliceSession = await alice.deriveSession();
      final bobSession = await bob.deriveSession();

      // The keys should be swapped (Alice's send = Bob's receive)
      final aliceSendBytes = await aliceSession.sendKey.extractBytes();
      final bobReceiveBytes = await bobSession.receiveKey.extractBytes();

      expect(aliceSendBytes, bobReceiveBytes);
    });
  });
}
