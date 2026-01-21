import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/donation_service.dart';
export '../../data/services/donation_service.dart' show SupporterTier, SupporterTierExtension, SupporterStatus, DonationProduct;

/// Provider for the donation service singleton
final donationServiceProvider = Provider<DonationService>((ref) {
  return DonationService.instance;
});

/// Provider for supporter status (refreshes when customer info updates)
final supporterStatusProvider = StateNotifierProvider<SupporterStatusNotifier, SupporterStatus>((ref) {
  final service = ref.watch(donationServiceProvider);
  return SupporterStatusNotifier(service);
});

/// State notifier for supporter status
class SupporterStatusNotifier extends StateNotifier<SupporterStatus> {
  SupporterStatusNotifier(this._service) : super(const SupporterStatus()) {
    refresh();
  }

  final DonationService _service;

  /// Refresh status from service
  Future<void> refresh() async {
    state = _service.getSupporterStatus();
  }

  /// Purchase a product and update status
  Future<bool> purchase(DonationProduct product) async {
    final success = await _service.purchase(product);
    if (success) {
      state = _service.getSupporterStatus();
    }
    return success;
  }

  /// Restore purchases and update status
  Future<bool> restorePurchases() async {
    final success = await _service.restorePurchases();
    if (success) {
      state = _service.getSupporterStatus();
    }
    return success;
  }
}

/// Provider for current supporter tier
final supporterTierProvider = Provider<SupporterTier>((ref) {
  return ref.watch(supporterStatusProvider).tier;
});

/// Provider to check if user is any tier of supporter
final isSupporterProvider = Provider<bool>((ref) {
  return ref.watch(supporterTierProvider) != SupporterTier.none;
});

/// Provider for available donation products
final donationProductsProvider = FutureProvider<List<DonationProduct>>((ref) async {
  final service = ref.watch(donationServiceProvider);
  return service.getProducts();
});

/// Provider for supporter badge info
final supporterBadgeProvider = Provider<SupporterBadge>((ref) {
  final tier = ref.watch(supporterTierProvider);
  return SupporterBadge.fromTier(tier);
});

/// Badge display info
class SupporterBadge {
  final String emoji;
  final String label;
  final bool isVisible;

  const SupporterBadge({
    required this.emoji,
    required this.label,
    required this.isVisible,
  });

  factory SupporterBadge.fromTier(SupporterTier tier) {
    return SupporterBadge(
      emoji: tier.badgeEmoji,
      label: tier.displayName,
      isVisible: tier != SupporterTier.none,
    );
  }
}

/// Provider for subscription management URL
final managementUrlProvider = Provider<String?>((ref) {
  return ref.watch(supporterStatusProvider).managementUrl;
});

/// Provider for subscription expiration info
final subscriptionExpirationProvider = Provider<SubscriptionExpiration?>((ref) {
  final status = ref.watch(supporterStatusProvider);
  if (!status.isActive || status.expirationDate == null) {
    return null;
  }

  return SubscriptionExpiration(
    date: status.expirationDate!,
    willRenew: status.willRenew,
  );
});

/// Subscription expiration info
class SubscriptionExpiration {
  final DateTime date;
  final bool willRenew;

  const SubscriptionExpiration({
    required this.date,
    required this.willRenew,
  });

  int get daysRemaining => date.difference(DateTime.now()).inDays;

  bool get isExpiringSoon => daysRemaining <= 7 && !willRenew;
}
