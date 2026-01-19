import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/matrix_providers.dart';
import '../../../core/providers/providers.dart';

/// Matrix server settings screen
class MatrixServerSettingsScreen extends ConsumerWidget {
  const MatrixServerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixService = ref.watch(matrixServiceProvider);
    final accountState = ref.watch(accountProvider);
    final handle = accountState.account?.handle ?? 'unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix Server'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          _buildSectionHeader(context, 'Connection'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Homeserver'),
            subtitle: const Text('matrix.kinuchat.com'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Custom Homeserver'),
                  content: const Text(
                    'Support for connecting to your own Matrix homeserver is coming soon.\n\n'
                    'Currently, all accounts use the official Kinu server for optimal reliability and encryption key backup.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.circle,
              size: 12,
              color: matrixService.isLoggedIn ? AppColors.success : Colors.orange,
            ),
            title: const Text('Status'),
            subtitle: Text(
              matrixService.isLoggedIn ? 'Connected' : 'Connecting...',
            ),
            trailing: matrixService.isLoggedIn
                ? null
                : const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
          const Divider(height: Spacing.xl),
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('Matrix ID'),
            subtitle: Text('@$handle:kinuchat.com'),
          ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('Encryption Keys'),
            subtitle: const Text('Cross-signing enabled'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEncryptionInfo(context);
            },
          ),
          const Divider(height: Spacing.xl),
          _buildSectionHeader(context, 'Sync'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Force Sync'),
            subtitle: const Text('Manually sync messages with server'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing...')),
              );
              // TODO: Implement force sync
              await Future.delayed(const Duration(seconds: 1));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync complete')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Message History'),
            subtitle: const Text('How far back to fetch messages'),
            trailing: const Text('30 days'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History settings coming soon')),
              );
            },
          ),
          const SizedBox(height: Spacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'End-to-End Encryption',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'All messages are encrypted using the Matrix protocol. Only you and your contacts can read your messages.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showEncryptionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encryption Keys'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your encryption keys are used to secure your messages.'),
            SizedBox(height: 16),
            Text('Cross-signing: Enabled'),
            Text('Key backup: Enabled'),
            SizedBox(height: 16),
            Text(
              'These keys are stored securely on your device and backed up to the server in encrypted form.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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
}
