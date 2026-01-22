import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:meshlink_core/database/app_database.dart';
import 'package:meshlink_core/transport/transport_manager.dart';
import 'package:meshlink_core/mesh/mesh_transport_impl.dart';
import 'package:meshlink_core/transport/bridge_transport_impl.dart';
import 'package:meshlink_core/crypto/bridge_encryption.dart';
import '../services/matrix_service.dart';
import '../services/bridge_mode_service.dart';
import '../services/media_service.dart';

/// Repository for managing messages
/// Syncs between Matrix events and local Drift database
class MessageRepository {
  MessageRepository({
    required AppDatabase database,
    required MatrixService matrixService,
    required TransportManager transportManager,
    required MeshTransportImpl? meshTransport,
    required BridgeModeService? bridgeModeService,
    required BridgeTransportImpl? bridgeTransport,
    required String? myPublicKeyBase64,
  })  : _database = database,
        _matrixService = matrixService,
        _transportManager = transportManager,
        _meshTransport = meshTransport,
        _bridgeModeService = bridgeModeService,
        _bridgeTransport = bridgeTransport,
        _myPublicKeyBase64 = myPublicKeyBase64;

  final AppDatabase _database;
  final MatrixService _matrixService;
  final TransportManager _transportManager;
  final MeshTransportImpl? _meshTransport;
  final BridgeModeService? _bridgeModeService;
  final BridgeTransportImpl? _bridgeTransport;
  final String? _myPublicKeyBase64;

