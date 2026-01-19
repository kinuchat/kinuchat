# MeshLink Development - Current State & Next Steps

**Last Updated:** 2026-01-17
**Status:** Ready for iOS device deployment (pending macOS/Xcode update)

---

## Current Situation

### The Blocker (Being Resolved)
- **Issue:** Xcode 16.4 doesn't support iPhone 17 Pro on iOS 26.3
- **Error:** `kAMDMobileImageMounterPersonalizedBundleMissingVariantError`
- **Solution:** User is updating macOS to get newer Xcode version
- **Once resolved:** Deploy to iPhone 17 Pro + iPad for BLE mesh testing

### What's Working Right Now
- ✅ **Simulator deployment works** - App runs successfully on iPhone 16 Pro Max simulator
- ✅ **Code compiles cleanly** - `flutter analyze` shows 0 errors
- ✅ **iOS build succeeds** - 60.8s build time, 23.5MB
- ✅ **All 58 unit tests passing** - Geohash + Anonymous Identity tests

---

## What Was Just Completed (Phase 3: Rally Mode)

### Core Implementation
1. **Database Schema v3** - Rally channels, members, reports tables
2. **Geohash Utility** - Location encoding (precision 6 = ~1.2km)
3. **Anonymous Identity** - anon-adjective-noun-number generator
4. **Location Providers** - Geolocator integration with Riverpod
5. **Rally Repository** - Full CRUD operations for channels
6. **Rally UI** - List view, channel detail, map view with OpenStreetMap
7. **Rally Providers** - State management for channels, messages, cleanup

### Enhancements Added
1. **58 Unit Tests** - Geohash (36 tests) + Anonymous Identity (22 tests)
2. **Reputation Filtering** - Local moderation system
3. **Reverse Geocoding** - Human-readable channel names ("Rally on Main St")
4. **Map View** - Interactive OpenStreetMap with color-coded markers
5. **Background Cleanup** - Auto-delete expired messages every 10 minutes

### Critical Pre-Deployment Fixes
1. **Database initialization in main.dart** - Prevents first-launch crashes
2. **Auto-start mesh networking** - BLE starts automatically on HomeScreen
3. **Auto-start Rally cleanup** - Periodic message expiration task

### Files Created (Phase 3)
```
/packages/meshlink_core/lib/utils/geohash.dart
/packages/meshlink_core/lib/utils/anonymous_identity.dart
/packages/meshlink_core/test/utils/geohash_test.dart
/packages/meshlink_core/test/utils/anonymous_identity_test.dart
/apps/mobile/lib/core/providers/location_providers.dart
/apps/mobile/lib/core/providers/rally_providers.dart
/apps/mobile/lib/data/repositories/rally_repository.dart
/apps/mobile/lib/presentation/screens/rally/rally_screen.dart
/apps/mobile/lib/presentation/screens/rally/rally_channel_screen.dart
/apps/mobile/lib/presentation/widgets/rally_map_view.dart
```

### Files Modified (Phase 3)
```
/packages/meshlink_core/lib/database/app_database.dart - Schema v2→v3
/apps/mobile/lib/main.dart - Added initialization
/apps/mobile/lib/presentation/screens/home/home_screen.dart - Auto-start mesh+rally
/apps/mobile/ios/Runner/Info.plist - Location permissions
/apps/mobile/pubspec.yaml - Added geolocator, geocoding, flutter_map
```

---

## Project Status by Phase

### ✅ Phase 0: Foundation (Complete)
- Monorepo structure with Melos
- Clean architecture layers
- Core dependencies configured

### ✅ Phase 1: Cloud Messaging (Complete)
- Matrix SDK integrated
- Identity service (Ed25519/X25519)
- Secure storage (flutter_secure_storage)
- Database schema (Conversations, Messages, Contacts)
- Message encryption (Matrix handles)
- Chat UI (ChatScreen exists)

**Missing (non-blocking):**
- No onboarding wizard for Matrix registration (manual setup works)
- No contact discovery UI (manual Matrix ID entry works)
- No group chats yet (planned for Phase 5)

### ✅ Phase 2: Mesh Networking (Complete - Needs Device Testing)
- BLE scanning (flutter_blue_plus)
- Noise XX handshake
- Store-and-forward queue
- Route management
- Message deduplication
- Mesh status banner UI
- Auto-start on HomeScreen

**Critical:** BLE can only be tested on physical devices (not simulator)

### ✅ Phase 3: Rally Mode (Complete)
- Location services (geolocator)
- Geohash-based channels (precision 6)
- Rally repository & database
- Channel discovery UI
- Map view with OpenStreetMap markers
- Reputation filtering
- Reverse geocoding
- Anonymous identity generation
- 58 unit tests passing
- Rally screen integration

