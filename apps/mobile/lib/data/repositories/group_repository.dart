import 'package:matrix/matrix.dart';
import 'package:meshlink_core/database/app_database.dart';

import '../services/matrix_service.dart';

/// Member info for a group
class GroupMemberInfo {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final GroupRole role;
  final Membership membership;

  GroupMemberInfo({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.membership,
  });
}

/// Group info
class GroupInfo {
  final String id;
  final String name;
  final String? topic;
  final String? avatarUrl;
  final int memberCount;
  final bool isEncrypted;
  final bool isAdmin;

  GroupInfo({
    required this.id,
    required this.name,
    this.topic,
    this.avatarUrl,
    required this.memberCount,
    required this.isEncrypted,
    required this.isAdmin,
  });
}

/// Repository for managing group chats
class GroupRepository {
  final MatrixService _matrixService;
  final AppDatabase _database;

  GroupRepository({
    required MatrixService matrixService,
    required AppDatabase database,
  })  : _matrixService = matrixService,
        _database = database;

  /// Create a new group chat
  Future<ConversationEntity> createGroup({
    required String name,
    List<String>? memberIds,
    String? topic,
  }) async {
    // Create Matrix room with encryption
    final roomId = await _matrixService.createGroup(
      name: name,
      initialMembers: memberIds,
      isEncrypted: true,
      topic: topic,
    );

    // Create local conversation entity
    final now = DateTime.now();
    await _database.upsertConversation(
      ConversationsCompanion.insert(
        id: roomId,
        type: 'group',
        name: Value(name),
        createdAt: now,
      ),
    );

    // Get the created conversation
    final conversation = await _database.getConversationById(roomId);
    if (conversation == null) {
      throw Exception('Failed to create group conversation');
    }

    return conversation;
  }

  /// Get info about a group
  Future<GroupInfo?> getGroupInfo(String groupId) async {
    final room = _matrixService.getRoomById(groupId);
    if (room == null) return null;

    return GroupInfo(
      id: groupId,
      name: room.name,
      topic: room.topic,
      avatarUrl: room.avatar?.toString(),
      memberCount: room.summary.mJoinedMemberCount ?? 0,
      isEncrypted: room.encrypted,
      isAdmin: _matrixService.isGroupAdmin(groupId),
    );
  }

  /// Invite a member to a group
  Future<void> inviteMember({
    required String groupId,
    required String userId,
  }) async {
    await _matrixService.inviteToGroup(
      roomId: groupId,
      userId: userId,
    );

    // Add to local group members table
    await _database.addGroupMember(
      GroupMembersCompanion.insert(
        conversationId: groupId,
        contactId: userId,
        role: const Value('member'),
        joinedAt: DateTime.now(),
      ),
    );
  }

  /// Remove a member from a group
  Future<void> removeMember({
    required String groupId,
    required String userId,
    String? reason,
  }) async {
    await _matrixService.kickFromGroup(
      roomId: groupId,
      userId: userId,
      reason: reason,
    );

    // Remove from local group members table
    await _database.removeGroupMember(groupId, userId);
  }

  /// Ban a member from a group
  Future<void> banMember({
    required String groupId,
    required String userId,
    String? reason,
  }) async {
    await _matrixService.banFromGroup(
      roomId: groupId,
      userId: userId,
      reason: reason,
    );

    // Remove from local group members table
    await _database.removeGroupMember(groupId, userId);
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    await _matrixService.leaveGroup(groupId);

    // Delete local conversation and members
    await _database.deleteConversation(groupId);
  }

  /// Get members of a group
  Future<List<GroupMemberInfo>> getMembers(String groupId) async {
    final users = await _matrixService.getGroupMembers(groupId);
    final room = _matrixService.getRoomById(groupId);

    return users.map((user) {
      final powerLevel = room?.getPowerLevelByUserId(user.id) ?? 0;

      return GroupMemberInfo(
        id: user.id,
        displayName: user.displayName ?? user.id,
        avatarUrl: user.avatarUrl?.toString(),
        role: powerLevel.toGroupRole(),
        membership: user.membership,
      );
    }).toList();
  }

  /// Update a member's role
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupRole role,
  }) async {
    await _matrixService.setMemberRole(
      roomId: groupId,
      userId: userId,
      role: role,
    );

    // Update local database
    final members = await _database.getGroupMembers(groupId);
    final member = members.where((m) => m.contactId == userId).firstOrNull;
    if (member != null) {
      await _database.addGroupMember(
        GroupMembersCompanion(
          id: Value(member.id),
          conversationId: Value(groupId),
          contactId: Value(userId),
          role: Value(role.name),
          joinedAt: Value(member.joinedAt),
        ),
      );
    }
  }

  /// Update group settings
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? topic,
    String? avatarUrl,
  }) async {
    await _matrixService.updateGroupSettings(
      roomId: groupId,
      name: name,
      topic: topic,
      avatarUrl: avatarUrl,
    );

    // Update local conversation
    if (name != null) {
      await _database.upsertConversation(
        ConversationsCompanion(
          id: Value(groupId),
          name: Value(name),
          type: const Value('group'),
          createdAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Get all groups (non-DM rooms)
  Future<List<ConversationEntity>> getAllGroups() async {
    final conversations = await _database.getAllConversations();
    return conversations.where((c) => c.type == 'group').toList();
  }

  /// Check if a room is a group
  bool isGroup(String roomId) {
    return _matrixService.isGroup(roomId);
  }

  /// Check if current user is admin of a group
  bool isAdmin(String groupId) {
    return _matrixService.isGroupAdmin(groupId);
  }
}
