import 'dart:async';

import 'bridge_transport.dart';

/// Transport manager interface
/// Based on Section 3 of the specification
///
/// Handles automatic selection between cloud, mesh, and bridge transports
/// based on network conditions and peer availability.
abstract class TransportManager {
  /// Select the optimal transport for a message
  Future<Transport> selectTransport({
    required String recipientId,
    required Map<String, dynamic> message,
  });

  /// Get current transport status
  TransportStatus getStatus();

  /// Check if a peer is nearby via mesh
  Future<bool> isPeerNearby(String peerId);

  /// Check if we have internet connectivity
  Future<bool> hasInternetConnection();

  /// Check if bridge transport is available and enabled
  Future<bool> isBridgeAvailable();
}

/// Available transport types
enum Transport {
  /// Cloud transport via Matrix
  cloud,

  /// BLE mesh transport
  mesh,

  /// Bridge relay transport
  bridge,
}

/// Transport status information
class TransportStatus {
  const TransportStatus({
    required this.currentTransport,
    required this.isOnline,
    this.meshPeerCount = 0,
    this.isBridgeActive = false,
    this.bridgeMessageCount = 0,
  });

  final Transport currentTransport;
  final bool isOnline;
  final int meshPeerCount;
  final bool isBridgeActive;
  final int bridgeMessageCount;

  TransportStatus copyWith({
    Transport? currentTransport,
    bool? isOnline,
    int? meshPeerCount,
    bool? isBridgeActive,
    int? bridgeMessageCount,
  }) {
    return TransportStatus(
      currentTransport: currentTransport ?? this.currentTransport,
      isOnline: isOnline ?? this.isOnline,
      meshPeerCount: meshPeerCount ?? this.meshPeerCount,
      isBridgeActive: isBridgeActive ?? this.isBridgeActive,
      bridgeMessageCount: bridgeMessageCount ?? this.bridgeMessageCount,
    );
  }
}

/// Default transport manager implementation
class TransportManagerImpl implements TransportManager {
  final Future<bool> Function()? _checkInternetConnection;
  final Future<bool> Function(String peerId)? _checkPeerNearby;
  final BridgeTransport? _bridgeTransport;
  final BridgeConfig? _bridgeConfig;

  TransportStatus _status = const TransportStatus(
    currentTransport: Transport.cloud,
    isOnline: false,
  );

  TransportManagerImpl({
    Future<bool> Function()? checkInternetConnection,
    Future<bool> Function(String peerId)? checkPeerNearby,
    BridgeTransport? bridgeTransport,
    BridgeConfig? bridgeConfig,
  })  : _checkInternetConnection = checkInternetConnection,
        _checkPeerNearby = checkPeerNearby,
        _bridgeTransport = bridgeTransport,
        _bridgeConfig = bridgeConfig;

  @override
  Future<Transport> selectTransport({
    required String recipientId,
    required Map<String, dynamic> message,
  }) async {
    // Priority 1: If peer is nearby, use mesh (lowest latency, no internet needed)
    if (await isPeerNearby(recipientId)) {
      _status = _status.copyWith(currentTransport: Transport.mesh);
      return Transport.mesh;
    }

    // Priority 2: If we have internet, use cloud (reliable, fast)
    if (await hasInternetConnection()) {
      _status = _status.copyWith(currentTransport: Transport.cloud, isOnline: true);
      return Transport.cloud;
    }

    // Priority 3: If bridge is available, use it (internet via relay)
    if (await isBridgeAvailable()) {
      _status = _status.copyWith(currentTransport: Transport.bridge, isBridgeActive: true);
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
    if (_checkPeerNearby != null) {
      return _checkPeerNearby!(peerId);
    }
    return false;
  }

  @override
  Future<bool> hasInternetConnection() async {
    if (_checkInternetConnection != null) {
      final result = await _checkInternetConnection!();
      _status = _status.copyWith(isOnline: result);
      return result;
    }
    return false;
  }

  @override
  Future<bool> isBridgeAvailable() async {
    if (_bridgeTransport == null || _bridgeConfig == null) {
      return false;
    }

    if (!_bridgeConfig!.isEnabled) {
      return false;
    }

    try {
      final available = await _bridgeTransport!.isAvailable();
      _status = _status.copyWith(isBridgeActive: available);
      return available;
    } catch (_) {
      _status = _status.copyWith(isBridgeActive: false);
      return false;
    }
  }

  /// Update mesh peer count
  void updateMeshPeerCount(int count) {
    _status = _status.copyWith(meshPeerCount: count);
  }

  /// Update bridge message count
  void updateBridgeMessageCount(int count) {
    _status = _status.copyWith(bridgeMessageCount: count);
  }
}
