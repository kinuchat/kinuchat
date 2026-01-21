/// Test utilities for E2E tests
///
/// Provides identity generation, HTTP helpers, and demo data generation.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

/// Generate cryptographically secure random bytes
Uint8List generateSecureRandom(int length) {
  final random = Random.secure();
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

/// Test identity with X25519 key pair
class TestIdentity {
  final String name;
  final SimpleKeyPair keyPair;
  final Uint8List publicKeyBytes;
  final Uint8List keyHash;

  TestIdentity._({
    required this.name,
    required this.keyPair,
    required this.publicKeyBytes,
    required this.keyHash,
  });

  /// Generate a new test identity
  static Future<TestIdentity> generate(String name) async {
    final keyPair = await X25519().newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = Uint8List.fromList(publicKey.bytes);
    final keyHash = Uint8List.fromList(sha256.convert(publicKeyBytes).bytes);

    return TestIdentity._(
      name: name,
      keyPair: keyPair,
      publicKeyBytes: publicKeyBytes,
      keyHash: keyHash,
    );
  }

  String get keyHashBase64 => base64Encode(keyHash);
  String get keyHashHex => keyHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  String get publicKeyBase64 => base64Encode(publicKeyBytes);
}

/// HTTP POST helper
Future<HttpClientResponse> postJson(String url, Map<String, dynamic> body) async {
  final client = HttpClient();
  final request = await client.postUrl(Uri.parse(url));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(body));
  return request.close();
}

/// Extension to read response body
extension HttpClientResponseX on HttpClientResponse {
  Future<String> get body async {
    return transform(utf8.decoder).join();
  }
}

/// Demo data generator for screenshots
class DemoDataGenerator {
  final _random = Random(42); // Fixed seed for reproducible demo data

  /// Generate demo conversations
  List<DemoConversation> generateConversations() {
    return [
      DemoConversation(
        contactName: 'Alice Chen',
        avatarInitials: 'A',
        lastSeen: 'Online',
        messages: [
          DemoMessage(
            text: 'Hey! Are you coming to the concert?',
            isFromMe: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
            status: 'read',
          ),
          DemoMessage(
            text: "Yes! Can't wait \ud83c\udfb5",
            isFromMe: true,
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
            status: 'read',
          ),
          DemoMessage(
            text: 'Great! Meet at the north entrance',
            isFromMe: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
            status: 'read',
          ),
          DemoMessage(
            text: 'Sure, see you there!',
            isFromMe: true,
            timestamp: DateTime.now(),
            status: 'delivered',
          ),
        ],
      ),
      DemoConversation(
        contactName: 'Work Group',
        avatarInitials: '\ud83d\udc65',
        isGroup: true,
        memberCount: 8,
        messages: [
          DemoMessage(
            text: 'Bob: The meeting is moved to 3pm',
            isFromMe: false,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            status: 'read',
          ),
          DemoMessage(
            text: 'Got it, thanks!',
            isFromMe: true,
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
            status: 'read',
          ),
        ],
        unreadCount: 3,
      ),
      DemoConversation(
        contactName: 'Mom',
        avatarInitials: 'M',
        lastSeen: 'Last seen yesterday',
        messages: [
          DemoMessage(
            text: 'Call me when you can',
            isFromMe: false,
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            status: 'read',
          ),
        ],
      ),
      DemoConversation(
        contactName: 'David Park',
        avatarInitials: 'D',
        lastSeen: 'via Mesh',
        transportIndicator: 'mesh',
        messages: [
          DemoMessage(
            text: 'The signal here is terrible',
            isFromMe: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
            status: 'delivered',
          ),
          DemoMessage(
            text: 'Using mesh mode - works great!',
            isFromMe: true,
            timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
            status: 'delivered',
          ),
        ],
      ),
    ];
  }

