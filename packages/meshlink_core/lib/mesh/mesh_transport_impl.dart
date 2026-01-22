import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../database/app_database.dart';
import '../models/identity.dart';
import 'ble_service.dart';
import 'routing_engine.dart';
import 'noise_handshake.dart';
import 'packet_codec.dart';
import 'peer_announcement.dart';
import 'ble_constants.dart';

/// Concrete implementation of mesh transport
/// Integrates BLE, Noise encryption, routing, and store-and-forward
class MeshTransportImpl {
  final BleService _bleService;
  final RoutingEngine _routingEngine;
  final AppDatabase _db;
  final Identity _localIdentity;

  // Noise sessions for connected peers
  final Map<String, NoiseSession> _noiseSessions = {};

  // Message delivery callbacks
  final StreamController<MeshMessage> _messageController =
      StreamController.broadcast();
  final StreamController<MessageDeliveryStatus> _statusController =
      StreamController.broadcast();
  final StreamController<MeshRelayRequest> _relayRequestController =
      StreamController.broadcast();
  final StreamController<RallyChannelAnnouncement> _rallyChannelController =
      StreamController.broadcast();

  // Subscriptions
  StreamSubscription<MeshPacketReceived>? _packetSubscription;
  StreamSubscription<MeshPeerDiscovery>? _discoverySubscription;
  StreamSubscription<PacketForward>? _forwardSubscription;

  bool _isRunning = false;
  Timer? _announceTimer;
  Timer? _queueProcessTimer;

  MeshTransportImpl({
    required BleService bleService,
    required RoutingEngine routingEngine,
    required AppDatabase database,
    required Identity localIdentity,
  })  : _bleService = bleService,
        _routingEngine = routingEngine,
        _db = database,
        _localIdentity = localIdentity;

  /// Stream of incoming messages
  Stream<MeshMessage> get incomingMessages => _messageController.stream;

  /// Stream of message delivery status updates
  Stream<MessageDeliveryStatus> get deliveryStatus => _statusController.stream;

  /// Stream of relay requests (for bridge mode service)
  /// When a peer sends a relay request, it's emitted here for forwarding to the relay server
  Stream<MeshRelayRequest> get relayRequests => _relayRequestController.stream;

  /// Stream of Rally channel announcements from mesh peers
  /// Subscribe to discover Rally channels created by nearby devices
  Stream<RallyChannelAnnouncement> get rallyChannelAnnouncements =>
      _rallyChannelController.stream;

  /// Check if transport is available
  Future<bool> isAvailable() async {
    return _bleService.isInitialized;
  }

  /// Start mesh transport
  Future<void> start() async {
    if (_isRunning) return;

    // Initialize BLE
    await _bleService.initialize();

    // Start advertising our presence
    await _bleService.startAdvertising(_localIdentity);

    // Start scanning for peers
    _discoverySubscription = _bleService.startScanning().listen(_handlePeerDiscovery);

    // Listen to incoming packets
    _packetSubscription = _bleService.receivePackets().listen(_handleIncomingPacket);

    // Listen to forwarding requests
    _forwardSubscription = _routingEngine.packetsToForward.listen(_handlePacketForward);

    // Periodic peer announcement
    _announceTimer = Timer.periodic(
      BleConstants.peerAnnouncementInterval,
      (_) => _broadcastPeerAnnouncement(),
    );

    // Process message queue periodically
    _queueProcessTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _processMessageQueue(),
    );

