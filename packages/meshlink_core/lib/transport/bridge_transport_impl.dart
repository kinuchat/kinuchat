import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

import 'bridge_transport.dart';

/// Priority levels for relay messages
enum RelayPriority { normal, urgent, emergency }

/// Relay envelope format
class RelayEnvelope {
  final String recipientKeyHash;
  final String encryptedPayload;
  final int ttlHours;
  final RelayPriority priority;
  final String nonce;
  final int createdAt;

  RelayEnvelope({
    required this.recipientKeyHash,
    required this.encryptedPayload,
    this.ttlHours = 4,
    this.priority = RelayPriority.normal,
    required this.nonce,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'recipient_key_hash': recipientKeyHash,
        'encrypted_payload': encryptedPayload,
        'ttl_hours': ttlHours,
        'priority': priority.name,
        'nonce': nonce,
        'created_at': createdAt,
      };

  factory RelayEnvelope.fromJson(Map<String, dynamic> json) {
    return RelayEnvelope(
      recipientKeyHash: json['recipient_key_hash'] as String,
      encryptedPayload: json['encrypted_payload'] as String,
      ttlHours: json['ttl_hours'] as int? ?? 4,
      priority: RelayPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => RelayPriority.normal,
      ),
      nonce: json['nonce'] as String,
      createdAt: json['created_at'] as int,
    );
  }
}

/// Stored envelope with server-assigned ID
class StoredEnvelope {
  final String id;
  final RelayEnvelope envelope;
  final int storedAt;

  StoredEnvelope({
    required this.id,
    required this.envelope,
    required this.storedAt,
  });

  factory StoredEnvelope.fromJson(Map<String, dynamic> json) {
    return StoredEnvelope(
      id: json['id'] as String,
      envelope: RelayEnvelope.fromJson(json),
      storedAt: json['stored_at'] as int,
    );
  }
}

/// WebSocket message types
sealed class WsMessage {
  Map<String, dynamic> toJson();

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'subscribe' => WsSubscribe(keyHash: json['key_hash'] as String),
      'subscribed' => WsSubscribed(keyHash: json['key_hash'] as String),
      'new_message' => WsNewMessage(
          envelope: StoredEnvelope.fromJson(json['envelope'] as Map<String, dynamic>),
        ),
      'ack' => WsAck(messageIds: List<String>.from(json['message_ids'] as List)),
      'acked' => WsAcked(deleted: json['deleted'] as int),
      'ping' => WsPing(),
      'pong' => WsPong(),
      'error' => WsError(message: json['message'] as String),
      _ => throw FormatException('Unknown message type: $type'),
    };
  }
}

class WsSubscribe extends WsMessage {
  final String keyHash;
  WsSubscribe({required this.keyHash});

  @override
  Map<String, dynamic> toJson() => {'type': 'subscribe', 'key_hash': keyHash};
}

class WsSubscribed extends WsMessage {
  final String keyHash;
  WsSubscribed({required this.keyHash});

  @override
  Map<String, dynamic> toJson() => {'type': 'subscribed', 'key_hash': keyHash};
}

class WsNewMessage extends WsMessage {
  final StoredEnvelope envelope;
  WsNewMessage({required this.envelope});

  @override
  Map<String, dynamic> toJson() => {'type': 'new_message', 'envelope': envelope};
}

class WsAck extends WsMessage {
  final List<String> messageIds;
  WsAck({required this.messageIds});

  @override
  Map<String, dynamic> toJson() => {'type': 'ack', 'message_ids': messageIds};
}

class WsAcked extends WsMessage {
  final int deleted;
  WsAcked({required this.deleted});

  @override
  Map<String, dynamic> toJson() => {'type': 'acked', 'deleted': deleted};
}

class WsPing extends WsMessage {
  @override
  Map<String, dynamic> toJson() => {'type': 'ping'};
}

class WsPong extends WsMessage {
  @override
  Map<String, dynamic> toJson() => {'type': 'pong'};
}

class WsError extends WsMessage {
  final String message;
  WsError({required this.message});

  @override
  Map<String, dynamic> toJson() => {'type': 'error', 'message': message};
}

/// Bridge transport implementation using HTTP + WebSocket
class BridgeTransportImpl implements BridgeTransport {
  final String relayServerUrl;
  final String _myKeyHash;
  final http.Client _httpClient;

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;
  bool _isSubscribed = false;

  // Stream controller for incoming messages
  final _messageController = StreamController<StoredEnvelope>.broadcast();

  // Pending acknowledgments
  final List<String> _pendingAcks = [];
  Timer? _ackTimer;

  BridgeTransportImpl({
    required this.relayServerUrl,
    required String myPublicKey,
    http.Client? httpClient,
  })  : _myKeyHash = _computeKeyHash(myPublicKey),
        _httpClient = httpClient ?? http.Client();

