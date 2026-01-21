import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Provider for conversations list
final conversationsProvider = FutureProvider((ref) async {
  final repository = ref.watch(conversationRepositoryProvider);

  // Sync from Matrix first
  await repository.syncConversations();

  // Then get from local database
  return repository.getConversations();
});

/// Provider for messages in a conversation
final messagesProvider = FutureProvider.family<List<dynamic>, String>((ref, conversationId) async {
  final repository = ref.watch(messageRepositoryProvider);

  // Sync from Matrix first
  await repository.syncMessages(conversationId: conversationId);

  // Then get from local database
  return repository.getMessages(conversationId: conversationId);
});
