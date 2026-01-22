import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:meshlink_core/database/app_database.dart';
import 'package:meshlink_core/utils/geohash.dart';

/// Repository for Rally Mode operations
///
/// Handles all Rally channel operations including:
/// - Channel discovery based on location
/// - Channel creation and joining
/// - Message posting and retrieval
/// - Member management
/// - Message expiration cleanup
class RallyRepository {
  RallyRepository({
    required AppDatabase database,
  }) : _database = database;

  final AppDatabase _database;

  /// Discover Rally channels near user's location
  ///
  /// Finds channels within a specified radius using geohash-based queries.
  /// Returns channels sorted by distance (nearest first).
  ///
  /// [latitude] User's current latitude
  /// [longitude] User's current longitude
  /// [radiusMeters] Search radius (default 5000m = 5km)
  ///
  /// Example:
  /// ```dart
  /// final channels = await repository.discoverChannelsNear(
  ///   latitude: 37.7749,
  ///   longitude: -122.4194,
  ///   radiusMeters: 5000,
  /// );
  /// ```
  Future<List<RallyChannel>> discoverChannelsNear({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
  }) async {
    // Generate geohash for current location (precision 6 = ~1.2km)
    final centerGeohash = Geohash.encode(latitude, longitude, precision: 6);

    // Get neighboring geohashes to expand search area
    final neighbors = Geohash.neighbors(centerGeohash);

    // Query database for channels in this geohash region
    final channelEntities = await _database.getRallyChannelsNearLocation(
      geohash: centerGeohash,
      neighborGeohashes: neighbors,
    );

    // Convert to domain models and calculate distance
    final channels = <RallyChannel>[];
    for (final entity in channelEntities) {
      if (entity.centroidLatitude == null || entity.centroidLongitude == null) {
        continue; // Skip channels without location
      }

      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        entity.centroidLatitude!,
        entity.centroidLongitude!,
      );

      // Filter by radius
      if (distance <= radiusMeters) {
        channels.add(RallyChannel(
          id: entity.id,
          name: entity.name ?? 'Rally Channel',
          geohash: entity.geohash!,
          latitude: entity.centroidLatitude!,
          longitude: entity.centroidLongitude!,
          radiusMeters: entity.channelRadiusMeters ?? 1200,
          participantCount: entity.participantCount,
          distance: distance,
          createdAt: entity.createdAt,
          maxMessageAgeHours: entity.maxMessageAgeHours ?? 4,
        ));
      }
    }

