import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Supporter tier levels
enum SupporterTier {
  /// No active subscription
  none,

  /// Basic supporter - $2.99/month
  friend,

  /// Mid-tier supporter - $9.99/month
  champion,

  /// Top-tier supporter - $24.99/month
  guardian,
}

/// Extension to get tier details
extension SupporterTierExtension on SupporterTier {
  String get displayName {
    switch (this) {
      case SupporterTier.none:
        return 'Free';
      case SupporterTier.friend:
        return 'Friend';
      case SupporterTier.champion:
        return 'Champion';
      case SupporterTier.guardian:
        return 'Guardian';
    }
  }

  String get badgeEmoji {
    switch (this) {
      case SupporterTier.none:
        return '';
      case SupporterTier.friend:
        return '\u2764\ufe0f'; // heart
      case SupporterTier.champion:
        return '\u2b50'; // star
      case SupporterTier.guardian:
        return '\ud83d\udc8e'; // gem
    }
  }

  String get description {
    switch (this) {
      case SupporterTier.none:
        return 'Support the app to unlock badges';
      case SupporterTier.friend:
        return 'Shows a heart badge on your profile';
      case SupporterTier.champion:
        return 'Shows a star badge and priority support';
      case SupporterTier.guardian:
        return 'Shows a gem badge, priority support, and early access to features';
    }
  }

  /// RevenueCat entitlement identifier
  String get entitlementId {
    switch (this) {
      case SupporterTier.none:
        return '';
      case SupporterTier.friend:
        return 'friend_supporter';
      case SupporterTier.champion:
        return 'champion_supporter';
      case SupporterTier.guardian:
        return 'guardian_supporter';
    }
  }
}

/// Current supporter status
class SupporterStatus {
  final SupporterTier tier;
  final DateTime? expirationDate;
  final bool willRenew;
  final String? managementUrl;

  const SupporterStatus({
    this.tier = SupporterTier.none,
    this.expirationDate,
    this.willRenew = false,
    this.managementUrl,
  });

  bool get isActive => tier != SupporterTier.none;

  SupporterStatus copyWith({
    SupporterTier? tier,
    DateTime? expirationDate,
    bool? willRenew,
    String? managementUrl,
  }) {
    return SupporterStatus(
      tier: tier ?? this.tier,
      expirationDate: expirationDate ?? this.expirationDate,
      willRenew: willRenew ?? this.willRenew,
      managementUrl: managementUrl ?? this.managementUrl,
    );
  }
}

/// Available product for purchase
class DonationProduct {
  final String id;
  final String title;
  final String description;
  final String priceString;
  final SupporterTier tier;
  final StoreProduct storeProduct;

  const DonationProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.priceString,
    required this.tier,
    required this.storeProduct,
  });
}

/// Service for handling donations via RevenueCat
class DonationService {
  DonationService._();
  static final DonationService instance = DonationService._();

  bool _initialized = false;
  CustomerInfo? _customerInfo;

  /// Current customer info from RevenueCat
  CustomerInfo? get customerInfo => _customerInfo;

  /// Initialize RevenueCat
  ///
  /// [apiKey] - RevenueCat public API key (iOS or Android)
  /// [userId] - Optional user ID for cross-platform sync
  Future<void> initialize({
    required String apiKey,
    String? userId,
  }) async {
    if (_initialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration configuration;
      if (userId != null) {
        configuration = PurchasesConfiguration(apiKey)..appUserID = userId;
      } else {
        configuration = PurchasesConfiguration(apiKey);
      }

      await Purchases.configure(configuration);

      // Get initial customer info
      _customerInfo = await Purchases.getCustomerInfo();

      // Listen for customer info updates
      Purchases.addCustomerInfoUpdateListener((info) {
        _customerInfo = info;
        debugPrint('Customer info updated: ${info.entitlements.active.keys}');
      });

      _initialized = true;
      debugPrint('DonationService initialized');
    } catch (e) {
      debugPrint('Failed to initialize DonationService: $e');
    }
  }

