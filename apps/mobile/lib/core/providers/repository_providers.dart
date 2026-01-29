import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart' show EventUpdateType;
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/message_repository.dart';
import 'database_providers.dart';
import 'matrix_providers.dart';
import 'transport_providers.dart';
import 'mesh_providers.dart';
import 'bridge_providers.dart';
import 'identity_providers.dart';

/// Provider for ConversationRepository
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final matrixService = ref.watch(matrixServiceProvider);

  return ConversationRepository(
    database: database,
    matrixService: matrixService,
  );
});

/// Provider for MessageRepository
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final matrixService = ref.watch(matrixServiceProvider);
  final transportManager = ref.watch(transportManagerProvider);
  final meshTransport = ref.watch(meshTransportProvider);
  final bridgeModeService = ref.watch(bridgeModeServiceProvider);
  final bridgeTransport = ref.watch(bridgeTransportProvider);
  final identity = ref.watch(identityProvider).value;

  // Compute my public key base64 for bridge relay
  final myPublicKeyBase64 = identity != null
      ? base64.encode(identity.exchangeKeyPair.publicKey)
      : null;

  return MessageRepository(
    database: database,
    matrixService: matrixService,
    transportManager: transportManager,
    meshTransport: meshTransport,
    bridgeModeService: bridgeModeService,
    bridgeTransport: bridgeTransport,
    myPublicKeyBase64: myPublicKeyBase64,
  );
});

/// Exception indicating offline state for UI handling
class OfflineException implements Exception {
  const OfflineException([this.message = 'No internet connection']);
  final String message;
  @override
  String toString() => message;
}

/// Check if an exception is due to connectivity issues
bool isOfflineException(Object error) {
  final errorStr = error.toString().toLowerCase();
  return errorStr.contains('socketexception') ||
      errorStr.contains('connection refused') ||
      errorStr.contains('connection closed') ||
      errorStr.contains('connection reset') ||
      errorStr.contains('network is unreachable') ||
      errorStr.contains('no internet') ||
      errorStr.contains('failed host lookup') ||
      errorStr.contains('websocket') ||
      errorStr.contains('timeout');
}

/// Provider for conversations list
final conversationsProvider = FutureProvider((ref) async {
  final repository = ref.watch(conversationRepositoryProvider);

  // Try to sync from Matrix, fall back to cached on network errors
  try {
    await repository.syncConversations();
  } catch (e) {
    // If sync fails due to connectivity, continue with cached data
    if (isOfflineException(e)) {
      // Just continue to return cached data
    } else {
      rethrow;
    }
  }

  // Return conversations from local database
  return repository.getConversations();
});

/// Provider for messages in a conversation
///
/// Reads directly from Matrix SDK timeline - SDK handles decryption internally.
/// This bypasses the local DB sync which fails for encrypted messages without
/// proper Olm initialization.
final messagesProvider = FutureProvider.family<List<dynamic>, String>((ref, conversationId) async {
  final repository = ref.watch(messageRepositoryProvider);

  // Read directly from Matrix SDK (handles decryption)
  return repository.getMessagesFromMatrix(conversationId: conversationId);
});

/// Provider that starts Matrix sync and listens to events to auto-refresh data
/// Initialize this provider on app start to enable real-time updates
///
/// IMPORTANT: This provider ONLY invalidates conversationsProvider (for the home list).
/// It does NOT invalidate messagesProvider to avoid infinite loops.
/// Messages are refreshed via pull-to-refresh or explicit user action.
final matrixSyncListenerProvider = Provider<void>((ref) {
  final matrixService = ref.watch(matrixServiceProvider);

  // Start continuous sync if logged in (runs in background)
  if (matrixService.isLoggedIn) {
    // Don't await - let it run in background
    matrixService.startSync();
  }

  // Listen to sync events - ONLY invalidate conversations, NOT messages
  final syncSubscription = matrixService.onSync.listen((syncUpdate) {
    ref.invalidate(conversationsProvider);
  });

  // Listen to message events for conversation list updates
  final eventSubscription = matrixService.onEvent.listen((event) {
    // Only refresh conversations on timeline events (new messages)
    // This updates last message/unread count in the chat list
    // DO NOT invalidate messagesProvider here - it causes infinite loops
    if (event.type == EventUpdateType.timeline) {
      ref.invalidate(conversationsProvider);
    }
  });

  ref.onDispose(() {
    syncSubscription.cancel();
    eventSubscription.cancel();
    matrixService.stopSync();
  });
});

// NOTE: periodicSyncProvider was removed as it's redundant.
// Background sync in matrixSyncListenerProvider handles continuous syncing.
// The periodic sync caused unnecessary invalidation loops.
