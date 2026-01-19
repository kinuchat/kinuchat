import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:meshlink_core/mesh/packet_codec.dart';
import 'package:meshlink_core/mesh/ble_constants.dart';

void main() {
  group('PacketType', () {
    test('has correct values', () {
      expect(PacketType.text.value, 0x01);
      expect(PacketType.handshakeInit.value, 0x05);
      expect(PacketType.peerAnnounce.value, 0x08);
    });

    test('can convert from value', () {
      expect(PacketType.fromValue(0x01), PacketType.text);
      expect(PacketType.fromValue(0x04), PacketType.ack);
    });

    test('throws on invalid value', () {
      expect(() => PacketType.fromValue(0xFF), throwsArgumentError);
    });
  });

  group('PacketFlags', () {
    test('can check flags', () {
      const flags = PacketFlags.hasRecipient | PacketFlags.requiresAck;

      expect(PacketFlags.hasFlag(flags, PacketFlags.hasRecipient), isTrue);
      expect(PacketFlags.hasFlag(flags, PacketFlags.requiresAck), isTrue);
      expect(PacketFlags.hasFlag(flags, PacketFlags.hasSignature), isFalse);
    });

    test('can set flags', () {
      var flags = 0;
      flags = PacketFlags.setFlag(flags, PacketFlags.hasRecipient);
      flags = PacketFlags.setFlag(flags, PacketFlags.requiresAck);

      expect(PacketFlags.hasFlag(flags, PacketFlags.hasRecipient), isTrue);
      expect(PacketFlags.hasFlag(flags, PacketFlags.requiresAck), isTrue);
    });

    test('can clear flags', () {
      var flags = PacketFlags.hasRecipient | PacketFlags.requiresAck;
      flags = PacketFlags.clearFlag(flags, PacketFlags.hasRecipient);

      expect(PacketFlags.hasFlag(flags, PacketFlags.hasRecipient), isFalse);
      expect(PacketFlags.hasFlag(flags, PacketFlags.requiresAck), isTrue);
    });
  });

  group('MeshPacket', () {
    late Uint8List messageId;
    late Uint8List recipientId;
    late Uint8List payload;

    setUp(() {
      // Create test data
      messageId = Uint8List(BleConstants.messageIdLength);
      for (int i = 0; i < messageId.length; i++) {
        messageId[i] = i;
      }

      recipientId = Uint8List(BleConstants.meshPeerIdLength);
      for (int i = 0; i < recipientId.length; i++) {
        recipientId[i] = 0xFF - i;
      }

      payload = Uint8List.fromList('Hello mesh world!'.codeUnits);
    });

    test('validates message ID length', () {
      expect(
        () => MeshPacket(
          type: PacketType.text,
          ttl: 7,
          flags: 0,
          timestamp: DateTime.now(),
          messageId: Uint8List(8), // Wrong size
          payload: payload,
        ),
        throwsArgumentError,
      );
    });

    test('validates recipient ID length', () {
      expect(
        () => MeshPacket(
          type: PacketType.text,
          ttl: 7,
          flags: 0,
          timestamp: DateTime.now(),
          messageId: messageId,
          recipientId: Uint8List(4), // Wrong size
          payload: payload,
        ),
        throwsArgumentError,
      );
    });

    test('validates TTL range', () {
      expect(
        () => MeshPacket(
          type: PacketType.text,
          ttl: 10, // Too high
          flags: 0,
          timestamp: DateTime.now(),
          messageId: messageId,
          payload: payload,
        ),
        throwsArgumentError,
      );

      expect(
        () => MeshPacket(
          type: PacketType.text,
          ttl: -1, // Negative
          flags: 0,
          timestamp: DateTime.now(),
          messageId: messageId,
          payload: payload,
        ),
        throwsArgumentError,
      );
    });

    test('encode/decode roundtrip preserves data', () {
      final timestamp = DateTime.now();
      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 5,
        flags: PacketFlags.hasRecipient | PacketFlags.requiresAck,
        timestamp: timestamp,
        messageId: messageId,
        recipientId: recipientId,
        payload: payload,
      );

      final encoded = packet.encode();
      final decoded = MeshPacket.decode(encoded);

      expect(decoded.version, packet.version);
      expect(decoded.type, packet.type);
      expect(decoded.ttl, packet.ttl);
      expect(decoded.flags, packet.flags);
      expect(decoded.timestamp.millisecondsSinceEpoch,
          timestamp.millisecondsSinceEpoch);
      expect(decoded.messageId, messageId);
      expect(decoded.recipientId, recipientId);
      expect(decoded.payload, payload);
    });

    test('encode produces 64-byte header', () {
      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 7,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: messageId,
        payload: payload,
      );

      final encoded = packet.encode();

      // Header is 64 bytes, payload is variable
      expect(encoded.length, 64 + payload.length);
    });

    test('decode handles broadcast (null recipient)', () {
      final packet = MeshPacket(
        type: PacketType.peerAnnounce,
        ttl: 7,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: messageId,
        payload: payload,
      );

      final encoded = packet.encode();
      final decoded = MeshPacket.decode(encoded);

      expect(decoded.recipientId, isNull);
    });

    test('copyWith creates modified copy', () {
      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 7,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: messageId,
        payload: payload,
      );

      final modified = packet.copyWith(ttl: 5, type: PacketType.ack);

      expect(modified.ttl, 5);
      expect(modified.type, PacketType.ack);
      expect(modified.messageId, packet.messageId);
      expect(modified.payload, packet.payload);
    });

    test('toString includes relevant info', () {
      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 7,
        flags: PacketFlags.hasRecipient,
        timestamp: DateTime.now(),
        messageId: messageId,
        recipientId: recipientId,
        payload: payload,
      );

      final str = packet.toString();

      expect(str, contains('MeshPacket'));
      expect(str, contains('type=PacketType.text'));
      expect(str, contains('ttl=7'));
      expect(str, contains('flags=0x1'));
      expect(str, contains('payloadSize=${payload.length}'));
    });
  });

  group('Padding', () {
    test('applies PKCS#7 padding to power of 2', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final padded = MeshPacket.applyPadding(data);

      // Should pad to 64 bytes (smallest power of 2 >= 5)
      expect(padded.length, 64);

      // Padding should be PKCS#7 (pad length = 59)
      expect(padded.last, 59);
    });

    test('removes PKCS#7 padding correctly', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final padded = MeshPacket.applyPadding(data);
      final unpadded = MeshPacket.removePadding(padded);

      expect(unpadded, data);
    });

    test('roundtrip preserves original data', () {
      final testCases = [
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList(List.generate(100, (i) => i % 256)),
        Uint8List.fromList('Test message content'.codeUnits),
      ];

      for (final data in testCases) {
        final padded = MeshPacket.applyPadding(data);
        final unpadded = MeshPacket.removePadding(padded);
        expect(unpadded, data, reason: 'Failed for ${data.length} bytes');
      }
    });

    test('handles invalid padding gracefully', () {
      final invalid = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = MeshPacket.removePadding(invalid);

      // Should return data as-is when padding is invalid
      expect(result, invalid);
    });
  });

  group('Binary Format', () {
    test('version is first byte', () {
      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 7,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: Uint8List(16),
        payload: Uint8List(0),
      );

      final encoded = packet.encode();
      expect(encoded[0], 1); // Version 1
    });

    test('type is second byte', () {
      final packet = MeshPacket(
        type: PacketType.handshakeInit,
        ttl: 7,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: Uint8List(16),
        payload: Uint8List(0),
      );

      final encoded = packet.encode();
      expect(encoded[1], PacketType.handshakeInit.value);
    });

    test('ttl is third byte', () {
      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 5,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: Uint8List(16),
        payload: Uint8List(0),
      );

      final encoded = packet.encode();
      expect(encoded[2], 5);
    });

    test('flags is fourth byte', () {
      final flags = PacketFlags.hasRecipient | PacketFlags.requiresAck;
      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 7,
        flags: flags,
        timestamp: DateTime.now(),
        messageId: Uint8List(16),
        payload: Uint8List(0),
      );

      final encoded = packet.encode();
      expect(encoded[3], flags);
    });

    test('rejects packets smaller than header', () {
      expect(
        () => MeshPacket.decode(Uint8List(32)),
        throwsArgumentError,
      );
    });

    test('rejects unsupported protocol version', () {
      final invalidPacket = Uint8List(64);
      invalidPacket[0] = 2; // Unsupported version

      expect(
        () => MeshPacket.decode(invalidPacket),
        throwsArgumentError,
      );
    });
  });
}
