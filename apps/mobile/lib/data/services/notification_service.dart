import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Callback for handling notification actions
typedef NotificationActionCallback = void Function(Map<String, dynamic> data);

/// Service for handling push notifications via OneSignal
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _playerId;
  NotificationActionCallback? _onNotificationAction;

  /// Get the OneSignal player ID for this device
  String? get playerId => _playerId;

  /// Set callback for notification actions
  set onNotificationAction(NotificationActionCallback? callback) {
    _onNotificationAction = callback;
  }

  /// Android notification channel for messages
  static const AndroidNotificationChannel _messageChannel =
      AndroidNotificationChannel(
    'messages_channel',
    'Messages',
    description: 'Notifications for new messages',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Android notification channel for other notifications
  static const AndroidNotificationChannel _generalChannel =
      AndroidNotificationChannel(
    'general_channel',
    'General',
    description: 'General app notifications',
    importance: Importance.defaultImportance,
  );

  /// Initialize the notification service
  ///
  /// [oneSignalAppId] - Your OneSignal App ID from the dashboard
  Future<void> initialize({required String oneSignalAppId}) async {
    if (_initialized) return;

    try {
      // Initialize OneSignal
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(oneSignalAppId);

      // Request permission
      await OneSignal.Notifications.requestPermission(true);

      // Set up notification handlers
      _setupNotificationHandlers();

      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();

      // Get player ID
      _playerId = OneSignal.User.pushSubscription.id;
      debugPrint('OneSignal Player ID: $_playerId');

      // Listen for subscription changes
      OneSignal.User.pushSubscription.addObserver((state) {
        _playerId = state.current.id;
        debugPrint('OneSignal Player ID updated: $_playerId');
      });

      _initialized = true;
      debugPrint('NotificationService initialized with OneSignal');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channels on Android
    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(_messageChannel);
      await androidPlugin?.createNotificationChannel(_generalChannel);
    }
  }

  /// Set up OneSignal notification handlers
  void _setupNotificationHandlers() {
    // Notification received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('Notification received in foreground: ${event.notification.notificationId}');

      // Display the notification
      event.notification.display();
    });

    // Notification clicked/opened
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('Notification clicked: ${event.notification.notificationId}');

      final data = event.notification.additionalData;
      if (data != null && _onNotificationAction != null) {
        _onNotificationAction!(Map<String, dynamic>.from(data));
      }
    });

    // Permission changed
    OneSignal.Notifications.addPermissionObserver((permission) {
      debugPrint('Notification permission changed: $permission');
    });
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');

    if (response.payload != null && _onNotificationAction != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _onNotificationAction!(data);
      } catch (e) {
        debugPrint('Failed to parse notification payload: $e');
      }
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String? channelId,
    int? id,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? _generalChannel.id,
      channelId == _messageChannel.id
          ? _messageChannel.name
          : _generalChannel.name,
      channelDescription: channelId == _messageChannel.id
          ? _messageChannel.description
          : _generalChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show a message notification
  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String conversationId,
    String? senderAvatar,
  }) async {
    final payload = jsonEncode({
      'type': 'message',
      'conversationId': conversationId,
    });

    await showNotification(
      title: senderName,
      body: message,
      payload: payload,
      channelId: _messageChannel.id,
    );
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _localNotifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Set external user ID (for targeting specific users)
  Future<void> setExternalUserId(String userId) async {
    OneSignal.login(userId);
    debugPrint('Set external user ID: $userId');
  }

  /// Remove external user ID (on logout)
  Future<void> removeExternalUserId() async {
    OneSignal.logout();
    debugPrint('Removed external user ID');
  }

  /// Add a tag for segmentation
  Future<void> addTag(String key, String value) async {
    OneSignal.User.addTagWithKey(key, value);
    debugPrint('Added tag: $key = $value');
  }

  /// Add multiple tags
  Future<void> addTags(Map<String, String> tags) async {
    OneSignal.User.addTags(tags);
    debugPrint('Added tags: $tags');
  }

  /// Remove a tag
  Future<void> removeTag(String key) async {
    OneSignal.User.removeTag(key);
    debugPrint('Removed tag: $key');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return OneSignal.Notifications.permission;
  }

  /// Open app notification settings
  Future<void> openNotificationSettings() async {
    await OneSignal.Notifications.requestPermission(true);
  }

  /// Send a notification to specific users (requires OneSignal REST API key on server)
  /// This is typically done server-side, but included for reference
  static Map<String, dynamic> buildPushPayload({
    required List<String> playerIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return {
      'include_player_ids': playerIds,
      'headings': {'en': title},
      'contents': {'en': body},
      'data': data ?? {},
    };
  }
}
