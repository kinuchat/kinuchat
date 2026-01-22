import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/transport_indicator.dart';
import '../groups/group_info_screen.dart';

/// Chat conversation screen
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) {
      return;
    }

    debugPrint('[ChatScreen] Sending message to ${widget.conversationId}');

    setState(() {
      _isSending = true;
    });

    try {
      final repository = ref.read(messageRepositoryProvider);
      final identity = ref.read(identityProvider).value;

      if (identity == null) {
        debugPrint('[ChatScreen] ERROR: No identity found');
        throw Exception('No identity found');
      }

      debugPrint('[ChatScreen] Calling repository.sendTextMessage...');
      await repository.sendTextMessage(
        conversationId: widget.conversationId,
        content: message,
        senderId: identity.meshPeerIdHex,
      );

      debugPrint('[ChatScreen] Message sent successfully');
      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: MeshLinkAnimations.messageReceive,
          curve: Curves.easeOut,
        );
      }

      // Refresh messages
      debugPrint('[ChatScreen] Refreshing messages provider...');
      ref.invalidate(messagesProvider(widget.conversationId));
    } catch (e, stack) {
      debugPrint('[ChatScreen] ERROR sending message: $e');
      debugPrint('[ChatScreen] Stack: $stack');
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(
      conversationsProvider.select(
        (value) => value.whenData(
          (conversations) => conversations.firstWhere(
            (c) => c.id == widget.conversationId,
            orElse: () => throw Exception('Conversation not found'),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: conversationAsync.when(
          data: (conversation) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(conversation.name ?? 'Unknown'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Online',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const TransportIndicator(),
                ],
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              // TODO: Video call (future feature)
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              // TODO: Voice call (future feature)
            },
          ),
          conversationAsync.when(
            data: (conversation) => IconButton(
              icon: Icon(
                conversation.isGroup == true ? Icons.group : Icons.more_vert,
              ),
              onPressed: () {
                if (conversation.isGroup == true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupInfoScreen(
                        groupId: widget.conversationId,
                      ),
                    ),
                  );
                } else {
                  // TODO: Direct message options
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: conversationAsync.when(
        data: (conversation) => Column(
          children: [
            Expanded(
              child: MessageListView(
                conversationId: widget.conversationId,
                scrollController: _scrollController,
                isGroup: conversation.isGroup == true,
              ),
            ),
            SafeArea(
              top: false,
              child: MessageInputBar(
                controller: _messageController,
                isSending: _isSending,
                onSend: _sendMessage,
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Column(
          children: [
            Expanded(
              child: MessageListView(
                conversationId: widget.conversationId,
                scrollController: _scrollController,
              ),
            ),
            SafeArea(
              top: false,
              child: MessageInputBar(
                controller: _messageController,
                isSending: _isSending,
                onSend: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Message list view with pull-to-refresh support
class MessageListView extends ConsumerWidget {
  const MessageListView({
    required this.conversationId,
    required this.scrollController,
    this.isGroup = false,
    super.key,
  });

  final String conversationId;
  final ScrollController scrollController;
  final bool isGroup;

  /// Refresh messages by invalidating the provider
  /// Provider will re-read from Matrix SDK timeline (handles decryption)
  Future<void> _refreshMessages(WidgetRef ref) async {
    ref.invalidate(messagesProvider(conversationId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider(conversationId));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          // Empty state with pull-to-refresh
          return RefreshIndicator(
            onRefresh: () => _refreshMessages(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: Spacing.md),
                        Text(
                          'No messages yet',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'Pull to refresh or start the conversation!',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // For reverse list, RefreshIndicator triggers when scrolling to the "top"
        // which is visually at the bottom (oldest messages)
        // We use a custom refresh approach for better UX
        return RefreshIndicator(
          onRefresh: () => _refreshMessages(ref),
          child: ListView.builder(
            controller: scrollController,
            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              // With reverse: true, index 0 is at the bottom visually
              // messages are sorted DESC (newest first), so messages[0] = newest
              // We want newest at bottom, so just use messages[index] directly
              final message = messages[index];
              return MessageBubble(
                message: message,
                showSenderName: isGroup,
              );
            },
          ),
        );
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Failed to load messages',
                style: AppTypography.body,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                error.toString(),
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              FilledButton(
                onPressed: () => ref.refresh(messagesProvider(conversationId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Message bubble widget
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    this.showSenderName = false,
    super.key,
  });

  final dynamic message;
  final bool showSenderName;

  @override
  Widget build(BuildContext context) {
    try {
      final isFromMe = _getIsFromMe(message);
      final senderName = _getSenderName(message);
      final content = _getContent(message);
      final timestamp = _getTimestamp(message);
      final status = _getStatus(message);

      return Align(
        alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isFromMe
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Spacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSenderName && !isFromMe && senderName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.xs),
                  child: Text(
                    senderName,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              Text(
                content,
                style: AppTypography.body.copyWith(
                  color: isFromMe ? Colors.white : null,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: AppTypography.caption.copyWith(
                      color: isFromMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  if (isFromMe) ...[
                    const SizedBox(width: Spacing.xs),
                    Icon(
                      _getStatusIcon(status),
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('[MessageBubble] Error rendering message: $e');
      debugPrint('[MessageBubble] Stack: $stack');
      // Show error placeholder instead of crashing
      return Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Spacing.radiusMd),
        ),
        child: Text(
          'Error displaying message',
          style: AppTypography.caption.copyWith(color: AppColors.error),
        ),
      );
    }
  }

  bool _getIsFromMe(dynamic message) {
    try {
      return message.isFromMe as bool;
    } catch (_) {
      return false;
    }
  }

  String _getContent(dynamic message) {
    try {
      return (message.content as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  DateTime _getTimestamp(dynamic message) {
    try {
      return message.timestamp as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  String _getStatus(dynamic message) {
    try {
      return (message.status as String?) ?? 'pending';
    } catch (_) {
      return 'pending';
    }
  }

  /// Get sender name from message, handling MessageEntity which only has senderId
  String? _getSenderName(dynamic message) {
    // Try to get senderName if it exists (for future-proofing)
    try {
      final name = message.senderName as String?;
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {
      // senderName doesn't exist on this message type
    }

    // Fall back to senderId if available
    try {
      final senderId = message.senderId as String?;
      if (senderId != null && senderId.isNotEmpty) {
        // Extract username from Matrix ID if it's in format @user:server
        if (senderId.startsWith('@') && senderId.contains(':')) {
          return senderId.substring(1, senderId.indexOf(':'));
        }
        return senderId;
      }
    } catch (_) {
      // senderId doesn't exist
    }

    return null;
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'sent':
        return Icons.check;
      case 'delivered':
        return Icons.done_all;
      case 'read':
        return Icons.done_all;
      case 'failed':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }
}

/// Message input bar
class MessageInputBar extends StatelessWidget {
  const MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Attach file (Phase 5)
            },
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacing.radiusLg),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          IconButton(
            icon: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: isSending ? null : onSend,
          ),
        ],
      ),
    );
  }
}
