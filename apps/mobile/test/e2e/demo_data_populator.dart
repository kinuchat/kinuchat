/// Demo Data Populator for Screenshots
///
/// This script generates realistic demo data that can be used to:
/// 1. Populate the app with sample conversations for screenshots
/// 2. Show all features working in demo mode
/// 3. Create consistent demo states for marketing materials
///
/// Run with: dart test/e2e/demo_data_populator.dart

import 'dart:convert';
import 'dart:io';

import 'test_utils.dart';

void main() async {
  print('MeshLink Demo Data Generator');
  print('============================\n');

  final generator = DemoDataGenerator();

  // Generate all demo data
  final demoData = DemoData(
    conversations: generator.generateConversations(),
    rallyChannel: generator.generateRallyChannel(),
    bridgeStats: generator.generateBridgeStats(),
    contacts: generator.generateContacts(),
    supporterTiers: generator.generateSupporterTiers(),
  );

  // Output as JSON for easy import
  final json = demoData.toJson();
  final prettyJson = const JsonEncoder.withIndent('  ').convert(json);

  // Save to file
  final outputFile = File('test/e2e/demo_data.json');
  await outputFile.writeAsString(prettyJson);
  print('Demo data saved to: ${outputFile.path}\n');

  // Print summary
  print('Generated Data Summary:');
  print('-----------------------');
  print('Conversations: ${demoData.conversations.length}');
  print('Rally Messages: ${demoData.rallyChannel.messages.length}');
  print('Contacts: ${demoData.contacts.length}');
  print('Supporter Tiers: ${demoData.supporterTiers.length}');
  print('');

  // Print screenshot scenarios
  printScreenshotScenarios(demoData);
}

void printScreenshotScenarios(DemoData data) {
  print('\nScreenshot Scenarios:');
  print('=====================\n');

  print('1. CHAT LIST (Home Screen)');
  print('   - Shows ${data.conversations.length} conversations');
  print('   - Mix of 1:1 and group chats');
  print('   - Unread badges visible');
  print('   - Mesh status banner: "📡 Mesh Active · 12 peers nearby"');
  print('');

  print('2. CHAT VIEW (Conversation)');
  print('   Conversation: Alice Chen');
  for (final msg in data.conversations.first.messages) {
    final prefix = msg.isFromMe ? '   [You]' : '   [Alice]';
    print('$prefix ${msg.text}');
  }
  print('   Transport: Cloud (☁️)');
  print('');

  print('3. MESH CONVERSATION');
  final meshConv = data.conversations.firstWhere(
    (c) => c.transportIndicator == 'mesh',
    orElse: () => data.conversations.first,
  );
  print('   Conversation: ${meshConv.contactName}');
  print('   Transport: Mesh (📡)');
  print('   Shows: "via Mesh" indicator');
  print('');

  print('4. RALLY MODE');
  print('   Channel: #${data.rallyChannel.channelId}');
  print('   People nearby: ~${data.rallyChannel.peopleCount}');
  print('   Messages:');
  for (final msg in data.rallyChannel.messages) {
    final badge = msg.isVerified ? ' ✓' : '';
    final urgent = msg.isUrgent ? ' ⚠️' : '';
    print('     ${msg.anonymousName}$badge$urgent: ${msg.text}');
  }
  print('');

  print('5. BRIDGE MODE SETTINGS');
  print('   Status: ${data.bridgeStats.isActive ? "Active" : "Disabled"}');
  print('   Messages relayed: ${data.bridgeStats.messagesRelayed}');
  print('   Bandwidth used: ${data.bridgeStats.bandwidthUsedMb.toStringAsFixed(1)} MB');
  print('   Nearby peers: ${data.bridgeStats.nearbyPeers}');
  print('');

  print('6. SUPPORTER TIERS');
  for (final tier in data.supporterTiers) {
    print('   ${tier.badge} ${tier.name} - ${tier.price}');
    print('      ${tier.description}');
  }
  print('');

  print('7. CONTACTS LIST');
  for (final contact in data.contacts) {
    final verified = contact.isVerified ? ' ✓' : '';
    final mesh = contact.isMeshNearby ? ' (📡 nearby)' : '';
    print('   ${contact.initials} ${contact.name}$verified$mesh');
    print('      ${contact.lastSeen}');
  }
  print('');
}

/// Container for all demo data
class DemoData {
  final List<DemoConversation> conversations;
  final DemoRallyChannel rallyChannel;
  final DemoBridgeStats bridgeStats;
  final List<DemoContact> contacts;
  final List<DemoSupporterTier> supporterTiers;

  DemoData({
    required this.conversations,
    required this.rallyChannel,
    required this.bridgeStats,
    required this.contacts,
    required this.supporterTiers,
  });

  Map<String, dynamic> toJson() => {
        'conversations': conversations
            .map((c) => {
                  'contactName': c.contactName,
                  'avatarInitials': c.avatarInitials,
                  'lastSeen': c.lastSeen,
                  'isGroup': c.isGroup,
                  'memberCount': c.memberCount,
                  'unreadCount': c.unreadCount,
                  'transportIndicator': c.transportIndicator,
                  'messages': c.messages
                      .map((m) => {
                            'text': m.text,
                            'isFromMe': m.isFromMe,
                            'timestamp': m.timestamp.toIso8601String(),
                            'status': m.status,
                          })
                      .toList(),
                })
            .toList(),
        'rallyChannel': {
          'channelId': rallyChannel.channelId,
          'location': rallyChannel.location,
          'peopleCount': rallyChannel.peopleCount,
          'messages': rallyChannel.messages
              .map((m) => {
                    'anonymousName': m.anonymousName,
                    'text': m.text,
                    'timestamp': m.timestamp.toIso8601String(),
                    'isVerified': m.isVerified,
                    'isUrgent': m.isUrgent,
                    'isMe': m.isMe,
                  })
              .toList(),
        },
        'bridgeStats': {
          'messagesRelayed': bridgeStats.messagesRelayed,
          'bandwidthUsedMb': bridgeStats.bandwidthUsedMb,
          'nearbyPeers': bridgeStats.nearbyPeers,
          'isActive': bridgeStats.isActive,
          'uptimeMinutes': bridgeStats.uptime.inMinutes,
        },
        'contacts': contacts
            .map((c) => {
                  'name': c.name,
                  'initials': c.initials,
                  'isVerified': c.isVerified,
                  'lastSeen': c.lastSeen,
                  'isMeshNearby': c.isMeshNearby,
                })
            .toList(),
        'supporterTiers': supporterTiers
            .map((t) => {
                  'name': t.name,
                  'price': t.price,
                  'badge': t.badge,
                  'description': t.description,
                })
            .toList(),
      };
}
