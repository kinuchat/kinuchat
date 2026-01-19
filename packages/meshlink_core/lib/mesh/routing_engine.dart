import 'dart:async';
import '../database/app_database.dart';
import 'packet_codec.dart';
import 'ble_constants.dart';
import 'deduplication.dart';

/// Multi-hop routing engine for mesh network
/// Implements hybrid flooding + route caching strategy
class RoutingEngine {
  final AppDatabase _db;
  final DeduplicationEngine _dedup;

  // In-memory route cache for fast lookup
  final Map<String, MeshRoute> _routeCache = {};

  // Callbacks for routing events
  final StreamController<RouteUpdate> _routeUpdateController =
      StreamController.broadcast();
  final StreamController<PacketForward> _forwardController =
      StreamController.broadcast();

  RoutingEngine(this._db)
      : _dedup = DeduplicationEngine(_db) {
    _startRouteCleanupTimer();
  }

  /// Stream of route updates (for UI/monitoring)
  Stream<RouteUpdate> get routeUpdates => _routeUpdateController.stream;

  /// Stream of packets to forward (for mesh transport)
  Stream<PacketForward> get packetsToForward => _forwardController.stream;

  /// Find best route to destination
  /// Returns null if no route exists
  Future<MeshRoute?> findRoute(String destinationPeerId) async {
    // Check cache first
    final cached = _routeCache[destinationPeerId];
    if (cached != null && !_isRouteExpired(cached)) {
      return cached;
    }

    // Query database for all routes to destination
    final routes = await _db.getRoutesToDestination(destinationPeerId);

    if (routes.isEmpty) {
      return null;
    }

    // Filter expired routes
    final validRoutes = routes.where((r) => !_isRouteExpired(r)).toList();

    if (validRoutes.isEmpty) {
      return null;
    }

    // Select best route: lowest hop count, highest quality
    validRoutes.sort((a, b) {
      // Prioritize hop count
      final hopCompare = a.hopCount.compareTo(b.hopCount);
      if (hopCompare != 0) return hopCompare;

      // Then quality score (descending)
      return b.qualityScore.compareTo(a.qualityScore);
    });

    final bestRoute = validRoutes.first;

    // Update cache
    _routeCache[destinationPeerId] = bestRoute;

    return bestRoute;
  }

  /// Update routing table from peer announcement
  /// Called when we discover a peer or receive a packet from them
  Future<void> updateRouteFromPeer({
    required String sourcePeerId,
    required String nextHopPeerId,
    required int hopCount,
    required int rssi,
  }) async {
    // Calculate quality score based on hop count and RSSI
    final qualityScore = _calculateQualityScore(hopCount, rssi);

    // Check if route already exists
    final existingRoutes = await _db.getRoutesToDestination(sourcePeerId);
    final existingRoute = existingRoutes
        .where((r) => r.nextHopPeerId == nextHopPeerId)
        .firstOrNull;

    final now = DateTime.now();
    final expiresAt = now.add(BleConstants.routeExpiration);

    if (existingRoute != null) {
      // Update existing route if better quality
      if (qualityScore > existingRoute.qualityScore ||
          hopCount < existingRoute.hopCount) {
        await _db.updateMeshRoute(
          id: existingRoute.id,
          hopCount: hopCount,
          qualityScore: qualityScore,
          lastUsed: now,
          expiresAt: expiresAt,
        );

        // Update cache
        _routeCache[sourcePeerId] = MeshRouteEntity(
          id: existingRoute.id,
          destinationPeerId: sourcePeerId,
          nextHopPeerId: nextHopPeerId,
          hopCount: hopCount,
          qualityScore: qualityScore,
          lastUsed: now,
          discoveredAt: existingRoute.discoveredAt,
          expiresAt: expiresAt,
        );

        _routeUpdateController.add(RouteUpdate(
          destinationPeerId: sourcePeerId,
          nextHopPeerId: nextHopPeerId,
          hopCount: hopCount,
          type: RouteUpdateType.updated,
        ));
      }
    } else {
      // Insert new route
      await _db.insertMeshRoute(
        destinationPeerId: sourcePeerId,
        nextHopPeerId: nextHopPeerId,
        hopCount: hopCount,
        qualityScore: qualityScore,
        lastUsed: now,
        discoveredAt: now,
        expiresAt: expiresAt,
      );

      // Update cache
      _routeCache[sourcePeerId] = MeshRouteEntity(
        id: 0, // Will be assigned by DB
        destinationPeerId: sourcePeerId,
        nextHopPeerId: nextHopPeerId,
        hopCount: hopCount,
        qualityScore: qualityScore,
        lastUsed: now,
        discoveredAt: now,
        expiresAt: expiresAt,
      );

      _routeUpdateController.add(RouteUpdate(
        destinationPeerId: sourcePeerId,
        nextHopPeerId: nextHopPeerId,
        hopCount: hopCount,
        type: RouteUpdateType.discovered,
      ));
    }
  }

