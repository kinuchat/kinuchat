import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/providers.dart';
import '../profile/qr_code_screen.dart';
import 'account_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'mesh_network_settings_screen.dart';
import 'bridge_settings_screen.dart';
import 'matrix_server_settings_screen.dart';
import 'theme_settings_screen.dart';
import 'help_screen.dart';
import 'support_screen.dart';

/// Main settings screen with categorized sections
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountProvider);
    final identityAsync = ref.watch(identityProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          children: [
            // Profile header
            _buildProfileHeader(context, ref, accountState, identityAsync),
            const SizedBox(height: Spacing.lg),

            // Account section
            _buildSectionHeader(context, 'Account'),
            _buildSettingsTile(
              context: context,
              icon: Icons.person_outline,
              title: 'Account Settings',
              subtitle: 'Password, email, security',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.lg),

            // Privacy section
            _buildSectionHeader(context, 'Privacy'),
            _buildSettingsTile(
              context: context,
              icon: Icons.lock_outline,
              title: 'Privacy',
              subtitle: 'Message settings, visibility',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.security_outlined,
              title: 'Security',
              subtitle: 'Encryption keys, verification',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatrixServerSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.lg),

            // Notifications section
            _buildSectionHeader(context, 'Notifications'),
            _buildSettingsTile(
              context: context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Push notifications, sounds',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.lg),

            // Network section
            _buildSectionHeader(context, 'Network'),
            _buildSettingsTile(
              context: context,
              icon: Icons.wifi_outlined,
              title: 'Mesh Network',
              subtitle: 'Bluetooth, local connectivity',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MeshNetworkSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.hub_outlined,
              title: 'Bridge Mode',
              subtitle: 'Relay messages for others',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BridgeSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.cloud_outlined,
              title: 'Matrix Server',
              subtitle: 'Cloud messaging settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatrixServerSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.lg),

            // Appearance section
            _buildSectionHeader(context, 'Appearance'),
            _buildSettingsTile(
              context: context,
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: 'Dark mode, colors',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.lg),

            // About section
            _buildSectionHeader(context, 'About'),
            _buildSettingsTile(
              context: context,
              icon: Icons.info_outline,
              title: 'About Kinu',
              subtitle: 'Version, licenses',
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            _buildSupportTile(context, ref),
            _buildSettingsTile(
              context: context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'FAQ, contact us',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpScreen(),
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

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    AccountState accountState,
    AsyncValue<dynamic> identityAsync,
  ) {
    final displayName = accountState.account?.displayName ??
        identityAsync.valueOrNull?.displayName ??
        'User';
    final handle = accountState.account?.handle;
    final supporterBadge = ref.watch(supporterBadgeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: AppTypography.headline.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: AppTypography.title,
                    ),
                    if (supporterBadge.isVisible) ...[
                      const SizedBox(width: Spacing.sm),
                      Text(
                        supporterBadge.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ],
                ),
                if (handle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$handle',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QrCodeScreen(),
                ),
              );
            },
            tooltip: 'Show QR Code',
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

  Widget _buildSupportTile(BuildContext context, WidgetRef ref) {
    final supporterStatus = ref.watch(supporterStatusProvider);
    final tier = supporterStatus.tier;
    final isSupporter = tier != SupporterTier.none;

    return ListTile(
      leading: Icon(
        isSupporter ? Icons.favorite : Icons.favorite_border,
        color: isSupporter ? Colors.red : null,
      ),
      title: Row(
        children: [
          Text('Support Kinu', style: AppTypography.body),
          if (isSupporter) ...[
            const SizedBox(width: Spacing.sm),
            Text(
              tier.badgeEmoji,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ],
      ),
      subtitle: Text(
        isSupporter ? '${tier.displayName} supporter' : 'Help keep Kinu free',
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SupportScreen(),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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

  void _showComingSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Kinu',
      applicationVersion: '0.1.0',
      applicationIcon: Icon(
        Icons.hub,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        const Text(
          'A privacy-first messaging app with mesh networking capabilities.',
        ),
      ],
    );
  }
}