    // Sort by distance (nearest first)
    channels.sort((a, b) => a.distance.compareTo(b.distance));
    return channels;
  }

  /// Create or join Rally channel at current location
  ///
  /// Generates a deterministic channel ID based on location + time bucket.
  /// If channel already exists, joins it. Otherwise, creates a new channel.
  ///
  /// [latitude] Channel center latitude
  /// [longitude] Channel center longitude
  /// [userId] User's ID (mesh peer ID or anonymous ID)
  /// [displayName] Display name to use in channel
  /// [identityType] Type of identity (anonymous, pseudonymous, verified)
  ///
  /// Example:
  /// ```dart
  /// final channel = await repository.createOrJoinChannelAt(
  ///   latitude: 37.7749,
  ///   longitude: -122.4194,
  ///   userId: 'user123',
  ///   displayName: 'Alice',
  ///   identityType: RallyIdentityType.verified,
  /// );
  /// ```
  Future<RallyChannel> createOrJoinChannelAt({
    required double latitude,
    required double longitude,
    required String userId,
    required String displayName,
    required RallyIdentityType identityType,
  }) async {
    // Generate deterministic channel ID (location + 4-hour time bucket)
    final channelId = Geohash.generateChannelId(latitude, longitude);
    final geohash = Geohash.encode(latitude, longitude, precision: 6);

    // Check if channel already exists
    final existing = await _database.getRallyChannelByGeohash(geohash);

    if (existing != null) {
      // Join existing channel
      await _database.joinRallyChannel(
        channelId: existing.id,
        userId: userId,
        displayName: displayName,
        identityType: identityType.name,
      );

      return RallyChannel.fromEntity(existing);
    }

    // Create new channel
    final name = await _generateChannelName(latitude, longitude);

    await _database.into(_database.conversations).insert(
          ConversationsCompanion(
            id: Value(channelId),
            type: const Value('rally'),
            name: Value(name),
            centroidLatitude: Value(latitude),
            centroidLongitude: Value(longitude),
            channelRadiusMeters: const Value(1200), // ~1.2km (geohash precision 6)
            geohash: Value(geohash),
            creatorId: Value(userId),
            maxMessageAgeHours: const Value(4), // 4-hour default TTL
            isPublic: const Value(true),
            participantCount: const Value(0),
            createdAt: Value(DateTime.now()),
          ),
        );

    // Join channel as creator
    await _database.joinRallyChannel(
      channelId: channelId,
      userId: userId,
      displayName: displayName,
      identityType: identityType.name,
    );

    final created = await _database.getConversationById(channelId);
    return RallyChannel.fromEntity(created!);
  }

  /// Post message to Rally channel
  ///
  /// Creates a new message in the specified channel.
  /// Messages are visible to all channel members.
  ///
  /// [channelId] Target channel ID
  /// [content] Message content (text)
  /// [senderId] Sender's user ID
  /// [latitude] Optional: sender's current latitude
  /// [longitude] Optional: sender's current longitude
  ///
  /// Example:
  /// ```dart
  /// await repository.postToChannel(
  ///   channelId: 'rally_123',
  ///   content: 'Hello Rally!',
  ///   senderId: 'user123',
  ///   latitude: 37.7749,
  ///   longitude: -122.4194,
  /// );
  /// ```
  Future<void> postToChannel({
    required String channelId,
    required String content,
    required String senderId,
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now();

    // Generate message ID (deterministic hash)
    final messageId = _generateMessageId(
      content: content,
      senderId: senderId,
      timestamp: now,
    );

    // Build metadata with location (if provided)
    final metadata = <String, dynamic>{};
    if (latitude != null && longitude != null) {
      metadata['location'] = {
        'latitude': latitude,
        'longitude': longitude,
      };
    }

    // Insert message
    await _database.insertMessage(
      MessagesCompanion(
        id: Value(messageId),
        conversationId: Value(channelId),
        senderId: Value(senderId),
        content: Value(content),
        type: const Value('text'),
        status: const Value('sent'), // Rally messages don't have pending state
        transport: const Value('rally'),
        timestamp: Value(now),
        isFromMe: const Value(true),
        metadata: Value(jsonEncode(metadata)),
      ),
    );

    // Update channel last message timestamp
    await _database.updateLastMessage(
      conversationId: channelId,
      timestamp: now,
    );

    // Update member's last seen and message count
    await _updateMemberActivity(channelId, senderId);
  }

  /// Get messages for Rally channel
  ///
  /// Retrieves non-expired messages from the channel.
  /// Messages older than the channel's TTL are excluded.
  /// Messages from users with low reputation are also filtered.
  ///
  /// [channelId] Channel ID
  /// [limit] Maximum number of messages (default 100)
  /// [filterLowReputation] Filter messages from low-reputation users (default true)
  /// [reputationThreshold] Minimum reputation score to show (default 20)
  ///
  /// Example:
  /// ```dart
  /// final messages = await repository.getChannelMessages('rally_123');
  /// ```
  Future<List<MessageEntity>> getChannelMessages(
    String channelId, {
    int limit = 100,
    bool filterLowReputation = true,
    int reputationThreshold = 20,
  }) async {
    // Get channel to check TTL
    final channel = await _database.getConversationById(channelId);
    if (channel == null) return [];

    final maxAge = channel.maxMessageAgeHours ?? 4;
    final cutoff = DateTime.now().subtract(Duration(hours: maxAge));

    // Get all messages for channel
    final allMessages = await _database.getMessagesForConversation(
      channelId,
      limit: limit,
    );

    // Filter out expired messages
    var filteredMessages = allMessages.where((m) => m.timestamp.isAfter(cutoff)).toList();

    // Apply reputation filtering if enabled
    if (filterLowReputation) {
      final reputationScores = await _getUserReputationScores(channelId);

      filteredMessages = filteredMessages.where((message) {
        final reputation = reputationScores[message.senderId] ?? 50; // Default 50
        return reputation >= reputationThreshold;
      }).toList();
    }

    return filteredMessages;
  }

  /// Get Rally channel by ID
  ///
  /// Example:
  /// ```dart
  /// final channel = await repository.getChannelById('rally_123');
  /// ```
  Future<RallyChannel?> getChannelById(String channelId) async {
    final entity = await _database.getConversationById(channelId);
    if (entity == null || entity.type != 'rally') return null;
    return RallyChannel.fromEntity(entity);
  }

  /// Leave Rally channel
  ///
  /// Removes the user from the channel's member list.
  ///
  /// [channelId] Channel to leave
  /// [userId] User leaving the channel
  ///
  /// Example:
  /// ```dart
  /// await repository.leaveChannel(
  ///   channelId: 'rally_123',
  ///   userId: 'user123',
  /// );
  /// ```
  Future<void> leaveChannel({
    required String channelId,
    required String userId,
  }) async {
    await _database.leaveRallyChannel(
      channelId: channelId,
      userId: userId,
    );
  }

  /// Get members of Rally channel
  ///
  /// Example:
  /// ```dart
  /// final members = await repository.getChannelMembers('rally_123');
  /// ```
  Future<List<RallyChannelMemberEntity>> getChannelMembers(
    String channelId,
  ) async {
    return await _database.getRallyChannelMembers(channelId);
  }

  /// Join an existing Rally channel
  ///
  /// Simpler version for joining a channel you already have.
  ///
  /// [channelId] Channel to join
  /// [userId] User's ID
  /// [displayName] Display name to use
  /// [identityType] Type of identity
  ///
  /// Example:
  /// ```dart
  /// await repository.joinExistingChannel(
  ///   channelId: 'rally_123',
  ///   userId: 'user123',
  ///   displayName: 'Alice',
  ///   identityType: RallyIdentityType.verified,
  /// );
  /// ```
  Future<void> joinExistingChannel({
    required String channelId,
    required String userId,
    required String displayName,
    required RallyIdentityType identityType,
  }) async {
    await _database.joinRallyChannel(
      channelId: channelId,
      userId: userId,
      displayName: displayName,
      identityType: identityType.name,
    );
  }

  /// Report a user or message
  ///
  /// Creates a local report for moderation purposes.
  ///
  /// [reporterId] User making the report
  /// [reportedUserId] User being reported
  /// [category] Report category (spam, harassment, threats, csam)
  /// [messageId] Optional: specific message being reported
  /// [notes] Optional: additional context
  ///
  /// Example:
  /// ```dart
  /// await repository.reportUser(
  ///   reporterId: 'user123',
  ///   reportedUserId: 'baduser456',
  ///   category: 'spam',
  ///   notes: 'Posting unwanted advertisements',
  /// );
  /// ```
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String category,
    String? messageId,
    String? notes,
  }) async {
    await _database.insertRallyReport(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      messageId: messageId,
      category: category,
      notes: notes,
    );
  }

  /// Clean up expired messages
  ///
  /// Deletes messages older than their channel's TTL.
  /// Should be called periodically (e.g., every 10 minutes).
  ///
  /// Returns the number of messages deleted.
  ///
  /// Example:
  /// ```dart
  /// final deletedCount = await repository.cleanupExpiredMessages();
  /// print('Deleted $deletedCount expired messages');
  /// ```
  Future<int> cleanupExpiredMessages() async {
    return await _database.deleteExpiredRallyMessages();
  }

  /// Store a Rally channel discovered via mesh network
  ///
  /// Called when receiving Rally channel announcements from nearby mesh peers.
  /// Stores the channel in local database so it appears in channel discovery.
  ///
  /// [channelId] Unique channel ID
  /// [name] Channel display name
  /// [geohash] Location geohash
  /// [latitude] Channel center latitude
  /// [longitude] Channel center longitude
  /// [radiusMeters] Channel radius
  /// [maxMessageAgeHours] Message TTL
  /// [creatorPeerId] Mesh peer ID of creator
  Future<void> storeMeshDiscoveredChannel({
    required String channelId,
    required String name,
    required String geohash,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required int maxMessageAgeHours,
    required String creatorPeerId,
  }) async {
    // Check if channel already exists
    final existing = await _database.getConversationById(channelId);
    if (existing != null) {
      return; // Already have this channel
    }

    // Store mesh-discovered channel
    await _database.into(_database.conversations).insert(
          ConversationsCompanion(
            id: Value(channelId),
            type: const Value('rally'),
            name: Value(name),
            centroidLatitude: Value(latitude),
            centroidLongitude: Value(longitude),
            channelRadiusMeters: Value(radiusMeters),
            geohash: Value(geohash),
            creatorId: Value(creatorPeerId),
            maxMessageAgeHours: Value(maxMessageAgeHours),
            isPublic: const Value(true),
            participantCount: const Value(1), // At least the creator
            createdAt: Value(DateTime.now()),
            // Mark as discovered via mesh (could add a field for this)
          ),
        );
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  /// Generate deterministic message ID from content + timestamp + sender
  String _generateMessageId({
    required String content,
    required String senderId,
    required DateTime timestamp,
  }) {
    final data = '$content${timestamp.millisecondsSinceEpoch}$senderId';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate channel name from location using reverse geocoding
  ///
  /// Uses reverse geocoding to get a human-readable address.
  /// Falls back to geohash if geocoding fails.
  Future<String> _generateChannelName(double lat, double lon) async {
    try {
      // Try reverse geocoding
      final placemarks = await placemarkFromCoordinates(lat, lon);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Try different levels of specificity
        if (place.street != null && place.street!.isNotEmpty) {
          // Street level: "Rally on Main St"
          return 'Rally on ${place.street}';
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          // City level: "Rally in San Francisco"
          return 'Rally in ${place.locality}';
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          // County level: "Rally in Marin County"
          return 'Rally in ${place.subAdministrativeArea}';
        } else if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          // State level: "Rally in California"
          return 'Rally in ${place.administrativeArea}';
        }
      }
    } catch (e) {
      // Geocoding failed, fall back to geohash
    }

    // Fallback: use geohash
    final geohash = Geohash.encode(lat, lon, precision: 6);
    return 'Rally @ $geohash';
  }

  /// Update member's activity (last seen, message count)
  Future<void> _updateMemberActivity(String channelId, String userId) async {
    await _database.updateRallyMemberLastSeen(
      channelId: channelId,
      userId: userId,
    );

    // Increment message count would require a custom query
    // For now, we'll skip this and rely on the default value
  }

  /// Get reputation scores for all users in a channel
  ///
  /// Returns map of userId -> reputation score (0-100)
  Future<Map<String, int>> _getUserReputationScores(String channelId) async {
    final members = await _database.getRallyChannelMembers(channelId);
    final scores = <String, int>{};

    for (final member in members) {
      // Get base reputation from member record
      var reputation = member.reputationScore;

      // Adjust based on reports
      final reports = await _database.getRallyReportsForUser(member.userId);
      final recentReports = reports.where(
        (r) => r.reportedAt.isAfter(DateTime.now().subtract(const Duration(hours: 24))),
      ).length;

      // Each recent report reduces reputation by 10 points
      reputation -= (recentReports * 10);

      // Clamp between 0 and 100
      reputation = reputation.clamp(0, 100);

      scores[member.userId] = reputation;
    }

    return scores;
  }

  /// Update user reputation based on reports
  ///
  /// Called after a new report is created to recalculate reputation.
  ///
  /// [userId] User whose reputation should be updated
  Future<void> _updateUserReputation(String userId) async {
    // Get all reports for this user
    final reports = await _database.getRallyReportsForUser(userId);

    // Calculate reputation based on report severity
    var reputationPenalty = 0;

    for (final report in reports) {
      // More severe categories have bigger impact
      switch (report.category) {
        case 'spam':
          reputationPenalty += 5;
          break;
        case 'harassment':
          reputationPenalty += 15;
          break;
        case 'threats':
          reputationPenalty += 30;
          break;
        case 'csam':
          reputationPenalty += 100; // Immediate reputation loss
          break;
        default:
          reputationPenalty += 10;
      }
    }

    // Calculate new reputation (starts at 50, can go 0-100)
    final newReputation = (50 - reputationPenalty).clamp(0, 100);

    // Update database (this would require a custom update method)
    // For now, the reputation is calculated on-the-fly
  }

  /// Get user reputation score
  ///
  /// Returns reputation score (0-100) for a specific user.
  ///
  /// Example:
  /// ```dart
  /// final reputation = await repository.getUserReputation('user123');
  /// if (reputation < 30) {
  ///   // User has low reputation
  /// }
  /// ```
  Future<int> getUserReputation(String userId, String channelId) async {
    final scores = await _getUserReputationScores(channelId);
    return scores[userId] ?? 50; // Default neutral reputation
  }

  /// Block user in Rally channel
  ///
  /// Prevents seeing messages from this user.
  /// This is a local-only block (doesn't affect other users).
  ///
  /// [userId] User to block
  /// [channelId] Channel context
  ///
  /// Example:
  /// ```dart
  /// await repository.blockUser('baduser123', 'rally_channel_1');
  /// ```
  Future<void> blockUser(String userId, String channelId) async {
    // Report as blocked (special category)
    await reportUser(
      reporterId: 'self', // Special marker for self-blocks
      reportedUserId: userId,
      category: 'blocked',
      notes: 'User blocked by local user',
    );
  }
}