  /// Get messages for a conversation from local database
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    return _database.getMessagesForConversation(
      conversationId,
      limit: limit,
      offset: offset,
    );
  }

  /// Get messages directly from Matrix SDK timeline
  /// Bypasses local DB - SDK handles decryption internally
  /// This solves the E2EE issue where encrypted events can't be read from local DB
  /// Also includes locally-stored messages (pending/sent) that may not be in timeline yet
  Future<List<MessageEntity>> getMessagesFromMatrix({
    required String conversationId,
    int limit = 50,
  }) async {
    // Try to get room, with retry if sync is still loading
    matrix.Room? room = _matrixService.getRoomById(conversationId);

    // If room not found, wait a bit for sync to complete
    if (room == null) {
      debugPrint('[MessageRepository] Room not found, waiting for sync...');
      for (var i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        room = _matrixService.getRoomById(conversationId);
        if (room != null) {
          debugPrint('[MessageRepository] Room found after ${i + 1} retries');
          break;
        }
      }
    }

    if (room == null) {
      debugPrint('[MessageRepository] Room still not found after retries: $conversationId');
      // Fall back to local DB if room not found
      return _database.getMessagesForConversation(conversationId, limit: limit);
    }

    debugPrint('[MessageRepository] Getting timeline for room: $conversationId');
    debugPrint('[MessageRepository] Room encrypted: ${room.encrypted}');

    final timeline = await room.getTimeline();
    final currentUserId = _matrixService.client?.userID;

    debugPrint('[MessageRepository] Timeline has ${timeline.events.length} events');

    // Get locally-stored messages (includes pending/sent that may not be in timeline)
    final localMessages = await _database.getMessagesForConversation(
      conversationId,
      limit: limit,
    );
    debugPrint('[MessageRepository] Local DB has ${localMessages.length} messages');

    // Build a map of messages by ID, starting with local messages
    final messageMap = <String, MessageEntity>{};
    for (final msg in localMessages) {
      messageMap[msg.id] = msg;
    }

    // Add/update from Matrix timeline (these have decrypted content)
    for (final event in timeline.events) {
      debugPrint('[MessageRepository] Event type: ${event.type}, body: "${event.body}", senderId: ${event.senderId}');

      // Only process message events
      if (event.type != matrix.EventTypes.Message) continue;

      // Skip if body is empty (failed decryption or non-text content)
      if (event.body.isEmpty) {
        // Log detailed info to help diagnose decryption issues
        // Check if event is still encrypted (decryption failed)
        final isEncryptedType = event.type == matrix.EventTypes.Encrypted;
        debugPrint('[MessageRepository] Empty body - type: ${event.type}, '
            'isEncrypted: $isEncryptedType, senderId: ${event.senderId}, '
            'eventId: ${event.eventId}');
        continue;
      }

      // Use Matrix event data (has decrypted content)
      messageMap[event.eventId] = MessageEntity(
        id: event.eventId,
        conversationId: event.roomId ?? conversationId,
        senderId: event.senderId,
        content: event.body,
        type: _getMessageType(event),
        status: 'delivered',
        transport: 'cloud',
        timestamp: event.originServerTs,
        isFromMe: event.senderId == currentUserId,
        deliveredAt: null,
        readAt: null,
        metadata: null,
      );
    }

    // Convert to list and sort by timestamp (newest first for reverse list)
    final messages = messageMap.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    debugPrint('[MessageRepository] Returning ${messages.length} merged messages');
    return messages.take(limit).toList();
  }

  /// Get message type from Matrix event
  String _getMessageType(matrix.Event event) {
    final msgtype = event.content['msgtype'];
    return switch (msgtype) {
      'm.text' => 'text',
      'm.image' => 'image',
      'm.video' => 'video',
      'm.audio' => 'audio',
      'm.file' => 'file',
      _ => 'text',
    };
  }

  /// Send a text message
  Future<MessageEntity> sendTextMessage({
    required String conversationId,
    required String content,
    required String senderId,
  }) async {
    try {
      // Generate message ID
      final messageId = _generateMessageId(
        content: content,
        senderId: senderId,
        timestamp: DateTime.now(),
      );

      // Select transport (cloud vs mesh)
      final selectedTransport = await _transportManager.selectTransport(
        recipientId: conversationId,
        message: {
          'content': content,
          'type': 'text',
        },
      );

      // Store locally first with pending status
      final message = MessagesCompanion(
        id: Value(messageId),
        conversationId: Value(conversationId),
        senderId: Value(senderId),
        content: Value(content),
        type: const Value('text'),
        status: const Value('pending'),
        transport: Value(selectedTransport.name),
        timestamp: Value(DateTime.now()),
        isFromMe: const Value(true),
      );

      await _database.insertMessage(message);

      // Send via selected transport
      switch (selectedTransport) {
        case Transport.cloud:
          await _matrixService.sendTextMessage(
            roomId: conversationId,
            message: content,
          );
          break;

        case Transport.mesh:
          if (_meshTransport != null) {
            await _meshTransport.sendTextMessage(
              messageId: messageId,
              recipientPeerId: conversationId,
              content: content,
            );
          } else {
            throw Exception('Mesh transport not available');
          }
          break;

        case Transport.bridge:
          if (_bridgeModeService == null || _bridgeTransport == null) {
            throw Exception('Bridge transport not available');
          }

          // For bridge transport, we need the recipient's public key
          // This should be obtained from the contact's stored exchange key
          final recipientKeyData = await _getRecipientKeyData(conversationId);

          // Encrypt message using ECIES-style encryption with recipient's X25519 key
          final encryptedPayload = await BridgeEncryption.encryptText(
            message: content,
            recipientPublicKey: recipientKeyData.publicKeyBytes,
          );

          // Queue the message for relay
          await _bridgeModeService!.queueMessageForRelay(
            messageId: messageId,
            recipientKeyHash: recipientKeyData.keyHash,
            encryptedPayload: encryptedPayload,
            ttlHours: 4,
            priority: 'normal',
          );
      }

      // Update with sent status
      await _database.updateMessageStatus(messageId, 'sent');

      final sent = await _database.getMessageById(messageId);
      if (sent == null) {
        throw Exception('Message not found after sending');
      }

      return sent;
    } catch (e) {
      throw MessageRepositoryException('Failed to send message: $e');
    }
  }

  /// Sync messages from a Matrix room to local database
  ///
  /// IMPORTANT: This method does NOT trigger a full Matrix sync.
  /// It reads timeline from the already-synced client state.
  /// Background sync (via matrixSyncListenerProvider) keeps client state updated.
  Future<void> syncMessages({
    required String conversationId,
    int limit = 50,
  }) async {
    try {
      // DON'T call full sync here - background sync handles that
      // Just read timeline from already-synced client state

      final room = _matrixService.getRoomById(conversationId);
      if (room == null) {
        return;
      }

      // Get timeline events from already-synced state
      final timeline = await room.getTimeline();
      final events = timeline.events;

      for (final event in events.take(limit)) {
        await _syncEvent(event);
      }
    } catch (e) {
      throw MessageRepositoryException('Failed to sync messages: $e');
    }
  }

  /// Sync a single Matrix event to local database
  Future<void> _syncEvent(matrix.Event event) async {
    // Only process message events
    if (event.type != matrix.EventTypes.Message) {
      return;
    }

    final messageId = event.eventId;
    final conversationId = event.roomId;
    final senderId = event.senderId;
    final content = event.body;
    final timestamp = event.originServerTs;

    // Check if we already have this message
    final existing = await _database.getMessageById(messageId);
    if (existing != null) {
      return;
    }

    // Determine if message is from current user
    final currentUserId = _matrixService.client?.userID;
    final isFromMe = senderId == currentUserId;

    final message = MessagesCompanion(
      id: Value(messageId),
      conversationId: Value(conversationId ?? ''),
      senderId: Value(senderId),
      content: Value(content),
      type: const Value('text'),
      status: const Value('delivered'),
      transport: const Value('cloud'),
      timestamp: Value(timestamp),
      isFromMe: Value(isFromMe),
    );

    await _database.insertMessage(message);
  }

  /// Mark message as delivered
  Future<void> markAsDelivered(String messageId) async {
    await _database.updateMessageDelivered(messageId, DateTime.now());
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    await _database.updateMessageRead(messageId, DateTime.now());
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    await _database.deleteMessage(messageId);
  }

  /// Get pending messages for retry
  Future<List<MessageEntity>> getPendingMessages() async {
    return _database.getPendingMessages();
  }

  /// Retry failed message
  Future<void> retryMessage(String messageId) async {
    final message = await _database.getMessageById(messageId);
    if (message == null) {
      return;
    }

    try {
      // Resend via Matrix
      await _matrixService.sendTextMessage(
        roomId: message.conversationId,
        message: message.content,
      );

      // Update status
      await _database.updateMessageStatus(messageId, 'sent');
    } catch (e) {
      await _database.updateMessageStatus(messageId, 'failed');
      rethrow;
    }
  }

  // ============================================================================
  // Media Message Methods
  // ============================================================================

  /// Send an image message
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required String senderId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      final mediaService = MediaService();

      // Get image dimensions
      final dimensions = await mediaService.getImageDimensions(imageFile);

      // Generate thumbnail
      final thumbnail = await mediaService.generateImageThumbnail(imageFile);

      // Generate message ID
      final messageId = _generateMessageId(
        content: caption ?? 'Image',
        senderId: senderId,
        timestamp: DateTime.now(),
      );

      // Build metadata
      final metadata = jsonEncode({
        'type': 'image',
        'width': dimensions.width,
        'height': dimensions.height,
        'size': await imageFile.length(),
        'fileName': imageFile.path.split('/').last,
      });

      // Store locally first with pending status
      final message = MessagesCompanion(
        id: Value(messageId),
        conversationId: Value(conversationId),
        senderId: Value(senderId),
        content: Value(caption ?? 'Image'),
        type: const Value('image'),
        status: const Value('pending'),
        transport: const Value('cloud'),
        timestamp: Value(DateTime.now()),
        isFromMe: const Value(true),
        metadata: Value(metadata),
      );

      await _database.insertMessage(message);

      // Send via Matrix (cloud transport for media)
      await _matrixService.sendImageMessage(
        roomId: conversationId,
        imageFile: imageFile,
        caption: caption,
        width: dimensions.width,
        height: dimensions.height,
        thumbnailBytes: thumbnail.bytes,
        thumbnailWidth: thumbnail.width,
        thumbnailHeight: thumbnail.height,
      );

      // Update with sent status
      await _database.updateMessageStatus(messageId, 'sent');

      final sent = await _database.getMessageById(messageId);
      if (sent == null) {
        throw MessageRepositoryException('Message not found after sending');
      }

      return sent;
    } catch (e) {
      throw MessageRepositoryException('Failed to send image: $e');
    }
  }

  /// Send a video message
  Future<MessageEntity> sendVideoMessage({
    required String conversationId,
    required String senderId,
    required File videoFile,
    String? caption,
  }) async {
    try {
      final mediaService = MediaService();

      // Get video metadata
      final videoMeta = await mediaService.getVideoMetadata(videoFile);

      // Generate thumbnail
      final thumbnail = await mediaService.generateVideoThumbnail(videoFile);

      // Generate message ID
      final messageId = _generateMessageId(
        content: caption ?? 'Video',
        senderId: senderId,
        timestamp: DateTime.now(),
      );

      // Build metadata
      final metadata = jsonEncode({
        'type': 'video',
        'width': videoMeta?.width ?? 0,
        'height': videoMeta?.height ?? 0,
        'duration': videoMeta?.duration ?? 0,
        'size': videoMeta?.size ?? await videoFile.length(),
        'fileName': videoFile.path.split('/').last,
      });

      // Store locally first
      final message = MessagesCompanion(
        id: Value(messageId),
        conversationId: Value(conversationId),
        senderId: Value(senderId),
        content: Value(caption ?? 'Video'),
        type: const Value('video'),
        status: const Value('pending'),
        transport: const Value('cloud'),
        timestamp: Value(DateTime.now()),
        isFromMe: const Value(true),
        metadata: Value(metadata),
      );

      await _database.insertMessage(message);

      // Send via Matrix
      await _matrixService.sendVideoMessage(
        roomId: conversationId,
        videoFile: videoFile,
        caption: caption,
        width: videoMeta?.width,
        height: videoMeta?.height,
        duration: videoMeta?.duration,
        thumbnailBytes: thumbnail?.bytes,
        thumbnailWidth: thumbnail?.width,
        thumbnailHeight: thumbnail?.height,
      );

      // Update status
      await _database.updateMessageStatus(messageId, 'sent');

      final sent = await _database.getMessageById(messageId);
      if (sent == null) {
        throw MessageRepositoryException('Message not found after sending');
      }

      return sent;
    } catch (e) {
      throw MessageRepositoryException('Failed to send video: $e');
    }
  }

  /// Send a voice message
  Future<MessageEntity> sendVoiceMessage({
    required String conversationId,
    required String senderId,
    required File audioFile,
    required int durationMs,
    List<int>? waveform,
  }) async {
    try {
      // Generate message ID
      final messageId = _generateMessageId(
        content: 'Voice message',
        senderId: senderId,
        timestamp: DateTime.now(),
      );

      // Build metadata
      final metadata = jsonEncode({
        'type': 'voice',
        'duration': durationMs,
        'size': await audioFile.length(),
        'fileName': audioFile.path.split('/').last,
        if (waveform != null) 'waveform': waveform,
      });

      // Store locally first
      final message = MessagesCompanion(
        id: Value(messageId),
        conversationId: Value(conversationId),
        senderId: Value(senderId),
        content: const Value('Voice message'),
        type: const Value('voice'),
        status: const Value('pending'),
        transport: const Value('cloud'),
        timestamp: Value(DateTime.now()),
        isFromMe: const Value(true),
        metadata: Value(metadata),
      );

      await _database.insertMessage(message);

      // Send via Matrix
      await _matrixService.sendAudioMessage(
        roomId: conversationId,
        audioFile: audioFile,
        duration: durationMs,
        isVoiceMessage: true,
        waveform: waveform,
      );

      // Update status
      await _database.updateMessageStatus(messageId, 'sent');

      final sent = await _database.getMessageById(messageId);
      if (sent == null) {
        throw MessageRepositoryException('Message not found after sending');
      }

      return sent;
    } catch (e) {
      throw MessageRepositoryException('Failed to send voice message: $e');
    }
  }

  /// Send a file attachment
  Future<MessageEntity> sendFileMessage({
    required String conversationId,
    required String senderId,
    required File file,
    String? caption,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      // Generate message ID
      final messageId = _generateMessageId(
        content: caption ?? fileName,
        senderId: senderId,
        timestamp: DateTime.now(),
      );

      // Build metadata
      final metadata = jsonEncode({
        'type': 'file',
        'fileName': fileName,
        'size': fileSize,
      });

      // Store locally first
      final message = MessagesCompanion(
        id: Value(messageId),
        conversationId: Value(conversationId),
        senderId: Value(senderId),
        content: Value(caption ?? fileName),
        type: const Value('file'),
        status: const Value('pending'),
        transport: const Value('cloud'),
        timestamp: Value(DateTime.now()),
        isFromMe: const Value(true),
        metadata: Value(metadata),
      );

      await _database.insertMessage(message);

      // Send via Matrix
      await _matrixService.sendFileMessage(
        roomId: conversationId,
        file: file,
        caption: caption,
      );

      // Update status
      await _database.updateMessageStatus(messageId, 'sent');

      final sent = await _database.getMessageById(messageId);
      if (sent == null) {
        throw MessageRepositoryException('Message not found after sending');
      }

      return sent;
    } catch (e) {
      throw MessageRepositoryException('Failed to send file: $e');
    }
  }

  // ============================================================================
  // Private Methods
  // ============================================================================

  /// Generate deterministic message ID
  /// Per spec: SHA256(content + timestamp + sender)
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

  /// Get recipient's key data for bridge relay
  /// Per spec section 6.4: SHA256(recipient_X25519_public_key) base64 encoded
  Future<RecipientKeyData> _getRecipientKeyData(String conversationId) async {
    // Try to get the recipient's exchange key from conversation metadata
    // This is a 1:1 conversation, so we need to find the other party's key
    final conversation = await _database.getConversationById(conversationId);
    if (conversation == null) {
      throw MessageRepositoryException('Conversation not found: $conversationId');
    }

    // For Matrix DMs, the conversation ID is the room ID
    // We need to get the recipient's identity key from the room members
    // The participantKey field stores the X25519 public key (base64 encoded)
    final recipientPublicKeyBase64 = conversation.participantKey;
    if (recipientPublicKeyBase64 == null || recipientPublicKeyBase64.isEmpty) {
      throw MessageRepositoryException(
        'Recipient exchange key not found for conversation: $conversationId',
      );
    }

    // Decode the public key
    final keyBytes = base64.decode(recipientPublicKeyBase64);
    if (keyBytes.length != 32) {
      throw MessageRepositoryException(
        'Invalid recipient key length: ${keyBytes.length}',
      );
    }

    // Compute SHA256 hash of the public key for relay server lookup
    final keyHash = sha256.convert(keyBytes);
    final keyHashBase64 = base64.encode(keyHash.bytes);

    return RecipientKeyData(
      publicKeyBytes: Uint8List.fromList(keyBytes),
      keyHash: keyHashBase64,
    );
  }
}

/// Data class for recipient's key information
class RecipientKeyData {
  final Uint8List publicKeyBytes;
  final String keyHash;

  const RecipientKeyData({
    required this.publicKeyBytes,
    required this.keyHash,
  });
}

/// Exception thrown when message operations fail
class MessageRepositoryException implements Exception {
  MessageRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'MessageRepositoryException: $message';
}