  /// Generate demo rally channel
  DemoRallyChannel generateRallyChannel() {
    return DemoRallyChannel(
      channelId: 'rally-x7k2',
      location: 'Central Park, NYC',
      peopleCount: 2400,
      messages: [
        DemoRallyMessage(
          anonymousName: 'brave-fox-23',
          text: 'Anyone know where the water station is?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        DemoRallyMessage(
          anonymousName: 'calm-river-87',
          text: 'Northwest corner near the big tree',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
        DemoRallyMessage(
          anonymousName: 'quick-bear-12',
          text: '\u26a0\ufe0f Medic needed section B!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          isUrgent: true,
        ),
        DemoRallyMessage(
          anonymousName: '@RedCross',
          text: "First aid tent is at coordinates 40.7829, -73.9654. We're sending someone to section B.",
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          isVerified: true,
        ),
        DemoRallyMessage(
          anonymousName: 'bold-wave-55',
          text: 'Thanks for the quick response! \ud83d\ude4f',
          timestamp: DateTime.now(),
          isMe: true,
        ),
      ],
    );
  }

  /// Generate demo bridge stats
  DemoBridgeStats generateBridgeStats() {
    return DemoBridgeStats(
      messagesRelayed: 12,
      bandwidthUsedMb: 2.3,
      nearbyPeers: 47,
      isActive: true,
      uptime: const Duration(hours: 2, minutes: 34),
    );
  }

  /// Generate demo contacts
  List<DemoContact> generateContacts() {
    return [
      DemoContact(
        name: 'Alice Chen',
        initials: 'A',
        isVerified: true,
        lastSeen: 'Online',
      ),
      DemoContact(
        name: 'Bob Smith',
        initials: 'B',
        isVerified: true,
        lastSeen: '2 hours ago',
      ),
      DemoContact(
        name: 'Carol Williams',
        initials: 'C',
        isVerified: false,
        lastSeen: 'Yesterday',
      ),
      DemoContact(
        name: 'David Park',
        initials: 'D',
        isVerified: true,
        lastSeen: 'via Mesh',
        isMeshNearby: true,
      ),
      DemoContact(
        name: 'Emma Garcia',
        initials: 'E',
        isVerified: false,
        lastSeen: 'Last week',
      ),
    ];
  }

  /// Generate demo supporter tiers
  List<DemoSupporterTier> generateSupporterTiers() {
    return [
      DemoSupporterTier(
        name: 'Friend',
        price: '\$2.99/month',
        badge: '\u2764\ufe0f',
        description: 'Show your support with a heart badge',
      ),
      DemoSupporterTier(
        name: 'Champion',
        price: '\$9.99/month',
        badge: '\u2b50',
        description: 'Star badge + priority support',
      ),
      DemoSupporterTier(
        name: 'Guardian',
        price: '\$24.99/month',
        badge: '\ud83d\udc8e',
        description: 'Gem badge + priority support + early access',
      ),
    ];
  }
}

// Demo data models

class DemoConversation {
  final String contactName;
  final String avatarInitials;
  final String? lastSeen;
  final List<DemoMessage> messages;
  final bool isGroup;
  final int? memberCount;
  final int? unreadCount;
  final String? transportIndicator;

  DemoConversation({
    required this.contactName,
    required this.avatarInitials,
    this.lastSeen,
    required this.messages,
    this.isGroup = false,
    this.memberCount,
    this.unreadCount,
    this.transportIndicator,
  });
}

class DemoMessage {
  final String text;
  final bool isFromMe;
  final DateTime timestamp;
  final String status;

  DemoMessage({
    required this.text,
    required this.isFromMe,
    required this.timestamp,
    required this.status,
  });
}

class DemoRallyChannel {
  final String channelId;
  final String location;
  final int peopleCount;
  final List<DemoRallyMessage> messages;

  DemoRallyChannel({
    required this.channelId,
    required this.location,
    required this.peopleCount,
    required this.messages,
  });
}

class DemoRallyMessage {
  final String anonymousName;
  final String text;
  final DateTime timestamp;
  final bool isVerified;
  final bool isUrgent;
  final bool isMe;

  DemoRallyMessage({
    required this.anonymousName,
    required this.text,
    required this.timestamp,
    this.isVerified = false,
    this.isUrgent = false,
    this.isMe = false,
  });
}

class DemoBridgeStats {
  final int messagesRelayed;
  final double bandwidthUsedMb;
  final int nearbyPeers;
  final bool isActive;
  final Duration uptime;

  DemoBridgeStats({
    required this.messagesRelayed,
    required this.bandwidthUsedMb,
    required this.nearbyPeers,
    required this.isActive,
    required this.uptime,
  });
}

class DemoContact {
  final String name;
  final String initials;
  final bool isVerified;
  final String lastSeen;
  final bool isMeshNearby;

  DemoContact({
    required this.name,
    required this.initials,
    required this.isVerified,
    required this.lastSeen,
    this.isMeshNearby = false,
  });
}

class DemoSupporterTier {
  final String name;
  final String price;
  final String badge;
  final String description;

  DemoSupporterTier({
    required this.name,
    required this.price,
    required this.badge,
    required this.description,
  });
}