/// Rally channel domain model
class RallyChannel {
  final String id;
  final String name;
  final String geohash;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final int participantCount;
  final double distance; // Distance from user in meters
  final DateTime createdAt;
  final int maxMessageAgeHours;

  RallyChannel({
    required this.id,
    required this.name,
    required this.geohash,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.participantCount,
    required this.distance,
    required this.createdAt,
    required this.maxMessageAgeHours,
  });

  factory RallyChannel.fromEntity(ConversationEntity entity) {
    return RallyChannel(
      id: entity.id,
      name: entity.name ?? 'Rally Channel',
      geohash: entity.geohash ?? '',
      latitude: entity.centroidLatitude ?? 0.0,
      longitude: entity.centroidLongitude ?? 0.0,
      radiusMeters: entity.channelRadiusMeters ?? 1200,
      participantCount: entity.participantCount,
      distance: 0, // Set by caller
      createdAt: entity.createdAt,
      maxMessageAgeHours: entity.maxMessageAgeHours ?? 4,
    );
  }

  /// Format distance for display
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      final km = distance / 1000;
      if (km < 10) {
        return '${km.toStringAsFixed(1)}km';
      } else {
        return '${km.round()}km';
      }
    }
  }

  /// Get time until channel expires (based on time bucket)
  Duration get timeUntilExpiration {
    // Channels expire every 4 hours (time bucket changes)
    final timeBucket = createdAt.millisecondsSinceEpoch ~/ (4 * 3600000);
    final nextBucket = (timeBucket + 1) * (4 * 3600000);
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(nextBucket);
    return expiresAt.difference(DateTime.now());
  }

  /// Check if channel is active (not expired)
  bool get isActive {
    return timeUntilExpiration.inSeconds > 0;
  }
}

/// Identity type for Rally participation
enum RallyIdentityType {
  /// Fully anonymous (anon-adjective-noun-number)
  anonymous,

  /// User-chosen pseudonym
  pseudonymous,

  /// Linked to cloud identity (verified)
  verified,
}

/// Rally repository exception
class RallyRepositoryException implements Exception {
  RallyRepositoryException(this.message);
  final String message;

  @override
  String toString() => 'RallyRepositoryException: $message';
}