  /// Process incoming packet for routing
  /// Returns true if packet should be delivered locally
  /// Returns false if packet was forwarded or dropped
  Future<bool> processIncomingPacket(
    MeshPacket packet,
    String fromPeerId,
    String localPeerId,
  ) async {
    final messageIdHex = _bytesToHex(packet.messageId);

    // Check deduplication
    if (await _dedup.hasSeenMessage(messageIdHex)) {
      // Already seen, drop packet
      return false;
    }

    // Mark as seen
    await _dedup.markMessageSeen(messageIdHex);

    // Update route to sender (we can reach them via fromPeerId)
    // Extract sender from packet if available
    // For now, we learn routes from the immediate sender
    await updateRouteFromPeer(
      sourcePeerId: fromPeerId,
      nextHopPeerId: fromPeerId,
      hopCount: 1, // Direct connection
      rssi: BleConstants.goodRssi, // Assume good if we received it
    );

    // Check if packet is for us
    if (packet.recipientId == null) {
      // Broadcast packet - deliver locally AND forward
      if (packet.ttl > 0) {
        _scheduleForward(packet, fromPeerId);
      }
      return true;
    }

    final recipientIdHex = _bytesToHex(packet.recipientId!);
    if (recipientIdHex == localPeerId) {
      // Packet is for us - deliver locally
      return true;
    }

    // Packet is for someone else - forward if TTL allows
    if (packet.ttl > 0) {
      _scheduleForward(packet, fromPeerId);
    }

    return false;
  }

  /// Flood packet to all connected neighbors except sender
  Future<void> floodPacket(MeshPacket packet, {String? excludePeerId}) async {
    // Get all connected peers
    final connectedPeers = await _db.getConnectedMeshPeers();

    for (final peer in connectedPeers) {
      // Skip excluded peer (usually the sender)
      if (excludePeerId != null && peer.meshPeerId == excludePeerId) {
        continue;
      }

      // Schedule forward to this peer
      _forwardController.add(PacketForward(
        packet: packet,
        toPeerId: peer.meshPeerId,
      ));
    }
  }

  /// Mark route as successfully used
  Future<void> markRouteSuccess(String destinationPeerId) async {
    final route = await findRoute(destinationPeerId);
    if (route == null) return;

    // Increase quality score
    final newQuality =
        (route.qualityScore + BleConstants.successBonus).clamp(0.0, 2.0);

    await _db.updateMeshRoute(
      id: route.id,
      qualityScore: newQuality,
      lastUsed: DateTime.now(),
    );

    // Update cache
    _routeCache[destinationPeerId] = MeshRouteEntity(
      id: route.id,
      destinationPeerId: route.destinationPeerId,
      nextHopPeerId: route.nextHopPeerId,
      hopCount: route.hopCount,
      qualityScore: newQuality,
      lastUsed: DateTime.now(),
      discoveredAt: route.discoveredAt,
      expiresAt: route.expiresAt,
    );
  }

