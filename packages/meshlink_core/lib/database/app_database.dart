import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

/// Contacts table
@DataClassName('ContactEntity')
class Contacts extends Table {
  /// Unique contact ID (mesh peer ID or Matrix user ID)
  TextColumn get id => text()();

  /// Display name
  TextColumn get displayName => text()();

  /// Optional avatar URL or base64 data
  TextColumn get avatar => text().nullable()();

  /// Ed25519 public key (hex encoded)
  TextColumn get publicKey => text()();

  /// X25519 public key for key exchange (hex encoded)
  TextColumn get exchangePublicKey => text()();

  /// Verification status (verified, unverified)
  TextColumn get verificationStatus =>
      text().withDefault(const Constant('unverified'))();

  /// When the contact was added
  DateTimeColumn get createdAt => dateTime()();

  /// Last time we saw this contact online
  DateTimeColumn get lastSeen => dateTime().nullable()();

  /// Is this contact blocked
  BoolColumn get isBlocked => boolean().withDefault(const Constant(false))();

  /// RSSI when last seen on mesh (signal strength in dBm)
  IntColumn get lastMeshRssi => integer().nullable()();

  /// Last time seen via mesh network
  DateTimeColumn get lastMeshSeen => dateTime().nullable()();

  /// Hop count when last reached via mesh
  IntColumn get lastMeshHopCount => integer().nullable()();

  /// Preferred transport hint (cloud, mesh, bridge)
  TextColumn get preferredTransport => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Conversations table (1:1, group, or rally chats)
@DataClassName('ConversationEntity')
class Conversations extends Table {
  /// Unique conversation ID
  TextColumn get id => text()();

  /// Conversation type (direct, group, rally)
  TextColumn get type => text()();

  /// Display name for groups
  TextColumn get name => text().nullable()();

  /// Avatar for groups
  TextColumn get avatar => text().nullable()();

  /// When the conversation was created
  DateTimeColumn get createdAt => dateTime()();

  /// Last message timestamp
  DateTimeColumn get lastMessageAt => dateTime().nullable()();

  /// Unread message count
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  /// Is this conversation muted
  BoolColumn get isMuted => boolean().withDefault(const Constant(false))();

  /// Is this conversation archived
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  // Rally-specific fields (Phase 3)
  /// Rally channel center latitude
  RealColumn get centroidLatitude => real().nullable()();

  /// Rally channel center longitude
  RealColumn get centroidLongitude => real().nullable()();

  /// Rally channel coverage radius in meters
  IntColumn get channelRadiusMeters => integer().nullable()();

  /// Rally channel geohash (precision 6 = ~1.2km)
  TextColumn get geohash => text().nullable()();

  /// Rally channel creator ID
  TextColumn get creatorId => text().nullable()();

  /// Rally message TTL in hours (default 4)
  IntColumn get maxMessageAgeHours => integer().nullable()();

  /// Is this a public Rally channel
  BoolColumn get isPublic => boolean().withDefault(const Constant(true))();

  /// Rally channel participant count
  IntColumn get participantCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Messages table
@DataClassName('MessageEntity')
class Messages extends Table {
  /// Unique message ID (SHA256 hash of content + timestamp + sender)
  TextColumn get id => text()();

