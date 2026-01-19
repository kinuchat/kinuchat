import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/providers.dart';
import '../auth/two_factor_setup_screen.dart';
import 'change_password_screen.dart';
import 'change_email_screen.dart';
import 'manage_2fa_screen.dart';
import 'devices_screen.dart';
import 'delete_account_screen.dart';

/// Account settings screen with security and profile options
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountProvider);
    final account = accountState.account;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          children: [
            // Profile section
            _buildSectionHeader(context, 'Profile'),
            _buildSettingsTile(
              context: context,
              icon: Icons.badge_outlined,
              title: 'Display Name',
              subtitle: account?.displayName ?? 'Not set',
              onTap: () {
                _showEditDisplayNameDialog(context, ref, account?.displayName);
              },
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.alternate_email,
              title: 'Handle',
              subtitle: account?.handle != null ? '@${account!.handle}' : 'Not set',
              trailing: const SizedBox.shrink(),
              onTap: null, // Handle cannot be changed
            ),

            const SizedBox(height: Spacing.lg),

            // Security section
            _buildSectionHeader(context, 'Security'),
            _buildSettingsTile(
              context: context,
              icon: Icons.lock_outline,
              title: 'Password',
              subtitle: account?.hasPassword == true ? 'Password set' : 'No password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.fingerprint,
              title: 'Passkey',
              subtitle: account?.hasPasskey == true ? 'Passkey configured' : 'Not configured',
              onTap: () {
                _showPasskeyOptions(context, ref, account?.hasPasskey == true);
              },
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.security,
              title: 'Two-Factor Authentication',
              subtitle: account?.totpEnabled == true ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: account?.totpEnabled == true,
                onChanged: (enabled) {
                  if (enabled) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TwoFactorSetupScreen(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Manage2FAScreen(),
                      ),
                    );
                  }
                },
              ),
              onTap: () {
                if (account?.totpEnabled == true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Manage2FAScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TwoFactorSetupScreen(),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: Spacing.lg),

            // Recovery section
            _buildSectionHeader(context, 'Recovery'),
            _buildSettingsTile(
              context: context,
              icon: Icons.email_outlined,
              title: 'Recovery Email',
              subtitle: _getEmailSubtitle(account),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangeEmailScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.lg),

            // Devices section
            _buildSectionHeader(context, 'Devices'),
            _buildSettingsTile(
              context: context,
              icon: Icons.devices,
              title: 'Manage Devices',
              subtitle: 'View and revoke device access',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DevicesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.xl),

            // Danger zone
            _buildSectionHeader(context, 'Danger Zone'),
            _buildDangerTile(
              context: context,
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Sign out of this device',
              onTap: () => _showLogoutConfirmation(context, ref),
            ),
            _buildDangerTile(
              context: context,
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeleteAccountScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
  }

  String _getEmailSubtitle(dynamic account) {
    if (account == null) return 'Not set';
    if (account.hasEmail != true) return 'Not set';
    if (account.emailVerified == true) return 'Verified';
    return 'Not verified';
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
          color: title == 'Danger Zone'
              ? AppColors.error
              : Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: AppTypography.body),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDangerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.error),
      title: Text(
        title,
        style: AppTypography.body.copyWith(color: AppColors.error),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.error.withValues(alpha: 0.7),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.error),
      onTap: onTap,
    );
  }

  void _showEditDisplayNameDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentName,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your display name',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                Navigator.pop(context);
                try {
                  await ref.read(accountProvider.notifier).updateDisplayName(newName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Display name updated')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPasskeyOptions(BuildContext context, WidgetRef ref, bool hasPasskey) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasPasskey) ...[
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Set Up Passkey'),
                subtitle: const Text('Use biometrics to sign in'),
                onTap: () {
                  Navigator.pop(context);
                  _setupPasskey(context, ref);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Replace Passkey'),
                subtitle: const Text('Set up a new passkey'),
                onTap: () {
                  Navigator.pop(context);
                  _setupPasskey(context, ref);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text(
                  'Remove Passkey',
                  style: TextStyle(color: AppColors.error),
                ),
                subtitle: Text(
                  'You will need a password to sign in',
                  style: TextStyle(color: AppColors.error.withValues(alpha: 0.7)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removePasskey(context, ref);
                },
              ),
            ],
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _setupPasskey(BuildContext context, WidgetRef ref) async {
    try {
      final account = ref.read(currentAccountProvider);
      if (account == null) {
        throw Exception('No account found');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setting up passkey...')),
      );
      await ref.read(passkeyServiceProvider).registerPasskey(
            email: account.handle,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passkey configured successfully')),
        );
        ref.read(accountProvider.notifier).refresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set up passkey: $e')),
        );
      }
    }
  }

  Future<void> _removePasskey(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Passkey?'),
        content: const Text(
          'You will need to use your password to sign in after removing the passkey.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passkey removal coming soon')),
      );
    }
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'You will need to sign in again to access your messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(accountProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to sign out: $e')),
                  );
                }
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
