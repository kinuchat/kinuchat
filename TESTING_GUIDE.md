# MeshLink Phase 2 Testing Guide

## Overview

This guide covers testing procedures for Phase 2: Mesh Networking (BLE). All mesh networking features must be tested on **physical devices** - BLE does not work in simulators/emulators.

## Prerequisites

### Hardware Requirements

- **Minimum 2 devices** for basic testing
- **3+ devices** for multi-hop routing tests
- **Android 10+** or **iOS 14+**
- Bluetooth Low Energy (BLE) 5.0+ support

### Software Requirements

```bash
# Install dependencies
cd apps/mobile
flutter pub get

# Build for devices
flutter build ios --debug  # For iOS
flutter build apk --debug  # For Android
```

### Permissions Setup

#### Android
On first launch, the app will request:
- Bluetooth permissions
- Location permissions (required for BLE scanning)
- Notification permissions (for background service)

Grant all permissions to enable mesh networking.

#### iOS
On first launch, the app will request:
- Bluetooth permissions

Grant to enable mesh networking. Background mode is automatically enabled via Info.plist.

---

## Test Suite

### 1. Unit Tests (Automated)

Run all unit tests to verify core components:

```bash
cd packages/meshlink_core
flutter test
```

**Expected Results:**
- ✅ 89/89 tests passing
- ✅ Packet codec: 24 tests
- ✅ Noise handshake: 17 tests
- ✅ Peer announcement: 15 tests
- ✅ Routing engine: 20 tests
- ✅ Deduplication: tests within routing
- ✅ Identity service: 13 tests

**If tests fail:**
1. Check error messages for specific failures
2. Verify database schema is up to date
3. Run `melos bootstrap` to ensure dependencies are synced

---

### 2. Integration Tests (Manual - 2 Devices)

#### Test 2.1: Peer Discovery

**Setup:** 2 devices within 10m range

**Steps:**
1. Launch app on both devices
2. Complete identity setup on both
3. Navigate to home screen
4. Observe mesh status banner

**Expected Results:**
- ✅ Mesh status banner appears: "Mesh Active • 1 peer nearby"
- ✅ Banner appears within 30 seconds of launch
- ✅ Peer count updates in real-time

**Troubleshooting:**
- If no banner appears, check Bluetooth is enabled
- Check permissions are granted
- Look for errors in device logs: `flutter logs`

#### Test 2.2: Noise Handshake Completion

**Setup:** 2 devices with peer discovery working

**Steps:**
1. Observe device logs: `flutter logs`
2. Look for handshake completion messages

**Expected Results:**
- ✅ Logs show: "Noise handshake completed with peer [ID]"
- ✅ Session state stored in database
- ✅ Encrypted session keys generated

**Troubleshooting:**
- If handshake fails, check BLE connection stability
- Verify devices are within 10m range
- Check for interference from other BLE devices

#### Test 2.3: Direct Message Send/Receive (Mesh)

**Setup:** 2 devices with completed handshake, **no internet connection**

**Steps:**
1. Disable Wi-Fi and cellular data on both devices
2. On Device A, create new conversation with Device B's user ID
3. Send text message: "Hello from mesh!"
4. Observe on Device B

