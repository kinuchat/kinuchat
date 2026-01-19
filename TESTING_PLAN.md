# MeshLink Testing Plan

## Pre-Deployment Checklist

### ✅ Code Readiness
- [x] Phase 1: Cloud messaging (Matrix integration)
- [x] Phase 2: Mesh networking (BLE + Noise protocol)
- [x] Phase 3: Rally Mode (location-based channels)
- [x] All compilation errors fixed
- [x] Database migrations ready (v1 → v2 → v3)
- [x] 58 unit tests passing (geohash + anonymous identity)

### ⚠️ Missing Critical Components

Before deploying, you should verify these exist:

#### **Onboarding Flow**
- [ ] User can create a new account
- [ ] Identity is generated (Ed25519 + X25519 keys)
- [ ] Keys are backed up to secure storage
- [ ] Matrix registration works
- [ ] First-time setup wizard

#### **Contact Management**
- [ ] Add contact by Matrix ID
- [ ] View contact list
- [ ] Start new conversation
- [ ] Contact verification flow

#### **Message Sending UI**
- [ ] Chat screen works (already exists)
- [ ] Can compose and send messages
- [ ] Messages show delivery status
- [ ] Read receipts work
- [ ] Message history loads

---

## Testing Scenarios (Two Devices)

### Device Setup
- **Device A:** iPhone (your primary phone)
- **Device B:** iPad (secondary device)
- **Network:** WiFi + Cellular available
- **Location:** Same room (~10 feet apart for BLE testing)

---

## Test 1: Account Creation & Onboarding

### Device A (iPhone)
```
1. Launch MeshLink
2. See onboarding/welcome screen (or skip if not built)
3. Create account
   Expected: Identity created, keys stored securely
4. Note down Matrix User ID: @user:matrix.org
5. Grant Bluetooth permission
6. Grant Location permission
7. Grant Notification permission
```

### Device B (iPad)
```
1. Launch MeshLink
2. Create account
3. Note down Matrix User ID
4. Grant all permissions
```

**Success Criteria:**
- ✅ Both devices have unique identities
- ✅ Matrix User IDs are different
- ✅ No crashes during setup

---

## Test 2: Cloud Messaging (Phase 1)

**Preconditions:** Both devices on WiFi/Cellular, Bluetooth OFF

### Send Message: Device A → Device B
```
Device A (iPhone):
1. Tap "+" to start new conversation
2. Enter Device B's Matrix User ID
3. Type message: "Hello from iPhone!"
4. Send

Device B (iPad):
1. Wait for message to arrive
2. Verify message content matches
3. Check sender is Device A
4. Reply: "Hello from iPad!"

Device A:
5. Verify reply arrived
6. Check delivery receipts (sent/delivered/read)
```

**Success Criteria:**
- ✅ Message delivered within 2 seconds
- ✅ Messages are encrypted (check transport = "cloud")
- ✅ Delivery receipts update correctly
- ✅ Conversation appears in both chat lists
- ✅ Unread count increments correctly

### Edge Cases to Test
```
- Send while offline → goes to pending → delivers when online
- Send very long message (>1000 chars)
- Send special characters / emojis
- Send rapidly (5 messages in a row)
- Receive while app is backgrounded
```

---

## Test 3: Mesh Networking (Phase 2) - THE CRITICAL TEST

**Preconditions:** Both devices in same room

### Setup Offline Environment
```
Device A:
1. Enable Airplane Mode
2. Enable Bluetooth (while in Airplane Mode)

Device B:
1. Enable Airplane Mode
2. Enable Bluetooth
```

### BLE Discovery & Connection
```
Device A:
1. Navigate to existing chat with Device B
2. Observe mesh status banner
   Expected: "Scanning for nearby peers..."

Device B:
1. Navigate to existing chat with Device A
2. Observe mesh status banner

BOTH DEVICES:
3. Wait 10-30 seconds
4. Check status banner updates to:
   "Connected to 1 peer via Mesh" (or similar)
```

**Success Criteria:**
- ✅ BLE scanning starts automatically
- ✅ Devices discover each other within 30 seconds
- ✅ Noise handshake completes (XX pattern)
- ✅ Status banner shows "Connected via Mesh"
- ✅ Signal strength (RSSI) shown in UI

