# MeshLink Battery Optimization Guide

## Overview

BLE mesh networking is battery-intensive due to continuous scanning and advertising. This guide provides strategies to optimize battery life while maintaining mesh functionality.

## Current Baseline

**Expected Battery Usage (Phase 2):**
- **Foreground (active scanning):** ~8-10% per hour
- **Background (reduced scanning):** ~3-5% per hour
- **Idle (mesh disabled):** <1% per hour

## Optimization Strategies

### 1. Adaptive Scan Intervals

**Problem:** Continuous scanning at fixed 30-second intervals drains battery.

**Solution:** Dynamically adjust scan interval based on activity.

#### Implementation

Update `/packages/meshlink_core/lib/mesh/ble_constants.dart`:

```dart
class BleConstants {
  // Current fixed interval
  static const Duration scanInterval = Duration(seconds: 30);

  // Adaptive intervals
  static const Duration scanIntervalActive = Duration(seconds: 15);    // When user is active
  static const Duration scanIntervalIdle = Duration(seconds: 60);      // When idle >5 min
  static const Duration scanIntervalBackground = Duration(minutes: 2);  // When backgrounded
}
```

Update `/packages/meshlink_core/lib/mesh/ble_service.dart`:

```dart
class BleService {
  Duration _currentScanInterval = BleConstants.scanIntervalActive;
  DateTime _lastUserActivity = DateTime.now();

  void onUserActivity() {
    _lastUserActivity = DateTime.now();
    _currentScanInterval = BleConstants.scanIntervalActive;
  }

  void _adjustScanInterval() {
    final idleTime = DateTime.now().difference(_lastUserActivity);

    if (idleTime > Duration(minutes: 5)) {
      _currentScanInterval = BleConstants.scanIntervalIdle;
    } else {
      _currentScanInterval = BleConstants.scanIntervalActive;
    }
  }

  Future<void> _scanPeriodically() async {
    while (true) {
      _adjustScanInterval();
      await startScanning();
      await Future.delayed(_currentScanInterval);
    }
  }
}
```

**Expected Improvement:** 30-40% reduction in battery usage when idle.

---

### 2. Connection Pooling

**Problem:** Opening/closing BLE connections for every message is expensive.

**Solution:** Maintain persistent connections to known contacts.

#### Implementation

Update `/packages/meshlink_core/lib/mesh/mesh_transport_impl.dart`:

```dart
class MeshTransportImpl {
  // Connection pool for active peers
  final Map<String, BluetoothDevice> _activeConnections = {};
  static const int maxConnections = 7; // Limit concurrent connections

  Future<void> _maintainConnectionPool() async {
    // Get contacts with recent activity
    final recentContacts = await _database.getRecentMeshContacts(limit: maxConnections);

    for (final contact in recentContacts) {
      if (!_activeConnections.containsKey(contact.meshPeerId)) {
        final device = await _bleService.connectToPeer(contact.meshPeerId);
        if (device != null) {
          _activeConnections[contact.meshPeerId] = device;
        }
      }
    }

    // Close connections to non-contact peers
    _activeConnections.removeWhere((peerId, device) {
      final isContact = recentContacts.any((c) => c.meshPeerId == peerId);
      if (!isContact) {
        device.disconnect();
        return true;
      }
      return false;
    });
  }
}
```

**Expected Improvement:** 20-30% reduction in battery for frequent messaging.

---

### 3. Battery-Aware Scanning

**Problem:** Scanning continues even when battery is low.

**Solution:** Reduce or pause scanning below battery threshold.

#### Implementation

Create `/apps/mobile/lib/data/services/battery_monitor.dart`:

```dart
import 'package:battery_plus/battery_plus.dart';

class BatteryMonitor {
  final Battery _battery = Battery();
  Stream<int>? _batteryStream;

  Stream<BatteryLevel> get batteryLevelStream async* {
    _batteryStream ??= _battery.onBatteryStateChanged.asyncExpand((_) async* {
      final level = await _battery.batteryLevel;
      yield level;
    });

    await for (final level in _batteryStream!) {
      if (level >= 50) {
        yield BatteryLevel.high;
      } else if (level >= 20) {
        yield BatteryLevel.medium;
      } else if (level >= 10) {
        yield BatteryLevel.low;
      } else {
        yield BatteryLevel.critical;
      }
    }
  }
}

enum BatteryLevel {
  high,     // >50%: Normal scanning
  medium,   // 20-50%: Reduced scanning
  low,      // 10-20%: Minimal scanning
  critical, // <10%: Mesh disabled
}
```

