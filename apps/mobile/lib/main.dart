import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import 'core/providers/database_providers.dart';
import 'core/providers/settings_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/identity/identity_setup_screen.dart';
import 'presentation/screens/matrix/matrix_auth_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/auth/handle_selection_screen.dart';
import 'presentation/screens/auth/login_screen.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Create provider container for early initialization
  final container = ProviderContainer();

  try {
    // Pre-initialize database to ensure it's ready before app starts
    // This prevents crashes when accessing database on first launch
    await container.read(asyncDatabaseProvider.future);
  } catch (e) {
    // Database initialization failed - log but continue
    // The app will show appropriate error UI
    debugPrint('Database initialization warning: $e');
  } finally {
    container.dispose();
  }

  runApp(
    const ProviderScope(
      child: MeshLinkApp(),
    ),
  );
}

class MeshLinkApp extends ConsumerWidget {
  const MeshLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Kinu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        IdentitySetupScreen.routeName: (context) => const IdentitySetupScreen(),
        MatrixAuthScreen.routeName: (context) => const MatrixAuthScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        HandleSelectionScreen.routeName: (context) => const HandleSelectionScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
      },
    );
  }
}
