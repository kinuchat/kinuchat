import 'package:flutter/material.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import '../auth/handle_selection_screen.dart';

/// Onboarding screen explaining MeshLink features
/// Based on Section 8.1 of the specification
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Welcome to Kinu',
      description:
          'Encrypted messaging that works everywhere, even without internet.',
      icon: Icons.waving_hand_outlined,
    ),
    const OnboardingPage(
      title: 'Always Connected',
      description:
          'Strong signal? Messages go through encrypted cloud servers.\n\n'
          'Weak signal? Messages hop through nearby Kinu users via Bluetooth.\n\n'
          'You don\'t have to do anything. It just works.',
      icon: Icons.cloud_outlined,
    ),
    const OnboardingPage(
      title: 'Your Messages, Your Business',
      description:
          '✓ End-to-end encrypted\n'
          '✓ No phone number required\n'
          '✓ No data collection\n'
          '✓ Open protocol',
      icon: Icons.lock_outlined,
    ),
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: MeshLinkAnimations.statusTransition,
        curve: Curves.easeInOut,
      );
    } else {
      _getStarted();
    }
  }

  void _getStarted() {
    Navigator.of(context).pushReplacementNamed(HandleSelectionScreen.routeName);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: Spacing.xs,
                        ),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual onboarding page
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: Spacing.xxl),
          Text(
            title,
            style: AppTypography.display,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            description,
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
