import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/auth_providers.dart';
import 'onboarding/onboarding_screen.dart';
import 'home/home_screen.dart';

/// Splash screen that checks for existing account and routes accordingly
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Delay minimum splash time, then trigger navigation check
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _checkAndNavigate();
      }
    });
  }

  void _checkAndNavigate() {
    if (_hasNavigated || !mounted) return;

    final accountState = ref.read(accountProvider);

    // Check Kinu account auth state
    switch (accountState.status) {
      case AccountStatus.unknown:
        // Still loading, listen for changes in build method
        break;
      case AccountStatus.authenticated:
        _navigate(isAuthenticated: true);
        break;
      case AccountStatus.unauthenticated:
        _navigate(isAuthenticated: false);
        break;
    }
  }

  void _navigate({required bool isAuthenticated}) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    if (isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(OnboardingScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch account provider to react to state changes
    ref.listen<AccountState>(accountProvider, (previous, next) {
      if (!_hasNavigated && mounted) {
        if (next.status != AccountStatus.unknown) {
          _navigate(isAuthenticated: next.isAuthenticated);
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Spacing.radiusXl),
              ),
              child: Icon(
                Icons.share,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'Kinu',
              style: AppTypography.display.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Hybrid Cloud/Mesh Messaging',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: Spacing.xxl),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