  /// Compute SHA256 hash of public key (base64 encoded)
  static String _computeKeyHash(String publicKey) {
    final bytes = base64.decode(publicKey);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  /// Stream of incoming messages
  Stream<StoredEnvelope> get messageStream => _messageController.stream;

  /// Whether the bridge transport is connected
  bool get isConnected => _isConnected;

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$relayServerUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> sendMessage({
    required String recipientId,
    required Map<String, dynamic> message,
  }) async {
    // The recipientId should be the recipient's X25519 public key (base64)
    final recipientKeyHash = _computeKeyHash(recipientId);

    // Generate nonce for deduplication
    final nonce = base64.encode(List.generate(16, (_) => DateTime.now().microsecond));

    final envelope = RelayEnvelope(
      recipientKeyHash: recipientKeyHash,
      encryptedPayload: base64.encode(utf8.encode(jsonEncode(message))),
      ttlHours: 4,
      priority: RelayPriority.normal,
      nonce: nonce,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final response = await _httpClient.post(
      Uri.parse('$relayServerUrl/relay/upload'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'envelope': envelope.toJson()}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to upload message: ${response.body}');
    }
  }

  /// Send a pre-encrypted message
  Future<String> sendEncryptedMessage({
    required String recipientKeyHash,
    required String encryptedPayload,
    int ttlHours = 4,
    RelayPriority priority = RelayPriority.normal,
  }) async {
    final nonce = base64.encode(
      List.generate(16, (i) => (DateTime.now().microsecondsSinceEpoch + i) % 256),
    );

    final envelope = RelayEnvelope(
      recipientKeyHash: recipientKeyHash,
      encryptedPayload: encryptedPayload,
      ttlHours: ttlHours,
      priority: priority,
      nonce: nonce,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final response = await _httpClient.post(
      Uri.parse('$relayServerUrl/relay/upload'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'envelope': envelope.toJson()}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to upload message: ${response.body}');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return result['id'] as String;
  }

  @override
  Future<List<Map<String, dynamic>>> pollMessages() async {
    final response = await _httpClient.get(
      Uri.parse('$relayServerUrl/relay/poll?key_hash=$_myKeyHash&limit=50'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to poll messages: ${response.body}');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = (result['messages'] as List).cast<Map<String, dynamic>>();

    return messages.map((m) {
      final encryptedPayload = m['encrypted_payload'] as String;
      try {
        final decrypted = utf8.decode(base64.decode(encryptedPayload));
        return jsonDecode(decrypted) as Map<String, dynamic>;
      } catch (_) {
        // Return raw payload if decoding fails (already encrypted)
        return m;
      }
    }).toList();
  }

  /// Poll for encrypted messages (returns StoredEnvelope objects)
  Future<List<StoredEnvelope>> pollEncryptedMessages({int limit = 50}) async {
    final response = await _httpClient.get(
      Uri.parse('$relayServerUrl/relay/poll?key_hash=$_myKeyHash&limit=$limit'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to poll messages: ${response.body}');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = (result['messages'] as List)
        .map((m) => StoredEnvelope.fromJson(m as Map<String, dynamic>))
        .toList();

    return messages;
  }

  /// Acknowledge messages (delete them from relay)
  Future<int> acknowledgeMessages(List<String> messageIds) async {
    if (messageIds.isEmpty) return 0;

    final response = await _httpClient.post(
      Uri.parse('$relayServerUrl/relay/ack'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message_ids': messageIds,
        'key_hash': _myKeyHash,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to acknowledge messages: ${response.body}');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return result['deleted'] as int;
  }

  /// Get count of pending messages
  Future<int> getPendingCount() async {
    final response = await _httpClient.get(
      Uri.parse('$relayServerUrl/relay/pending?key_hash=$_myKeyHash'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get pending count: ${response.body}');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return result['count'] as int;
  }

  /// Connect to WebSocket for real-time message delivery
  Future<void> connectWebSocket() async {
    if (_isConnected) return;

    final wsUrl = relayServerUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse('$wsUrl/relay/ws'));
      _isConnected = true;

      _wsSubscription = _wsChannel!.stream.listen(
        (data) => _handleWsMessage(data as String),
        onError: (error) {
          _isConnected = false;
          _isSubscribed = false;
          // Attempt reconnection after delay
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isConnected) connectWebSocket();
          });
        },
        onDone: () {
          _isConnected = false;
          _isSubscribed = false;
        },
      );

      // Subscribe to our key hash
      _sendWsMessage(WsSubscribe(keyHash: _myKeyHash));

      // Start ping timer
      _startPingTimer();
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  void _handleWsMessage(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final message = WsMessage.fromJson(json);

      switch (message) {
        case WsSubscribed():
          _isSubscribed = true;
        case WsNewMessage(:final envelope):
          _messageController.add(envelope);
          // Queue acknowledgment
          _queueAck(envelope.id);
        case WsAcked(:final deleted):
          // Acknowledgment confirmed
          break;
        case WsPong():
          // Keepalive response
          break;
        case WsError(:final message):
          // Handle error
          print('WebSocket error: $message');
          break;
        default:
          break;
      }
    } catch (e) {
      print('Failed to parse WebSocket message: $e');
    }
  }

  void _sendWsMessage(WsMessage message) {
    if (_wsChannel != null) {
      _wsChannel!.sink.add(jsonEncode(message.toJson()));
    }
  }

  void _queueAck(String messageId) {
    _pendingAcks.add(messageId);

    // Batch acknowledgments
    _ackTimer?.cancel();
    _ackTimer = Timer(const Duration(seconds: 1), _flushAcks);
  }

  void _flushAcks() {
    if (_pendingAcks.isEmpty) return;

    final acks = List<String>.from(_pendingAcks);
    _pendingAcks.clear();

    _sendWsMessage(WsAck(messageIds: acks));
  }

  Timer? _pingTimer;

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        _sendWsMessage(WsPing());
      }
    });
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _ackTimer?.cancel();
    _flushAcks();

    await _wsSubscription?.cancel();
    await _wsChannel?.sink.close();

    _wsChannel = null;
    _isConnected = false;
    _isSubscribed = false;
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