Update mesh providers:

```dart
final batteryMonitorProvider = Provider<BatteryMonitor>((ref) => BatteryMonitor());

class MeshNetworkNotifier extends StateNotifier<MeshNetworkState> {
  late final StreamSubscription _batterySubscription;

  MeshNetworkNotifier(this._transport, BatteryMonitor batteryMonitor)
      : super(const MeshNetworkState()) {

    _batterySubscription = batteryMonitor.batteryLevelStream.listen((level) {
      _adjustForBatteryLevel(level);
    });
  }

  void _adjustForBatteryLevel(BatteryLevel level) {
    switch (level) {
      case BatteryLevel.critical:
        stop(); // Auto-disable mesh
        break;
      case BatteryLevel.low:
        // Reduce scan frequency to every 5 minutes
        _transport?.setScanInterval(Duration(minutes: 5));
        break;
      case BatteryLevel.medium:
        // Moderate scanning
        _transport?.setScanInterval(Duration(minutes: 2));
        break;
      case BatteryLevel.high:
        // Normal scanning
        _transport?.setScanInterval(Duration(seconds: 30));
        break;
    }
  }

  @override
  void dispose() {
    _batterySubscription.cancel();
    super.dispose();
  }
}
```

Add to `pubspec.yaml`:

```yaml
dependencies:
  battery_plus: ^6.0.2
```

**Expected Improvement:** Prevents battery drain in low-battery situations.

---

### 4. RSSI-Based Range Filtering

**Problem:** Scanning for peers at maximum range (-80 dBm) includes weak connections.

**Solution:** Only connect to peers with strong signal.

#### Implementation

Update `/packages/meshlink_core/lib/mesh/ble_constants.dart`:

```dart
class BleConstants {
  // Current threshold
  static const int minRssiForConnection = -80; // dBm

  // Optimized thresholds
  static const int minRssiStrong = -60;     // Close range (<5m)
  static const int minRssiMedium = -70;     // Medium range (5-15m)
  static const int minRssiWeak = -80;       // Far range (15-30m)
}
```

Update peer discovery logic:

```dart
Future<void> _onPeerDiscovered(String peerId, int rssi) async {
  // Only connect to peers with strong/medium signal
  if (rssi < BleConstants.minRssiMedium) {
    // Weak signal - skip for now
    return;
  }

  // Prioritize strong signals
  if (rssi >= BleConstants.minRssiStrong) {
    await _connectImmediately(peerId);
  } else {
    await _queueConnection(peerId, priority: rssi);
  }
}
```

**Expected Improvement:** 15-20% reduction by avoiding weak connections.

---

### 5. Opportunistic Scanning

**Problem:** Continuous scanning even when no messages to send.

**Solution:** Pause scanning when inactive, resume on demand.

#### Implementation

```dart
class MeshTransportImpl {
  bool _hasPendingMessages = false;
  Timer? _inactivityTimer;

  Future<void> sendTextMessage(...) async {
    _hasPendingMessages = true;
    _inactivityTimer?.cancel();

    // Send message...

    // Resume normal scanning
    await _bleService.startScanning();

    // After 5 minutes of no activity, reduce scanning
    _inactivityTimer = Timer(Duration(minutes: 5), () {
      _hasPendingMessages = false;
      _bleService.reduceScanFrequency();
    });
  }
}
```

**Expected Improvement:** 25-35% reduction when not actively messaging.

---

### 6. Platform-Specific Optimizations

#### Android

**Use BLE Scan Modes:**

```dart
// In BleService
Future<void> startScanning() async {
  await FlutterBluePlus.startScan(
    timeout: Duration(seconds: 10),
    androidScanMode: ScanMode.lowPower, // Instead of balanced
  );
}
```

**Expected Improvement:** 10-15% reduction on Android.

#### iOS

**Use Background BLE Sparingly:**

```dart
// Only advertise when necessary
class BleService {
  Future<void> startAdvertising() async {
    if (_isInForeground) {
      // Full advertising
      await _advertiseWithFullPower();
    } else {
      // Minimal advertising in background
      await _advertiseWithReducedPower();
    }
  }
}
```

**Expected Improvement:** iOS automatically throttles; ensure we don't fight it.

---

## Tuning Parameters

### Recommended Settings

Based on usage patterns:

#### High Activity (Frequent Messaging)
```dart
scanInterval: Duration(seconds: 15)
connectionPool: 7 peers
rssiThreshold: -70 dBm
batteryThreshold: 10% (disable below)
```

