import 'dart:async';
import 'package:meshlink_core/mesh/mesh_transport_impl.dart';

/// Background service for mesh networking
/// TODO: Temporarily disabled - flutter_background_service crashes on Android 14+
/// Needs notification channel fix before re-enabling
@pragma('vm:entry-point')
class MeshBackgroundService {
  static const String _notificationChannelId = 'meshlink_mesh_service';
  static const int _notificationId = 888;

  /// Initialize the background service (stub)
  static Future<void> initialize() async {}

  /// Start the background service (stub)
  static Future<void> start() async {}

  /// Stop the background service (stub)
  static Future<void> stop() async {}

  /// Check if service is running (stub)
  static Future<bool> isRunning() async => false;

  /// Update notification with peer count (stub)
  static Future<void> updatePeerCount(int count) async {}
}

/// Extension methods for managing mesh background service
extension MeshBackgroundServiceExtension on MeshTransportImpl {
  Future<void> startBackgroundService() async {}
  Future<void> stopBackgroundService() async {}
  Future<void> updateBackgroundPeerCount(int count) async {}
}
