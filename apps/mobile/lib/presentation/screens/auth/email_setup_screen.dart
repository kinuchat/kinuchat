import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/meshlink_core.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/providers.dart';
import 'registration_complete_screen.dart';

/// Screen for optional email setup during registration
class EmailSetupScreen extends ConsumerStatefulWidget {
  const EmailSetupScreen({
    super.key,
    required this.handle,
    required this.displayName,
    required this.password,
  });

  final String handle;
  final String displayName;
  final String password;

  static const routeName = '/auth/email-setup';

  @override
  ConsumerState<EmailSetupScreen> createState() => _EmailSetupScreenState();
}

class _EmailSetupScreenState extends ConsumerState<EmailSetupScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isRegistering = false;
  bool _addEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    // If adding email, validate it
    if (_addEmail && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      await ref.read(accountProvider.notifier).register(
            handle: widget.handle,
            displayName: widget.displayName,
            password: widget.password,
            email: _addEmail ? _emailController.text.trim() : null,
          );

      if (!mounted) return;

      // Navigate to completion screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => RegistrationCompleteScreen(
            handle: widget.handle,
            displayName: widget.displayName,
          ),
        ),
        (route) => false, // Remove all previous routes
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Email'),
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
                  'Add Recovery Email?',
                  style: AppTypography.headline,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Adding an email allows you to recover your account if you lose access.',
                  style: AppTypography.body.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                // Toggle option
                SwitchListTile(
                  title: const Text('Add recovery email'),
                  subtitle: Text(
                    'Recommended for account recovery',
                    style: AppTypography.bodySmall,
                  ),
                  value: _addEmail,
                  onChanged: (value) {
                    setState(() {
                      _addEmail = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: Spacing.md),
                // Email field (shown when toggle is on)
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _addEmail
                      ? Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'your@email.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              enableSuggestions: false,
                              validator: (value) {
                                if (_addEmail) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: Spacing.md),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                // Privacy note
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
                            Icons.privacy_tip_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            'Privacy Note',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        _addEmail
                            ? 'Your email is encrypted before storage. We cannot read it, but can send recovery emails when you request them.'
                            : 'Without an email, you cannot recover your account if you forget your password. Make sure to keep your password safe.',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isRegistering ? null : _completeRegistration,
                    child: _isRegistering
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                if (!_addEmail)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _addEmail = true;
                        });
                      },
                      child: const Text('Add email instead'),
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
