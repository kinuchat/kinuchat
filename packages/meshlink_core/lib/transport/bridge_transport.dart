/// Bridge relay transport interface
///
/// Handles message relay through internet-connected nodes for offline users.
/// Part of Phase 5 implementation.
abstract class BridgeTransport {
  /// Send a message via bridge relay
  ///
  /// The message will be encrypted and stored on the relay server
  /// until the recipient polls for it.
  Future<void> sendMessage({
    required String recipientId,
    required Map<String, dynamic> message,
  });

  /// Check if bridge transport is available
  ///
  /// Returns true if the relay server is reachable and healthy.
  Future<bool> isAvailable();

  /// Poll for messages from relay server
  ///
  /// Returns a list of messages waiting for this user on the relay.
  Future<List<Map<String, dynamic>>> pollMessages();
}

/// Bridge transport configuration
class BridgeConfig {
  /// Relay server URL
  final String relayServerUrl;

  /// Whether bridge mode is enabled
  final bool isEnabled;

  /// Only relay for contacts (not strangers)
  final bool relayForContactsOnly;

  /// Maximum bandwidth to use per day (MB)
  final int maxBandwidthMbPerDay;

  /// Minimum battery percent to enable relaying
  final int minBatteryPercent;

  const BridgeConfig({
    required this.relayServerUrl,
    this.isEnabled = false,
    this.relayForContactsOnly = false,
    this.maxBandwidthMbPerDay = 50,
    this.minBatteryPercent = 30,
  });

  BridgeConfig copyWith({
    String? relayServerUrl,
    bool? isEnabled,
    bool? relayForContactsOnly,
    int? maxBandwidthMbPerDay,
    int? minBatteryPercent,
  }) {
    return BridgeConfig(
      relayServerUrl: relayServerUrl ?? this.relayServerUrl,
      isEnabled: isEnabled ?? this.isEnabled,
      relayForContactsOnly: relayForContactsOnly ?? this.relayForContactsOnly,
      maxBandwidthMbPerDay: maxBandwidthMbPerDay ?? this.maxBandwidthMbPerDay,
      minBatteryPercent: minBatteryPercent ?? this.minBatteryPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'relayServerUrl': relayServerUrl,
        'isEnabled': isEnabled,
        'relayForContactsOnly': relayForContactsOnly,
        'maxBandwidthMbPerDay': maxBandwidthMbPerDay,
        'minBatteryPercent': minBatteryPercent,
      };

  factory BridgeConfig.fromJson(Map<String, dynamic> json) {
    return BridgeConfig(
      relayServerUrl: json['relayServerUrl'] as String,
      isEnabled: json['isEnabled'] as bool? ?? false,
      relayForContactsOnly: json['relayForContactsOnly'] as bool? ?? false,
      maxBandwidthMbPerDay: json['maxBandwidthMbPerDay'] as int? ?? 50,
      minBatteryPercent: json['minBatteryPercent'] as int? ?? 30,
    );
  }
}
