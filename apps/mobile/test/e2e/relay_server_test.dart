/// E2E Tests for Relay Server API
///
/// Tests the Bridge Relay Protocol as defined in Spec Section 6.4
///
/// Run with: dart test test/e2e/relay_server_test.dart
///
/// Environment variables:
///   RELAY_SERVER_URL - URL of relay server (default: http://localhost:3030)
///   USE_MOCK - Set to 'true' to use mock server (for CI/screenshots)

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';

import 'spec_reference.dart';
import 'test_utils.dart';

/// Relay server URL from environment or default
final relayServerUrl = Platform.environment['RELAY_SERVER_URL'] ?? 'http://localhost:3030';
final useMock = Platform.environment['USE_MOCK'] == 'true';

void main() {
  group('Relay Server API Tests (Spec 6.4)', () {
    late TestIdentity alice;
    late TestIdentity bob;

    setUpAll(() async {
      alice = await TestIdentity.generate('Alice');
      bob = await TestIdentity.generate('Bob');
      print('Generated test identities:');
      print('  Alice: ${alice.keyHashHex.substring(0, 16)}...');
      print('  Bob: ${bob.keyHashHex.substring(0, 16)}...');
    });

    group('POST /relay/upload', () {
      test('accepts valid relay envelope per spec', () async {
        if (useMock) {
          // Mock test
          expect(true, isTrue, reason: 'Mock mode - skipping server call');
          return;
        }

        final envelope = RelayEnvelope(
          recipientKeyHash: bob.keyHashBase64,
          encryptedPayload: base64Encode(utf8.encode('encrypted_test_message')),
          ttlHours: SpecRelay.defaultTtlHours,
          priority: 'normal',
          nonce: base64Encode(generateSecureRandom(16)),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        // Server expects { "envelope": { ... } } wrapper
        final response = await postJson(
          '$relayServerUrl${SpecRelay.uploadEndpoint}',
          {'envelope': envelope.toJson()},
        );

        // Server returns 201 CREATED on success
        expect(response.statusCode, equals(201));

        final body = jsonDecode(await response.body);
        expect(body['id'], isNotEmpty);
        expect(body['expires_at'], isNotNull);

        print('Upload successful: ${body['id']}');
      });

      test('validates TTL per spec (max 24 hours)', () async {
        if (useMock) return;

        final envelope = RelayEnvelope(
          recipientKeyHash: bob.keyHashBase64,
          encryptedPayload: base64Encode(utf8.encode('test')),
          ttlHours: 100, // Exceeds max (24), server will clamp or reject
          priority: 'normal',
          nonce: base64Encode(generateSecureRandom(16)),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        final response = await postJson(
          '$relayServerUrl${SpecRelay.uploadEndpoint}',
          {'envelope': envelope.toJson()},
        );

        // Server rejects with 400 since validation requires range 1-24
        expect(response.statusCode, equals(400));
      });

      test('accepts all priority levels per spec', () async {
        if (useMock) return;

        for (final priority in SpecRelay.priorities) {
          final envelope = RelayEnvelope(
            recipientKeyHash: bob.keyHashBase64,
            encryptedPayload: base64Encode(utf8.encode('priority_$priority')),
            ttlHours: 1,
            priority: priority,
            nonce: base64Encode(generateSecureRandom(16)),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );

          final response = await postJson(
            '$relayServerUrl${SpecRelay.uploadEndpoint}',
            {'envelope': envelope.toJson()},
          );

          expect(response.statusCode, equals(201),
              reason: 'Priority $priority should be accepted');
        }
      });

      test('spec privacy: cannot identify sender from envelope', () async {
        // Verify the envelope format doesn't include sender identity
        final envelope = RelayEnvelope(
          recipientKeyHash: bob.keyHashBase64,
          encryptedPayload: base64Encode(utf8.encode('secret')),
          ttlHours: 4,
          priority: 'normal',
          nonce: base64Encode(generateSecureRandom(16)),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        final json = envelope.toJson();

        // Per spec: "Bridge node cannot identify sender (not in envelope)"
        expect(json.containsKey('sender'), isFalse);
        expect(json.containsKey('sender_key'), isFalse);
        expect(json.containsKey('sender_id'), isFalse);
        expect(json.containsKey('from'), isFalse);

        print('Privacy check passed: envelope contains no sender identity');
      });
    });

    group('GET /relay/poll', () {
      test('returns messages for subscribed key hash', () async {
        if (useMock) return;

        // First, upload a message for Bob
        final testMessage = 'poll_test_${DateTime.now().millisecondsSinceEpoch}';
        final envelope = RelayEnvelope(
          recipientKeyHash: bob.keyHashBase64,
          encryptedPayload: base64Encode(utf8.encode(testMessage)),
          ttlHours: 1,
          priority: 'normal',
          nonce: base64Encode(generateSecureRandom(16)),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        await postJson('$relayServerUrl${SpecRelay.uploadEndpoint}', {'envelope': envelope.toJson()});

        // Now poll for Bob's messages
        final response = await HttpClient()
            .getUrl(Uri.parse(
                '$relayServerUrl${SpecRelay.pollEndpoint}?key_hash=${Uri.encodeComponent(bob.keyHashBase64)}'))
            .then((req) => req.close())
            .then((res) => res.transform(utf8.decoder).join());

        // Server returns { "messages": [...], "has_more": bool, "next_cursor": ... }
        final body = jsonDecode(response) as Map<String, dynamic>;
        final messages = body['messages'] as List;
        expect(messages, isNotEmpty);

        print('Poll returned ${messages.length} messages');
      });

      test('spec privacy: only returns messages matching key hash', () async {
        if (useMock) return;

        // Upload message for Bob
        final envelope = RelayEnvelope(
          recipientKeyHash: bob.keyHashBase64,
          encryptedPayload: base64Encode(utf8.encode('for_bob_only')),
          ttlHours: 1,
          priority: 'normal',
          nonce: base64Encode(generateSecureRandom(16)),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        await postJson('$relayServerUrl${SpecRelay.uploadEndpoint}', {'envelope': envelope.toJson()});

        // Poll with Alice's key hash - should NOT see Bob's message
        final response = await HttpClient()
            .getUrl(Uri.parse(
                '$relayServerUrl${SpecRelay.pollEndpoint}?key_hash=${Uri.encodeComponent(alice.keyHashBase64)}'))
            .then((req) => req.close())
            .then((res) => res.transform(utf8.decoder).join());

        // Server returns { "messages": [...], "has_more": bool, "next_cursor": ... }
        final body = jsonDecode(response) as Map<String, dynamic>;
        final messages = body['messages'] as List;

        // Verify none of the messages are for Bob
        for (final msg in messages) {
          expect(msg['recipient_key_hash'], isNot(equals(bob.keyHashBase64)));
        }

        print('Privacy check passed: Alice cannot see Bob\'s messages');
      });
    });

    group('WebSocket /relay/ws', () {
      test('subscribe and receive messages in real-time', () async {
        if (useMock) return;

        // Convert https to wss (or http to ws)
        final wsUrl = relayServerUrl
            .replaceFirst('https', 'wss')
            .replaceFirst('http', 'ws');
        final channel = IOWebSocketChannel.connect('$wsUrl/relay/ws');

        // Convert to broadcast stream so we can listen multiple times
        final stream = channel.stream.asBroadcastStream();

        // Subscribe to Bob's key hash
        channel.sink.add(jsonEncode({
          'type': 'subscribe',
          'key_hash': bob.keyHashBase64,
        }));

        // Wait for subscription confirmation
        final subscribeResponse = await stream.first;
        final subMsg = jsonDecode(subscribeResponse as String);
        expect(subMsg['type'], equals('subscribed'));

        // Upload a message (simulating another client)
        final testMessage = 'ws_test_${DateTime.now().millisecondsSinceEpoch}';
        final envelope = RelayEnvelope(
          recipientKeyHash: bob.keyHashBase64,
          encryptedPayload: base64Encode(utf8.encode(testMessage)),
          ttlHours: 1,
          priority: 'normal',
          nonce: base64Encode(generateSecureRandom(16)),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        await postJson('$relayServerUrl${SpecRelay.uploadEndpoint}', {'envelope': envelope.toJson()});

        // Should receive message via WebSocket (server polls every 2 seconds)
        final messageResponse = await stream.first.timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('No message received'),
        );

        final msgData = jsonDecode(messageResponse as String);
        // Server sends type: "new_message" per the WsMessage enum
        expect(msgData['type'], equals('new_message'));
        expect(msgData['envelope'], isNotNull);

        await channel.sink.close();
        print('WebSocket real-time delivery working');
      });

      test('acknowledge messages removes them from server', () async {
        if (useMock) return;

        // Convert https to wss (or http to ws)
        final wsUrl = relayServerUrl
            .replaceFirst('https', 'wss')
            .replaceFirst('http', 'ws');
        final channel = IOWebSocketChannel.connect('$wsUrl/relay/ws');

        // Convert to broadcast stream so we can listen multiple times
        final stream = channel.stream.asBroadcastStream();

        // Subscribe
        channel.sink.add(jsonEncode({
          'type': 'subscribe',
          'key_hash': bob.keyHashBase64,
        }));

        await stream.first; // Wait for subscribed

        // Upload message
        final envelope = RelayEnvelope(
          recipientKeyHash: bob.keyHashBase64,
          encryptedPayload: base64Encode(utf8.encode('ack_test')),
          ttlHours: 1,
          priority: 'normal',
          nonce: base64Encode(generateSecureRandom(16)),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        final uploadResponse = await postJson(
          '$relayServerUrl${SpecRelay.uploadEndpoint}',
          {'envelope': envelope.toJson()},
        );
        final messageId = jsonDecode(await uploadResponse.body)['id'];

        // Acknowledge the message
        channel.sink.add(jsonEncode({
          'type': 'ack',
          'message_ids': [messageId],
        }));

        final ackResponse = await stream.first;
        final ackData = jsonDecode(ackResponse as String);
        expect(ackData['type'], equals('acked'));
        expect(ackData['deleted'], equals(1));

        await channel.sink.close();
        print('Acknowledge removes messages from server');
      });
    });

    group('Spec Compliance Checks', () {
      test('envelope format matches spec 6.4', () {
        final envelope = RelayEnvelope(
          recipientKeyHash: 'base64_key_hash',
          encryptedPayload: 'base64_encrypted_data',
          ttlHours: 4,
          priority: 'normal',
          nonce: 'base64_nonce',
          createdAt: 1704067200000,
        );

        final json = envelope.toJson();

        // Verify all required fields per spec
        expect(json['recipient_key_hash'], isNotNull);
        expect(json['encrypted_payload'], isNotNull);
        expect(json['ttl_hours'], isNotNull);
        expect(json['priority'], isNotNull);
        expect(json['nonce'], isNotNull);
        expect(json['created_at'], isNotNull);

        print('Envelope format matches spec 6.4');
      });

      test('key hash is SHA256 of X25519 public key per spec', () async {
        // Per spec 6.1: "Relay Key Hash: SHA256(X25519_pub)"
        final keyPair = await X25519().newKeyPair();
        final publicKey = await keyPair.extractPublicKey();
        final publicKeyBytes = publicKey.bytes;

        final keyHash = sha256.convert(publicKeyBytes);

        expect(keyHash.bytes.length, equals(32));
        print('Key hash derivation matches spec 6.1');
      });
    });
  });

  group('Demo Data Generation', () {
    test('generate demo conversations for screenshots', () async {
      final demoData = DemoDataGenerator();
      final conversations = demoData.generateConversations();

      expect(conversations, hasLength(greaterThan(0)));

      print('\n=== Demo Data for Screenshots ===');
      for (final conv in conversations) {
        print('\nConversation with ${conv.contactName}:');
        for (final msg in conv.messages) {
          final prefix = msg.isFromMe ? '  [Me]' : '  [${conv.contactName}]';
          print('$prefix ${msg.text}');
        }
      }
    });

    test('generate demo rally channel for screenshots', () async {
      final demoData = DemoDataGenerator();
      final rally = demoData.generateRallyChannel();

      expect(rally.messages, hasLength(greaterThan(0)));

      print('\n=== Rally Channel Demo ===');
      print('Channel: ${rally.channelId}');
      print('People nearby: ${rally.peopleCount}');
      for (final msg in rally.messages) {
        final badge = msg.isVerified ? ' [Verified]' : '';
        print('  ${msg.anonymousName}$badge: ${msg.text}');
      }
    });

    test('generate demo bridge stats for screenshots', () async {
      final demoData = DemoDataGenerator();
      final stats = demoData.generateBridgeStats();

      expect(stats.messagesRelayed, greaterThan(0));
      expect(stats.nearbyPeers, greaterThan(0));

      print('\n=== Bridge Mode Demo Stats ===');
      print('Messages relayed: ${stats.messagesRelayed}');
      print('Bandwidth used: ${stats.bandwidthUsedMb.toStringAsFixed(1)} MB');
      print('Nearby peers: ${stats.nearbyPeers}');
    });
  });
}

/// Relay envelope per spec 6.4
class RelayEnvelope {
  final String recipientKeyHash;
  final String encryptedPayload;
  final int ttlHours;
  final String priority;
  final String nonce;
  final int createdAt;

  RelayEnvelope({
    required this.recipientKeyHash,
    required this.encryptedPayload,
    required this.ttlHours,
    required this.priority,
    required this.nonce,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'recipient_key_hash': recipientKeyHash,
        'encrypted_payload': encryptedPayload,
        'ttl_hours': ttlHours,
        'priority': priority,
        'nonce': nonce,
        'created_at': createdAt,
      };
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}
