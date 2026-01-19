import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_providers.dart';

/// Keys for settings storage
class SettingsKeys {
  static const String themeMode = 'settings_theme_mode';
  static const String notificationsEnabled = 'settings_notifications_enabled';
  static const String messageSoundsEnabled = 'settings_message_sounds_enabled';
  static const String showReadReceipts = 'settings_show_read_receipts';
  static const String showTypingIndicators = 'settings_show_typing_indicators';
  static const String meshNetworkEnabled = 'settings_mesh_network_enabled';
  // Quiet hours settings
  static const String quietHoursEnabled = 'settings_quiet_hours_enabled';
  static const String quietHoursStartHour = 'settings_quiet_hours_start_hour';
  static const String quietHoursStartMinute = 'settings_quiet_hours_start_minute';
  static const String quietHoursEndHour = 'settings_quiet_hours_end_hour';
  static const String quietHoursEndMinute = 'settings_quiet_hours_end_minute';
}

/// App settings state
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.messageSoundsEnabled = true,
    this.showReadReceipts = true,
    this.showTypingIndicators = true,
    this.meshNetworkEnabled = false,
    // Quiet hours defaults: disabled, 10 PM - 7 AM
    this.quietHoursEnabled = false,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 7, minute: 0),
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool messageSoundsEnabled;
  final bool showReadReceipts;
  final bool showTypingIndicators;
  final bool meshNetworkEnabled;
  // Quiet hours settings
  final bool quietHoursEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;

  /// Check if the current time is within quiet hours
  bool get isInQuietHours {
    if (!quietHoursEnabled) return false;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = quietHoursStart.hour * 60 + quietHoursStart.minute;
    final endMinutes = quietHoursEnd.hour * 60 + quietHoursEnd.minute;

    // Handle overnight quiet hours (e.g., 10 PM - 7 AM)
    if (startMinutes > endMinutes) {
      // Quiet hours span midnight
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    } else {
      // Quiet hours within same day (e.g., 1 PM - 5 PM)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
  }

  /// Check if notifications should be muted (either disabled or in quiet hours)
  bool get shouldMuteNotifications {
    return !notificationsEnabled || isInQuietHours;
  }

  /// Check if sounds should be muted
  bool get shouldMuteSounds {
    return !messageSoundsEnabled || isInQuietHours;
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? messageSoundsEnabled,
    bool? showReadReceipts,
    bool? showTypingIndicators,
    bool? meshNetworkEnabled,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      messageSoundsEnabled: messageSoundsEnabled ?? this.messageSoundsEnabled,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      showTypingIndicators: showTypingIndicators ?? this.showTypingIndicators,
      meshNetworkEnabled: meshNetworkEnabled ?? this.meshNetworkEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}

/// Settings notifier for managing app settings
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _loadSettings();
  }

  final FlutterSecureStorage _storage;

  Future<void> _loadSettings() async {
    try {
      final themeModeStr = await _storage.read(key: SettingsKeys.themeMode);
      final notificationsStr = await _storage.read(key: SettingsKeys.notificationsEnabled);
      final soundsStr = await _storage.read(key: SettingsKeys.messageSoundsEnabled);
      final readReceiptsStr = await _storage.read(key: SettingsKeys.showReadReceipts);
      final typingStr = await _storage.read(key: SettingsKeys.showTypingIndicators);
      final meshStr = await _storage.read(key: SettingsKeys.meshNetworkEnabled);

      // Load quiet hours settings
      final quietHoursEnabledStr = await _storage.read(key: SettingsKeys.quietHoursEnabled);
      final quietHoursStartHourStr = await _storage.read(key: SettingsKeys.quietHoursStartHour);
      final quietHoursStartMinuteStr = await _storage.read(key: SettingsKeys.quietHoursStartMinute);
      final quietHoursEndHourStr = await _storage.read(key: SettingsKeys.quietHoursEndHour);
      final quietHoursEndMinuteStr = await _storage.read(key: SettingsKeys.quietHoursEndMinute);

      state = AppSettings(
        themeMode: _parseThemeMode(themeModeStr),
        notificationsEnabled: notificationsStr != 'false',
        messageSoundsEnabled: soundsStr != 'false',
        showReadReceipts: readReceiptsStr != 'false',
        showTypingIndicators: typingStr != 'false',
        meshNetworkEnabled: meshStr == 'true',
        quietHoursEnabled: quietHoursEnabledStr == 'true',
        quietHoursStart: TimeOfDay(
          hour: int.tryParse(quietHoursStartHourStr ?? '') ?? 22,
          minute: int.tryParse(quietHoursStartMinuteStr ?? '') ?? 0,
        ),
        quietHoursEnd: TimeOfDay(
          hour: int.tryParse(quietHoursEndHourStr ?? '') ?? 7,
          minute: int.tryParse(quietHoursEndMinuteStr ?? '') ?? 0,
        ),
      );
    } catch (e) {
      // Use defaults on error
      debugPrint('Failed to load settings: $e');
    }
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.write(key: SettingsKeys.themeMode, value: _themeModeToString(mode));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _storage.write(key: SettingsKeys.notificationsEnabled, value: enabled.toString());
  }

  Future<void> setMessageSoundsEnabled(bool enabled) async {
    state = state.copyWith(messageSoundsEnabled: enabled);
    await _storage.write(key: SettingsKeys.messageSoundsEnabled, value: enabled.toString());
  }

  Future<void> setShowReadReceipts(bool show) async {
    state = state.copyWith(showReadReceipts: show);
    await _storage.write(key: SettingsKeys.showReadReceipts, value: show.toString());
  }

  Future<void> setShowTypingIndicators(bool show) async {
    state = state.copyWith(showTypingIndicators: show);
    await _storage.write(key: SettingsKeys.showTypingIndicators, value: show.toString());
  }

  Future<void> setMeshNetworkEnabled(bool enabled) async {
    state = state.copyWith(meshNetworkEnabled: enabled);
    await _storage.write(key: SettingsKeys.meshNetworkEnabled, value: enabled.toString());
  }

  Future<void> setQuietHoursEnabled(bool enabled) async {
    state = state.copyWith(quietHoursEnabled: enabled);
    await _storage.write(key: SettingsKeys.quietHoursEnabled, value: enabled.toString());
  }

  Future<void> setQuietHoursStart(TimeOfDay time) async {
    state = state.copyWith(quietHoursStart: time);
    await _storage.write(key: SettingsKeys.quietHoursStartHour, value: time.hour.toString());
    await _storage.write(key: SettingsKeys.quietHoursStartMinute, value: time.minute.toString());
  }

  Future<void> setQuietHoursEnd(TimeOfDay time) async {
    state = state.copyWith(quietHoursEnd: time);
    await _storage.write(key: SettingsKeys.quietHoursEndHour, value: time.hour.toString());
    await _storage.write(key: SettingsKeys.quietHoursEndMinute, value: time.minute.toString());
  }

  /// Set all quiet hours settings at once
  Future<void> setQuietHours({
    required bool enabled,
    required TimeOfDay start,
    required TimeOfDay end,
  }) async {
    state = state.copyWith(
      quietHoursEnabled: enabled,
      quietHoursStart: start,
      quietHoursEnd: end,
    );
    await _storage.write(key: SettingsKeys.quietHoursEnabled, value: enabled.toString());
    await _storage.write(key: SettingsKeys.quietHoursStartHour, value: start.hour.toString());
    await _storage.write(key: SettingsKeys.quietHoursStartMinute, value: start.minute.toString());
    await _storage.write(key: SettingsKeys.quietHoursEndHour, value: end.hour.toString());
    await _storage.write(key: SettingsKeys.quietHoursEndMinute, value: end.minute.toString());
  }
}

/// Provider for app settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return SettingsNotifier(storage);
});

/// Provider for just the theme mode (for use in MaterialApp)
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
