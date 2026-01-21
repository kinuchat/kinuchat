import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/settings_provider.dart';
import 'bridge_settings_screen.dart';

/// Mesh network settings screen
class MeshNetworkSettingsScreen extends ConsumerWidget {
  const MeshNetworkSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesh Network'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          _buildSectionHeader(context, 'Bluetooth Mesh'),
          SwitchListTile(
            secondary: const Icon(Icons.bluetooth),
            title: const Text('Enable Mesh Network'),
            subtitle: const Text('Connect with nearby devices via Bluetooth'),
            value: settings.meshNetworkEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setMeshNetworkEnabled(value);
              if (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mesh networking enabled. Scanning for nearby devices...'),
                  ),
                );
              }
            },
          ),
          const Divider(height: Spacing.xl),
          _buildSectionHeader(context, 'Status'),
          ListTile(
            leading: Icon(
              Icons.circle,
              size: 12,
              color: settings.meshNetworkEnabled ? AppColors.success : Colors.grey,
            ),
            title: const Text('Connection Status'),
            subtitle: Text(
              settings.meshNetworkEnabled ? 'Active - Scanning' : 'Disabled',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Nearby Devices'),
            subtitle: const Text('0 devices found'),
            trailing: const Icon(Icons.chevron_right),
            enabled: settings.meshNetworkEnabled,
            onTap: settings.meshNetworkEnabled
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device discovery coming soon')),
                    );
                  }
                : null,
          ),
          const Divider(height: Spacing.xl),
          _buildSectionHeader(context, 'Advanced'),
          ListTile(
            leading: const Icon(Icons.hub_outlined),
            title: const Text('Bridge Mode'),
            subtitle: const Text('Help relay messages for other users'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BridgeSettingsScreen(),
                ),
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
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'About Mesh Networking',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Mesh networking allows you to send messages to nearby contacts even without internet access. Messages are encrypted and can hop through multiple devices to reach their destination.',
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
}
