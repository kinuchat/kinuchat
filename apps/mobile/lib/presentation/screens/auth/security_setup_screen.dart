import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import 'password_setup_screen.dart';

/// Screen for choosing security method during registration
class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({
    super.key,
    required this.handle,
    required this.displayName,
  });

  final String handle;
  final String displayName;

  static const routeName = '/auth/security-setup';

  @override
  ConsumerState<SecuritySetupScreen> createState() =>
      _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen> {
  bool _isSettingUpPasskey = false;

  Future<void> _setupPasskey() async {
    setState(() {
      _isSettingUpPasskey = true;
    });

    try {
      // TODO: Implement passkey setup with platform APIs
      // For now, show a message that passkey is coming soon
      // and redirect to password setup

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passkey support coming soon. Please use password for now.'),
        ),
      );

      // Navigate to password setup as fallback
      _setupWithPassword();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passkey setup failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSettingUpPasskey = false;
        });
      }
    }
  }

  void _setupWithPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PasswordSetupScreen(
          handle: widget.handle,
          displayName: widget.displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Your Account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Secure Your Account',
                style: AppTypography.headline,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Choose how you want to protect your account.',
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              // Passkey option (recommended)
              _SecurityOptionCard(
                icon: Icons.fingerprint,
                title: 'Set up Face ID / Touch ID',
                subtitle: 'Recommended - Most secure, no password to remember',
                recommended: true,
                onTap: _isSettingUpPasskey ? null : _setupPasskey,
                isLoading: _isSettingUpPasskey,
              ),
              const SizedBox(height: Spacing.md),
              // Divider with "or"
              Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    child: Text(
                      'or',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                ],
              ),
              const SizedBox(height: Spacing.md),
              // Password option
              _SecurityOptionCard(
                icon: Icons.lock_outline,
                title: 'Use Password Instead',
                subtitle: 'Traditional password authentication',
                onTap: _setupWithPassword,
              ),
              const Spacer(),
              // Info box
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Spacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          'Why Passkey?',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '• Synced across your Apple/Google devices\n'
                      '• Protected by your device biometrics\n'
                      '• Cannot be phished or stolen\n'
                      '• No password to forget',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityOptionCard extends StatelessWidget {
  const _SecurityOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.recommended = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool recommended;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: recommended ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        side: BorderSide(
          color: recommended
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: recommended ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: recommended
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Spacing.radiusMd),
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(
                        icon,
                        color: recommended
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
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
                          title,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: Spacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'RECOMMENDED',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
