import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import 'donation_service.dart';
import 'notification_service.dart';

/// Service for initializing app dependencies
class AppInitializationService {
  AppInitializationService._();
  static final AppInitializationService instance = AppInitializationService._();

  bool _initialized = false;

  /// Initialize all app services
  ///
  /// Call this from main() before runApp()
  Future<void> initialize({String? userId}) async {
    if (_initialized) return;

    debugPrint('Initializing app services...');

    // Validate config in production
    if (AppConfig.isProduction) {
      final errors = AppConfig.validateForProduction();
      if (errors.isNotEmpty) {
        debugPrint('Configuration errors:');
        for (final error in errors) {
          debugPrint('  - $error');
        }
      }
    }

    // Initialize OneSignal for push notifications
    if (AppConfig.isOneSignalConfigured) {
      await NotificationService.instance.initialize(
        oneSignalAppId: AppConfig.oneSignalAppId,
      );

      // Link user ID for targeting
      if (userId != null) {
        await NotificationService.instance.setExternalUserId(userId);
      }
    } else {
      debugPrint('OneSignal not configured - push notifications disabled');
    }

    // Initialize RevenueCat for donations
    if (AppConfig.isRevenueCatConfigured) {
      await DonationService.instance.initialize(
        apiKey: AppConfig.revenueCatKey,
        userId: userId,
      );
    } else {
      debugPrint('RevenueCat not configured - donations disabled');
    }

    _initialized = true;
    debugPrint('App services initialized');
  }

  /// Update user ID after login
  Future<void> setUserId(String userId) async {
    // Update OneSignal
    if (AppConfig.isOneSignalConfigured) {
      await NotificationService.instance.setExternalUserId(userId);
    }

    // Update RevenueCat
    if (AppConfig.isRevenueCatConfigured) {
      await DonationService.instance.setUserId(userId);
    }
  }

  /// Clear user ID on logout
  Future<void> clearUserId() async {
    // Clear OneSignal
    if (AppConfig.isOneSignalConfigured) {
      await NotificationService.instance.removeExternalUserId();
    }

    // Clear RevenueCat
    if (AppConfig.isRevenueCatConfigured) {
      await DonationService.instance.logOut();
    }
  }

  /// Sync supporter badge to push notifications
  ///
  /// This allows targeting supporters with special notifications
  Future<void> syncSupporterBadge() async {
    if (!AppConfig.isOneSignalConfigured || !AppConfig.isRevenueCatConfigured) {
      return;
    }

    final tier = DonationService.instance.getCurrentTier();
    await NotificationService.instance.addTag('supporter_tier', tier.name);
  }
}
