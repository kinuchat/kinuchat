import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/providers.dart';
import '../auth/two_factor_setup_screen.dart';

/// Screen for managing two-factor authentication settings
class Manage2FAScreen extends ConsumerStatefulWidget {
  const Manage2FAScreen({super.key});

  @override
  ConsumerState<Manage2FAScreen> createState() => _Manage2FAScreenState();
}

class _Manage2FAScreenState extends ConsumerState<Manage2FAScreen> {
  bool _isLoading = false;
  List<String>? _backupCodes;

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final totpEnabled = accountState.account?.totpEnabled == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: totpEnabled
                    ? Colors.green.shade50
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Spacing.radiusMd),
                border: Border.all(
                  color: totpEnabled ? Colors.green : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: totpEnabled ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      totpEnabled ? Icons.security : Icons.security_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totpEnabled ? '2FA Enabled' : '2FA Disabled',
                          style: AppTypography.title.copyWith(
                            color: totpEnabled ? Colors.green.shade700 : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totpEnabled
                              ? 'Your account is protected with an authenticator app'
                              : 'Add an extra layer of security to your account',
                          style: AppTypography.bodySmall.copyWith(
                            color: totpEnabled
                                ? Colors.green.shade600
                                : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),

            if (totpEnabled) ...[
              // Backup codes section
              Text(
                'Backup Codes',
                style: AppTypography.title,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Use backup codes to sign in if you lose access to your authenticator app.',
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: Spacing.md),

              if (_backupCodes != null) ...[
                _buildBackupCodesDisplay(),
                const SizedBox(height: Spacing.md),
              ],

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _generateNewBackupCodes,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _backupCodes == null
                        ? 'View Backup Codes'
                        : 'Generate New Codes',
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),

              // Danger zone
              Text(
                'Danger Zone',
                style: AppTypography.title.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.radiusMd),
                  border: Border.all(color: AppColors.error),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disable Two-Factor Authentication',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'This will remove the extra security from your account. You will only need your password to sign in.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                        ),
                        onPressed: () => _showDisable2FADialog(),
                        child: const Text('Disable 2FA'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Enable 2FA section
              Text(
                'Why Enable 2FA?',
                style: AppTypography.title,
              ),
              const SizedBox(height: Spacing.md),
              _buildBenefitItem(
                Icons.lock,
                'Enhanced Security',
                'Protect your account even if your password is compromised',
              ),
              _buildBenefitItem(
                Icons.phone_android,
                'Device Verification',
                'Verify sign-ins with your phone or authenticator app',
              ),
              _buildBenefitItem(
                Icons.backup,
                'Backup Codes',
                'Get recovery codes in case you lose your device',
              ),
              const SizedBox(height: Spacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TwoFactorSetupScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.security),
                  label: const Text('Enable Two-Factor Authentication'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Spacing.radiusSm),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCodesDisplay() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _backupCodes!.length; i += 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    _backupCodes![i],
                    style: AppTypography.body.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (i + 1 < _backupCodes!.length)
                    Text(
                      _backupCodes![i + 1],
                      style: AppTypography.body.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _backupCodes!.join('\n')),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup codes copied')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy All'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateNewBackupCodes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.getBackupCodes();

      if (!mounted) return;

      setState(() {
        _backupCodes = response.codes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get backup codes: $e')),
      );
    }
  }

  void _showDisable2FADialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable 2FA?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a code from your authenticator app to confirm disabling two-factor authentication.',
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                hintText: '000000',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;

              Navigator.pop(context);

              try {
                final authService = ref.read(authServiceProvider);
                await authService.disableTotp(code);
                ref.read(accountProvider.notifier).refresh();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Two-factor authentication disabled'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to disable 2FA: $e')),
                );
              }
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }
}
