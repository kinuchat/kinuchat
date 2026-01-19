import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/meshlink_core.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/providers/providers.dart';

/// Screen for setting up two-factor authentication
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  static const routeName = '/settings/2fa-setup';

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TotpSetupResponse? _setupResponse;
  List<String>? _backupCodes;
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _setupComplete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startSetup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.setupTotp();

      if (!mounted) return;

      setState(() {
        _setupResponse = response;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to set up 2FA: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.verifyTotp(_codeController.text.trim());

      if (!mounted) return;

      setState(() {
        _backupCodes = response.codes;
        _setupComplete = true;
        _isVerifying = false;
      });

      // Refresh account data to update 2FA status
      ref.read(accountProvider.notifier).refresh();
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
        _isVerifying = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Verification failed: $e';
        _isVerifying = false;
      });
    }
  }

  void _copySecret() {
    if (_setupResponse?.secret != null) {
      Clipboard.setData(ClipboardData(text: _setupResponse!.secret));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Secret copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_setupComplete && _backupCodes != null) {
      return _buildBackupCodesScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up 2FA'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication',
                        style: AppTypography.headline,
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        'Scan the QR code with your authenticator app (Google Authenticator, Authy, etc.)',
                        style: AppTypography.body.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
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
                              const Icon(Icons.error_outline,
                                  color: AppColors.error),
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
                      // QR Code
                      if (_setupResponse != null) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(Spacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(Spacing.radiusMd),
                            ),
                            child: QrImageView(
                              data: _setupResponse!.otpauthUrl,
                              version: QrVersions.auto,
                              size: 200,
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                        // Manual entry
                        Container(
                          padding: const EdgeInsets.all(Spacing.md),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(Spacing.radiusMd),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manual Entry',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),
                              Text(
                                "Can't scan? Enter this code manually:",
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                              const SizedBox(height: Spacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(Spacing.sm),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        borderRadius: BorderRadius.circular(
                                            Spacing.radiusSm),
                                      ),
                                      child: Text(
                                        _setupResponse!.secret,
                                        style: AppTypography.body.copyWith(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: _copySecret,
                                    tooltip: 'Copy secret',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Spacing.xl),
                        // Verification field
                        Text(
                          'Enter the 6-digit code from your authenticator app:',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: Spacing.md),
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Verification Code',
                            hintText: '000000',
                            prefixIcon: Icon(Icons.security),
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 6,
                          onFieldSubmitted: (_) => _verifyCode(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Code is required';
                            }
                            if (value.trim().length != 6) {
                              return 'Code must be 6 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Spacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isVerifying ? null : _verifyCode,
                            child: _isVerifying
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Verify and Enable 2FA'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBackupCodesScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Codes'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 40,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                '2FA Enabled Successfully',
                style: AppTypography.headline,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Save these backup codes in a secure place. You can use them to access your account if you lose your authenticator device.',
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              // Backup codes
              Container(
                width: double.infinity,
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
                        const SnackBar(
                          content: Text('Backup codes copied to clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy All'),
                  ),
                ],
              ),
              const Spacer(),
              // Warning
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(Spacing.radiusMd),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        'Each code can only be used once. Store them securely.',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
