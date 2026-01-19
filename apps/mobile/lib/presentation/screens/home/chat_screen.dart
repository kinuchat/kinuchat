import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/transport_indicator.dart';

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

    setState(() {
      _isSending = true;
    });

    try {
      final repository = ref.read(messageRepositoryProvider);
      final identity = ref.read(identityProvider).value;

      if (identity == null) {
        throw Exception('No identity found');
      }

      await repository.sendTextMessage(
        conversationId: widget.conversationId,
        content: message,
        senderId: identity.meshPeerIdHex,
      );

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
      ref.invalidate(messagesProvider(widget.conversationId));
    } catch (e) {
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
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Conversation options
            },
          ),
        ],
      ),
      body: Column(
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
    );
  }
}

/// Message list view
class MessageListView extends ConsumerWidget {
  const MessageListView({
    required this.conversationId,
    required this.scrollController,
    super.key,
  });

  final String conversationId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider(conversationId));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
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
                  'Start the conversation!',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          reverse: true,
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[messages.length - 1 - index];
            return MessageBubble(message: message);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
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
      ),
    );
  }
}

/// Message bubble widget
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    super.key,
  });

  final dynamic message;

  @override
  Widget build(BuildContext context) {
    final isFromMe = message.isFromMe as bool;

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
            Text(
              message.content as String,
              style: AppTypography.body.copyWith(
                color: isFromMe ? Colors.white : null,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp as DateTime),
                  style: AppTypography.caption.copyWith(
                    color: isFromMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                if (isFromMe) ...[
                  const SizedBox(width: Spacing.xs),
                  Icon(
                    _getStatusIcon(message.status as String),
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
