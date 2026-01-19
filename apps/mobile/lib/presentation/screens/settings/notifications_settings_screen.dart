import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/settings_provider.dart';
import 'quiet_hours_screen.dart';

/// Notifications settings screen
class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          _buildSectionHeader(context, 'Push Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive notifications for new messages'),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setNotificationsEnabled(value);
            },
          ),
          const Divider(height: Spacing.xl),
          _buildSectionHeader(context, 'Sounds'),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Message Sounds'),
            subtitle: const Text('Play a sound for new messages'),
            value: settings.messageSoundsEnabled,
            onChanged: settings.notificationsEnabled
                ? (value) {
                    ref.read(settingsProvider.notifier).setMessageSoundsEnabled(value);
                  }
                : null,
          ),
          const Divider(height: Spacing.xl),
          _buildSectionHeader(context, 'Do Not Disturb'),
          ListTile(
            leading: Icon(
              settings.quietHoursEnabled
                  ? Icons.do_not_disturb_on
                  : Icons.do_not_disturb_on_outlined,
              color: settings.isInQuietHours
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('Schedule Quiet Hours'),
            subtitle: Text(
              settings.quietHoursEnabled
                  ? (settings.isInQuietHours
                      ? 'Active now'
                      : 'Enabled')
                  : 'Mute notifications during specific times',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QuietHoursScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: Spacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Text(
              'You can also manage notification permissions in your device settings.',
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
}
