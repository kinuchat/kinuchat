import 'package:drift/drift.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:meshlink_core/database/app_database.dart';
import '../services/matrix_service.dart';

/// Repository for managing conversations
/// Syncs between Matrix rooms and local Drift database
class ConversationRepository {
  ConversationRepository({
    required AppDatabase database,
    required MatrixService matrixService,
  })  : _database = database,
        _matrixService = matrixService;

  final AppDatabase _database;
  final MatrixService _matrixService;

  /// Get all conversations from local database
  Future<List<ConversationEntity>> getConversations() async {
    return _database.getAllConversations();
  }

  /// Get conversation by ID
  Future<ConversationEntity?> getConversationById(String id) async {
    return _database.getConversationById(id);
  }

  /// Create a direct message conversation
  Future<ConversationEntity> createDirectMessage({
    required String recipientId,
    required String recipientName,
  }) async {
    try {
      // Create Matrix room
      final roomId = await _matrixService.createDirectMessageRoom(
        userId: recipientId,
      );

      // Store in local database
      final conversation = ConversationsCompanion(
        id: Value(roomId),
        type: const Value('direct'),
        name: Value(recipientName),
        createdAt: Value(DateTime.now()),
      );

      await _database.upsertConversation(conversation);

      final created = await _database.getConversationById(roomId);
      if (created == null) {
        throw Exception('Failed to create conversation');
      }

      return created;
    } catch (e) {
      throw ConversationRepositoryException('Failed to create DM: $e');
    }
  }

  /// Sync conversations from Matrix to local database
  Future<void> syncConversations() async {
    try {
      final rooms = _matrixService.getRooms();

      for (final room in rooms) {
        await _syncRoom(room);
      }
    } catch (e) {
      throw ConversationRepositoryException('Failed to sync conversations: $e');
    }
  }

  /// Sync a single room to local database
  Future<void> _syncRoom(matrix.Room room) async {
    final conversation = ConversationsCompanion(
      id: Value(room.id),
      type: Value(room.isDirectChat ? 'direct' : 'group'),
      name: Value(room.getLocalizedDisplayname()),
      avatar: room.avatar != null ? Value(room.avatar.toString()) : const Value.absent(),
      createdAt: Value(DateTime.now()),
      lastMessageAt: room.lastEvent != null
          ? Value(room.lastEvent!.originServerTs)
          : const Value.absent(),
      unreadCount: Value(room.notificationCount),
    );

    await _database.upsertConversation(conversation);
  }

  /// Update conversation last message timestamp
  Future<void> updateLastMessage({
    required String conversationId,
    required DateTime timestamp,
  }) async {
    final conversation = await _database.getConversationById(conversationId);
    if (conversation == null) {
      return;
    }

    await _database.upsertConversation(
      ConversationsCompanion(
        id: Value(conversationId),
        lastMessageAt: Value(timestamp),
      ),
    );
  }

  /// Increment unread count
  Future<void> incrementUnreadCount(String conversationId) async {
    final conversation = await _database.getConversationById(conversationId);
    if (conversation == null) {
      return;
    }

    await _database.upsertConversation(
      ConversationsCompanion(
        id: Value(conversationId),
        unreadCount: Value(conversation.unreadCount + 1),
      ),
    );
  }

  /// Reset unread count
  Future<void> resetUnreadCount(String conversationId) async {
    await _database.upsertConversation(
      ConversationsCompanion(
        id: Value(conversationId),
        unreadCount: const Value(0),
      ),
    );
  }

  /// Delete conversation
  Future<void> deleteConversation(String id) async {
    await _database.deleteConversation(id);
  }
}

/// Exception thrown when conversation operations fail
class ConversationRepositoryException implements Exception {
  ConversationRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ConversationRepositoryException: $message';
}