    _isRunning = true;
  }

  /// Stop mesh transport
  Future<void> stop() async {
    if (!_isRunning) return;

    await _packetSubscription?.cancel();
    await _discoverySubscription?.cancel();
    await _forwardSubscription?.cancel();
    _announceTimer?.cancel();
    _queueProcessTimer?.cancel();

    await _bleService.stopScanning();
    await _bleService.stopAdvertising();
    await _bleService.disconnect();

    _isRunning = false;
  }

  /// Send a text message
  Future<void> sendTextMessage({
    required String messageId,
    required String recipientPeerId,
    required String content,
  }) async {
    // Encode message
    final payload = utf8.encode(content);

    await _sendMessage(
      messageId: messageId,
      recipientPeerId: recipientPeerId,
      type: PacketType.text,
      payload: Uint8List.fromList(payload),
    );
  }

  /// Send a message packet
  Future<void> _sendMessage({
    required String messageId,
    required String recipientPeerId,
    required PacketType type,
    required Uint8List payload,
  }) async {
    // Get or establish Noise session
    final session = await _getOrCreateSession(recipientPeerId);

    if (session == null) {
      // No route and can't establish session - queue for later
      await _queueMessage(
        messageId: messageId,
        recipientPeerId: recipientPeerId,
        type: type,
        payload: payload,
      );
      return;
    }

    try {
      // Encrypt payload
      final encryptedPayload = await session.encrypt(payload);

      // Create packet
      final packet = MeshPacket(
        type: type,
        ttl: BleConstants.maxHops,
        flags: PacketFlags.hasRecipient | PacketFlags.requiresAck,
        timestamp: DateTime.now(),
        messageId: _hexToBytes(messageId),
        recipientId: _hexToBytes(recipientPeerId),
        payload: encryptedPayload,
      );

      // Find route
      final route = await _routingEngine.findRoute(recipientPeerId);

      if (route != null) {
        // Send via route
        await _sendPacketToPeer(packet, route.nextHopPeerId);

        _statusController.add(MessageDeliveryStatus(
          messageId: messageId,
          status: DeliveryStatus.sent,
          timestamp: DateTime.now(),
        ));
      } else {
        // No route - flood packet
        await _routingEngine.floodPacket(packet);

        _statusController.add(MessageDeliveryStatus(
          messageId: messageId,
          status: DeliveryStatus.sent,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      // Failed to send - queue for retry
      await _queueMessage(
        messageId: messageId,
        recipientPeerId: recipientPeerId,
        type: type,
        payload: payload,
      );

      _statusController.add(MessageDeliveryStatus(
        messageId: messageId,
        status: DeliveryStatus.failed,
        timestamp: DateTime.now(),
        error: e.toString(),
      ));
    }
  }

  /// Handle peer discovery
  void _handlePeerDiscovery(MeshPeerDiscovery discovery) async {
    // Update routing table
    await _routingEngine.updateRouteFromPeer(
      sourcePeerId: discovery.meshPeerId,
      nextHopPeerId: discovery.meshPeerId,
      hopCount: 1,
      rssi: discovery.rssi,
    );

    // Store/update peer in database
    await _db.upsertMeshPeer(MeshPeersCompanion.insert(
      meshPeerId: discovery.meshPeerId,
      publicKey: '', // Will be filled during handshake
      exchangePublicKey: '', // Will be filled during handshake
      rssi: discovery.rssi,
      lastSeen: discovery.timestamp,
      firstSeen: discovery.timestamp,
    ));

    // Connect if RSSI is good enough
    if (discovery.rssi >= BleConstants.minRssiForConnection) {
      await _connectToPeer(discovery);
    }
  }

  /// Connect to a peer and perform handshake
  Future<void> _connectToPeer(MeshPeerDiscovery discovery) async {
    try {
      // Connect via BLE
      await _bleService.connectToPeer(discovery.device);

      // Read peer announcement
      final announcementData = await _bleService.readPeerAnnouncement();
      if (announcementData == null) {
        throw Exception('No peer announcement');
      }

      final announcement = PeerAnnouncement.decode(announcementData);

      // Perform Noise handshake (we are initiator)
      final localEphemeral = await X25519().newKeyPair();

      // Create static key pair for handshake
      final localStaticPrivate = SecretKey(_localIdentity.exchangeKeyPair.privateKey);
      final localStaticSeed = await localStaticPrivate.extractBytes();
      final localStaticKeyPair = await X25519().newKeyPairFromSeed(localStaticSeed);

      final handshake = NoiseHandshake(
        role: NoiseRole.initiator,
        staticKeyPair: localStaticKeyPair,
        ephemeralKeyPair: localEphemeral,
      );

      // Message 1: → e
      final msg1 = await handshake.generateMessage1();
      await _bleService.sendHandshakeMessage(msg1);

      // Wait for message 2
      final msg2Response = await _bleService.receivePackets()
          .where((p) => p.source == PacketSource.handshake)
          .first
          .timeout(const Duration(seconds: 10));

      // Message 3: → s, se
      final msg3 = await handshake.processMessage2AndGenerateMessage3(msg2Response.data);
      await _bleService.sendHandshakeMessage(msg3);

      // Derive session
      final session = await handshake.deriveSession();
      _noiseSessions[discovery.meshPeerId] = session;

      // Store session state
      final sessionJson = await session.toJson();
      await _db.updateMeshPeerNoiseState(
        discovery.meshPeerId,
        'completed',
        noiseTransportState: jsonEncode(sessionJson),
      );

      // Update connection state
      await _db.updateMeshPeerConnectionState(
        discovery.meshPeerId,
        'connected',
      );
    } catch (e) {
      // Handshake failed
      await _db.updateMeshPeerConnectionState(
        discovery.meshPeerId,
        'failed',
      );
    }
  }

  /// Handle incoming packet
  void _handleIncomingPacket(MeshPacketReceived packetReceived) async {
    try {
      final packet = MeshPacket.decode(packetReceived.data);

      // Process through routing engine
      final shouldDeliver = await _routingEngine.processIncomingPacket(
        packet,
        'unknown', // TODO: Track which peer sent this
        _localIdentity.meshPeerIdHex,
      );

      if (shouldDeliver) {
        // Packet is for us - decrypt and deliver
        await _deliverPacket(packet);
      }
    } catch (e) {
      // Failed to process packet
    }
  }

  /// Deliver packet to local user
  Future<void> _deliverPacket(MeshPacket packet) async {
    final messageIdHex = _bytesToHex(packet.messageId);

    // Handle Rally broadcast packets
    if (packet.type == PacketType.rallyBroadcast) {
      await _handleRallyBroadcastPacket(packet);
      return;
    }

    // Handle relay request packets specially (for bridge mode)
    if (packet.type == PacketType.relayRequest) {
      await _handleRelayRequestPacket(packet, messageIdHex);
      return;
    }

    // Get sender's session
    // TODO: Need to track sender peer ID with packet
    // For now, try to decrypt with all sessions
    NoiseSession? senderSession;
    for (final session in _noiseSessions.values) {
      try {
        final decrypted = await session.decrypt(packet.payload);
        senderSession = session;

        // Deliver message
        _messageController.add(MeshMessage(
          messageId: messageIdHex,
          type: packet.type,
          content: utf8.decode(decrypted),
          timestamp: packet.timestamp,
          senderPeerId: '', // TODO: Track sender
        ));

        // Send ACK if requested
        if (PacketFlags.hasFlag(packet.flags, PacketFlags.requiresAck)) {
          await _sendAck(messageIdHex, ''); // TODO: sender peer ID
        }

        break;
      } catch (e) {
        continue;
      }
    }
  }

  /// Handle relay request packet (bridge mode)
  /// Relay requests contain an already-encrypted envelope destined for the relay server
  Future<void> _handleRelayRequestPacket(MeshPacket packet, String messageIdHex) async {
    try {
      // Relay request payload format (JSON):
      // {
      //   "recipient_key_hash": "<base64>",
      //   "encrypted_payload": "<base64>",
      //   "ttl_hours": 4,
      //   "priority": "normal"
      // }
      final payloadJson = utf8.decode(packet.payload);
      final payloadData = jsonDecode(payloadJson) as Map<String, dynamic>;

      final relayRequest = MeshRelayRequest(
        messageId: messageIdHex,
        recipientKeyHash: payloadData['recipient_key_hash'] as String,
        encryptedPayload: payloadData['encrypted_payload'] as String,
        ttlHours: payloadData['ttl_hours'] as int? ?? 4,
        priority: payloadData['priority'] as String? ?? 'normal',
        senderPeerId: '', // TODO: Track sender
        receivedAt: DateTime.now(),
      );

      // Emit relay request for bridge mode service to handle
      _relayRequestController.add(relayRequest);

      // Send ACK if requested
      if (PacketFlags.hasFlag(packet.flags, PacketFlags.requiresAck)) {
        await _sendAck(messageIdHex, '');
      }
    } catch (e) {
      // Invalid relay request format
    }
  }

  /// Send ACK packet
  Future<void> _sendAck(String messageId, String recipientPeerId) async {
    // Create ACK packet
    final ackPacket = MeshPacket(
      type: PacketType.ack,
      ttl: BleConstants.maxHops,
      flags: PacketFlags.hasRecipient,
      timestamp: DateTime.now(),
      messageId: _hexToBytes(messageId),
      recipientId: _hexToBytes(recipientPeerId),
      payload: Uint8List(0),
    );

    // Send back to sender
    final route = await _routingEngine.findRoute(recipientPeerId);
    if (route != null) {
      await _sendPacketToPeer(ackPacket, route.nextHopPeerId);
    }
  }

  /// Forward packet to next hop
  void _handlePacketForward(PacketForward forward) async {
    await _sendPacketToPeer(forward.packet, forward.toPeerId);
  }

  /// Send packet to specific peer
  Future<void> _sendPacketToPeer(MeshPacket packet, String peerId) async {
    try {
      final encoded = packet.encode();

      // TODO: Send to specific peer via BLE
      // For now, just send via current connection
      await _bleService.sendPacket(encoded);
    } catch (e) {
      // Failed to send
    }
  }

  /// Broadcast peer announcement
  Future<void> _broadcastPeerAnnouncement() async {
    final announcement = PeerAnnouncement.fromIdentity(_localIdentity);
    final announcementData = announcement.encode();

    final packet = MeshPacket(
      type: PacketType.peerAnnounce,
      ttl: 2, // Limited TTL for announcements
      flags: 0, // Broadcast
      timestamp: DateTime.now(),
      messageId: Uint8List.fromList(
        List.generate(16, (i) => DateTime.now().millisecondsSinceEpoch % 256),
      ),
      payload: announcementData,
    );

    await _routingEngine.floodPacket(packet);
  }

  /// Broadcast a Rally channel to nearby mesh peers
  /// This allows offline devices to discover Rally channels created by others
  Future<void> broadcastRallyChannel({
    required String channelId,
    required String name,
    required String geohash,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required int maxMessageAgeHours,
  }) async {
    // Create Rally channel announcement payload
    final announcementData = jsonEncode({
      'channel_id': channelId,
      'name': name,
      'geohash': geohash,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'max_message_age_hours': maxMessageAgeHours,
      'created_by': _localIdentity.meshPeerIdHex,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final packet = MeshPacket(
      type: PacketType.rallyBroadcast,
      ttl: 3, // Limited TTL for Rally broadcasts
      flags: 0, // Broadcast to all
      timestamp: DateTime.now(),
      messageId: Uint8List.fromList(
        List.generate(16, (i) => DateTime.now().microsecondsSinceEpoch % 256),
      ),
      payload: Uint8List.fromList(utf8.encode(announcementData)),
    );

    await _routingEngine.floodPacket(packet);
  }

  /// Handle incoming Rally broadcast packet
  Future<void> _handleRallyBroadcastPacket(MeshPacket packet) async {
    try {
      final payloadJson = utf8.decode(packet.payload);
      final data = jsonDecode(payloadJson) as Map<String, dynamic>;

      final announcement = RallyChannelAnnouncement(
        channelId: data['channel_id'] as String,
        name: data['name'] as String,
        geohash: data['geohash'] as String,
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
        radiusMeters: data['radius_meters'] as int,
        maxMessageAgeHours: data['max_message_age_hours'] as int,
        creatorPeerId: data['created_by'] as String,
        receivedAt: DateTime.now(),
      );

      // Emit for Rally repository to handle
      _rallyChannelController.add(announcement);
    } catch (e) {
      // Invalid Rally broadcast format
    }
  }

  /// Queue message for later delivery
  Future<void> _queueMessage({
    required String messageId,
    required String recipientPeerId,
    required PacketType type,
    required Uint8List payload,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(BleConstants.storeAndForwardTtl);

    // Store encrypted packet (hex encoded)
    final encryptedHex = _bytesToHex(payload);

    await _db.insertMeshMessageQueue(MeshMessageQueueCompanion.insert(
      messageId: messageId,
      recipientPeerId: recipientPeerId,
      encryptedPacket: encryptedHex,
      queuedAt: now,
      expiresAt: expiresAt,
    ));

    _statusController.add(MessageDeliveryStatus(
      messageId: messageId,
      status: DeliveryStatus.queued,
      timestamp: now,
    ));
  }

  /// Process queued messages
  Future<void> _processMessageQueue() async {
    final queued = await _db.getQueuedMessages();

    for (final item in queued) {
      // Check if we now have a route
      final route = await _routingEngine.findRoute(item.recipientPeerId);

      if (route != null) {
        // Try to send
        try {
          // Decode hex-encoded packet
          final packetBytes = _hexToBytes(item.encryptedPacket);
          final packet = MeshPacket.decode(packetBytes);
          await _sendPacketToPeer(packet, route.nextHopPeerId);

          // Remove from queue
          await _db.deleteMeshQueuedMessage(item.messageId);

          _statusController.add(MessageDeliveryStatus(
            messageId: item.messageId,
            status: DeliveryStatus.sent,
            timestamp: DateTime.now(),
          ));
        } catch (e) {
          // Failed - leave in queue for next attempt
          await _db.updateMeshMessageRetry(item.messageId);
        }
      }
    }

    // Clean up expired messages
    await _db.deleteExpiredQueuedMessages();
  }

  /// Get or create Noise session with peer
  Future<NoiseSession?> _getOrCreateSession(String peerId) async {
    // Check if we already have a session
    if (_noiseSessions.containsKey(peerId)) {
      return _noiseSessions[peerId];
    }

    // Try to load from database
    final peer = await _db.getMeshPeerById(peerId);
    if (peer?.noiseTransportState != null) {
      try {
        final sessionJson = jsonDecode(peer!.noiseTransportState!);
        final session = NoiseSession.fromJson(sessionJson as Map<String, dynamic>);
        _noiseSessions[peerId] = session;
        return session;
      } catch (e) {
        // Failed to load session
      }
    }

    // No existing session - need to connect
    // Return null to trigger queueing
    return null;
  }

  /// Helper to convert hex string to bytes
  Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  /// Helper to convert bytes to hex
  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// Dispose resources
  void dispose() {
    _packetSubscription?.cancel();
    _discoverySubscription?.cancel();
    _forwardSubscription?.cancel();
    _announceTimer?.cancel();
    _queueProcessTimer?.cancel();
    _messageController.close();
    _statusController.close();
    _relayRequestController.close();
    _rallyChannelController.close();
  }
}

/// Incoming mesh message
class MeshMessage {
  final String messageId;
  final PacketType type;
  final String content;
  final DateTime timestamp;
  final String senderPeerId;

  MeshMessage({
    required this.messageId,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.senderPeerId,
  });
}

/// Message delivery status
class MessageDeliveryStatus {
  final String messageId;
  final DeliveryStatus status;
  final DateTime timestamp;
  final String? error;

  MessageDeliveryStatus({
    required this.messageId,
    required this.status,
    required this.timestamp,
    this.error,
  });
}

/// Delivery status enum
enum DeliveryStatus {
  queued,
  sent,
  delivered,
  failed,
}

/// Relay request received from mesh for bridge mode
/// Contains an already-encrypted envelope to be forwarded to the relay server
class MeshRelayRequest {
  final String messageId;
  final String recipientKeyHash;
  final String encryptedPayload;
  final int ttlHours;
  final String priority;
  final String senderPeerId;
  final DateTime receivedAt;

  const MeshRelayRequest({
    required this.messageId,
    required this.recipientKeyHash,
    required this.encryptedPayload,
    required this.ttlHours,
    required this.priority,
    required this.senderPeerId,
    required this.receivedAt,
  });

  /// Convert to RelayRequest for bridge mode service
  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'recipient_key_hash': recipientKeyHash,
        'encrypted_payload': encryptedPayload,
        'ttl_hours': ttlHours,
        'priority': priority,
        'sender_peer_id': senderPeerId,
      };
}

/// Rally channel announcement received from mesh peer
/// Used to discover Rally channels without internet connectivity
class RallyChannelAnnouncement {
  final String channelId;
  final String name;
  final String geohash;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final int maxMessageAgeHours;
  final String creatorPeerId;
  final DateTime receivedAt;

  const RallyChannelAnnouncement({
    required this.channelId,
    required this.name,
    required this.geohash,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.maxMessageAgeHours,
    required this.creatorPeerId,
    required this.receivedAt,
  });
}