  /// Conversation this message belongs to
  TextColumn get conversationId => text().references(Conversations, #id)();

  /// Sender ID (contact ID)
  TextColumn get senderId => text()();

  /// Message content (encrypted for storage)
  TextColumn get content => text()();

  /// Message type (text, image, voice, file)
  TextColumn get type => text().withDefault(const Constant('text'))();

  /// Message status (pending, sent, delivered, read, failed)
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Transport used (cloud, mesh, bridge)
  TextColumn get transport => text().nullable()();

  /// When the message was created
  DateTimeColumn get timestamp => dateTime()();

  /// When the message was delivered
  DateTimeColumn get deliveredAt => dateTime().nullable()();

  /// When the message was read
  DateTimeColumn get readAt => dateTime().nullable()();

  /// Is this message from me
  BoolColumn get isFromMe => boolean()();

  /// Reply to message ID (for threading)
  TextColumn get replyToId => text().nullable()();

  /// Metadata JSON (for media, reactions, etc.)
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Group members table (for Phase 5)
@DataClassName('GroupMemberEntity')
class GroupMembers extends Table {
  /// Auto-incrementing ID
  IntColumn get id => integer().autoIncrement()();

  /// Conversation (group) ID
  TextColumn get conversationId => text().references(Conversations, #id)();

  /// Contact ID
  TextColumn get contactId => text().references(Contacts, #id)();

  /// Member role (owner, admin, member)
  TextColumn get role => text().withDefault(const Constant('member'))();

  /// When the member joined
  DateTimeColumn get joinedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {conversationId, contactId},
      ];
}

/// Mesh peers table - Track nearby BLE devices
@DataClassName('MeshPeerEntity')
class MeshPeers extends Table {
  /// Mesh peer ID (8 bytes from SHA256 of Ed25519 public key, hex encoded)
  TextColumn get meshPeerId => text()();

  /// Ed25519 public key (hex encoded, for verification)
  TextColumn get publicKey => text()();

  /// X25519 public key for key exchange (hex encoded)
  TextColumn get exchangePublicKey => text()();

  /// Display name (optional, from peer announcement)
  TextColumn get displayName => text().nullable()();

  /// RSSI (signal strength in dBm, updated on each scan)
  IntColumn get rssi => integer()();

  /// Connection state (discovered, connecting, connected, disconnected)
  TextColumn get connectionState =>
      text().withDefault(const Constant('discovered'))();

  /// Last time we saw this peer in BLE scan
  DateTimeColumn get lastSeen => dateTime()();

  /// First discovered timestamp
  DateTimeColumn get firstSeen => dateTime()();

  /// Noise session state (null, handshake_init, handshake_resp, established)
  TextColumn get noiseSessionState => text().nullable()();

  /// Noise transport state (encrypted session keys, serialized as JSON)
  TextColumn get noiseTransportState => text().nullable()();

  /// Is this peer a contact we know?
  BoolColumn get isContact => boolean().withDefault(const Constant(false))();

  /// Contact ID if this peer is a known contact
  TextColumn get contactId => text().nullable().references(Contacts, #id)();

  @override
  Set<Column> get primaryKey => {meshPeerId};
}

/// Mesh routes table - Routing information for multi-hop paths
@DataClassName('MeshRouteEntity')
class MeshRoutes extends Table {
  /// Auto-incrementing ID
  IntColumn get id => integer().autoIncrement()();

  /// Destination mesh peer ID
  TextColumn get destinationPeerId => text()();

  /// Next hop peer ID (immediate neighbor to forward to)
  TextColumn get nextHopPeerId => text()();

  /// Hop count to destination (TTL calculation)
  IntColumn get hopCount => integer()();

  /// Route quality score (based on RSSI, success rate)
  RealColumn get qualityScore => real().withDefault(const Constant(1.0))();

  /// Last time this route was used successfully
  DateTimeColumn get lastUsed => dateTime()();

  /// When this route was discovered
  DateTimeColumn get discoveredAt => dateTime()();

  /// Route expires if not refreshed
  DateTimeColumn get expiresAt => dateTime()();
}

/// Mesh message queue - Store-and-forward queue for offline peers
@DataClassName('MeshMessageQueueEntity')
class MeshMessageQueue extends Table {
  /// Message ID (same as Messages table)
  TextColumn get messageId => text()();

  /// Recipient mesh peer ID
  TextColumn get recipientPeerId => text()();

  /// Encrypted packet payload (hex encoded binary)
  TextColumn get encryptedPacket => text()();

  /// When the message was queued
  DateTimeColumn get queuedAt => dateTime()();

  /// Retry count
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Last retry attempt
  DateTimeColumn get lastRetryAt => dateTime().nullable()();

  /// Expires after (store-and-forward TTL, max 24 hours)
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {messageId};
}

/// Mesh seen messages - Deduplication via message ID tracking
@DataClassName('MeshSeenMessageEntity')
class MeshSeenMessages extends Table {
  /// Message ID from packet header
  TextColumn get messageId => text()();

  /// When we first saw this message
  DateTimeColumn get seenAt => dateTime()();

  /// Auto-cleanup after 1 hour (messages older than this can be forgotten)
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {messageId};
}

/// Rally channel members - Track who has joined which Rally channels
@DataClassName('RallyChannelMemberEntity')
class RallyChannelMembers extends Table {
  /// Auto-incrementing ID
  IntColumn get id => integer().autoIncrement()();

  /// Rally channel ID
  TextColumn get channelId => text().references(Conversations, #id)();

  /// User ID (mesh peer ID or anonymous ID)
  TextColumn get userId => text()();

  /// Display name (anonymous/pseudonymous/real)
  TextColumn get displayName => text()();

  /// Identity type (anonymous, pseudonymous, verified)
  TextColumn get identityType => text()();

  /// When the user joined the channel
  DateTimeColumn get joinedAt => dateTime()();

  /// Last time the user was active in the channel
  DateTimeColumn get lastSeenAt => dateTime()();

  /// Number of messages posted by this user
  IntColumn get messageCount => integer().withDefault(const Constant(0))();

  /// Local reputation score (0-100)
  IntColumn get reputationScore => integer().withDefault(const Constant(50))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {channelId, userId},
      ];
}

/// Rally reports - Track moderation reports (local only)
@DataClassName('RallyReportEntity')
class RallyReports extends Table {
  /// Auto-incrementing ID
  IntColumn get id => integer().autoIncrement()();

  /// Who reported
  TextColumn get reporterId => text()();

  /// Who was reported
  TextColumn get reportedUserId => text()();

  /// Optional message ID
  TextColumn get messageId => text().nullable()();

  /// Report category (spam, harassment, threats, csam)
  TextColumn get category => text()();

  /// Additional notes
  TextColumn get notes => text().nullable()();

  /// When the report was made
  DateTimeColumn get reportedAt => dateTime()();

  /// Whether report was uploaded to authorities (for credible threats)
  BoolColumn get isUploaded => boolean().withDefault(const Constant(false))();
}

/// Bridge message queue - Messages waiting to be relayed (Phase 5)
@DataClassName('BridgeMessageQueueEntity')
class BridgeMessageQueue extends Table {
  /// Message ID
  TextColumn get messageId => text()();

  /// SHA256 hash of recipient's X25519 public key (base64)
  TextColumn get recipientKeyHash => text()();

  /// Noise-encrypted packet payload (base64)
  TextColumn get encryptedPayload => text()();

  /// Time-to-live in hours
  IntColumn get ttlHours => integer().withDefault(const Constant(4))();

  /// Message priority (normal, urgent, emergency)
  TextColumn get priority => text().withDefault(const Constant('normal'))();

  /// When the message was queued locally
  DateTimeColumn get queuedAt => dateTime()();

  /// When the message expires
  DateTimeColumn get expiresAt => dateTime()();

  /// Retry count
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Last retry attempt
  DateTimeColumn get lastRetryAt => dateTime().nullable()();

  /// Upload status (pending, uploaded, failed)
  TextColumn get uploadStatus => text().withDefault(const Constant('pending'))();

  /// Server-assigned ID after upload
  TextColumn get serverId => text().nullable()();

  @override
  Set<Column> get primaryKey => {messageId};
}

/// Bridge settings - User preferences for bridge mode (Phase 5)
@DataClassName('BridgeSettingsEntity')
class BridgeSettings extends Table {
  /// Settings ID (always 'default' for single row)
  TextColumn get id => text().withDefault(const Constant('default'))();

  /// Whether bridge mode is enabled
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();

  /// Only relay for known contacts
  BoolColumn get relayForContactsOnly =>
      boolean().withDefault(const Constant(false))();

  /// Maximum bandwidth to use per day (MB)
  IntColumn get maxBandwidthMbPerDay =>
      integer().withDefault(const Constant(50))();

  /// Minimum battery percent to enable relaying
  IntColumn get minBatteryPercent =>
      integer().withDefault(const Constant(30))();

  /// Bandwidth used today (MB)
  RealColumn get bandwidthUsedTodayMb =>
      real().withDefault(const Constant(0.0))();

  /// Date when bandwidth counter was last reset
  DateTimeColumn get bandwidthResetDate => dateTime().nullable()();

  /// When settings were last updated
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift database for MeshLink
@DriftDatabase(tables: [
  Contacts,
  Conversations,
  Messages,
  GroupMembers,
  MeshPeers,
  MeshRoutes,
  MeshMessageQueue,
  MeshSeenMessages,
  RallyChannelMembers,
  RallyReports,
  BridgeMessageQueue,
  BridgeSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Create database with file path
  factory AppDatabase.forPath(String path) {
    return AppDatabase(NativeDatabase(File(path)));
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration from v1 to v2: Add mesh networking tables and fields
        if (from < 2) {
          // Create new mesh tables
          await m.createTable(meshPeers);
          await m.createTable(meshRoutes);
          await m.createTable(meshMessageQueue);
          await m.createTable(meshSeenMessages);

          // Add new columns to Contacts table
          await m.addColumn(contacts, contacts.lastMeshRssi);
          await m.addColumn(contacts, contacts.lastMeshSeen);
          await m.addColumn(contacts, contacts.lastMeshHopCount);
          await m.addColumn(contacts, contacts.preferredTransport);
        }

        // Migration from v2 to v3: Add Rally Mode support
        if (from < 3) {
          // Add Rally-specific columns to Conversations table
          await m.addColumn(conversations, conversations.centroidLatitude);
          await m.addColumn(conversations, conversations.centroidLongitude);
          await m.addColumn(conversations, conversations.channelRadiusMeters);
          await m.addColumn(conversations, conversations.geohash);
          await m.addColumn(conversations, conversations.creatorId);
          await m.addColumn(conversations, conversations.maxMessageAgeHours);
          await m.addColumn(conversations, conversations.isPublic);
          await m.addColumn(conversations, conversations.participantCount);

          // Create new Rally tables
          await m.createTable(rallyChannelMembers);
          await m.createTable(rallyReports);
        }

        // Migration from v3 to v4: Add Bridge Relay support (Phase 5)
        if (from < 4) {
          // Create new Bridge tables
          await m.createTable(bridgeMessageQueue);
          await m.createTable(bridgeSettings);
        }
      },
    );
  }

  // ============================================================================
  // Contacts Queries
  // ============================================================================

  /// Get all contacts
  Future<List<ContactEntity>> getAllContacts() {
    return select(contacts).get();
  }

  /// Get contact by ID
  Future<ContactEntity?> getContactById(String id) {
    return (select(contacts)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Insert or update contact
  Future<void> upsertContact(ContactsCompanion contact) {
    return into(contacts).insertOnConflictUpdate(contact);
  }

  /// Delete contact
  Future<void> deleteContact(String id) {
    return (delete(contacts)..where((c) => c.id.equals(id))).go();
  }

  /// Get blocked contacts
  Future<List<ContactEntity>> getBlockedContacts() {
    return (select(contacts)..where((c) => c.isBlocked.equals(true))).get();
  }

  // ============================================================================
  // Conversations Queries
  // ============================================================================

  /// Get all conversations ordered by last message
  Future<List<ConversationEntity>> getAllConversations() {
    return (select(conversations)
          ..where((c) => c.isArchived.equals(false))
          ..orderBy([
            (c) => OrderingTerm(
                  expression: c.lastMessageAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// Get conversation by ID
  Future<ConversationEntity?> getConversationById(String id) {
    return (select(conversations)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or update conversation
  Future<void> upsertConversation(ConversationsCompanion conversation) {
    return into(conversations).insertOnConflictUpdate(conversation);
  }

  /// Delete conversation
  Future<void> deleteConversation(String id) {
    return (delete(conversations)..where((c) => c.id.equals(id))).go();
  }

  /// Get unread count
  Future<int> getTotalUnreadCount() async {
    final query = selectOnly(conversations)
      ..addColumns([conversations.unreadCount.sum()]);
    final result = await query.getSingle();
    return result.read(conversations.unreadCount.sum()) ?? 0;
  }

  // ============================================================================
  // Messages Queries
  // ============================================================================

  /// Get messages for a conversation
  Future<List<MessageEntity>> getMessagesForConversation(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([
            (m) => OrderingTerm(expression: m.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Get message by ID
  Future<MessageEntity?> getMessageById(String id) {
    return (select(messages)..where((m) => m.id.equals(id))).getSingleOrNull();
  }

  /// Insert message
  Future<void> insertMessage(MessagesCompanion message) {
    return into(messages).insert(message);
  }

  /// Update message status
  Future<void> updateMessageStatus(String id, String status) {
    return (update(messages)..where((m) => m.id.equals(id)))
        .write(MessagesCompanion(status: Value(status)));
  }

  /// Update message delivery time
  Future<void> updateMessageDelivered(String id, DateTime deliveredAt) {
    return (update(messages)..where((m) => m.id.equals(id))).write(
      MessagesCompanion(
        status: const Value('delivered'),
        deliveredAt: Value(deliveredAt),
      ),
    );
  }

  /// Update message read time
  Future<void> updateMessageRead(String id, DateTime readAt) {
    return (update(messages)..where((m) => m.id.equals(id))).write(
      MessagesCompanion(
        status: const Value('read'),
        readAt: Value(readAt),
      ),
    );
  }

  /// Delete message
  Future<void> deleteMessage(String id) {
    return (delete(messages)..where((m) => m.id.equals(id))).go();
  }

  /// Get pending messages (for retry)
  Future<List<MessageEntity>> getPendingMessages() {
    return (select(messages)..where((m) => m.status.equals('pending'))).get();
  }

  /// Search messages by content
  Future<List<MessageEntity>> searchMessages(String query) {
    return (select(messages)..where((m) => m.content.contains(query))).get();
  }

  // ============================================================================
  // Group Members Queries (Phase 5)
  // ============================================================================

  /// Get members of a group
  Future<List<GroupMemberEntity>> getGroupMembers(String conversationId) {
    return (select(groupMembers)
          ..where((m) => m.conversationId.equals(conversationId)))
        .get();
  }

  /// Add member to group
  Future<void> addGroupMember(GroupMembersCompanion member) {
    return into(groupMembers).insert(member);
  }

  /// Remove member from group
  Future<void> removeGroupMember(String conversationId, String contactId) {
    return (delete(groupMembers)
          ..where((m) =>
              m.conversationId.equals(conversationId) &
              m.contactId.equals(contactId)))
        .go();
  }

  // ============================================================================
  // Mesh Peers Queries
  // ============================================================================

  /// Get all mesh peers
  Future<List<MeshPeerEntity>> getAllMeshPeers() {
    return select(meshPeers).get();
  }

  /// Get connected mesh peers
  Future<List<MeshPeerEntity>> getConnectedMeshPeers() {
    return (select(meshPeers)
          ..where((p) => p.connectionState.equals('connected')))
        .get();
  }

  /// Get mesh peer by ID
  Future<MeshPeerEntity?> getMeshPeerById(String meshPeerId) {
    return (select(meshPeers)..where((p) => p.meshPeerId.equals(meshPeerId)))
        .getSingleOrNull();
  }

  /// Insert or update mesh peer
  Future<void> upsertMeshPeer(MeshPeersCompanion peer) {
    return into(meshPeers).insertOnConflictUpdate(peer);
  }

  /// Insert a new mesh peer
  Future<void> insertMeshPeer({
    required String meshPeerId,
    required String publicKey,
    required String exchangePublicKey,
    String? displayName,
    required int rssi,
    required String connectionState,
    required DateTime lastSeen,
    required DateTime firstSeen,
    String? noiseSessionState,
    String? noiseTransportState,
    bool isContact = false,
    String? contactId,
  }) {
    return into(meshPeers).insert(MeshPeersCompanion.insert(
      meshPeerId: meshPeerId,
      publicKey: publicKey,
      exchangePublicKey: exchangePublicKey,
      displayName: Value(displayName),
      rssi: rssi,
      connectionState: Value(connectionState),
      lastSeen: lastSeen,
      firstSeen: firstSeen,
      noiseSessionState: Value(noiseSessionState),
      noiseTransportState: Value(noiseTransportState),
      isContact: Value(isContact),
      contactId: Value(contactId),
    ));
  }

  /// Update mesh peer connection state
  Future<void> updateMeshPeerConnectionState(
    String meshPeerId,
    String connectionState,
  ) {
    return (update(meshPeers)..where((p) => p.meshPeerId.equals(meshPeerId)))
        .write(MeshPeersCompanion(connectionState: Value(connectionState)));
  }

  /// Update mesh peer Noise session state
  Future<void> updateMeshPeerNoiseState(
    String meshPeerId,
    String noiseSessionState, {
    String? noiseTransportState,
  }) {
    return (update(meshPeers)..where((p) => p.meshPeerId.equals(meshPeerId)))
        .write(
      MeshPeersCompanion(
        noiseSessionState: Value(noiseSessionState),
        noiseTransportState: Value(noiseTransportState),
      ),
    );
  }

  /// Delete mesh peer
  Future<void> deleteMeshPeer(String meshPeerId) {
    return (delete(meshPeers)..where((p) => p.meshPeerId.equals(meshPeerId)))
        .go();
  }

  /// Delete stale mesh peers (not seen in last N minutes)
  Future<void> deleteStaleMeshPeers(Duration staleAfter) {
    final cutoff = DateTime.now().subtract(staleAfter);
    return (delete(meshPeers)..where((p) => p.lastSeen.isSmallerThanValue(cutoff)))
        .go();
  }

  // ============================================================================
  // Mesh Routes Queries
  // ============================================================================

  /// Get routes to a specific peer
  Future<List<MeshRouteEntity>> getRoutesToPeer(String destinationPeerId) {
    return (select(meshRoutes)
          ..where((r) => r.destinationPeerId.equals(destinationPeerId))
          ..orderBy([
            (r) => OrderingTerm(expression: r.hopCount, mode: OrderingMode.asc),
            (r) => OrderingTerm(
                  expression: r.qualityScore,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// Insert or update route
  Future<void> upsertRoute(MeshRoutesCompanion route) {
    return into(meshRoutes).insert(
      route,
      onConflict: DoUpdate(
        (old) => MeshRoutesCompanion(
          hopCount: route.hopCount,
          qualityScore: route.qualityScore,
          lastUsed: route.lastUsed,
          expiresAt: route.expiresAt,
        ),
      ),
    );
  }

  /// Get routes to a specific destination (alias for getRoutesToPeer)
  Future<List<MeshRouteEntity>> getRoutesToDestination(
      String destinationPeerId) {
    return getRoutesToPeer(destinationPeerId);
  }

  /// Insert a new route
  Future<void> insertMeshRoute({
    required String destinationPeerId,
    required String nextHopPeerId,
    required int hopCount,
    required double qualityScore,
    required DateTime lastUsed,
    required DateTime discoveredAt,
    required DateTime expiresAt,
  }) {
    return into(meshRoutes).insert(MeshRoutesCompanion.insert(
      destinationPeerId: destinationPeerId,
      nextHopPeerId: nextHopPeerId,
      hopCount: hopCount,
      qualityScore: Value(qualityScore),
      lastUsed: lastUsed,
      discoveredAt: discoveredAt,
      expiresAt: expiresAt,
    ));
  }

  /// Update an existing route
  Future<void> updateMeshRoute({
    required int id,
    int? hopCount,
    double? qualityScore,
    DateTime? lastUsed,
    DateTime? expiresAt,
  }) {
    return (update(meshRoutes)..where((r) => r.id.equals(id))).write(
      MeshRoutesCompanion(
        hopCount: hopCount != null ? Value(hopCount) : const Value.absent(),
        qualityScore:
            qualityScore != null ? Value(qualityScore) : const Value.absent(),
        lastUsed: lastUsed != null ? Value(lastUsed) : const Value.absent(),
        expiresAt: expiresAt != null ? Value(expiresAt) : const Value.absent(),
      ),
    );
  }

  /// Delete a specific route
  Future<void> deleteMeshRoute(int id) {
    return (delete(meshRoutes)..where((r) => r.id.equals(id))).go();
  }

  /// Get all routes
  Future<List<MeshRouteEntity>> getAllMeshRoutes() {
    return select(meshRoutes).get();
  }

  /// Delete all routes
  Future<void> deleteAllMeshRoutes() {
    return delete(meshRoutes).go();
  }

  /// Delete expired routes
  Future<void> deleteExpiredRoutes() {
    return (delete(meshRoutes)
          ..where((r) => r.expiresAt.isSmallerThanValue(DateTime.now())))
        .go();
  }

  /// Delete expired routes (alias)
  Future<void> deleteExpiredMeshRoutes() {
    return deleteExpiredRoutes();
  }

  // ============================================================================
  // Mesh Message Queue Queries
  // ============================================================================

  /// Get all queued messages
  Future<List<MeshMessageQueueEntity>> getQueuedMessages() {
    return (select(meshMessageQueue)
          ..where((q) => q.expiresAt.isBiggerThanValue(DateTime.now()))
          ..orderBy([
            (q) => OrderingTerm(expression: q.queuedAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Get queued messages for a specific peer
  Future<List<MeshMessageQueueEntity>> getQueuedMessagesForPeer(
    String recipientPeerId,
  ) {
    return (select(meshMessageQueue)
          ..where(
            (q) =>
                q.recipientPeerId.equals(recipientPeerId) &
                q.expiresAt.isBiggerThanValue(DateTime.now()),
          ))
        .get();
  }

  /// Insert message into queue
  Future<void> insertMeshMessageQueue(MeshMessageQueueCompanion message) {
    return into(meshMessageQueue).insert(message);
  }

  /// Update retry count
  Future<void> updateMeshMessageRetry(String messageId) {
    return (update(meshMessageQueue)
          ..where((q) => q.messageId.equals(messageId)))
        .write(
      MeshMessageQueueCompanion(
        retryCount: Value(1), // Increment logic handled in Dart
        lastRetryAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete message from queue
  Future<void> deleteMeshQueuedMessage(String messageId) {
    return (delete(meshMessageQueue)
          ..where((q) => q.messageId.equals(messageId)))
        .go();
  }

  /// Delete expired queued messages
  Future<void> deleteExpiredQueuedMessages() {
    return (delete(meshMessageQueue)
          ..where((q) => q.expiresAt.isSmallerThanValue(DateTime.now())))
        .go();
  }

  // ============================================================================
  // Mesh Seen Messages Queries
  // ============================================================================

  /// Check if message has been seen
  Future<MeshSeenMessageEntity?> getMeshSeenMessage(String messageId) {
    return (select(meshSeenMessages)
          ..where((m) => m.messageId.equals(messageId)))
        .getSingleOrNull();
  }

  /// Mark message as seen
  Future<void> insertMeshSeenMessage({
    required String messageId,
    required DateTime seenAt,
    required DateTime expiresAt,
  }) {
    return into(meshSeenMessages).insert(
      MeshSeenMessagesCompanion(
        messageId: Value(messageId),
        seenAt: Value(seenAt),
        expiresAt: Value(expiresAt),
      ),
    );
  }

  /// Delete expired seen messages (cleanup)
  Future<void> deleteExpiredMeshSeenMessages() {
    return (delete(meshSeenMessages)
          ..where((m) => m.expiresAt.isSmallerThanValue(DateTime.now())))
        .go();
  }

  // ============================================================================
  // Rally Channel Queries (Phase 3)
  // ============================================================================

  /// Get Rally channels near a location using geohash
  Future<List<ConversationEntity>> getRallyChannelsNearLocation({
    required String geohash,
    required List<String> neighborGeohashes,
  }) async {
    final allGeohashes = [geohash, ...neighborGeohashes];
    return (select(conversations)
          ..where((c) => c.type.equals('rally'))
          ..where((c) => c.geohash.isIn(allGeohashes))
          ..orderBy([(c) => OrderingTerm.desc(c.participantCount)]))
        .get();
  }

  /// Get Rally channel by geohash
  Future<ConversationEntity?> getRallyChannelByGeohash(String geohash) async {
    return (select(conversations)
          ..where((c) => c.type.equals('rally'))
          ..where((c) => c.geohash.equals(geohash)))
        .getSingleOrNull();
  }

  /// Join Rally channel
  Future<void> joinRallyChannel({
    required String channelId,
    required String userId,
    required String displayName,
    required String identityType,
  }) async {
    // Insert or update member
    await into(rallyChannelMembers).insertOnConflictUpdate(
      RallyChannelMembersCompanion(
        channelId: Value(channelId),
        userId: Value(userId),
        displayName: Value(displayName),
        identityType: Value(identityType),
        joinedAt: Value(DateTime.now()),
        lastSeenAt: Value(DateTime.now()),
      ),
    );

    // Increment participant count
    final current = await getConversationById(channelId);
    if (current != null) {
      await (update(conversations)..where((c) => c.id.equals(channelId))).write(
        ConversationsCompanion(
          participantCount: Value(current.participantCount + 1),
        ),
      );
    }
  }

  /// Leave Rally channel
  Future<void> leaveRallyChannel({
    required String channelId,
    required String userId,
  }) async {
    // Delete member record
    await (delete(rallyChannelMembers)
          ..where((m) => m.channelId.equals(channelId) & m.userId.equals(userId)))
        .go();

    // Decrement participant count
    final current = await getConversationById(channelId);
    if (current != null && current.participantCount > 0) {
      await (update(conversations)..where((c) => c.id.equals(channelId))).write(
        ConversationsCompanion(
          participantCount: Value(current.participantCount - 1),
        ),
      );
    }
  }

  /// Get members of a Rally channel
  Future<List<RallyChannelMemberEntity>> getRallyChannelMembers(
    String channelId,
  ) {
    return (select(rallyChannelMembers)
          ..where((m) => m.channelId.equals(channelId))
          ..orderBy([(m) => OrderingTerm.desc(m.messageCount)]))
        .get();
  }

  /// Update Rally member's last seen timestamp
  Future<void> updateRallyMemberLastSeen({
    required String channelId,
    required String userId,
  }) async {
    await (update(rallyChannelMembers)
          ..where((m) => m.channelId.equals(channelId) & m.userId.equals(userId)))
        .write(
      RallyChannelMembersCompanion(
        lastSeenAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete expired Rally messages
  Future<int> deleteExpiredRallyMessages() async {
    final now = DateTime.now();

    // Get all Rally channels with their TTL
    final rallyChannels = await (select(conversations)
          ..where((c) => c.type.equals('rally')))
        .get();

    int deletedCount = 0;
    for (final channel in rallyChannels) {
      final maxAge = channel.maxMessageAgeHours ?? 4; // Default 4 hours
      final cutoff = now.subtract(Duration(hours: maxAge));

      deletedCount += await (delete(messages)
            ..where((m) => m.conversationId.equals(channel.id))
            ..where((m) => m.timestamp.isSmallerThanValue(cutoff)))
          .go();
    }

    return deletedCount;
  }

  /// Insert Rally report
  Future<void> insertRallyReport({
    required String reporterId,
    required String reportedUserId,
    String? messageId,
    required String category,
    String? notes,
  }) async {
    await into(rallyReports).insert(
      RallyReportsCompanion(
        reporterId: Value(reporterId),
        reportedUserId: Value(reportedUserId),
        messageId: Value(messageId),
        category: Value(category),
        notes: Value(notes),
        reportedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get Rally reports for a user
  Future<List<RallyReportEntity>> getRallyReportsForUser(
    String reportedUserId,
  ) {
    return (select(rallyReports)
          ..where((r) => r.reportedUserId.equals(reportedUserId))
          ..orderBy([(r) => OrderingTerm.desc(r.reportedAt)]))
        .get();
  }

  /// Update conversation last message timestamp
  Future<void> updateLastMessage({
    required String conversationId,
    required DateTime timestamp,
  }) async {
    await (update(conversations)..where((c) => c.id.equals(conversationId)))
        .write(
      ConversationsCompanion(
        lastMessageAt: Value(timestamp),
      ),
    );
  }

  // ============================================================================
  // Bridge Message Queue Queries (Phase 5)
  // ============================================================================

  /// Get all pending bridge messages
  Future<List<BridgeMessageQueueEntity>> getPendingBridgeMessages() {
    return (select(bridgeMessageQueue)
          ..where((m) => m.uploadStatus.equals('pending'))
          ..where((m) => m.expiresAt.isBiggerThanValue(DateTime.now()))
          ..orderBy([(m) => OrderingTerm.asc(m.queuedAt)]))
        .get();
  }

  /// Get bridge messages for a recipient
  Future<List<BridgeMessageQueueEntity>> getBridgeMessagesForRecipient(
    String recipientKeyHash,
  ) {
    return (select(bridgeMessageQueue)
          ..where((m) => m.recipientKeyHash.equals(recipientKeyHash))
          ..where((m) => m.expiresAt.isBiggerThanValue(DateTime.now())))
        .get();
  }

  /// Insert a bridge message
  Future<void> insertBridgeMessage({
    required String messageId,
    required String recipientKeyHash,
    required String encryptedPayload,
    int ttlHours = 4,
    String priority = 'normal',
  }) async {
    final now = DateTime.now();
    await into(bridgeMessageQueue).insert(
      BridgeMessageQueueCompanion.insert(
        messageId: messageId,
        recipientKeyHash: recipientKeyHash,
        encryptedPayload: encryptedPayload,
        ttlHours: Value(ttlHours),
        priority: Value(priority),
        queuedAt: now,
        expiresAt: now.add(Duration(hours: ttlHours)),
      ),
    );
  }

  /// Update bridge message upload status
  Future<void> updateBridgeMessageStatus({
    required String messageId,
    required String uploadStatus,
    String? serverId,
  }) {
    return (update(bridgeMessageQueue)
          ..where((m) => m.messageId.equals(messageId)))
        .write(
      BridgeMessageQueueCompanion(
        uploadStatus: Value(uploadStatus),
        serverId: Value(serverId),
        lastRetryAt: Value(DateTime.now()),
      ),
    );
  }

  /// Increment retry count for bridge message
  Future<void> incrementBridgeMessageRetry(String messageId) async {
    final msg = await (select(bridgeMessageQueue)
          ..where((m) => m.messageId.equals(messageId)))
        .getSingleOrNull();

    if (msg != null) {
      await (update(bridgeMessageQueue)
            ..where((m) => m.messageId.equals(messageId)))
          .write(
        BridgeMessageQueueCompanion(
          retryCount: Value(msg.retryCount + 1),
          lastRetryAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Delete bridge message
  Future<void> deleteBridgeMessage(String messageId) {
    return (delete(bridgeMessageQueue)
          ..where((m) => m.messageId.equals(messageId)))
        .go();
  }

  /// Delete expired bridge messages
  Future<void> deleteExpiredBridgeMessages() {
    return (delete(bridgeMessageQueue)
          ..where((m) => m.expiresAt.isSmallerThanValue(DateTime.now())))
        .go();
  }

  // ============================================================================
  // Bridge Settings Queries (Phase 5)
  // ============================================================================

  /// Get bridge settings
  Future<BridgeSettingsEntity?> getBridgeSettings() {
    return (select(bridgeSettings)..where((s) => s.id.equals('default')))
        .getSingleOrNull();
  }

  /// Save or update bridge settings
  Future<void> saveBridgeSettings({
    bool? isEnabled,
    bool? relayForContactsOnly,
    int? maxBandwidthMbPerDay,
    int? minBatteryPercent,
  }) async {
    await into(bridgeSettings).insertOnConflictUpdate(
      BridgeSettingsCompanion(
        id: const Value('default'),
        isEnabled: isEnabled != null ? Value(isEnabled) : const Value.absent(),
        relayForContactsOnly: relayForContactsOnly != null
            ? Value(relayForContactsOnly)
            : const Value.absent(),
        maxBandwidthMbPerDay: maxBandwidthMbPerDay != null
            ? Value(maxBandwidthMbPerDay)
            : const Value.absent(),
        minBatteryPercent: minBatteryPercent != null
            ? Value(minBatteryPercent)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update bandwidth usage
  Future<void> updateBridgeBandwidthUsage(double mbUsed) async {
    final settings = await getBridgeSettings();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    double newUsage = mbUsed;

    // Reset counter if new day
    if (settings != null && settings.bandwidthResetDate != null) {
      final resetDate = DateTime(
        settings.bandwidthResetDate!.year,
        settings.bandwidthResetDate!.month,
        settings.bandwidthResetDate!.day,
      );
      if (resetDate.isBefore(today)) {
        // New day, reset counter
        newUsage = mbUsed;
      } else {
        // Same day, add to existing
        newUsage = settings.bandwidthUsedTodayMb + mbUsed;
      }
    }

    await into(bridgeSettings).insertOnConflictUpdate(
      BridgeSettingsCompanion(
        id: const Value('default'),
        bandwidthUsedTodayMb: Value(newUsage),
        bandwidthResetDate: Value(today),
        updatedAt: Value(now),
      ),
    );
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  /// Delete all data (for testing or reset)
  Future<void> deleteAllData() async {
    await delete(bridgeMessageQueue).go();
    await delete(bridgeSettings).go();
    await delete(rallyReports).go();
    await delete(rallyChannelMembers).go();
    await delete(meshSeenMessages).go();
    await delete(meshMessageQueue).go();
    await delete(meshRoutes).go();
    await delete(meshPeers).go();
    await delete(messages).go();
    await delete(groupMembers).go();
    await delete(conversations).go();
    await delete(contacts).go();
  }
}
