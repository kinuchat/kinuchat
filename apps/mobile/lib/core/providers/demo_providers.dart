import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global demo mode toggle
final appDemoModeProvider = StateProvider<bool>((ref) => false);

/// Demo conversation for chat list
class DemoConversation {
  final String id;
  final String name;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isGroup;

  const DemoConversation({
    required this.id,
    required this.name,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isGroup = false,
  });
}

/// Demo message for chat view
class DemoMessage {
  final String id;
  final String content;
  final bool isFromMe;
  final DateTime timestamp;
  final String status;
  final String? senderName;

  const DemoMessage({
    required this.id,
    required this.content,
    required this.isFromMe,
    required this.timestamp,
    this.status = 'delivered',
    this.senderName,
  });
}

/// Demo rally channel
class DemoRallyChannel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int participantCount;
  final String formattedDistance;

  const DemoRallyChannel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.participantCount,
    required this.formattedDistance,
  });
}

/// Demo conversations provider
final demoConversationsProvider = Provider<List<DemoConversation>>((ref) {
  final now = DateTime.now();
  return [
    DemoConversation(
      id: 'demo-1',
      name: 'Sarah Chen',
      lastMessage: 'See you at the rally point! 🎉',
      lastMessageAt: now.subtract(const Duration(minutes: 5)),
      unreadCount: 2,
    ),
    DemoConversation(
      id: 'demo-2',
      name: 'Alex Rivera',
      lastMessage: 'The mesh network is working great here',
      lastMessageAt: now.subtract(const Duration(minutes: 23)),
      unreadCount: 0,
    ),
    DemoConversation(
      id: 'demo-3',
      name: 'Emergency Response Team',
      lastMessage: 'All units check in please',
      lastMessageAt: now.subtract(const Duration(hours: 1)),
      unreadCount: 5,
      isGroup: true,
    ),
    DemoConversation(
      id: 'demo-4',
      name: 'Jordan Kim',
      lastMessage: 'Thanks for relaying my messages!',
      lastMessageAt: now.subtract(const Duration(hours: 2)),
      unreadCount: 0,
    ),
    DemoConversation(
      id: 'demo-5',
      name: 'Neighborhood Watch',
      lastMessage: 'Stay safe everyone',
      lastMessageAt: now.subtract(const Duration(hours: 3)),
      unreadCount: 1,
      isGroup: true,
    ),
    DemoConversation(
      id: 'demo-6',
      name: 'Taylor Swift Fan Club',
      lastMessage: 'Who\'s going to the concert?',
      lastMessageAt: now.subtract(const Duration(hours: 5)),
      unreadCount: 0,
      isGroup: true,
    ),
  ];
});

/// Demo messages for a specific conversation
final demoMessagesProvider = Provider.family<List<DemoMessage>, String>((ref, conversationId) {
  final now = DateTime.now();

  if (conversationId == 'demo-1') {
    return [
      DemoMessage(
        id: 'm1',
        content: 'Hey! Are you coming to the meetup?',
        isFromMe: false,
        timestamp: now.subtract(const Duration(minutes: 30)),
        senderName: 'Sarah',
      ),
      DemoMessage(
        id: 'm2',
        content: 'Yes! Just got the location from the rally channel',
        isFromMe: true,
        timestamp: now.subtract(const Duration(minutes: 28)),
        status: 'read',
      ),
      DemoMessage(
        id: 'm3',
        content: 'Perfect! The mesh network is strong there',
        isFromMe: false,
        timestamp: now.subtract(const Duration(minutes: 25)),
        senderName: 'Sarah',
      ),
      DemoMessage(
        id: 'm4',
        content: 'I\'ll relay messages for anyone who needs it',
        isFromMe: true,
        timestamp: now.subtract(const Duration(minutes: 20)),
        status: 'delivered',
      ),
      DemoMessage(
        id: 'm5',
        content: 'See you at the rally point! 🎉',
        isFromMe: false,
        timestamp: now.subtract(const Duration(minutes: 5)),
        senderName: 'Sarah',
      ),
    ];
  }

  if (conversationId == 'demo-3') {
    return [
      DemoMessage(
        id: 'm1',
        content: 'Emergency drill starts in 10 minutes',
        isFromMe: false,
        timestamp: now.subtract(const Duration(hours: 2)),
        senderName: 'Commander Lee',
      ),
      DemoMessage(
        id: 'm2',
        content: 'Copy that, team alpha ready',
        isFromMe: true,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 55)),
        status: 'read',
      ),
      DemoMessage(
        id: 'm3',
        content: 'Team bravo standing by',
        isFromMe: false,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 50)),
        senderName: 'Maria',
      ),
      DemoMessage(
        id: 'm4',
        content: 'All units check in please',
        isFromMe: false,
        timestamp: now.subtract(const Duration(hours: 1)),
        senderName: 'Commander Lee',
      ),
    ];
  }

  return [
    DemoMessage(
      id: 'm1',
      content: 'This is a demo conversation',
      isFromMe: false,
      timestamp: now.subtract(const Duration(hours: 1)),
    ),
    DemoMessage(
      id: 'm2',
      content: 'Messages are end-to-end encrypted',
      isFromMe: true,
      timestamp: now.subtract(const Duration(minutes: 30)),
      status: 'delivered',
    ),
  ];
});

/// Demo rally channels
final demoRallyChannelsProvider = Provider<List<DemoRallyChannel>>((ref) {
  return const [
    DemoRallyChannel(
      id: 'rally-1',
      name: 'Downtown Rally Point',
      latitude: 37.7749,
      longitude: -122.4194,
      participantCount: 23,
      formattedDistance: '0.3 km',
    ),
    DemoRallyChannel(
      id: 'rally-2',
      name: 'Central Park Meetup',
      latitude: 37.7751,
      longitude: -122.4180,
      participantCount: 15,
      formattedDistance: '0.8 km',
    ),
    DemoRallyChannel(
      id: 'rally-3',
      name: 'Community Center',
      latitude: 37.7760,
      longitude: -122.4200,
      participantCount: 8,
      formattedDistance: '1.1 km',
    ),
    DemoRallyChannel(
      id: 'rally-4',
      name: 'Waterfront Plaza',
      latitude: 37.7735,
      longitude: -122.4220,
      participantCount: 31,
      formattedDistance: '1.5 km',
    ),
  ];
});
