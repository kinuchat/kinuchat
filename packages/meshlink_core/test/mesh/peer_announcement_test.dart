import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:meshlink_core/mesh/peer_announcement.dart';
import 'package:meshlink_core/models/identity.dart';
import 'package:meshlink_core/models/key_pair.dart';

void main() {
  group('PeerAnnouncement', () {
    late Uint8List ed25519Key;
    late Uint8List x25519Key;
    late String meshPeerId;

    setUp(() {
      ed25519Key = Uint8List.fromList(List.generate(32, (i) => i));
      x25519Key = Uint8List.fromList(List.generate(32, (i) => 255 - i));
      meshPeerId = '0123456789abcdef'; // 8 bytes
    });

    test('creates announcement with valid data', () {
      final announcement = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: 'Alice',
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      expect(announcement.meshPeerId, meshPeerId);
      expect(announcement.displayName, 'Alice');
      expect(announcement.ed25519PublicKey, ed25519Key);
      expect(announcement.x25519PublicKey, x25519Key);
    });

    test('validates mesh peer ID length', () {
      expect(
        () => PeerAnnouncement(
          meshPeerId: '0123456789', // Too short
          displayName: 'Alice',
          ed25519PublicKey: ed25519Key,
          x25519PublicKey: x25519Key,
        ),
        throwsArgumentError,
      );
    });

    test('validates ed25519 key length', () {
      expect(
        () => PeerAnnouncement(
          meshPeerId: meshPeerId,
          displayName: 'Alice',
          ed25519PublicKey: Uint8List(16), // Too short
          x25519PublicKey: x25519Key,
        ),
        throwsArgumentError,
      );
    });

    test('validates x25519 key length', () {
      expect(
        () => PeerAnnouncement(
          meshPeerId: meshPeerId,
          displayName: 'Alice',
          ed25519PublicKey: ed25519Key,
          x25519PublicKey: Uint8List(16), // Too short
        ),
        throwsArgumentError,
      );
    });

    test('encode/decode roundtrip preserves data', () {
      final original = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: 'Alice',
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      final encoded = original.encode();
      final decoded = PeerAnnouncement.decode(encoded);

      expect(decoded.meshPeerId, original.meshPeerId);
      expect(decoded.displayName, original.displayName);
      expect(decoded.ed25519PublicKey, original.ed25519PublicKey);
      expect(decoded.x25519PublicKey, original.x25519PublicKey);
    });

    test('handles empty display name', () {
      final announcement = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: '',
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      final encoded = announcement.encode();
      final decoded = PeerAnnouncement.decode(encoded);

      expect(decoded.displayName, '');
    });

    test('handles long display name', () {
      final longName = 'A' * 100;

      final announcement = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: longName,
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      final encoded = announcement.encode();
      final decoded = PeerAnnouncement.decode(encoded);

      expect(decoded.displayName, longName);
    });

    test('handles UTF-8 display names', () {
      final unicodeName = 'Alice 👋 スミス';

      final announcement = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: unicodeName,
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      final encoded = announcement.encode();
      final decoded = PeerAnnouncement.decode(encoded);

      expect(decoded.displayName, unicodeName);
    });

    test('encoded format has correct structure', () {
      final announcement = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: 'Alice',
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      final encoded = announcement.encode();

      // Check size: 8 (peer ID) + 2 (length) + 5 (name) + 32 + 32 = 79
      expect(encoded.length, 79);

      // Verify first 8 bytes are mesh peer ID
      final meshPeerIdBytes = encoded.sublist(0, 8);
      expect(
        meshPeerIdBytes,
        [0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef],
      );

      // Verify display name length (bytes 8-9)
      final nameLength = ByteData.sublistView(encoded).getUint16(8);
      expect(nameLength, 5); // "Alice"
    });

    test('rejects data too short', () {
      expect(
        () => PeerAnnouncement.decode(Uint8List(50)),
        throwsArgumentError,
      );
    });

    test('rejects incomplete data', () {
      final announcement = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: 'Alice',
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      final encoded = announcement.encode();

      // Truncate encoded data
      final truncated = encoded.sublist(0, 40);

      expect(
        () => PeerAnnouncement.decode(truncated),
        throwsArgumentError,
      );
    });

    test('equality comparison works', () {
      final announcement1 = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: 'Alice',
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      final announcement2 = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: 'Alice',
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      expect(announcement1, equals(announcement2));
      expect(announcement1.hashCode, equals(announcement2.hashCode));
    });

    test('inequality comparison works', () {
      final announcement1 = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: 'Alice',
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      final announcement2 = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: 'Bob',
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      expect(announcement1, isNot(equals(announcement2)));
    });

    test('toString includes key information', () {
      final announcement = PeerAnnouncement(
        meshPeerId: meshPeerId,
        displayName: 'Alice',
        ed25519PublicKey: ed25519Key,
        x25519PublicKey: x25519Key,
      );

      final str = announcement.toString();

      expect(str, contains('PeerAnnouncement'));
      expect(str, contains(meshPeerId));
      expect(str, contains('Alice'));
    });
  });

  group('PeerAnnouncement.fromIdentity', () {
    test('creates announcement from identity', () {
      final ed25519KeyPair = Ed25519KeyPair(
        publicKey: Uint8List.fromList(List.generate(32, (i) => i)),
        privateKey: Uint8List(64),
      );

      final x25519KeyPair = X25519KeyPair(
        publicKey: Uint8List.fromList(List.generate(32, (i) => 255 - i)),
        privateKey: Uint8List(32),
      );

      final identity = Identity(
        signingKeyPair: ed25519KeyPair,
        exchangeKeyPair: x25519KeyPair,
        meshPeerId: Uint8List.fromList([0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]),
        createdAt: DateTime.now(),
        displayName: 'Test User',
      );

      final announcement = PeerAnnouncement.fromIdentity(identity);

      expect(announcement.meshPeerId, identity.meshPeerIdHex);
      expect(announcement.displayName, identity.displayName);
      expect(announcement.ed25519PublicKey, ed25519KeyPair.publicKey);
      expect(announcement.x25519PublicKey, x25519KeyPair.publicKey);
    });
  });
}
