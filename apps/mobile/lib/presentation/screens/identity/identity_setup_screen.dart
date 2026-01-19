import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import '../../../core/providers/providers.dart';
import '../home/home_screen.dart';

/// Identity setup screen for creating a new identity
class IdentitySetupScreen extends ConsumerStatefulWidget {
  const IdentitySetupScreen({super.key});

  static const routeName = '/identity-setup';

  @override
  ConsumerState<IdentitySetupScreen> createState() =>
      _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends ConsumerState<IdentitySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _createIdentity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final displayName = _displayNameController.text.trim();

      // Generate identity
      await ref.read(identityProvider.notifier).generateIdentity(
            displayName: displayName.isEmpty ? null : displayName,
          );

      if (!mounted) {
        return;
      }

      // Navigate to home screen
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create identity: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Identity'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Your Identity',
                  style: AppTypography.headline,
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'Your identity is securely generated on your device. '
                  'You can optionally add a display name.',
                  style: AppTypography.body.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name (Optional)',
                    hintText: 'How should others see you?',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  validator: (value) {
                    if (value != null && value.trim().length > 50) {
                      return 'Display name must be 50 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Spacing.xl),
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.lightPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Spacing.radiusMd),
                    border: Border.all(
                      color: AppColors.lightPrimary.withValues(alpha: 0.3),
                    ),
                  ),
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
                            'Privacy First',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        '• Your identity is generated using cryptographic keys\n'
                        '• No phone number or email required\n'
                        '• Keys are stored securely on your device\n'
                        '• You can export your identity for backup',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isGenerating ? null : _createIdentity,
                    child: _isGenerating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Identity'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