  /// Get current supporter status
  SupporterStatus getSupporterStatus() {
    if (_customerInfo == null) {
      return const SupporterStatus();
    }

    final entitlements = _customerInfo!.entitlements.active;

    // Check tiers from highest to lowest
    for (final tier in [
      SupporterTier.guardian,
      SupporterTier.champion,
      SupporterTier.friend,
    ]) {
      final entitlement = entitlements[tier.entitlementId];
      if (entitlement != null && entitlement.isActive) {
        return SupporterStatus(
          tier: tier,
          expirationDate: entitlement.expirationDate != null
              ? DateTime.parse(entitlement.expirationDate!)
              : null,
          willRenew: entitlement.willRenew,
          managementUrl: _customerInfo!.managementURL,
        );
      }
    }

    return SupporterStatus(
      managementUrl: _customerInfo!.managementURL,
    );
  }

  /// Get current supporter tier
  SupporterTier getCurrentTier() {
    return getSupporterStatus().tier;
  }

  /// Check if user has any active subscription
  bool isSupporter() {
    return getCurrentTier() != SupporterTier.none;
  }

  /// Get available donation products
  Future<List<DonationProduct>> getProducts() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current == null) {
        debugPrint('No current offering available');
        return [];
      }

      final products = <DonationProduct>[];

      for (final package in current.availablePackages) {
        final tier = _getTierFromPackageId(package.identifier);
        if (tier != SupporterTier.none) {
          products.add(DonationProduct(
            id: package.identifier,
            title: package.storeProduct.title,
            description: package.storeProduct.description,
            priceString: package.storeProduct.priceString,
            tier: tier,
            storeProduct: package.storeProduct,
          ));
        }
      }

      // Sort by tier (friend -> champion -> guardian)
      products.sort((a, b) => a.tier.index.compareTo(b.tier.index));

      return products;
    } catch (e) {
      debugPrint('Failed to get products: $e');
      return [];
    }
  }

  /// Purchase a donation product
  Future<bool> purchase(DonationProduct product) async {
    try {
      final result = await Purchases.purchaseStoreProduct(product.storeProduct);
      _customerInfo = result;

      debugPrint('Purchase successful: ${result.entitlements.active.keys}');
      return true;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('Purchase cancelled by user');
      } else {
        debugPrint('Purchase error: $e');
      }
      return false;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    try {
      _customerInfo = await Purchases.restorePurchases();
      debugPrint('Purchases restored: ${_customerInfo?.entitlements.active.keys}');
      return true;
    } catch (e) {
      debugPrint('Failed to restore purchases: $e');
      return false;
    }
  }

  /// Sync user ID across platforms
  Future<void> setUserId(String userId) async {
    try {
      final result = await Purchases.logIn(userId);
      _customerInfo = result.customerInfo;
      debugPrint('User logged in to RevenueCat: $userId');
    } catch (e) {
      debugPrint('Failed to log in user: $e');
    }
  }

  /// Log out user (for anonymous purchases after)
  Future<void> logOut() async {
    try {
      _customerInfo = await Purchases.logOut();
      debugPrint('User logged out from RevenueCat');
    } catch (e) {
      debugPrint('Failed to log out user: $e');
    }
  }

  /// Open subscription management (App Store / Play Store)
  Future<void> openManagementUrl() async {
    final url = _customerInfo?.managementURL;
    if (url != null) {
      debugPrint('Management URL: $url');
      // Would use url_launcher here, but keeping service pure
    }
  }

  /// Get tier from RevenueCat package identifier
  SupporterTier _getTierFromPackageId(String packageId) {
    // Package IDs should match: friend_monthly, champion_monthly, guardian_monthly
    if (packageId.contains('friend')) return SupporterTier.friend;
    if (packageId.contains('champion')) return SupporterTier.champion;
    if (packageId.contains('guardian')) return SupporterTier.guardian;
    return SupporterTier.none;
  }

  /// Refresh customer info from server
  Future<void> refreshCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('Failed to refresh customer info: $e');
    }
  }
}
