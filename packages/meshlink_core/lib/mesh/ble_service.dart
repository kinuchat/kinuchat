import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/identity.dart';
import 'ble_constants.dart';

/// BLE service wrapper for MeshLink mesh networking
/// Provides abstraction over flutter_blue_plus for mesh operations
class BleService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _messageChar;
  BluetoothCharacteristic? _handshakeChar;
  BluetoothCharacteristic? _peerAnnouncementChar;

  final _packetController = StreamController<MeshPacketReceived>.broadcast();
  final _discoveryController = StreamController<MeshPeerDiscovery>.broadcast();

  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isAdvertising = false;

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// Check if BLE service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if currently scanning
  bool get isScanning => _isScanning;

  /// Check if currently advertising
  bool get isAdvertising => _isAdvertising;

  /// Initialize BLE service
  /// Checks BLE support and adapter state
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    // Check if Bluetooth is supported on this device
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      throw BleException('BLE not supported on this device');
    }

    // Check adapter state
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      throw BleException(
        'Bluetooth is off. Please enable Bluetooth to use mesh networking.',
      );
    }

    _isInitialized = true;
  }

  /// Start advertising our presence as a mesh peer
  /// Advertises the MeshLink service UUID and peer ID
  Future<void> startAdvertising(Identity identity) async {
    if (!_isInitialized) {
      throw BleException('BLE service not initialized');
    }

    if (_isAdvertising) {
      return;
    }

    try {
      // Note: flutter_blue_plus doesn't directly support advertising on all platforms
      // iOS: Can advertise as peripheral via CoreBluetooth
      // Android: Limited advertising support
      //
      // For now, we'll mark as advertising and rely on the peer announcement
      // characteristic being readable when devices connect
      //
      // TODO: Platform-specific advertising implementation

      _isAdvertising = true;
    } catch (e) {
      throw BleException('Failed to start advertising: $e');
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) {
      return;
    }

    // TODO: Stop platform-specific advertising
    _isAdvertising = false;
  }

  /// Start scanning for nearby mesh peers
  /// Returns a stream of discovered peers
  Stream<MeshPeerDiscovery> startScanning() {
    if (!_isInitialized) {
      throw BleException('BLE service not initialized');
    }

    if (_isScanning) {
      return _discoveryController.stream;
    }

    _startScanningInternal();
    return _discoveryController.stream;
  }

  void _startScanningInternal() async {
    try {
      _isScanning = true;

      // Start scanning for MeshLink service UUID
      await FlutterBluePlus.startScan(
        withServices: [Guid(BleConstants.meshLinkServiceUuid)],
        timeout: BleConstants.scanDuration,
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      _scanSubscription =
          FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
        for (final result in results) {
          _processScanResult(result);
        }
      });

      // Auto-stop after scan duration
      Future.delayed(BleConstants.scanDuration, () {
        stopScanning();
      });
    } catch (e) {
      _isScanning = false;
      throw BleException('Failed to start scanning: $e');
    }
  }

  void _processScanResult(ScanResult result) {
    // Extract mesh peer ID from advertising data
    // For now, use device ID as placeholder
    // TODO: Parse actual mesh peer ID from advertising data or service data

    final discovery = MeshPeerDiscovery(
      meshPeerId: result.device.remoteId.str, // Placeholder
      deviceId: result.device.remoteId.str,
      rssi: result.rssi,
      timestamp: DateTime.now(),
      device: result.device,
    );

    _discoveryController.add(discovery);
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    if (!_isScanning) {
      return;
    }

    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _isScanning = false;
    } catch (e) {
      // Ignore errors when stopping scan
    }
  }

  /// Connect to a specific peer device
  Future<void> connectToPeer(BluetoothDevice device) async {
    if (!_isInitialized) {
      throw BleException('BLE service not initialized');
    }

    try {
      // Disconnect from current device if any
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      // Connect to new device
      await device.connect(
        timeout: BleConstants.connectionTimeout,
        autoConnect: false,
      );

      _connectedDevice = device;

      // Discover services
      final services = await device.discoverServices();

      // Find MeshLink service
      final meshService = services.firstWhere(
        (service) => service.uuid.str == BleConstants.meshLinkServiceUuid,
        orElse: () => throw BleException('MeshLink service not found'),
      );

      // Find characteristics
      _messageChar = meshService.characteristics.firstWhere(
        (char) => char.uuid.str == BleConstants.messagePacketCharUuid,
        orElse: () => throw BleException('Message characteristic not found'),
      );

      _handshakeChar = meshService.characteristics.firstWhere(
        (char) => char.uuid.str == BleConstants.handshakeCharUuid,
        orElse: () => throw BleException('Handshake characteristic not found'),
      );

      _peerAnnouncementChar = meshService.characteristics.firstWhere(
        (char) => char.uuid.str == BleConstants.peerAnnouncementCharUuid,
        orElse: () =>
            throw BleException('Peer announcement characteristic not found'),
      );

      // Enable notifications on message and handshake characteristics
      if (_messageChar!.properties.notify) {
        await _messageChar!.setNotifyValue(true);
        _messageChar!.lastValueStream.listen((value) {
          if (value.isNotEmpty) {
            _handleIncomingPacket(value, PacketSource.message);
          }
        });
      }

      if (_handshakeChar!.properties.notify) {
        await _handshakeChar!.setNotifyValue(true);
        _handshakeChar!.lastValueStream.listen((value) {
          if (value.isNotEmpty) {
            _handleIncomingPacket(value, PacketSource.handshake);
          }
        });
      }
    } catch (e) {
      _connectedDevice = null;
      _messageChar = null;
      _handshakeChar = null;
      _peerAnnouncementChar = null;
      throw BleException('Failed to connect to peer: $e');
    }
  }

  void _handleIncomingPacket(List<int> value, PacketSource source) {
    final packet = MeshPacketReceived(
      data: Uint8List.fromList(value),
      source: source,
      timestamp: DateTime.now(),
    );
    _packetController.add(packet);
  }

  /// Send a packet to the connected peer
  Future<void> sendPacket(Uint8List packet,
      {PacketSource source = PacketSource.message}) async {
    if (_connectedDevice == null) {
      throw BleException('No device connected');
    }

    final characteristic =
        source == PacketSource.handshake ? _handshakeChar : _messageChar;

    if (characteristic == null) {
      throw BleException('Characteristic not available');
    }

    try {
      // Check if packet exceeds max size
      if (packet.length > BleConstants.maxPacketSize) {
        // TODO: Implement fragmentation for large packets
        throw BleException(
          'Packet too large: ${packet.length} > ${BleConstants.maxPacketSize}',
        );
      }

      // Write packet
      await characteristic.write(packet, withoutResponse: false);
    } catch (e) {
      throw BleException('Failed to send packet: $e');
    }
  }

  /// Send a handshake message
  Future<void> sendHandshakeMessage(Uint8List message) async {
    await sendPacket(message, source: PacketSource.handshake);
  }

  /// Read peer announcement data
  Future<Uint8List?> readPeerAnnouncement() async {
    if (_peerAnnouncementChar == null) {
      throw BleException('Peer announcement characteristic not available');
    }

    try {
      final value = await _peerAnnouncementChar!.read();
      return Uint8List.fromList(value);
    } catch (e) {
      throw BleException('Failed to read peer announcement: $e');
    }
  }

  /// Stream of incoming packets
  Stream<MeshPacketReceived> receivePackets() {
    return _packetController.stream;
  }

  /// Disconnect from current peer
  Future<void> disconnect() async {
    if (_connectedDevice == null) {
      return;
    }

    try {
      await _connectedDevice!.disconnect();
    } catch (e) {
      // Ignore disconnect errors
    } finally {
      _connectedDevice = null;
      _messageChar = null;
      _handshakeChar = null;
      _peerAnnouncementChar = null;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopScanning();
    await stopAdvertising();
    await disconnect();

    await _packetController.close();
    await _discoveryController.close();

    _isInitialized = false;
  }
}

/// Peer discovery event
class MeshPeerDiscovery {
  final String meshPeerId; // Mesh peer ID (8 bytes hex)
  final String deviceId; // BLE device ID
  final int rssi; // Signal strength in dBm
  final DateTime timestamp;
  final BluetoothDevice device;

  MeshPeerDiscovery({
    required this.meshPeerId,
    required this.deviceId,
    required this.rssi,
    required this.timestamp,
    required this.device,
  });

  @override
  String toString() {
    return 'MeshPeerDiscovery(meshPeerId=$meshPeerId, deviceId=$deviceId, rssi=$rssi)';
  }
}

/// Received packet with metadata
class MeshPacketReceived {
  final Uint8List data;
  final PacketSource source;
  final DateTime timestamp;

  MeshPacketReceived({
    required this.data,
    required this.source,
    required this.timestamp,
  });
}

/// Packet source (which characteristic it came from)
enum PacketSource {
  message,
  handshake,
}

/// BLE exception
class BleException implements Exception {
  final String message;

  BleException(this.message);

  @override
  String toString() => 'BleException: $message';
}
