import 'package:test/test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:meshlink_core/database/app_database.dart';
import 'package:meshlink_core/mesh/routing_engine.dart';
import 'package:meshlink_core/mesh/packet_codec.dart';
import 'package:meshlink_core/mesh/ble_constants.dart';
import 'dart:typed_data';

void main() {
  late AppDatabase db;
  late RoutingEngine engine;

  setUp(() async {
    // Create in-memory database for testing
    db = AppDatabase(NativeDatabase.memory());
    engine = RoutingEngine(db);
  });

  tearDown(() async {
    engine.dispose();
    await db.close();
  });

  group('RoutingEngine', () {
    test('finds no route for unknown destination', () async {
      final route = await engine.findRoute('unknown123');
      expect(route, isNull);
    });

    test('adds and finds route', () async {
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 1,
        rssi: -60,
      );

      final route = await engine.findRoute('peer1');
      expect(route, isNotNull);
      expect(route!.destinationPeerId, 'peer1');
      expect(route.nextHopPeerId, 'peer1');
      expect(route.hopCount, 1);
    });

    test('selects best route by hop count', () async {
      // Add two routes to same destination
      await engine.updateRouteFromPeer(
        sourcePeerId: 'destination',
        nextHopPeerId: 'peer1',
        hopCount: 3,
        rssi: -60,
      );

      await engine.updateRouteFromPeer(
        sourcePeerId: 'destination',
        nextHopPeerId: 'peer2',
        hopCount: 2,
        rssi: -60,
      );

      final route = await engine.findRoute('destination');
      expect(route, isNotNull);
      expect(route!.nextHopPeerId, 'peer2'); // Lower hop count
      expect(route.hopCount, 2);
    });

    test('selects best route by quality when hop count equal', () async {
      // Add two routes with same hop count
      await engine.updateRouteFromPeer(
        sourcePeerId: 'destination',
        nextHopPeerId: 'peer1',
        hopCount: 2,
        rssi: -70, // Fair signal
      );

      await engine.updateRouteFromPeer(
        sourcePeerId: 'destination',
        nextHopPeerId: 'peer2',
        hopCount: 2,
        rssi: -50, // Excellent signal
      );

      final route = await engine.findRoute('destination');
      expect(route, isNotNull);
      expect(route!.nextHopPeerId, 'peer2'); // Better quality
    });

    test('updates existing route if better', () async {
      // Add initial route
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 3,
        rssi: -70,
      );

      // Update with better route
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 2,
        rssi: -60,
      );

      final route = await engine.findRoute('peer1');
      expect(route, isNotNull);
      expect(route!.hopCount, 2); // Updated to better hop count
    });

    test('marks route success increases quality', () async {
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 2,
        rssi: -60,
      );

      final initialRoute = await engine.findRoute('peer1');
      final initialQuality = initialRoute!.qualityScore;

      await engine.markRouteSuccess('peer1');

      final updatedRoute = await engine.findRoute('peer1');
      expect(updatedRoute!.qualityScore, greaterThan(initialQuality));
    });

    test('marks route failure decreases quality', () async {
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 2,
        rssi: -60,
      );

      final initialRoute = await engine.findRoute('peer1');
      final initialQuality = initialRoute!.qualityScore;

      await engine.markRouteFailure('peer1');

      final updatedRoute = await engine.findRoute('peer1');
      expect(updatedRoute!.qualityScore, lessThan(initialQuality));
    });

    test('deletes route when quality too low', () async {
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 5, // Poor hop count
        rssi: -80, // Poor signal
      );

      // Mark failures multiple times
      for (int i = 0; i < 5; i++) {
        await engine.markRouteFailure('peer1');
      }

      final route = await engine.findRoute('peer1');
      expect(route, isNull); // Route should be deleted
    });

    test('processes incoming packet for local delivery', () async {
      final localPeerId = '0123456789abcdef'; // Valid hex
      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 5,
        flags: PacketFlags.hasRecipient,
        timestamp: DateTime.now(),
        messageId: Uint8List.fromList(List.generate(16, (i) => i)),
        recipientId: _hexToBytes(localPeerId),
        payload: Uint8List.fromList('Hello'.codeUnits),
      );

      final shouldDeliver = await engine.processIncomingPacket(
        packet,
        'abcdef0123456789',
        localPeerId,
      );

      expect(shouldDeliver, isTrue);
    });

    test('processes incoming broadcast packet', () async {
      final packet = MeshPacket(
        type: PacketType.peerAnnounce,
        ttl: 5,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: Uint8List.fromList(List.generate(16, (i) => i)),
        payload: Uint8List.fromList('Broadcast'.codeUnits),
      );

      final shouldDeliver = await engine.processIncomingPacket(
        packet,
        'peer1',
        'localpeerId',
      );

      expect(shouldDeliver, isTrue); // Broadcast always delivered
    });

    test('drops duplicate packets', () async {
      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 5,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: Uint8List.fromList(List.generate(16, (i) => 42)),
        payload: Uint8List.fromList('Test'.codeUnits),
      );

      // Process first time
      final firstResult = await engine.processIncomingPacket(
        packet,
        'peer1',
        'localpeerId',
      );
      expect(firstResult, isTrue);

      // Process second time (duplicate)
      final secondResult = await engine.processIncomingPacket(
        packet,
        'peer1',
        'localpeerId',
      );
      expect(secondResult, isFalse); // Should be dropped
    });

    test('learns route from incoming packet', () async {
      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 5,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: Uint8List.fromList(List.generate(16, (i) => i)),
        payload: Uint8List.fromList('Test'.codeUnits),
      );

      await engine.processIncomingPacket(
        packet,
        'peer1',
        'localpeerId',
      );

      // Should learn route to peer1
      final route = await engine.findRoute('peer1');
      expect(route, isNotNull);
      expect(route!.nextHopPeerId, 'peer1');
      expect(route.hopCount, 1);
    });

    test('gets all routes', () async {
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 1,
        rssi: -60,
      );

      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer2',
        nextHopPeerId: 'peer2',
        hopCount: 2,
        rssi: -65,
      );

      final routes = await engine.getAllRoutes();
      expect(routes.length, 2);
    });

    test('gets route count', () async {
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 1,
        rssi: -60,
      );

      final count = await engine.getRouteCount();
      expect(count, 1);
    });

    test('clears all routes', () async {
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 1,
        rssi: -60,
      );

      await engine.clearAllRoutes();

      final count = await engine.getRouteCount();
      expect(count, 0);
    });

    test('route update stream emits events', () async {
      final updates = <RouteUpdate>[];
      final subscription = engine.routeUpdates.listen(updates.add);

      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 1,
        rssi: -60,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(updates.length, 1);
      expect(updates[0].destinationPeerId, 'peer1');
      expect(updates[0].type, RouteUpdateType.discovered);

      await subscription.cancel();
    });

    test('quality score calculation considers hop count', () async {
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 1,
        rssi: -60,
      );

      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer2',
        nextHopPeerId: 'peer2',
        hopCount: 5,
        rssi: -60,
      );

      final route1 = await engine.findRoute('peer1');
      final route2 = await engine.findRoute('peer2');

      expect(route1!.qualityScore, greaterThan(route2!.qualityScore));
    });

    test('quality score calculation considers RSSI', () async {
      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer1',
        nextHopPeerId: 'peer1',
        hopCount: 2,
        rssi: -50, // Excellent
      );

      await engine.updateRouteFromPeer(
        sourcePeerId: 'peer2',
        nextHopPeerId: 'peer2',
        hopCount: 2,
        rssi: -80, // Poor
      );

      final route1 = await engine.findRoute('peer1');
      final route2 = await engine.findRoute('peer2');

      expect(route1!.qualityScore, greaterThan(route2!.qualityScore));
    });
  });

  group('Packet Forwarding', () {
    test('emits forward events for packets to forward', () async {
      final forwards = <PacketForward>[];
      final subscription = engine.packetsToForward.listen(forwards.add);

      // Add a connected peer to forward to
      await db.insertMeshPeer(
        meshPeerId: 'peer1',
        publicKey: 'key1',
        exchangePublicKey: 'exchKey1',
        rssi: -60,
        connectionState: 'connected',
        lastSeen: DateTime.now(),
        firstSeen: DateTime.now(),
      );

      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 5,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: Uint8List.fromList(List.generate(16, (i) => i)),
        payload: Uint8List.fromList('Broadcast'.codeUnits),
      );

      await engine.floodPacket(packet);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(forwards.length, greaterThan(0));
      expect(forwards[0].toPeerId, 'peer1');

      await subscription.cancel();
    });

    test('excludes sender when flooding', () async {
      final forwards = <PacketForward>[];
      final subscription = engine.packetsToForward.listen(forwards.add);

      // Add two connected peers
      await db.insertMeshPeer(
        meshPeerId: 'peer1',
        publicKey: 'key1',
        exchangePublicKey: 'exchKey1',
        rssi: -60,
        connectionState: 'connected',
        lastSeen: DateTime.now(),
        firstSeen: DateTime.now(),
      );

      await db.insertMeshPeer(
        meshPeerId: 'peer2',
        publicKey: 'key2',
        exchangePublicKey: 'exchKey2',
        rssi: -60,
        connectionState: 'connected',
        lastSeen: DateTime.now(),
        firstSeen: DateTime.now(),
      );

      final packet = MeshPacket(
        type: PacketType.text,
        ttl: 5,
        flags: 0,
        timestamp: DateTime.now(),
        messageId: Uint8List.fromList(List.generate(16, (i) => i)),
        payload: Uint8List.fromList('Test'.codeUnits),
      );

      await engine.floodPacket(packet, excludePeerId: 'peer1');

      await Future.delayed(const Duration(milliseconds: 100));

      // Should only forward to peer2 (peer1 excluded)
      expect(forwards.length, 1);
      expect(forwards[0].toPeerId, 'peer2');

      await subscription.cancel();
    });
  });
}

/// Helper to convert hex string to bytes
Uint8List _hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}