### Send Offline Message via BLE
```
Device A:
1. Type: "Testing offline mesh delivery"
2. Send
3. Observe message status changes:
   pending → sending → sent (via mesh)

Device B:
1. Message should arrive within 5 seconds
2. Verify content matches
3. Reply: "Mesh confirmed!"

Device A:
4. Receive reply via mesh
5. Verify delivery
```

**Success Criteria:**
- ✅ Messages delivered via BLE within 5-10 seconds
- ✅ Transport shows "mesh" (not "cloud")
- ✅ Bi-directional messaging works
- ✅ Message order preserved
- ✅ Encryption works (Noise protocol)

### Store-and-Forward Testing
```
1. Device A sends message
2. Immediately move Device B out of BLE range (>30 feet)
   Expected: Message queued on Device A
3. Bring devices back together
   Expected: Message delivers automatically
4. Verify message arrived on Device B
```

**Success Criteria:**
- ✅ Messages queue when peer offline
- ✅ Automatic delivery when peer comes back
- ✅ Queue persists across app restarts
- ✅ Messages expire after 24 hours

### Multi-Hop Testing (If you have 3 devices)
```
Device A ←→ Device B ←→ Device C

A sends to C (must route through B)
- Verify message reaches C
- Check hop count in metadata
```

---

## Test 4: Rally Mode (Phase 3)

**Preconditions:** Devices back online, Bluetooth + Location ON

### Channel Discovery
```
Device A:
1. Go to Rally tab
2. Grant location permission
3. Wait for nearby channels to load
   Expected: Empty (no channels yet) OR channels from other users

Device B:
1. Go to Rally tab
2. Grant location permission
3. Verify same location as Device A
```

### Create & Join Channel
```
Device A:
1. Tap "Create Channel"
2. Note the channel name (geocoded address)
3. Channel appears in list

Device B:
1. Refresh channel list
2. See Device A's channel
3. Note distance shown (~0m since same location)
4. Tap channel → Join
```

**Success Criteria:**
- ✅ Geohash generated correctly
- ✅ Channel name geocoded (e.g., "Rally on Main St")
- ✅ Channel visible to nearby devices
- ✅ Distance calculated accurately

### Map View Testing
```
Both Devices:
1. Toggle to Map View
2. Verify:
   - User location shows (blue pin)
   - Channel marker shows (purple pin with count)
   - Can zoom/pan map
3. Tap channel marker
   - Bottom sheet appears
   - Shows channel info
   - "Join" button works
```

**Success Criteria:**
- ✅ Map loads OpenStreetMap tiles
- ✅ Markers positioned correctly
- ✅ Tap-to-join works from map
- ✅ Toggle between map/list preserves state

### Rally Messaging
```
Device A (in channel):
1. Select "Anonymous" identity
2. Post: "Testing Rally Mode!"
3. Note display name (e.g., "anon-happy-fox-42")

Device B (in channel):
1. Refresh messages
2. See Device A's message
3. Reply as "Verified" identity
4. Message shows real identity

Device A:
5. Verify reply received
6. Note identity type badge (verified icon)
```

**Success Criteria:**
- ✅ Messages sync in real-time
- ✅ Identity types display correctly
- ✅ Anonymous names generated properly
- ✅ Message expiration works (4 hours)

### Reputation System
```
Device A:
1. Long-press message from Device B
2. Select "Report User"
3. Choose category: "Spam"
4. Submit report

Verify:
- Report stored locally
- User's reputation decreases (check internally)
- Messages filter if reputation < threshold
```

---

## Test 5: Edge Cases & Stress Tests

### Battery & Performance
```
- Run app for 30 minutes with BLE scanning
- Monitor battery drain
- Check CPU usage in Xcode Instruments
- Verify no memory leaks
```

### Network Transitions
```
1. Start on WiFi
2. Send message
3. Switch to Cellular mid-send
   Expected: Message still delivers
4. Switch back to WiFi
   Expected: Seamless transition
```