  /// Mark route as failed
  Future<void> markRouteFailure(String destinationPeerId) async {
    final route = await findRoute(destinationPeerId);
    if (route == null) return;

    // Decrease quality score
    final newQuality =
        (route.qualityScore - BleConstants.failurePenalty).clamp(0.0, 2.0);

    if (newQuality < 0.3) {
      // Quality too low, delete route
      await _db.deleteMeshRoute(route.id);
      _routeCache.remove(destinationPeerId);

      _routeUpdateController.add(RouteUpdate(
        destinationPeerId: destinationPeerId,
        nextHopPeerId: route.nextHopPeerId,
        hopCount: route.hopCount,
        type: RouteUpdateType.expired,
      ));
    } else {
      // Just decrease quality
      await _db.updateMeshRoute(
        id: route.id,
        qualityScore: newQuality,
      );

      // Update cache
      _routeCache[destinationPeerId] = MeshRouteEntity(
        id: route.id,
        destinationPeerId: route.destinationPeerId,
        nextHopPeerId: route.nextHopPeerId,
        hopCount: route.hopCount,
        qualityScore: newQuality,
        lastUsed: route.lastUsed,
        discoveredAt: route.discoveredAt,
        expiresAt: route.expiresAt,
      );
    }
  }

  /// Get all known routes (for debugging/monitoring)
  Future<List<MeshRoute>> getAllRoutes() async {
    final routes = await _db.getAllMeshRoutes();
    return routes.where((r) => !_isRouteExpired(r)).toList();
  }

  /// Get route count
  Future<int> getRouteCount() async {
    final routes = await getAllRoutes();
    return routes.length;
  }

  /// Clear all routes (for testing)
  Future<void> clearAllRoutes() async {
    await _db.deleteAllMeshRoutes();
    _routeCache.clear();
  }

  /// Calculate quality score based on hop count and RSSI
  double _calculateQualityScore(int hopCount, int rssi) {
    // Start with base score
    var score = BleConstants.baseQualityScore;

    // Decrease by hop count
    score -= hopCount * BleConstants.qualityDecayPerHop;

    // Adjust for RSSI
    if (rssi >= BleConstants.excellentRssi) {
      score += 0.2;
    } else if (rssi >= BleConstants.goodRssi) {
      score += 0.1;
    } else if (rssi < BleConstants.fairRssi) {
      score -= 0.2;
    }

    return score.clamp(0.0, 2.0);
  }

  /// Check if route is expired
  bool _isRouteExpired(MeshRoute route) {
    return route.expiresAt.isBefore(DateTime.now());
  }

  /// Schedule packet forward
  void _scheduleForward(MeshPacket packet, String fromPeerId) {
    // Decrement TTL
    final forwardPacket = packet.copyWith(ttl: packet.ttl - 1);

    // If packet has specific recipient, use routing
    if (forwardPacket.recipientId != null) {
      final recipientIdHex = _bytesToHex(forwardPacket.recipientId!);

      // Try to find direct route
      findRoute(recipientIdHex).then((route) {
        if (route != null) {
          // Forward to next hop
          _forwardController.add(PacketForward(
            packet: forwardPacket,
            toPeerId: route.nextHopPeerId,
          ));
        } else {
          // No route, flood
          floodPacket(forwardPacket, excludePeerId: fromPeerId);
        }
      });
    } else {
      // Broadcast packet - flood to all except sender
      floodPacket(forwardPacket, excludePeerId: fromPeerId);
    }
  }

  /// Periodic cleanup of expired routes
  void _startRouteCleanupTimer() {
    Timer.periodic(const Duration(minutes: 5), (_) async {
      // Delete expired routes from database
      await _db.deleteExpiredMeshRoutes();

      // Clean cache
      _routeCache.removeWhere((_, route) => _isRouteExpired(route));
    });
  }

  /// Dispose resources
  void dispose() {
    _routeUpdateController.close();
    _forwardController.close();
  }

  /// Helper to convert bytes to hex
  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
}

/// Route update event
class RouteUpdate {
  final String destinationPeerId;
  final String nextHopPeerId;
  final int hopCount;
  final RouteUpdateType type;

  RouteUpdate({
    required this.destinationPeerId,
    required this.nextHopPeerId,
    required this.hopCount,
    required this.type,
  });
}

/// Route update type
enum RouteUpdateType {
  discovered,
  updated,
  expired,
}

/// Packet to forward
class PacketForward {
  final MeshPacket packet;
  final String toPeerId;

  PacketForward({
    required this.packet,
    required this.toPeerId,
  });
}

/// Type alias for mesh route
typedef MeshRoute = MeshRouteEntity;
