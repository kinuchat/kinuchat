import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/group_providers.dart';

/// Screen for editing group settings
class GroupSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupSettingsScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _topicController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _topicController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupInfoAsync = ref.watch(groupInfoProvider(widget.groupId));
    final actionState = ref.watch(groupActionsProvider);

    // Initialize controllers when data loads
    groupInfoAsync.whenData((groupInfo) {
      if (groupInfo != null && _nameController.text.isEmpty) {
        _nameController.text = groupInfo.name;
        _topicController.text = groupInfo.topic ?? '';
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: actionState.isLoading ? null : _saveSettings,
              child: actionState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
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

          return Form(
            key: _formKey,
            onChanged: () {
              if (!_hasChanges) {
                setState(() {
                  _hasChanges = true;
                });
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Group avatar
                Center(
                  child: Stack(
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
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18),
                            color: Colors.white,
                            onPressed: () {
                              // TODO: Add avatar picker
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Group name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Group topic
                TextFormField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                // Group info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Group Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.people,
                          '${groupInfo.memberCount} members',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.lock,
                          groupInfo.isEncrypted
                              ? 'End-to-end encrypted'
                              : 'Not encrypted',
                          color: groupInfo.isEncrypted
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Danger zone
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danger Zone',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _confirmDeleteGroup(context, ref),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Delete Group'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: color ?? Colors.grey.shade700),
        ),
      ],
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      ref.read(groupActionsProvider.notifier).updateGroup(
            groupId: widget.groupId,
            name: _nameController.text.trim(),
            topic: _topicController.text.trim().isEmpty
                ? null
                : _topicController.text.trim(),
          );

      setState(() {
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  void _confirmDeleteGroup(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? '
          'This action cannot be undone and all messages will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement group deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Group deletion not yet implemented'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
