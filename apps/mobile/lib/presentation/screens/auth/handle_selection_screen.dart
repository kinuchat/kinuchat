import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/providers.dart';
import 'display_name_screen.dart';
import 'login_screen.dart';

/// Screen for selecting a unique @handle
class HandleSelectionScreen extends ConsumerStatefulWidget {
  const HandleSelectionScreen({super.key});

  static const routeName = '/auth/handle';

  @override
  ConsumerState<HandleSelectionScreen> createState() =>
      _HandleSelectionScreenState();
}

class _HandleSelectionScreenState extends ConsumerState<HandleSelectionScreen> {
  final _handleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isChecking = false;
  bool? _isAvailable;
  String? _errorMessage;
  Timer? _debounceTimer;

  // Handle validation regex (must start with letter, 3-20 chars, alphanumeric + underscore)
  static final _handleRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{2,19}$');

  @override
  void dispose() {
    _handleController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onHandleChanged(String value) {
    // Reset state
    setState(() {
      _isAvailable = null;
      _errorMessage = null;
    });

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Skip if empty or invalid format
    if (value.isEmpty) return;
    if (!_handleRegex.hasMatch(value)) {
      setState(() {
        _errorMessage = _getFormatError(value);
      });
      return;
    }

    // Debounce the API call
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkAvailability(value);
    });
  }

  String? _getFormatError(String value) {
    if (value.length < 3) {
      return 'Handle must be at least 3 characters';
    }
    if (value.length > 20) {
      return 'Handle must be at most 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z]').hasMatch(value)) {
      return 'Handle must start with a letter';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }

  Future<void> _checkAvailability(String handle) async {
    if (!mounted) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final response = await ref.read(accountProvider.notifier).checkHandle(handle);

      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _isAvailable = response.available;
        if (!response.available) {
          _errorMessage = 'This handle is already taken';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _errorMessage = 'Failed to check availability';
      });
    }
  }

  void _continue() {
    if (_formKey.currentState!.validate() && _isAvailable == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisplayNameSetupScreen(
            handle: _handleController.text.trim().toLowerCase(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _isAvailable == true && !_isChecking;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Handle'),
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
                  'Choose Your Handle',
                  style: AppTypography.headline,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'This is how others will find you. Choose something memorable.',
                  style: AppTypography.body.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                TextFormField(
                  controller: _handleController,
                  decoration: InputDecoration(
                    labelText: 'Handle',
                    hintText: 'yourhandle',
                    prefixText: '@',
                    prefixIcon: const Icon(Icons.alternate_email),
                    suffixIcon: _buildSuffixIcon(),
                    errorText: _errorMessage,
                  ),
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: _onHandleChanged,
                  onFieldSubmitted: (_) => _continue(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Handle is required';
                    }
                    return _getFormatError(value);
                  },
                ),
                const SizedBox(height: Spacing.md),
                _buildHelpText(),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canContinue ? _continue : null,
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Already have an account? Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isChecking) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (_isAvailable == false || _errorMessage != null) {
      return const Icon(Icons.error, color: Colors.red);
    }

    return null;
  }

  Widget _buildHelpText() {
    return Container(
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
                'Handle Rules',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '• 3-20 characters\n'
            '• Must start with a letter\n'
            '• Letters, numbers, and underscores only\n'
            '• This cannot be changed later',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
