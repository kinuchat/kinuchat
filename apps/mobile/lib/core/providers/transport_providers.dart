import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/transport/transport_manager.dart';
import 'package:meshlink_core/transport/bridge_transport.dart';

import 'mesh_providers.dart';
import 'matrix_providers.dart';
import 'bridge_providers.dart';

/// Provider for connectivity checking
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Provider for transport manager
final transportManagerProvider = Provider<TransportManager>((ref) {
  final matrixService = ref.watch(matrixServiceProvider);
  final meshTransport = ref.watch(meshTransportProvider);
  final bridgeTransport = ref.watch(bridgeTransportProvider);
  final bridgeSettings = ref.watch(bridgeSettingsProvider).value;
  final connectivity = ref.watch(connectivityProvider);

  // Create bridge config from settings
  final bridgeConfig = bridgeSettings != null
      ? BridgeConfig(
          relayServerUrl: 'https://relay.kinuchat.com',
          isEnabled: bridgeSettings.isEnabled,
          relayForContactsOnly: bridgeSettings.relayForContactsOnly,
          maxBandwidthMbPerDay: bridgeSettings.maxBandwidthMbPerDay,
          minBatteryPercent: bridgeSettings.minBatteryPercent,
        )
      : null;

  return TransportManagerImpl(
    cloudTransport: matrixService,
    meshTransport: meshTransport,
    bridgeTransport: bridgeTransport,
    bridgeConfig: bridgeConfig,
    connectivity: connectivity,
  );
});

/// Transport manager implementation with full bridge support
class TransportManagerImpl implements TransportManager {
  final dynamic _cloudTransport; // MatrixService
  final dynamic _meshTransport; // MeshTransportImpl?
  final BridgeTransport? _bridgeTransport;
  final BridgeConfig? _bridgeConfig;
  final Connectivity _connectivity;

  TransportStatus _status = const TransportStatus(
    currentTransport: Transport.cloud,
    isOnline: false,
  );

  TransportManagerImpl({
    required dynamic cloudTransport,
    required dynamic meshTransport,
    BridgeTransport? bridgeTransport,
    BridgeConfig? bridgeConfig,
    required Connectivity connectivity,
  })  : _cloudTransport = cloudTransport,
        _meshTransport = meshTransport,
        _bridgeTransport = bridgeTransport,
        _bridgeConfig = bridgeConfig,
        _connectivity = connectivity;

  @override
  Future<Transport> selectTransport({
    required String recipientId,
    required Map<String, dynamic> message,
  }) async {
    // Priority 1: If peer is nearby via mesh, use mesh (fastest, no internet)
    if (await isPeerNearby(recipientId)) {
      _status = _status.copyWith(currentTransport: Transport.mesh);
      return Transport.mesh;
    }

    // Priority 2: If we have internet, use cloud (reliable)
    if (await hasInternetConnection()) {
      _status = _status.copyWith(currentTransport: Transport.cloud, isOnline: true);
      return Transport.cloud;
    }

    // Priority 3: If bridge is available and enabled, use bridge relay
    if (await isBridgeAvailable()) {
      _status = _status.copyWith(
        currentTransport: Transport.bridge,
        isBridgeActive: true,
        isOnline: false,
      );
      return Transport.bridge;
    }

    // Fallback: Queue for mesh store-and-forward
    _status = _status.copyWith(currentTransport: Transport.mesh, isOnline: false);
    return Transport.mesh;
  }

  @override
  TransportStatus getStatus() => _status;

  @override
  Future<bool> isPeerNearby(String peerId) async {
    if (_meshTransport == null) return false;

    try {
      // Check if mesh transport has this peer connected
      // The mesh transport should track connected peers
      final isAvailable = await _meshTransport.isAvailable();
      if (!isAvailable) return false;

      // TODO: Implement actual peer lookup in mesh transport
      // For now, return false - peer-specific lookup needs mesh peer list
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = !results.contains(ConnectivityResult.none);
      _status = _status.copyWith(isOnline: hasConnection);
      return hasConnection;
    } catch (_) {
      _status = _status.copyWith(isOnline: false);
      return false;
    }
  }

  @override
  Future<bool> isBridgeAvailable() async {
    // Bridge must be configured and enabled
    if (_bridgeTransport == null || _bridgeConfig == null) {
      return false;
    }

    if (!_bridgeConfig!.isEnabled) {
      _status = _status.copyWith(isBridgeActive: false);
      return false;
    }

    try {
      // Check if relay server is reachable
      final available = await _bridgeTransport!.isAvailable();
      _status = _status.copyWith(isBridgeActive: available);
      return available;
    } catch (_) {
      _status = _status.copyWith(isBridgeActive: false);
      return false;
    }
  }

  /// Update mesh peer count (called by mesh service)
  void updateMeshPeerCount(int count) {
    _status = _status.copyWith(meshPeerCount: count);
  }

  /// Update bridge message count (called by bridge service)
  void updateBridgeMessageCount(int count) {
    _status = _status.copyWith(bridgeMessageCount: count);
  }
}

/// Provider for current transport status
final transportStatusProvider = StreamProvider<TransportStatus>((ref) async* {
  final manager = ref.watch(transportManagerProvider);

  // Initial status
  yield manager.getStatus();

  // Poll transport status every 2 seconds
  while (true) {
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Trigger status update checks
      await (manager as TransportManagerImpl).hasInternetConnection();
      await manager.isBridgeAvailable();

      yield manager.getStatus();
    } catch (e) {
      // Continue polling on error
    }
  }
});

/// Provider for checking if bridge transport is available
final isBridgeTransportAvailableProvider = FutureProvider<bool>((ref) async {
  final manager = ref.watch(transportManagerProvider);
  return await manager.isBridgeAvailable();
});

/// Provider for checking current internet connectivity
final hasInternetProvider = FutureProvider<bool>((ref) async {
  final manager = ref.watch(transportManagerProvider);
  return await manager.hasInternetConnection();
});