### ⏸️ Phase 4: Bridge Relay (Not Started)
- Users with internet relay messages for offline users
- Rust relay server
- Redis integration
- Recipient polling

### ⏸️ Phase 5: Group Chats (Not Started)
- Multi-party encryption
- Group management
- Admin controls

---

## Immediate Next Steps (After macOS/Xcode Update)

### 1. Deploy to Both Devices (30 minutes)
```bash
# After macOS update and Xcode reinstall
cd /Users/jayklauminzer/Development/bridgeChat/apps/mobile
open ios/Runner.xcworkspace

# In Xcode:
# - Select iPhone 17 Pro from device dropdown
# - Click Run (▶)
# - Wait for install
# - Repeat for iPad
```

### 2. Run Critical Tests (2 hours)

**Test 1: Account Creation (10 min)**
- Launch on both devices
- Complete onboarding
- Create identities
- Grant permissions (Bluetooth, Location, Notifications)

**Test 2: Cloud Messaging (15 min)**
- Both devices on WiFi
- Create conversation
- Send messages
- Verify encryption and delivery

**Test 3: Mesh Networking (BLE) - CRITICAL (30 min)**
- Enable Airplane Mode on BOTH devices
- Enable Bluetooth on BOTH devices
- Keep devices within 30 feet
- Send messages via BLE
- Verify mesh status banner shows "Connected via Mesh"
- Test bi-directional messaging

**Test 4: Rally Mode (15 min)**
- Both devices back online
- Grant location permissions
- Create Rally channel on Device A
- Device B discovers and joins
- Exchange messages
- Test map view

### 3. Document Findings
Use the bug reporting template in `TESTING_PLAN.md` to document any issues found.

---

## Key Documentation Files

**Read these in order:**

1. **READY_TO_DEPLOY.md** - Quick deployment checklist
2. **DEPLOYMENT_GUIDE.md** - Step-by-step Xcode instructions
3. **TESTING_PLAN.md** - Detailed test scenarios for 2 devices
4. **PRE_DEPLOYMENT_CHECKLIST.md** - Code completion status
5. **CRITICAL_FIXES_APPLIED.md** - What was fixed before deployment

---

## Known Issues & Workarounds

### Non-Critical Issues (Won't Block Testing)
1. **No Matrix auto-registration** - User must manually register
   - Workaround: Onboarding guides through manual setup
2. **Basic contact management** - No search/discovery UI
   - Workaround: Direct Matrix ID entry works
3. **BLE might not auto-reconnect** - May need app restart
   - Workaround: Restart app if mesh disconnects

### Current Blocker (Being Fixed)
- **Xcode 16.4 doesn't support iPhone 17 Pro (iOS 26.3)**
   - Solution: Update macOS → Get newer Xcode → Deploy

---

## What Works on Simulator vs Device

### ✅ Simulator (Working Now)
- App launches successfully
- Onboarding flow
- Identity creation
- Database operations
- Rally Mode UI (simulated location)
- Chat UI
- All navigation

### ❌ Simulator (Doesn't Work)
- BLE mesh networking (no Bluetooth hardware)
- Actual GPS (only simulated location)
- Push notifications

### ✅ Real Devices (After Xcode Update)
- Everything simulator has PLUS:
- Real BLE mesh networking
- Actual GPS location
- Real Bluetooth device discovery
- Store-and-forward testing
- Multi-device communication

---

## Critical Commands Reference

### Check Device Connection
```bash
flutter devices
xcrun devicectl list devices
```

### Deploy to Device
```bash
flutter run -d <device-id> --release
# or use Xcode Run button
```

### Clean Build
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

### Run Tests
```bash
cd /Users/jayklauminzer/Development/bridgeChat/packages/meshlink_core
dart test
# Should show: 58 tests passing
```

### Check Compilation
```bash
flutter analyze
# Should show: 0 errors
```

---

## Project Architecture Reminders

### Database Schema Version
- **Current:** v3 (Rally Mode tables added)
- **Migration path:** v1 → v2 → v3
- **Location:** `/packages/meshlink_core/lib/database/app_database.dart`

### Key Providers (Riverpod)
```dart
identityProvider          // User identity state
databaseProvider          // Database instance
meshNetworkProvider       // BLE mesh state
rallyRepositoryProvider   // Rally operations
nearbyRallyChannelsProvider  // Location-based discovery
currentLocationProvider   // GPS location stream
```

