import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/notification_service.dart';

/// Provider for the notification service singleton
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Provider for the OneSignal player ID
final playerIdProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  // Service should be initialized by the app before this is accessed
  return service.playerId;
});

/// Provider for notification permission status
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.areNotificationsEnabled();
});

/// State notifier for notification preferences
class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesNotifier() : super(const NotificationPreferences());

  void setMessagesEnabled(bool enabled) {
    state = state.copyWith(messagesEnabled: enabled);
  }

  void setGroupsEnabled(bool enabled) {
    state = state.copyWith(groupsEnabled: enabled);
  }

  void setSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
  }

  void setVibrationEnabled(bool enabled) {
    state = state.copyWith(vibrationEnabled: enabled);
  }

  void setPreviewEnabled(bool enabled) {
    state = state.copyWith(previewEnabled: enabled);
  }
}

/// Notification preferences state
class NotificationPreferences {
  final bool messagesEnabled;
  final bool groupsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool previewEnabled;

  const NotificationPreferences({
    this.messagesEnabled = true,
    this.groupsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.previewEnabled = true,
  });

  NotificationPreferences copyWith({
    bool? messagesEnabled,
    bool? groupsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? previewEnabled,
  }) {
    return NotificationPreferences(
      messagesEnabled: messagesEnabled ?? this.messagesEnabled,
      groupsEnabled: groupsEnabled ?? this.groupsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      previewEnabled: previewEnabled ?? this.previewEnabled,
    );
  }
}

/// Provider for notification preferences
final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
        (ref) {
  return NotificationPreferencesNotifier();
});

/// Provider to sync notification tags with OneSignal
final notificationTagsSyncProvider = Provider((ref) {
  final service = ref.watch(notificationServiceProvider);
  final prefs = ref.watch(notificationPreferencesProvider);

  // Update OneSignal tags when preferences change
  service.addTags({
    'messages_enabled': prefs.messagesEnabled.toString(),
    'groups_enabled': prefs.groupsEnabled.toString(),
    'sound_enabled': prefs.soundEnabled.toString(),
  });

  return null;
});