### App Lifecycle
```
- Background app → send message → reopen
  Expected: Message sent, notification received
- Force quit app → reopen
  Expected: Mesh connections re-establish
- Restart device → open app
  Expected: All data persists
```

### Data Persistence
```
1. Send 50 messages
2. Force quit app
3. Reopen
   Expected: All 50 messages still there
4. Check database version
   Expected: Schema v3 (Rally Mode tables exist)
```

---

## Test 6: Rally Mode Enhancements

### Reverse Geocoding
```
1. Create channel at known location
2. Verify channel name is human-readable
   Expected: "Rally on Market St" (not "Rally @ 9q8yy9")
3. If geocoding fails, should fall back to geohash
```

### Reputation Filtering
```
1. Create test user with low reputation (via reports)
2. Post message as low-rep user
3. Toggle reputation filter ON
   Expected: Message hidden
4. Toggle filter OFF
   Expected: Message visible
```

### Map Marker Colors
```
1. Create 4 channels with different participant counts:
   - 0 participants → Gray marker
   - 3 participants → Orange marker
   - 7 participants → Deep Orange marker
   - 12 participants → Red marker
2. Verify colors match activity levels
```

---

## Performance Benchmarks

### BLE Connection Time
- **Target:** < 10 seconds for initial discovery
- **Acceptable:** < 30 seconds
- **Fail:** > 60 seconds

### Message Delivery Time
- **Cloud (online):** < 2 seconds
- **Mesh (offline):** < 10 seconds
- **Store-and-forward:** < 5 seconds after reconnect

### Rally Channel Discovery
- **Target:** < 3 seconds with location
- **Map load:** < 5 seconds for tiles
- **Geocoding:** < 2 seconds per channel

---

## Known Limitations to Document

### Phase 1 (Cloud)
- ⚠️ No group chats yet (Phase 5)
- ⚠️ No media messages (images/voice) - text only
- ⚠️ No message search yet

### Phase 2 (Mesh)
- ⚠️ BLE range ~30 feet indoors, ~100 feet outdoors
- ⚠️ iOS background limitations (10 seconds)
- ⚠️ No multi-hop routing yet (Phase 2.5)
- ⚠️ Message queue max 24 hours

### Phase 3 (Rally)
- ⚠️ Channels expire every 4 hours
- ⚠️ No persistent channels yet
- ⚠️ No media in Rally (text only)
- ⚠️ Local-only moderation (no network-wide bans)

---

## Success Criteria Summary

### ✅ Must Work
- Account creation on both devices
- Send/receive cloud messages
- BLE discovery and connection
- Offline message delivery via mesh
- Rally channel creation and joining
- Map view with markers

### ✅ Should Work
- Delivery receipts
- Read receipts
- Message persistence
- Reputation filtering
- Reverse geocoding
- Background notifications

### 🤷 Nice to Have
- Multi-hop routing
- Group chats
- Media messages
- Message search
- Push notifications (requires paid Apple account)

---

## Bug Reporting Template

When you find issues, document:

```markdown
## Bug: [Short Description]

**Device:** iPhone 14 Pro / iPad Air 2022
**iOS Version:** 17.2
**App Version:** 1.0.0 (from Xcode)
**Network:** WiFi / Cellular / Offline

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Screenshots/Logs:**
Attach Xcode console output

**Workaround:**
If any

**Priority:** Critical / High / Medium / Low
```

---

## Next Steps After Testing

### If Everything Works ✅
1. Document any bugs found
2. Prioritize bug fixes
3. Consider Apple Developer Program ($99/year)
4. Set up TestFlight for beta testing
5. Invite friends to test Rally Mode

### If Major Issues Found ⚠️
1. Fix critical bugs first (crash, data loss, encryption)
2. Retest after fixes
3. Iterate until stable

### If BLE Doesn't Work 🔴
1. Check Bluetooth permissions granted
2. Verify BLE peripheral/central roles work
3. Check Noise handshake completes
4. Review BLE logs in Xcode
5. Test with simpler BLE example first

---

**Good luck with testing!** 🚀

The most critical test is **Phase 2 (Mesh Networking)** - that's the unique differentiator for MeshLink and can only be tested on real hardware.
