import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/meshlink_core.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/providers.dart';
import '../home/home_screen.dart';
import 'handle_selection_screen.dart';
import 'recovery_screen.dart';

/// Login screen for existing users
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/auth/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _handleController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _show2FAField = false;
  String? _errorMessage;

  @override
  void dispose() {
    _handleController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(accountProvider.notifier).login(
            handle: _handleController.text.trim(),
            password: _passwordController.text,
            totpCode: _show2FAField ? _totpController.text.trim() : null,
          );

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        HomeScreen.routeName,
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      if (e.is2FARequired) {
        setState(() {
          _show2FAField = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Login failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithPasskey() async {
    // Need handle for passkey auth
    final handle = _handleController.text.trim();
    if (handle.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your handle first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final passkeyService = ref.read(passkeyServiceProvider);
      final token = await passkeyService.authenticateWithPasskey(handle);

      if (token.isNotEmpty) {
        // Store token and get account info
        // The passkey auth endpoint should return everything we need
        // For now, just navigate to home - the account provider will
        // need to be updated to handle passkey auth tokens
        if (!mounted) return;

        Navigator.of(context).pushNamedAndRemoveUntil(
          HomeScreen.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Passkey login failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: AppTypography.headline,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Sign in to access your messages.',
                  style: AppTypography.body.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                // Passkey button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithPasskey,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Continue with Passkey'),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Theme.of(context).dividerColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                      child: Text(
                        'or sign in with password',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Theme.of(context).dividerColor),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
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
                // Handle field
                TextFormField(
                  controller: _handleController,
                  decoration: const InputDecoration(
                    labelText: 'Handle',
                    hintText: 'yourhandle',
                    prefixText: '@',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Handle is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Spacing.md),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
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
                  textInputAction:
                      _show2FAField ? TextInputAction.next : TextInputAction.done,
                  onFieldSubmitted: _show2FAField ? null : (_) => _loginWithPassword(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                // 2FA field (shown when required)
                if (_show2FAField) ...[
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    controller: _totpController,
                    decoration: const InputDecoration(
                      labelText: '2FA Code',
                      hintText: 'Enter 6-digit code',
                      prefixIcon: Icon(Icons.security),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 9, // Allow backup codes too
                    onFieldSubmitted: (_) => _loginWithPassword(),
                    validator: (value) {
                      if (_show2FAField && (value == null || value.trim().isEmpty)) {
                        return '2FA code is required';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: Spacing.md),
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RecoveryScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                // Sign in button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _loginWithPassword,
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
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                // Create account link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(
                        HandleSelectionScreen.routeName,
                      );
                    },
                    child: const Text("Don't have an account? Create one"),
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
