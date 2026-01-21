import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/bridge_providers.dart';

/// Bridge settings screen
class BridgeSettingsScreen extends ConsumerStatefulWidget {
  const BridgeSettingsScreen({super.key});

  @override
  ConsumerState<BridgeSettingsScreen> createState() =>
      _BridgeSettingsScreenState();
}

class _BridgeSettingsScreenState extends ConsumerState<BridgeSettingsScreen> {
  bool _isEnabled = false;
  bool _relayForContactsOnly = false;
  int _maxBandwidthMb = 50;
  int _minBatteryPercent = 30;
  bool _hasConsented = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsAsync = ref.read(bridgeSettingsProvider);
    final settings = settingsAsync.value;

    if (settings != null) {
      setState(() {
        _isEnabled = settings.isEnabled;
        _relayForContactsOnly = settings.relayForContactsOnly;
        _maxBandwidthMb = settings.maxBandwidthMbPerDay;
        _minBatteryPercent = settings.minBatteryPercent;
        _hasConsented = settings.isEnabled;
      });
    }
  }

  void _toggleDemoMode() {
    final currentMode = ref.read(bridgeDemoModeProvider);
    ref.read(bridgeDemoModeProvider.notifier).state = !currentMode;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!currentMode ? 'Demo mode enabled' : 'Demo mode disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final demoMode = ref.watch(bridgeDemoModeProvider);
    final statsAsync = ref.watch(bridgeStatsProvider);
    final stats = statsAsync.value ?? const BridgeStats();

    // Sync with provider when settings change
    ref.listen(bridgeSettingsProvider, (previous, next) {
      final settings = next.value;
      if (settings != null && !_hasConsented) {
        setState(() {
          _isEnabled = settings.isEnabled;
          _relayForContactsOnly = settings.relayForContactsOnly;
          _maxBandwidthMb = settings.maxBandwidthMbPerDay;
          _minBatteryPercent = settings.minBatteryPercent;
          _hasConsented = settings.isEnabled;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _toggleDemoMode,
          child: Text(
            demoMode ? 'Bridge Mode (Demo)' : 'Bridge Mode',
          ),
        ),
      ),
      body: ListView(
        children: [
          // Explanation card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hub, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'What is Bridge Mode?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'When you enable Bridge Mode, your device helps relay encrypted '
                  'messages for other Kinu users who are offline. You become part '
                  'of the network that keeps everyone connected.',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
                const SizedBox(height: 12),
                Text(
                  'Messages are end-to-end encrypted - you cannot read them. '
                  'You only help deliver them.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Consent section
          if (!_hasConsented && !_isEnabled)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Before You Enable',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bridge Mode will:\n'
                    '• Use your mobile data/WiFi to relay messages\n'
                    '• Run in the background when the app is closed\n'
                    '• Use some battery (we try to minimize this)',
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasConsented = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('I Understand'),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Enable toggle
          SwitchListTile(
            title: const Text('Enable Bridge Mode'),
            subtitle: Text(
              (_isEnabled || demoMode) ? 'Relaying messages for others' : 'Not relaying',
            ),
            value: _isEnabled || demoMode,
            onChanged: demoMode
                ? null  // Disable toggle in demo mode
                : (_hasConsented || _isEnabled)
                    ? (value) {
                        setState(() {
                          _isEnabled = value;
                        });
                        _saveSettings();
                      }
                    : null,
          ),

          const Divider(),

          // Settings (only show when enabled)
          if (_isEnabled || demoMode) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Relay Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            // Contacts only toggle
            SwitchListTile(
              title: const Text('Relay for Contacts Only'),
              subtitle: const Text(
                'Only relay messages for people in your contacts',
              ),
              value: _relayForContactsOnly,
              onChanged: (value) {
                setState(() {
                  _relayForContactsOnly = value;
                });
                _saveSettings();
              },
            ),

            // Bandwidth limit
            ListTile(
              title: const Text('Daily Bandwidth Limit'),
              subtitle: Text('$_maxBandwidthMb MB per day'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showBandwidthDialog(),
            ),

            // Battery threshold
            ListTile(
              title: const Text('Minimum Battery Level'),
              subtitle: Text(
                'Pause relaying below $_minBatteryPercent%',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showBatteryDialog(),
            ),

            const Divider(),

            // Statistics
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Statistics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Messages Relayed'),
              trailing: Text(
                '${stats.messagesRelayed}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.data_usage),
              title: const Text('Bandwidth Used Today'),
              trailing: Text(
                '${stats.bandwidthUsedMb.toStringAsFixed(1)} MB',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            if (demoMode)
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Nearby Peers'),
                trailing: Text(
                  '${stats.nearbyPeers}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _showBandwidthDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Bandwidth Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Maximum data to use per day for relaying:'),
            const SizedBox(height: 16),
            ...[10, 25, 50, 100, 200].map(
              (mb) => RadioListTile<int>(
                title: Text('$mb MB'),
                value: mb,
                groupValue: _maxBandwidthMb,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _maxBandwidthMb = result;
      });
      _saveSettings();
    }
  }

  Future<void> _showBatteryDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Minimum Battery Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pause relaying when battery drops below:'),
            const SizedBox(height: 16),
            ...[10, 20, 30, 40, 50].map(
              (percent) => RadioListTile<int>(
                title: Text('$percent%'),
                value: percent,
                groupValue: _minBatteryPercent,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _minBatteryPercent = result;
      });
      _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    await ref.read(bridgeModeProvider.notifier).updateSettings(
      isEnabled: _isEnabled,
      relayForContactsOnly: _relayForContactsOnly,
      maxBandwidthMbPerDay: _maxBandwidthMb,
      minBatteryPercent: _minBatteryPercent,
    );
  }
}
