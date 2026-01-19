import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';

import '../../../core/providers/group_providers.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/services/matrix_service.dart';

/// Screen showing group details and member management
class GroupInfoScreen extends ConsumerWidget {
  final String groupId;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupInfoAsync = ref.watch(groupInfoProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final isAdmin = ref.watch(isGroupAdminProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showGroupSettings(context, ref),
            ),
        ],
      ),
      body: groupInfoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (groupInfo) {
          if (groupInfo == null) {
            return const Center(child: Text('Group not found'));
          }

          return ListView(
            children: [
              // Group header
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade200,
                      backgroundImage: groupInfo.avatarUrl != null
                          ? NetworkImage(groupInfo.avatarUrl!)
                          : null,
                      child: groupInfo.avatarUrl == null
                          ? Icon(
                              Icons.group,
                              size: 50,
                              color: Colors.blue.shade700,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      groupInfo.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (groupInfo.topic != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        groupInfo.topic!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoChip(
                          Icons.people,
                          '${groupInfo.memberCount} members',
                        ),
                        const SizedBox(width: 12),
                        if (groupInfo.isEncrypted)
                          _buildInfoChip(
                            Icons.lock,
                            'Encrypted',
                            color: Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              if (isAdmin) ...[
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Add Members'),
                  onTap: () => _showInviteMemberDialog(context, ref),
                ),
                const Divider(),
              ],

              // Members section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Members',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              membersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading members: $error'),
                ),
                data: (members) => Column(
                  children: members.map((member) {
                    return _buildMemberTile(
                      context,
                      ref,
                      member,
                      isAdmin,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Leave group button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _confirmLeaveGroup(context, ref),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Leave Group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    WidgetRef ref,
    GroupMemberInfo member,
    bool isAdmin,
  ) {
    final roleColor = switch (member.role) {
      GroupRole.owner => Colors.purple,
      GroupRole.admin => Colors.blue,
      GroupRole.member => Colors.grey,
    };

    final roleLabel = switch (member.role) {
      GroupRole.owner => 'Owner',
      GroupRole.admin => 'Admin',
      GroupRole.member => '',
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
        child: member.avatarUrl == null
            ? Text(member.displayName[0].toUpperCase())
            : null,
      ),
      title: Row(
        children: [
          Expanded(child: Text(member.displayName)),
          if (roleLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(member.id),
      trailing: isAdmin && member.role != GroupRole.owner
          ? PopupMenuButton<String>(
              onSelected: (action) =>
                  _handleMemberAction(context, ref, member, action),
              itemBuilder: (context) => [
                if (member.role != GroupRole.admin)
                  const PopupMenuItem(
                    value: 'make_admin',
                    child: Text('Make Admin'),
                  ),
                if (member.role == GroupRole.admin)
                  const PopupMenuItem(
                    value: 'remove_admin',
                    child: Text('Remove Admin'),
                  ),
                const PopupMenuItem(
                  value: 'kick',
                  child: Text('Remove from Group'),
                ),
              ],
            )
          : null,
    );
  }

  void _handleMemberAction(
    BuildContext context,
    WidgetRef ref,
    GroupMemberInfo member,
    String action,
  ) {
    switch (action) {
      case 'make_admin':
        ref.read(groupActionsProvider.notifier).updateMemberRole(
              groupId: groupId,
              userId: member.id,
              role: GroupRole.admin,
            );
        break;
      case 'remove_admin':
        ref.read(groupActionsProvider.notifier).updateMemberRole(
              groupId: groupId,
              userId: member.id,
              role: GroupRole.member,
            );
        break;
      case 'kick':
        _confirmKickMember(context, ref, member);
        break;
    }
  }

  void _confirmKickMember(
    BuildContext context,
    WidgetRef ref,
    GroupMemberInfo member,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(groupActionsProvider.notifier).removeMember(
                    groupId: groupId,
                    userId: member.id,
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showInviteMemberDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Member'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'User ID',
            hintText: '@username:kinuchat.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                ref.read(groupActionsProvider.notifier).inviteMember(
                      groupId: groupId,
                      userId: controller.text,
                    );
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  void _showGroupSettings(BuildContext context, WidgetRef ref) {
    // TODO: Navigate to group settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group settings coming soon')),
    );
  }

  void _confirmLeaveGroup(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? '
          'You will need to be invited again to rejoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(groupActionsProvider.notifier).leaveGroup(groupId);
              Navigator.of(context).pop(); // Go back to conversations
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
