import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:meshlink_core/database/app_database.dart';
import '../../../core/providers/providers.dart';
import '../../../data/repositories/rally_repository.dart';

/// Rally channel detail screen
///
/// Displays:
/// - Channel messages
/// - Identity banner
/// - Message input
/// - Channel info
class RallyChannelScreen extends ConsumerStatefulWidget {
  const RallyChannelScreen({
    required this.channel,
    super.key,
  });

  final RallyChannel channel;

  @override
  ConsumerState<RallyChannelScreen> createState() => _RallyChannelScreenState();
}

class _RallyChannelScreenState extends ConsumerState<RallyChannelScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildIdentityBanner(),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.channel.name),
          Text(
            '${widget.channel.participantCount} active • Expires in ${_formatTTL()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(rallyMessagesProvider(widget.channel.id)),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showChannelInfo,
        ),
      ],
    );
  }

  Widget _buildIdentityBanner() {
    final displayName = ref.watch(rallyDisplayNameProvider);
    final identityType = ref.watch(rallyIdentityTypeProvider);

    Color bannerColor;
    IconData icon;
    String label;

    switch (identityType) {
      case RallyIdentityType.anonymous:
        bannerColor = Colors.grey;
        icon = Icons.person_outline;
        label = 'Anonymous';
        break;
      case RallyIdentityType.pseudonymous:
        bannerColor = Colors.blue;
        icon = Icons.person;
        label = 'Pseudonymous';
        break;
      case RallyIdentityType.verified:
        bannerColor = Colors.green;
        icon = Icons.verified_user;
        label = 'Verified';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bannerColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(icon, size: 16, color: bannerColor),
          const SizedBox(width: 8),
          Text(
            'Posting as $displayName ($label)',
            style: TextStyle(
              fontSize: 12,
              color: bannerColor,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _changeIdentity,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final messagesAsync = ref.watch(rallyMessagesProvider(widget.channel.id));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No messages yet. Start the conversation!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[messages.length - 1 - index];
            return RallyMessageBubble(message: message);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load messages',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(rallyMessagesProvider(widget.channel.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isSending ? null : _sendMessage,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final repository = ref.read(rallyRepositoryProvider);
      final userId = ref.read(rallyUserIdProvider);
      final locationAsync = await ref.read(currentLocationProvider.future);

      await repository.postToChannel(
        channelId: widget.channel.id,
        content: message,
        senderId: userId,
        latitude: locationAsync?.latitude,
        longitude: locationAsync?.longitude,
      );

      _messageController.clear();
      _scrollToBottom();
      ref.invalidate(rallyMessagesProvider(widget.channel.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTTL() {
    final remaining = widget.channel.timeUntilExpiration;
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h';
    } else {
      return '${remaining.inMinutes}m';
    }
  }

  void _changeIdentity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Identity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Anonymous'),
              subtitle: const Text('Random name, no traceability'),
              onTap: () {
                ref.read(rallyIdentityTypeProvider.notifier).state =
                    RallyIdentityType.anonymous;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Pseudonymous'),
              subtitle: const Text('Custom nickname'),
              onTap: () {
                ref.read(rallyIdentityTypeProvider.notifier).state =
                    RallyIdentityType.pseudonymous;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Verified'),
              subtitle: const Text('Linked to your account'),
              onTap: () {
                ref.read(rallyIdentityTypeProvider.notifier).state =
                    RallyIdentityType.verified;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChannelInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Channel Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Location', widget.channel.geohash),
              _infoRow('Radius', '${widget.channel.radiusMeters}m'),
              _infoRow('Participants', '${widget.channel.participantCount}'),
              _infoRow('Message TTL', '${widget.channel.maxMessageAgeHours}h'),
              _infoRow('Distance', widget.channel.formattedDistance),
              _infoRow(
                'Created',
                DateFormat.yMd().add_jm().format(widget.channel.createdAt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Rally message bubble widget
class RallyMessageBubble extends StatelessWidget {
  const RallyMessageBubble({
    required this.message,
    super.key,
  });

  final MessageEntity message;

  @override
  Widget build(BuildContext context) {
    final isFromMe = message.isFromMe;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isFromMe
              ? Colors.purple.shade100
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 4) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat.jm().format(timestamp);
    }
  }
}
