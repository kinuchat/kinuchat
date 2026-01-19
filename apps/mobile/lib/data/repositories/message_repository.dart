import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:meshlink_core/database/app_database.dart';
import 'package:meshlink_core/transport/transport_manager.dart';
import 'package:meshlink_core/mesh/mesh_transport_impl.dart';
import '../services/matrix_service.dart';

/// Repository for managing messages
/// Syncs between Matrix events and local Drift database
class MessageRepository {
  MessageRepository({
    required AppDatabase database,
    required MatrixService matrixService,
    required TransportManager transportManager,
    required MeshTransportImpl? meshTransport,
  })  : _database = database,
        _matrixService = matrixService,
        _transportManager = transportManager,
        _meshTransport = meshTransport;

  final AppDatabase _database;
  final MatrixService _matrixService;
  final TransportManager _transportManager;
  final MeshTransportImpl? _meshTransport;

  /// Get messages for a conversation
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
          throw UnimplementedError('Bridge transport not yet implemented');
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

  /// Sync messages from a Matrix room
  Future<void> syncMessages({
    required String conversationId,
    int limit = 50,
  }) async {
    try {
      final room = _matrixService.getRoomById(conversationId);
      if (room == null) {
        return;
      }

      // Get timeline events
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
}

/// Exception thrown when message operations fail
class MessageRepositoryException implements Exception {
  MessageRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'MessageRepositoryException: $message';
}
