import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../home/home_screen.dart';

/// Screen shown after successful registration
class RegistrationCompleteScreen extends ConsumerWidget {
  const RegistrationCompleteScreen({
    super.key,
    required this.handle,
    required this.displayName,
  });

  final String handle;
  final String displayName;

  static const routeName = '/auth/complete';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                'Welcome to Kinu!',
                style: AppTypography.headline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Your account has been created successfully.',
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xl),
              // Account summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Spacing.radiusMd),
                ),
                child: Column(
                  children: [
                    // Avatar placeholder
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : handle[0].toUpperCase(),
                        style: AppTypography.headline.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      displayName,
                      style: AppTypography.headline.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: Spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(Spacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alternate_email,
                            size: 14,
                            color:
                                Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            handle,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // What's next section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(Spacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's Next?",
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _NextStepItem(
                      icon: Icons.people_outline,
                      text: 'Find friends by their @handle',
                    ),
                    _NextStepItem(
                      icon: Icons.chat_bubble_outline,
                      text: 'Start a conversation',
                    ),
                    _NextStepItem(
                      icon: Icons.location_on_outlined,
                      text: 'Join a Rally channel nearby',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      HomeScreen.routeName,
                      (route) => false,
                    );
                  },
                  child: const Text('Start Messaging'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextStepItem extends StatelessWidget {
  const _NextStepItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            text,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
