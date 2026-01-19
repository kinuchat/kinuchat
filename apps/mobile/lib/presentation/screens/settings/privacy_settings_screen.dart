import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/settings_provider.dart';

/// Privacy settings screen
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _isExporting = false;

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final exportData = await authService.exportData();

      // Convert to pretty JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'exportedAt': exportData.exportedAt.toIso8601String(),
        'account': {
          'id': exportData.account.id,
          'handle': exportData.account.handle,
          'displayName': exportData.account.displayName,
          'hasEmail': exportData.account.hasEmail,
          'emailVerified': exportData.account.emailVerified,
          'createdAt': exportData.account.createdAt,
        },
        'devices': exportData.devices.map((d) => {
          'id': d.id,
          'name': d.name,
          'platform': d.platform,
          'firstSeen': d.firstSeen,
          'lastActive': d.lastActive,
        }).toList(),
        'security': {
          'hasPasskey': exportData.security.hasPasskey,
          'hasPassword': exportData.security.hasPassword,
          'totpEnabled': exportData.security.totpEnabled,
          'backupCodesRemaining': exportData.security.backupCodesRemaining,
        },
      });

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${tempDir.path}/kinu_data_export_$timestamp.json');
      await file.writeAsString(jsonString);

      // Share the file
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Kinu Data Export',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          _buildSectionHeader(context, 'Message Privacy'),
          SwitchListTile(
            secondary: const Icon(Icons.done_all),
            title: const Text('Read Receipts'),
            subtitle: const Text('Let others know when you\'ve read their messages'),
            value: settings.showReadReceipts,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setShowReadReceipts(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.edit_note),
            title: const Text('Typing Indicators'),
            subtitle: const Text('Show when you\'re typing a message'),
            value: settings.showTypingIndicators,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setShowTypingIndicators(value);
            },
          ),
          const Divider(height: Spacing.xl),
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            title: const Text('Export My Data'),
            subtitle: const Text('Download a copy of your account data'),
            trailing: _isExporting ? null : const Icon(Icons.chevron_right),
            enabled: !_isExporting,
            onTap: _isExporting ? null : _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Clear Message Cache'),
            subtitle: const Text('Remove locally cached messages'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearCacheDialog(context);
            },
          ),
          const SizedBox(height: Spacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Text(
              'Your messages are end-to-end encrypted. Only you and your contacts can read them.',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
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

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Message Cache?'),
        content: const Text(
          'This will remove locally cached messages. Your messages will be re-downloaded from the server when needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