### Important Entry Points
- **main.dart** - App initialization, database pre-init
- **splash_screen.dart** - Routing logic (onboarding vs home)
- **home_screen.dart** - Mesh auto-start, Rally cleanup
- **rally_screen.dart** - Location-based channel discovery

---

## Technical Specs Quick Reference

### BLE Mesh (Phase 2)
- Protocol: Noise XX handshake
- Range: ~30 feet indoors, ~100 feet outdoors
- Message queue: 24-hour TTL
- Auto-reconnect: On HomeScreen init

### Rally Mode (Phase 3)
- Geohash precision: 6 (~1.2km radius)
- Message TTL: 4 hours (configurable)
- Cleanup interval: Every 10 minutes
- Identity types: Anonymous, Pseudonymous, Verified
- Map: OpenStreetMap tiles
- Reputation: 0-100 score, filter threshold 20

### Crypto (Phase 1)
- Signing: Ed25519
- Key exchange: X25519
- Storage: flutter_secure_storage (iOS Keychain)
- Cloud: Matrix E2EE (handled by SDK)

---

## Success Criteria for First Device Test

### Minimum Viable Success
- ✅ App launches on both devices
- ✅ Can create accounts
- ✅ Can send cloud messages
- ✅ BLE connection establishes
- ✅ Offline messages deliver via mesh

### Bonus Success
- ✅ Rally channels work
- ✅ Map view displays correctly
- ✅ No crashes during 1-hour test
- ✅ Battery drain acceptable

**The most important test:** BLE mesh networking between two devices in Airplane Mode. This is the unique feature that can't be validated in simulator.

---

## When You Come Back

### Quick Start Checklist
1. ✅ macOS updated?
2. ✅ Xcode updated (supports iOS 26.3)?
3. ✅ Both devices connected and recognized?
4. ✅ Xcode shows devices as "available" not "no DDI"?

### First Commands to Run
```bash
cd /Users/jayklauminzer/Development/bridgeChat/apps/mobile
flutter devices
# Should see: iPhone 17 Pro + iPad both listed

flutter analyze
# Should see: 0 errors

open ios/Runner.xcworkspace
# Deploy from Xcode
```

### Expected First Launch
1. Splash screen (1-2 seconds)
2. Database initialization (~2 seconds)
3. Onboarding screen (3 slides)
4. Identity setup screen
5. Grant permissions (Bluetooth, Location, Notifications)
6. Home screen with 3 tabs: Chats, Rally, Settings

---

## Questions to Answer During Testing

1. **Does BLE mesh networking actually work?** (Most critical)
2. How far apart can devices be before BLE connection drops?
3. How long does BLE discovery take (target: <30 seconds)?
4. Do Rally channels discover correctly based on location?
5. Does message expiration cleanup work?
6. Are there any first-launch crashes we missed?
7. Is battery drain acceptable during BLE scanning?

---

## If You Need to Make Changes

### Quick Fixes
Most issues can be hot-reloaded:
- Press `r` in Flutter terminal for hot reload
- Press `R` for hot restart

### Requires Rebuild
- Database schema changes
- iOS permissions changes
- Native code changes
- Dependency updates

### Rebuild Command
```bash
flutter clean
flutter pub get
flutter run -d <device-id>
```

---

## Project Goal Reminder

**MeshLink** is a hybrid cloud/mesh messaging app that:
1. Uses Matrix for cloud messaging (when online)
2. Uses BLE mesh for offline messaging (when no internet)
3. Provides location-based Rally channels for public discourse
4. Maintains privacy with E2EE and anonymous options

**Current milestone:** Validate that BLE mesh networking works on real hardware. Everything else is secondary until this is proven.

---

## Important Notes

- **Free Apple ID:** Apps expire after 7 days, need rebuild
- **Developer Mode:** Must be enabled on iOS 16+ devices
- **BLE Limitations:** iOS backgrounds BLE after 10 seconds
- **Rally Cleanup:** Runs automatically every 10 minutes
- **Mesh Auto-Start:** Triggers 500ms after HomeScreen loads

---

## Contact Information

- **Project Path:** `/Users/jayklauminzer/Development/bridgeChat/`
- **Mobile App:** `/apps/mobile/`
- **Core Package:** `/packages/meshlink_core/`
- **Deployment Guides:** Root directory (*.md files)

---

**You're ready to deploy as soon as macOS/Xcode updates complete!** 🚀

The fastest path to success:
1. Update macOS + Xcode
2. Deploy to both devices
3. Test BLE mesh networking (the critical unknown)
4. Document what works and what doesn't
5. Iterate on fixes
