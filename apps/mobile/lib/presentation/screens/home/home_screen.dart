import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/mesh_status_banner.dart';
import 'chat_screen.dart';
import '../rally/rally_screen.dart';
import '../settings/settings_screen.dart';
import '../matrix/matrix_auth_screen.dart';
import '../groups/create_group_screen.dart';

/// Home screen showing chat list
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  bool _meshInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeMeshNetwork();
  }

  /// Initialize mesh networking and Matrix sync on app start
  Future<void> _initializeMeshNetwork() async {
    if (_meshInitialized) return;
    _meshInitialized = true;

    // Delay to ensure providers and UI are ready
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    try {
      // Check if mesh identity exists first
      final hasIdentity = ref.read(hasIdentityProvider);
      if (!hasIdentity) {
        debugPrint('Skipping mesh init - no identity yet');
        return;
      }

      // Start mesh networking if available
      final meshAvailable = ref.read(meshAvailableProvider);
      if (meshAvailable) {
        await ref.read(meshNetworkProvider.notifier).start();
        debugPrint('Mesh networking started automatically');
      }

      // Initialize Matrix sync listener for real-time message updates
      // This starts background sync and listens for conversation updates
      ref.read(matrixSyncListenerProvider);
      debugPrint('Matrix sync listener initialized');
    } catch (e, stack) {
      debugPrint('Failed to start mesh networking: $e');
      debugPrint('Stack trace: $stack');
      // Non-critical error - app can continue without mesh
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for Rally cleanup - must be in build method
    ref.listen(rallyCleanupProvider, (previous, next) {
      next.whenData((deletedCount) {
        if (deletedCount > 0) {
          debugPrint('Rally cleanup: deleted $deletedCount expired messages');
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => _toggleDemoMode(ref),
          child: Text(ref.watch(appDemoModeProvider) ? 'Kinu (Demo)' : 'Kinu'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? Column(
              children: [
                const MeshStatusBanner(),
                _buildMatrixSetupBanner(),
                const Expanded(child: ChatListView()),
              ],
            )
          : _selectedIndex == 1
              ? const RallyScreen()
              : const SettingsScreen(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                _showNewConversationOptions();
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Rally',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  /// Build Matrix setup banner if not authenticated
  /// Note: With unified auth, Matrix is auto-connected via Kinu login
  Widget _buildMatrixSetupBanner() {
    // With unified auth, if user is logged into Kinu, Matrix should be connected
    final isKinuAuthenticated = ref.watch(isAuthenticatedProvider);
    final isMatrixAuthenticated = ref.watch(isMatrixAuthenticatedProvider);

    // Hide banner if logged into Kinu (Matrix will auto-connect)
    if (isKinuAuthenticated || isMatrixAuthenticated) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set up cloud messaging',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Connect to Matrix for cross-device sync',
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed(MatrixAuthScreen.routeName);
            },
            child: const Text('Set Up'),
          ),
        ],
      ),
    );
  }

  void _showNewConversationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('New Chat'),
              subtitle: const Text('Start a direct message'),
              onTap: () {
                Navigator.pop(context);
                _showNewConversationDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('New Group'),
              subtitle: const Text('Create an encrypted group chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewConversationDialog() {
    final handleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: TextField(
          controller: handleController,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'theirhandle',
            prefixText: '@',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          autocorrect: false,
          enableSuggestions: false,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              var handle = handleController.text.trim().toLowerCase();
              // Remove @ prefix if user typed it
              if (handle.startsWith('@')) {
                handle = handle.substring(1);
              }
              if (handle.isNotEmpty) {
                Navigator.pop(context);
                // Convert handle to Matrix user ID
                final matrixUserId = '@$handle:kinuchat.com';
                await _createConversation(matrixUserId, handle);
              }
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  Future<void> _createConversation(String matrixUserId, String displayName) async {
    try {
      final repository = ref.read(conversationRepositoryProvider);
      final conversation = await repository.createDirectMessage(
        recipientId: matrixUserId,
        recipientName: '@$displayName',
      );

      if (!mounted) {
        return;
      }

      // Invalidate conversations cache so it includes the new one
      ref.invalidate(conversationsProvider);

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(conversationId: conversation.id),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create conversation: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _toggleDemoMode(WidgetRef ref) {
    final current = ref.read(appDemoModeProvider);
    ref.read(appDemoModeProvider.notifier).state = !current;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!current ? 'Demo mode enabled' : 'Demo mode disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      // Logout from Kinu account (primary)
      await ref.read(accountProvider.notifier).logout();

      // Also logout from Matrix
      try {
        await ref.read(matrixAuthProvider.notifier).logout();
      } catch (e) {
        debugPrint('Matrix logout failed: $e');
      }

      // Optionally delete local identity
      try {
        await ref.read(identityProvider.notifier).deleteIdentity();
      } catch (e) {
        debugPrint('Identity deletion failed: $e');
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// Chat list view
class ChatListView extends ConsumerWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoMode = ref.watch(appDemoModeProvider);

    // Show demo conversations when in demo mode
    if (demoMode) {
      final demoConversations = ref.watch(demoConversationsProvider);
      return ListView.builder(
        itemCount: demoConversations.length,
        itemBuilder: (context, index) {
          final conversation = demoConversations[index];
          return DemoConversationListItem(conversation: conversation);
        },
      );
    }

    final conversationsAsync = ref.watch(conversationsProvider);

    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'No conversations yet',
                  style: AppTypography.title,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Tap + to start a new chat',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(conversationsProvider.future),
          child: ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ConversationListItem(conversation: conversation);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        // Check if this is an offline/connectivity error
        final isOffline = isOfflineException(error);
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOffline ? Icons.wifi_off : Icons.error_outline,
                  size: 64,
                  color: isOffline ? Colors.orange.shade400 : AppColors.error,
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  isOffline 
                      ? 'You\'re offline'
                      : 'Failed to load conversations',
                  style: AppTypography.title,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  isOffline
                      ? 'Enable mesh mode to chat with nearby people via Bluetooth'
                      : 'Please check your connection and try again',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.lg),
                if (isOffline)
                  FilledButton.icon(
                    onPressed: () async {
                      await ref.read(meshNetworkProvider.notifier).start();
                      ref.invalidate(conversationsProvider);
                    },
                    icon: const Icon(Icons.bluetooth_connected),
                    label: const Text('Enable Mesh Mode'),
                  )
                else
                  FilledButton(
                    onPressed: () => ref.invalidate(conversationsProvider),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Conversation list item widget
class ConversationListItem extends StatelessWidget {
  const ConversationListItem({
    required this.conversation,
    super.key,
  });

  final dynamic conversation;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          (conversation.name ?? 'U').substring(0, 1).toUpperCase(),
        ),
      ),
      title: Text(
        conversation.name ?? 'Unknown',
        style: AppTypography.body.copyWith(
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.w600
              : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessageAt != null
            ? _formatTimestamp(conversation.lastMessageAt)
            : 'No messages yet',
        style: AppTypography.bodySmall,
      ),
      trailing: conversation.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversationId: conversation.id),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Demo conversation list item widget
class DemoConversationListItem extends StatelessWidget {
  const DemoConversationListItem({
    required this.conversation,
    super.key,
  });

  final DemoConversation conversation;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: conversation.isGroup
            ? Colors.purple.shade100
            : Colors.blue.shade100,
        child: conversation.isGroup
            ? Icon(Icons.group, color: Colors.purple.shade700)
            : Text(
                conversation.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.blue.shade700),
              ),
      ),
      title: Text(
        conversation.name,
        style: AppTypography.body.copyWith(
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.w600
              : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'No messages yet',
        style: AppTypography.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessageAt != null)
            Text(
              _formatTimestamp(conversation.lastMessageAt!),
              style: AppTypography.caption,
            ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        // In demo mode, just show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo chat with ${conversation.name}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
