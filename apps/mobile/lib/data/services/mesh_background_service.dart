import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:meshlink_core/mesh/mesh_transport_impl.dart';

/// Background service for mesh networking
/// Keeps BLE mesh active when app is backgrounded
@pragma('vm:entry-point')
class MeshBackgroundService {
  static const String _notificationChannelId = 'meshlink_mesh_service';
  static const int _notificationId = 888;

  /// Initialize the background service
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        // Auto start service on app launch
        autoStart: false,

        // Background fetch (iOS will control the timing)
        onForeground: onIosStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        // Auto start service on app launch
        autoStart: false,

        // Service will run as foreground service (required for BLE)
        onStart: onAndroidStart,
        isForegroundMode: true,

        // Notification for foreground service
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Kinu',
        initialNotificationContent: 'Mesh network active',
        foregroundServiceNotificationId: _notificationId,
      ),
    );
  }

  /// Start the background service
  static Future<void> start() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  /// Stop the background service
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
  }

  /// Check if service is running
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// Update notification with peer count
  static Future<void> updatePeerCount(int count) async {
    final service = FlutterBackgroundService();
    service.invoke('updatePeerCount', {'count': count});
  }

  // ============================================================================
  // Android Service Entry Point
  // ============================================================================

  @pragma('vm:entry-point')
  static void onAndroidStart(ServiceInstance service) async {
    // Only run on Android
    if (service is! AndroidServiceInstance) {
      return;
    }

    DartPluginRegistrant.ensureInitialized();

    int peerCount = 0;
    Timer? updateTimer;

    // Listen for stop command
    service.on('stop').listen((event) {
      updateTimer?.cancel();
      service.stopSelf();
    });

    // Listen for peer count updates
    service.on('updatePeerCount').listen((event) {
      if (event != null && event['count'] != null) {
        peerCount = event['count'] as int;
        _updateAndroidNotification(service, peerCount);
      }
    });

    // Initial notification
    _updateAndroidNotification(service, peerCount);

    // Periodic check (every 30 seconds)
    updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      // Service is running - notification will be updated via invoke
      // The actual peer count is tracked by the main app
    });

    // Keep service running
    service.on('isRunning').listen((event) {
      service.invoke('isRunning', {'running': true});
    });
  }

  static void _updateAndroidNotification(
    AndroidServiceInstance service,
    int peerCount,
  ) {
    final content = peerCount > 0
        ? 'Connected to $peerCount peer${peerCount == 1 ? '' : 's'}'
        : 'Scanning for nearby peers...';

    service.setForegroundNotificationInfo(
      title: 'Mesh Network Active',
      content: content,
    );
  }

  // ============================================================================
  // iOS Service Entry Points
  // ============================================================================

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // iOS allows BLE in background with limited scan rate
    // The mesh transport will continue to work

    return true; // Return true to continue background execution
  }

  @pragma('vm:entry-point')
  static void onIosStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Listen for stop command
    service.on('stop').listen((event) {
      service.stopSelf();
    });

    // iOS doesn't need foreground notification
    // BLE background mode is enabled in Info.plist
  }
}

/// Extension methods for managing mesh background service
extension MeshBackgroundServiceExtension on MeshTransportImpl {
  /// Start background service for this transport
  Future<void> startBackgroundService() async {
    await MeshBackgroundService.initialize();
    await MeshBackgroundService.start();
  }

  /// Stop background service
  Future<void> stopBackgroundService() async {
    await MeshBackgroundService.stop();
  }

  /// Update background service with peer count
  Future<void> updateBackgroundPeerCount(int count) async {
    await MeshBackgroundService.updatePeerCount(count);
  }
}