**Expected Battery:** ~10% per hour

#### Medium Activity (Occasional Messaging)
```dart
scanInterval: Duration(seconds: 60)
connectionPool: 3 peers
rssiThreshold: -60 dBm (strong signals only)
batteryThreshold: 15%
```

**Expected Battery:** ~5% per hour

#### Low Activity (Mostly Idle)
```dart
scanInterval: Duration(minutes: 5)
connectionPool: 1 peer (closest contact)
rssiThreshold: -50 dBm (very strong only)
batteryThreshold: 20%
```

**Expected Battery:** ~2% per hour

---

## Measurement & Profiling

### Android Battery Profiler

1. Open Android Studio
2. Run app on device
3. **View → Tool Windows → Profiler**
4. Select **Energy** profiler
5. Record for 30 minutes
6. Analyze battery usage breakdown

**Look for:**
- CPU wake locks (should be minimal)
- Network activity (BLE appears here)
- Alarm/job scheduling frequency

### iOS Instruments

1. Open Xcode
2. **Product → Profile** (Cmd+I)
3. Select **Energy Log** template
4. Record for 30 minutes
5. Analyze energy impact

**Look for:**
- Bluetooth energy usage
- CPU usage spikes
- Background task frequency

### Manual Testing

```bash
# Android: Measure battery drain
adb shell dumpsys batterystats --reset
# Run app for 1 hour
adb shell dumpsys batterystats | grep -A 10 "MeshLink"

# iOS: Use Settings → Battery → Last 24 Hours
```

---

## Optimization Checklist

Before releasing Phase 2, verify:

- [ ] Scan interval adapts based on activity (15s → 60s → 5min)
- [ ] Connection pool limits concurrent connections (max 7)
- [ ] Battery monitor disables mesh below 10%
- [ ] RSSI filtering skips weak signals (<-70 dBm)
- [ ] Background scanning reduces frequency (2-5 minutes)
- [ ] No wake locks held when inactive
- [ ] BLE advertising pauses when no peers nearby
- [ ] Message queue doesn't trigger constant scanning

---

## Advanced Optimizations (Future)

### 1. Machine Learning Predictions

Train model to predict when user likely to message:
- Time of day patterns
- Contact frequency
- Location patterns

Adjust scan intervals proactively.

### 2. Crowd-Sourced Network Map

Cache known peer locations/times:
- "Bob is usually at coffee shop 8-9am"
- Increase scanning during expected encounter times

### 3. Wi-Fi-BLE Coordination

When on Wi-Fi, reduce BLE scanning:
- Cloud transport available
- Only scan for high-priority contacts

---

## Troubleshooting

### Battery Drain >15%/hour

**Check:**
1. Scan interval (should increase when idle)
2. Number of active connections (max 7)
3. BLE advertising frequency
4. Wake locks in background

**Fix:**
- Increase scan intervals
- Reduce connection pool size
- Disable advertising when no nearby peers

### Mesh Not Working After Optimization

**Check:**
1. Scan interval not too long (>5 min risky)
2. RSSI threshold not too strict (<-50 very strict)
3. Battery threshold not too high (>20% aggressive)

**Fix:**
- Balance between battery and functionality
- Test with real users to find sweet spot

---

## Target Metrics

### Phase 2 Goals
- **Foreground active:** 8-10% per hour ✅
- **Background:** 3-5% per hour ✅
- **Standby (mesh idle):** <1% per hour ✅

### Phase 3 Goals (with optimizations)
- **Foreground active:** 5-7% per hour
- **Background:** 2-3% per hour
- **Standby:** <0.5% per hour

---

## User Settings

Expose battery optimization settings to users:

```dart
// In Settings screen
enum MeshBatteryMode {
  performance,  // Fast scanning, max connections
  balanced,     // Default adaptive scanning
  batterySaver, // Minimal scanning, fewer connections
}
```

Let power users choose their preference.

---

## Summary

Key optimizations for Phase 2:

1. **Adaptive Scan Intervals** - 30-40% improvement
2. **Connection Pooling** - 20-30% improvement
3. **Battery Monitoring** - Prevents critical drain
4. **RSSI Filtering** - 15-20% improvement
5. **Opportunistic Scanning** - 25-35% improvement

**Combined Expected Improvement:** 50-60% reduction in battery usage vs. naive implementation.

**Realistic Target:** 5-8% per hour foreground, 2-4% per hour background.
