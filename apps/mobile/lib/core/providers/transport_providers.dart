import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/transport/transport_manager.dart';
import 'mesh_providers.dart';
import 'matrix_providers.dart';

/// Provider for transport manager
final transportManagerProvider = Provider<TransportManager>((ref) {
  final matrixService = ref.watch(matrixServiceProvider);
  final meshTransport = ref.watch(meshTransportProvider);

  return TransportManagerImpl(
    cloudTransport: matrixService,
    meshTransport: meshTransport,
  );
});

/// Transport manager implementation
class TransportManagerImpl implements TransportManager {
  final dynamic _cloudTransport; // MatrixService
  final dynamic _meshTransport; // MeshTransportImpl?

  TransportManagerImpl({
    required dynamic cloudTransport,
    required dynamic meshTransport,
  })  : _cloudTransport = cloudTransport,
        _meshTransport = meshTransport;

  @override
  Future<Transport> selectTransport({
    required String recipientId,
    required Map<String, dynamic> message,
  }) async {
    // Check if recipient is nearby via mesh
    // TODO: Implement contact lookup and mesh availability check
    final hasInternet = await _cloudTransport.isAvailable();
    final hasMesh = _meshTransport != null &&
        await _meshTransport.isAvailable();

    // Decision matrix
    if (hasMesh) {
      // TODO: Check if recipient is nearby
      // For now, prefer cloud if available
      if (hasInternet) {
        return Transport.cloud;
      } else {
        return Transport.mesh;
      }
    } else if (hasInternet) {
      return Transport.cloud;
    } else {
      // No transport available - queue for cloud retry
      return Transport.cloud;
    }
  }

  @override
  TransportStatus getStatus() {
    // Note: This is a synchronous approximation
    // In production, we would track these states
    final currentTransport = Transport.cloud; // Default for now

    return TransportStatus(
      currentTransport: currentTransport,
      isOnline: true, // TODO: Check actual connectivity
      meshPeerCount: 0, // TODO: Get from mesh transport
      isBridgeActive: false,
    );
  }
}

/// Provider for current transport status
final transportStatusProvider = StreamProvider<TransportStatus>((ref) async* {
  final manager = ref.watch(transportManagerProvider);

  // Poll transport status every 2 seconds
  while (true) {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final status = manager.getStatus();
      yield status;
    } catch (e) {
      // Continue polling on error
    }
  }
});