**Expected Results:**
- ✅ Message sends successfully on Device A
- ✅ Message delivers to Device B within 5 seconds
- ✅ Message shows transport indicator: "Mesh" (cyan icon)
- ✅ Message is encrypted (verify in database it's not plain text)

**Troubleshooting:**
- If message doesn't send, check mesh status banner shows peer
- Verify handshake completed (Test 2.2)
- Check device logs for errors

#### Test 2.4: Transport Failover (Cloud → Mesh)

**Setup:** 2 devices with internet connection

**Steps:**
1. Enable Wi-Fi on both devices
2. Send message from Device A to Device B
3. Observe transport indicator (should be "Cloud" - blue)
4. Disable Wi-Fi on both devices
5. Send another message
6. Observe transport indicator (should change to "Mesh" - cyan)

**Expected Results:**
- ✅ First message uses Cloud transport (blue icon)
- ✅ Second message uses Mesh transport (cyan icon)
- ✅ Both messages deliver successfully
- ✅ Transport selection is automatic

#### Test 2.5: Store-and-Forward

**Setup:** 2 devices

**Steps:**
1. Device A and B within range, handshake complete
2. Move Device B out of range (>30m)
3. On Device A, send message to Device B
4. Wait 1 minute
5. Move Device B back into range
6. Observe message delivery

**Expected Results:**
- ✅ Message queued on Device A when peer unavailable
- ✅ Message delivers when peer returns to range
- ✅ Delivery happens within 30 seconds of peer discovery

#### Test 2.6: Message Deduplication

**Setup:** 2 devices with handshake complete

**Steps:**
1. Send message from Device A to Device B
2. Observe device logs on Device B
3. Look for deduplication checks

**Expected Results:**
- ✅ Message received once on Device B
- ✅ Logs show: "Message [ID] seen, marked in dedup table"
- ✅ No duplicate messages in conversation

---

### 3. Multi-Hop Routing Tests (3+ Devices)

#### Test 3.1: 3-Device Chain Routing

**Setup:** 3 devices (A, B, C) arranged in chain

**Physical Layout:**
```
Device A <--10m--> Device B <--10m--> Device C
(A and C are >30m apart, out of direct BLE range)
```

**Steps:**
1. Launch app on all 3 devices
2. Verify Device B sees both A and C as peers
3. Verify Device A and C do NOT see each other directly
4. Disable internet on all devices
5. Send message from Device A to Device C
6. Observe routing

**Expected Results:**
- ✅ Message routes from A → B → C
- ✅ Device B logs show packet forwarding
- ✅ Message delivers to C within 10 seconds
- ✅ TTL decrements correctly (7 → 6 → 5)

**Troubleshooting:**
- Ensure Device B is in range of both A and C
- Check Device B's peer count shows 2
- Verify routing table updates on Device B

#### Test 3.2: Route Discovery

**Setup:** Same as Test 3.1

**Steps:**
1. On Device B, check database: `SELECT * FROM mesh_routes;`
2. Verify routes to both A and C exist

**Expected Results:**
- ✅ Route from B to A: hopCount=1, nextHop=A
- ✅ Route from B to C: hopCount=1, nextHop=C
- ✅ Routes from A to C: hopCount=2, nextHop=B
- ✅ Quality scores > 50

#### Test 3.3: TTL Expiration (7-Hop Limit)

**Setup:** 8 devices in a chain (if available)

**Steps:**
1. Arrange devices in chain with ~10m between each
2. Send message from Device 1 to Device 8
3. Observe if message delivers

**Expected Results:**
- ✅ Message does NOT deliver to Device 8
- ✅ Logs show TTL reached 0 at Device 7
- ✅ Message is dropped, not forwarded further

---

### 4. Background Operation Tests

#### Test 4.1: Android Background Service

**Setup:** Android device with mesh active

**Steps:**
1. Enable mesh networking
2. Press home button to background app
3. Check notification shade
4. Send message from another device

**Expected Results:**
- ✅ Notification shows: "Mesh Network Active • Connected to N peers"
- ✅ Notification persists while app is backgrounded
- ✅ Incoming message delivers to backgrounded device
- ✅ Notification updates when peer count changes

#### Test 4.2: iOS Background Mode

**Setup:** iOS device with mesh active

**Steps:**
1. Enable mesh networking
2. Press home button to background app
3. Wait 1 minute
4. Send message from another device
5. Check if message delivers

**Expected Results:**
- ✅ Message delivers to backgrounded iOS device
- ⚠️  Delivery may be delayed (iOS controls BLE scan rate)
- ✅ App wakes up to process incoming packet

**Note:** iOS reduces BLE scan frequency in background. Expect delays of 30-60 seconds.

---

### 5. Edge Case Tests

#### Test 5.1: Rapid Connect/Disconnect

**Setup:** 2 devices

**Steps:**
1. Start with devices within range
2. Rapidly move Device B in and out of range
3. Repeat 10 times
4. Send message when stable

**Expected Results:**
- ✅ No app crashes
- ✅ Peer count updates correctly
- ✅ Message delivers when peers stable
- ✅ No memory leaks (use profiler)

#### Test 5.2: Permission Denied

**Setup:** Fresh install on device

**Steps:**
1. Install app
2. When Bluetooth permission requested, deny
3. Observe behavior

**Expected Results:**
- ✅ Mesh status banner does not appear
- ✅ App shows error: "Bluetooth permission required"
- ✅ App does not crash
- ✅ User can grant permission later in settings

#### Test 5.3: Bluetooth Disabled

**Setup:** Device with mesh active

**Steps:**
1. Enable mesh networking
2. Disable Bluetooth in system settings
3. Observe behavior

**Expected Results:**
- ✅ Mesh status banner disappears
- ✅ Transport falls back to Cloud
- ✅ App shows warning about Bluetooth
- ✅ Re-enabling Bluetooth restores mesh

#### Test 5.4: Battery Low (<20%)

**Setup:** Device with low battery

**Steps:**
1. Drain battery to <20%
2. Enable mesh networking
3. Observe behavior

**Expected Results:**
- ✅ App warns about battery impact
- ✅ Optional: Mesh auto-disables below 15%
- ✅ User can re-enable if desired

---

### 6. Performance & Battery Tests

#### Test 6.1: Battery Drain (1 Hour Active)

**Setup:** Fully charged device

**Steps:**
1. Fully charge device
2. Enable mesh networking
3. Keep app in foreground for 1 hour
4. Record battery level every 15 minutes

**Expected Results:**
- ✅ Battery drain: <10% per hour
- ✅ Consistent drain rate
- ✅ No excessive CPU usage

**Troubleshooting:**
- If drain >10%, check scan interval settings
- Reduce BLE scan frequency
- Check for BLE connection leaks

#### Test 6.2: Memory Leak Check (24 Hours)

**Setup:** Device with mesh active

**Steps:**
1. Enable mesh networking
2. Leave app running for 24 hours
3. Use Android Profiler / Xcode Instruments
4. Monitor memory usage over time

**Expected Results:**
- ✅ Memory usage stable (<100MB)
- ✅ No gradual increase over time
- ✅ Garbage collection working properly

#### Test 6.3: Message Throughput

**Setup:** 2 devices with handshake complete

**Steps:**
1. Send 100 messages rapidly from Device A to B
2. Measure delivery rate

**Expected Results:**
- ✅ 100% delivery rate
- ✅ Average latency: <2 seconds per message
- ✅ No packet loss

---

## Test Results Template

Use this template to record test results:

```markdown
## Test Run: [Date]

**Devices:**
- Device A: [Model], [OS Version]
- Device B: [Model], [OS Version]
- Device C: [Model], [OS Version] (if applicable)

**App Version:** [Git commit hash]

### Unit Tests
- [ ] All 89 tests passing

### Integration Tests (2 Devices)
- [ ] Test 2.1: Peer Discovery
- [ ] Test 2.2: Noise Handshake
- [ ] Test 2.3: Direct Message (Mesh)
- [ ] Test 2.4: Transport Failover
- [ ] Test 2.5: Store-and-Forward
- [ ] Test 2.6: Message Deduplication

### Multi-Hop Tests (3+ Devices)
- [ ] Test 3.1: 3-Device Chain Routing
- [ ] Test 3.2: Route Discovery
- [ ] Test 3.3: TTL Expiration

### Background Tests
- [ ] Test 4.1: Android Background Service
- [ ] Test 4.2: iOS Background Mode

### Edge Cases
- [ ] Test 5.1: Rapid Connect/Disconnect
- [ ] Test 5.2: Permission Denied
- [ ] Test 5.3: Bluetooth Disabled
- [ ] Test 5.4: Battery Low

### Performance Tests
- [ ] Test 6.1: Battery Drain (1 Hour)
- [ ] Test 6.2: Memory Leak Check (24 Hours)
- [ ] Test 6.3: Message Throughput

**Issues Found:**
- [List any bugs or issues discovered]

**Notes:**
- [Any additional observations]
```

---

## Debugging Tips

### Enable Verbose Logging

Add to `main.dart`:

```dart
void main() {
  // Enable verbose logging for mesh networking
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(MyApp());
}
```

### View BLE Scan Results

Check device logs for peer discoveries:

```bash
flutter logs | grep "BLE"
```

### Inspect Database

Use Drift Inspector or direct SQLite access:

```sql
-- View discovered peers
SELECT * FROM mesh_peers ORDER BY lastSeen DESC;

-- View routing table
SELECT * FROM mesh_routes ORDER BY hopCount ASC;

-- View message queue
SELECT * FROM mesh_message_queue WHERE expiresAt > CURRENT_TIMESTAMP;

-- View deduplication table
SELECT * FROM mesh_seen_messages ORDER BY seenAt DESC LIMIT 20;
```

### Monitor BLE Connections

Use platform-specific tools:
- **Android:** nRF Connect app
- **iOS:** LightBlue app

---

## Acceptance Criteria

Phase 2 is **complete** when:

### Core Functionality ✅
- [ ] Two devices discover each other via BLE
- [ ] Noise handshake completes successfully
- [ ] Message delivers via mesh (no internet)
- [ ] Multi-hop (3 devices) works
- [ ] Deduplication prevents duplicates
- [ ] Transport manager selects mesh when peer nearby
- [ ] Store-and-forward queues/delivers

### UI ✅
- [ ] Chat header shows "via Mesh" indicator
- [ ] Chat list shows mesh banner with peer count
- [ ] Message status works for mesh
- [ ] Settings allow enable/disable mesh

### Quality ✅
- [ ] All unit tests pass (89/89)
- [ ] Integration tests pass on real devices
- [ ] No memory leaks (24-hour test)
- [ ] Battery <10%/hour active
- [ ] No crashes (24-hour stress test)

### Background Operation ✅
- [ ] Android foreground service works
- [ ] iOS background mode works
- [ ] Messages deliver when app backgrounded

---

## Next Steps

After completing Phase 2 testing:

1. **Document Results:** Fill out test results template
2. **Fix Bugs:** Address any issues found during testing
3. **Optimize:** Tune scan intervals, connection pooling based on results
4. **Phase 3:** Move to Bridge Mode implementation
