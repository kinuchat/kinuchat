import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/meshlink_core.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/providers.dart';

/// Screen for account deletion with confirmation
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _understandsConsequences = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canDelete {
    return _understandsConsequences &&
        _passwordController.text.isNotEmpty &&
        _confirmController.text.toLowerCase() == 'delete';
  }

  Future<void> _deleteAccount() async {
    if (!_canDelete) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount(_passwordController.text);

      if (!mounted) return;

      // Clear all local data
      await ref.read(accountProvider.notifier).logout();

      if (!mounted) return;

      // Show confirmation and navigate to start
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Account Deleted'),
          content: const Text(
            'Your account has been permanently deleted. All your data has been removed from our servers.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to delete account: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final handle = accountState.account?.handle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning header
              Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.radiusMd),
                  border: Border.all(color: AppColors.error),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      'Danger Zone',
                      style: AppTypography.headline.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Deleting your account is permanent and cannot be undone.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.error.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),

              // What will be deleted
              Text(
                'What will be deleted:',
                style: AppTypography.title,
              ),
              const SizedBox(height: Spacing.md),
              _buildDeleteItem(
                Icons.person_off,
                'Your account and profile',
                'Your handle @${handle ?? 'unknown'} will be released',
              ),
              _buildDeleteItem(
                Icons.chat_bubble_outline,
                'All your messages',
                'Message history from all conversations',
              ),
              _buildDeleteItem(
                Icons.contacts_outlined,
                'Your contacts',
                'All saved contacts and conversations',
              ),
              _buildDeleteItem(
                Icons.key_off,
                'Encryption keys',
                'Your device keys and encryption setup',
              ),
              _buildDeleteItem(
                Icons.devices,
                'Device sessions',
                'All logged-in devices will be signed out',
              ),
              const SizedBox(height: Spacing.xl),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Spacing.radiusMd),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
              ],

              // Confirmation checkbox
              CheckboxListTile(
                value: _understandsConsequences,
                onChanged: (value) {
                  setState(() {
                    _understandsConsequences = value ?? false;
                  });
                },
                title: Text(
                  'I understand that this action is permanent and all my data will be deleted forever.',
                  style: AppTypography.bodySmall,
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: Spacing.lg),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password to confirm',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Spacing.md),

              // Type DELETE to confirm
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                  hintText: 'DELETE',
                  prefixIcon: Icon(Icons.warning_amber),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Spacing.xl),

              // Delete button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  onPressed: _isLoading || !_canDelete ? null : _deleteAccount,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Delete My Account Forever'),
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: AppColors.error.withValues(alpha: 0.7),
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
}
