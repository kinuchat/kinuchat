import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/providers.dart';
import '../../../data/services/donation_service.dart';

/// Support/Donation screen
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supporterStatus = ref.watch(supporterStatusProvider);
    final productsAsync = ref.watch(donationProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Kinu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          // Current status card
          _buildStatusCard(context, supporterStatus),

          const SizedBox(height: Spacing.lg),

          // Benefits section
          _buildBenefitsSection(context),

          const SizedBox(height: Spacing.lg),

          // Donation tiers
          Text(
            'Support Tiers',
            style: AppTypography.title,
          ),
          const SizedBox(height: Spacing.md),

          productsAsync.when(
            data: (products) => products.isEmpty
                ? _buildNoProductsCard(context)
                : Column(
                    children: products
                        .map((p) => _buildProductCard(context, ref, p, supporterStatus))
                        .toList(),
                  ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(Spacing.xl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => _buildErrorCard(context, e.toString()),
          ),

          const SizedBox(height: Spacing.lg),

          // Restore purchases button
          Center(
            child: TextButton.icon(
              onPressed: () => _restorePurchases(context, ref),
              icon: const Icon(Icons.restore),
              label: const Text('Restore Purchases'),
            ),
          ),

          const SizedBox(height: Spacing.md),

          // Manage subscription link
          if (supporterStatus.managementUrl != null)
            Center(
              child: TextButton.icon(
                onPressed: () => _openManagement(supporterStatus.managementUrl!),
                icon: const Icon(Icons.settings),
                label: const Text('Manage Subscription'),
              ),
            ),

          const SizedBox(height: Spacing.xl),

          // Why support section
          _buildWhySupportSection(context),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SupporterStatus status) {
    final tier = status.tier;
    final isSupporter = tier != SupporterTier.none;

    return Card(
      color: isSupporter
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          children: [
            Text(
              tier.badgeEmoji.isEmpty ? '🙏' : tier.badgeEmoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              isSupporter ? 'Thank you for your support!' : 'Become a Supporter',
              style: AppTypography.title.copyWith(
                color: isSupporter
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              isSupporter
                  ? 'You\'re a ${tier.displayName} supporter'
                  : 'Help keep Kinu free and open',
              style: AppTypography.body.copyWith(
                color: isSupporter
                    ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            if (status.expirationDate != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                status.willRenew
                    ? 'Renews ${_formatDate(status.expirationDate!)}'
                    : 'Expires ${_formatDate(status.expirationDate!)}',
                style: AppTypography.caption.copyWith(
                  color: isSupporter
                      ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supporter Benefits',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Spacing.md),
            _buildBenefitRow(
              context,
              '❤️',
              'Friend',
              'Heart badge on your profile',
            ),
            const Divider(height: Spacing.lg),
            _buildBenefitRow(
              context,
              '⭐',
              'Champion',
              'Star badge + priority support',
            ),
            const Divider(height: Spacing.lg),
            _buildBenefitRow(
              context,
              '💎',
              'Guardian',
              'Gem badge + early access to features',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(
    BuildContext context,
    String emoji,
    String tier,
    String benefit,
  ) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                benefit,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    DonationProduct product,
    SupporterStatus currentStatus,
  ) {
    final isCurrentTier = currentStatus.tier == product.tier;
    final isHigherTier = product.tier.index > currentStatus.tier.index;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        side: isCurrentTier
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isCurrentTier ? null : () => _purchase(context, ref, product),
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Text(
                product.tier.badgeEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          product.tier.displayName,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrentTier) ...[
                          const SizedBox(width: Spacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(Spacing.radiusSm),
                            ),
                            child: Text(
                              'Current',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      product.tier.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.priceString,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    '/month',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoProductsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.store_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Products not available',
              style: AppTypography.body,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'In-app purchases are being set up. Check back soon!',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                'Failed to load products: $error',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhySupportSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Why Support Kinu?',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Kinu is built by a small team passionate about privacy and decentralized communication. '
              'Your support helps us:\n\n'
              '• Keep the app free for everyone\n'
              '• Maintain our Matrix servers\n'
              '• Develop new features\n'
              '• Stay independent (no ads, no tracking)\n\n'
              'Every contribution makes a difference!',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    DonationProduct product,
  ) async {
    final success = await ref.read(supporterStatusProvider.notifier).purchase(product);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for becoming a ${product.tier.displayName}!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase was cancelled or failed'),
        ),
      );
    }
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restoring purchases...')),
    );

    final success = await ref.read(supporterStatusProvider.notifier).restorePurchases();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Purchases restored!' : 'No purchases to restore',
        ),
      ),
    );
  }

  Future<void> _openManagement(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
