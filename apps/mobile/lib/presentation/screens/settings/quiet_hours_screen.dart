import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';

import '../../../core/providers/settings_provider.dart';

/// Quiet hours configuration screen
class QuietHoursScreen extends ConsumerStatefulWidget {
  const QuietHoursScreen({super.key});

  @override
  ConsumerState<QuietHoursScreen> createState() => _QuietHoursScreenState();
}

class _QuietHoursScreenState extends ConsumerState<QuietHoursScreen> {
  late bool _enabled;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _enabled = settings.quietHoursEnabled;
    _startTime = settings.quietHoursStart;
    _endTime = settings.quietHoursEnd;
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Select quiet hours start time',
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'Select quiet hours end time',
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    await ref.read(settingsProvider.notifier).setQuietHours(
          enabled: _enabled,
          start: _startTime,
          end: _endTime,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiet hours saved')),
      );
      setState(() {
        _hasChanges = false;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isCurrentlyQuiet = settings.isInQuietHours;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiet Hours'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          // Status indicator
          if (_enabled && isCurrentlyQuiet)
            Container(
              margin: const EdgeInsets.all(Spacing.md),
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.do_not_disturb_on,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      'Quiet hours are currently active',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Enable toggle
          SwitchListTile(
            secondary: const Icon(Icons.schedule_outlined),
            title: const Text('Enable Quiet Hours'),
            subtitle: const Text('Mute notification sounds during scheduled times'),
            value: _enabled,
            onChanged: (value) {
              setState(() {
                _enabled = value;
                _hasChanges = true;
              });
            },
          ),

          const Divider(height: Spacing.xl),

          // Time settings
          _buildSectionHeader(context, 'Schedule'),

          ListTile(
            enabled: _enabled,
            leading: const Icon(Icons.nightlight_outlined),
            title: const Text('Start Time'),
            subtitle: Text(
              _formatTime(_startTime),
              style: TextStyle(
                color: _enabled ? null : Theme.of(context).disabledColor,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _enabled ? _selectStartTime : null,
          ),

          ListTile(
            enabled: _enabled,
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('End Time'),
            subtitle: Text(
              _formatTime(_endTime),
              style: TextStyle(
                color: _enabled ? null : Theme.of(context).disabledColor,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _enabled ? _selectEndTime : null,
          ),

          const SizedBox(height: Spacing.lg),

          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Text(
              'During quiet hours, notification sounds and vibrations will be muted. '
              'You will still receive messages and see notifications silently.',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),

          const SizedBox(height: Spacing.md),

          // Show calculated duration
          if (_enabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Text(
                _getScheduleDescription(),
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getScheduleDescription() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    int durationMinutes;
    if (startMinutes > endMinutes) {
      // Overnight: e.g., 10 PM to 7 AM = (24*60 - 10*60) + 7*60 = 540 minutes = 9 hours
      durationMinutes = (24 * 60 - startMinutes) + endMinutes;
    } else {
      durationMinutes = endMinutes - startMinutes;
    }

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (minutes == 0) {
      return 'Notifications will be muted for $hours hours each day.';
    } else {
      return 'Notifications will be muted for $hours hours and $minutes minutes each day.';
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
