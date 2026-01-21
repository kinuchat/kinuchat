import 'dart:io';

/// Application configuration
///
/// Contains API keys and environment settings.
/// These should be loaded from environment variables or a secure config
/// in production.
class AppConfig {
  AppConfig._();

  /// Environment mode
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);

  // ============================================================
  // OneSignal Configuration
  // ============================================================

  /// OneSignal App ID
  /// Get this from: OneSignal Dashboard > Settings > Keys & IDs
  static const String oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '', // Set via --dart-define or env
  );

  // ============================================================
  // RevenueCat Configuration
  // ============================================================

  /// RevenueCat public API key for iOS
  /// Get this from: RevenueCat Dashboard > API Keys
  static const String revenueCatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
    defaultValue: '', // Set via --dart-define or env
  );

  /// RevenueCat public API key for Android
  /// Get this from: RevenueCat Dashboard > API Keys
  static const String revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
    defaultValue: '', // Set via --dart-define or env
  );

  /// Get the appropriate RevenueCat key for the current platform
  static String get revenueCatKey {
    if (Platform.isIOS) return revenueCatIosKey;
    if (Platform.isAndroid) return revenueCatAndroidKey;
    return '';
  }

  // ============================================================
  // Server Configuration
  // ============================================================

  /// Relay server URL
  static const String relayServerUrl = String.fromEnvironment(
    'RELAY_SERVER_URL',
    defaultValue: 'https://relay.kinuchat.com',
  );

  /// Matrix homeserver URL
  static const String matrixHomeserverUrl = String.fromEnvironment(
    'MATRIX_HOMESERVER_URL',
    defaultValue: 'https://matrix.kinuchat.com',
  );

  // ============================================================
  // Validation
  // ============================================================

  /// Check if OneSignal is configured
  static bool get isOneSignalConfigured => oneSignalAppId.isNotEmpty;

  /// Check if RevenueCat is configured
  static bool get isRevenueCatConfigured => revenueCatKey.isNotEmpty;

  /// Validate all required config is present for production
  static List<String> validateForProduction() {
    final errors = <String>[];

    if (!isOneSignalConfigured) {
      errors.add('ONESIGNAL_APP_ID is not configured');
    }

    if (!isRevenueCatConfigured) {
      errors.add('REVENUECAT_IOS_KEY or REVENUECAT_ANDROID_KEY is not configured');
    }

    return errors;
  }
}
