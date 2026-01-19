import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/settings_provider.dart';

/// Theme settings screen
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currentTheme = settings.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          _buildThemeOption(
            context: context,
            ref: ref,
            title: 'System Default',
            subtitle: 'Follow device settings',
            icon: Icons.settings_suggest_outlined,
            mode: ThemeMode.system,
            isSelected: currentTheme == ThemeMode.system,
          ),
          _buildThemeOption(
            context: context,
            ref: ref,
            title: 'Light',
            subtitle: 'Always use light theme',
            icon: Icons.light_mode_outlined,
            mode: ThemeMode.light,
            isSelected: currentTheme == ThemeMode.light,
          ),
          _buildThemeOption(
            context: context,
            ref: ref,
            title: 'Dark',
            subtitle: 'Always use dark theme',
            icon: Icons.dark_mode_outlined,
            mode: ThemeMode.dark,
            isSelected: currentTheme == ThemeMode.dark,
          ),
          const SizedBox(height: Spacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Text(
              'The app will use the selected theme. System default follows your device\'s theme settings.',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: AppTypography.body.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : null,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        ref.read(settingsProvider.notifier).setThemeMode(mode);
      },
    );
  }
}
