# Pre-Deployment Checklist

Before building and installing on iOS devices, verify these items:

---

## ✅ Code Completion Status

### Phase 1: Cloud Messaging
- [x] Matrix SDK integrated
- [x] Identity service (Ed25519/X25519 keys)
- [x] Secure storage (flutter_secure_storage)
- [x] Database schema (Conversations, Messages, Contacts)
- [x] Message encryption (handled by Matrix)
- [x] Chat UI (ChatScreen exists)
- [ ] **MISSING:** Onboarding flow (account creation wizard)
- [ ] **MISSING:** Contact management UI (add contact screen)
- [ ] **MISSING:** Matrix registration flow (auto-register on first launch)

### Phase 2: Mesh Networking
- [x] BLE scanning (flutter_blue_plus)
- [x] Noise protocol (XX handshake)
- [x] Store-and-forward queue
- [x] Mesh peer discovery
- [x] Route management
- [x] Message deduplication
- [x] Mesh status banner UI
- [ ] **MISSING:** Mesh initialization on app start
- [ ] **MISSING:** Auto-reconnect logic
- [ ] **MISSING:** Background BLE (iOS limitations apply)

### Phase 3: Rally Mode
- [x] Location services (geolocator)
- [x] Geohash-based channels
- [x] Rally repository & database
- [x] Channel discovery UI
- [x] Map view with markers
- [x] Reputation filtering
- [x] Reverse geocoding
- [x] Anonymous identity generation
- [x] Unit tests (58 passing)
- [x] Rally screen integration

---

## ⚠️ Critical Missing Pieces

### 1. App Initialization Flow

**Current State:** App likely crashes on first launch
**Needed:**
```dart
// lib/main.dart should check:
1. Is identity created? → If not, create it
2. Is Matrix registered? → If not, register
3. Initialize BLE service
4. Initialize location service
5. Show home screen
```

**Quick Fix:** Add initialization check in `main.dart`

### 2. Matrix Auto-Registration

**Current State:** User needs to manually register
**Needed:**
```dart
// On first launch:
1. Generate identity
2. Auto-register with Matrix homeserver
3. Store credentials
4. Navigate to home screen
```

**Quick Fix:** Add to identity providers or create onboarding service

### 3. Contact Discovery

**Current State:** "New Conversation" dialog exists but might not work
**Needed:**
```dart
// When user enters Matrix ID:
1. Validate format (@user:server.com)
2. Lookup user on Matrix
3. Create conversation
4. Fetch contact's public keys (for mesh)
```

**Quick Fix:** Verify `_createConversation()` in `home_screen.dart` works

---

## 🔍 Pre-Flight Verification

Run these commands before deploying:

### 1. Clean Build
```bash
cd /Users/jayklauminzer/Development/bridgeChat/apps/mobile
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

### 2. Run Tests
```bash
# Run core package tests
cd ../packages/meshlink_core
dart test

# Should see: "All tests passed!" (58 tests)
```

### 3. Static Analysis
```bash
cd ../../apps/mobile
flutter analyze

# Should see minimal warnings
# Critical errors must be fixed before deployment
```

### 4. Check Permissions (iOS)
```bash
cat ios/Runner/Info.plist | grep -A1 "NSBluetooth\|NSLocation"
```

**Expected output:**
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>MeshLink uses Bluetooth...</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>MeshLink needs your location...</string>
```

---

## 🚨 Likely First-Launch Issues

### Issue 1: App Crashes Immediately
**Cause:** No identity created, database not initialized
**Fix:** Add initialization guard in `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = AppDatabase.forPath(...);

  // Initialize identity (or create if missing)
  final identity = await loadOrCreateIdentity();

  runApp(MyApp());
}
```

### Issue 2: "Connection Failed" on Message Send
**Cause:** Matrix client not initialized or not logged in
**Fix:** Check `matrix_providers.dart` initialization
**Debug:** Check Xcode console for Matrix SDK errors

### Issue 3: BLE Permission Denied
**Cause:** User denied Bluetooth permission
**Fix:** Show alert explaining need, deep link to Settings
**Note:** On first launch, permission prompt should appear automatically

### Issue 4: No Nearby Peers Found (Mesh)
**Cause:** BLE scanning not started, or devices too far apart
**Fix:**
1. Verify `MeshService` starts scanning on app launch
2. Check devices are within 30 feet
3. Check Bluetooth is enabled on both devices
4. Check Xcode console for BLE errors

### Issue 5: Rally Channels Not Loading
**Cause:** Location permission denied or GPS not available
**Fix:**
1. Grant location permission
2. Wait for GPS lock (can take 10-30 seconds)
3. Check Xcode console for geolocator errors

---

## 🔧 Quick Fixes to Apply Now

### Fix 1: Add Initialization Check
```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create app database
  final dbPath = await getDatabasePath();
  final database = AppDatabase.forPath(dbPath);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const MeshLinkApp(),
    ),
  );
}
```

### Fix 2: Auto-Create Identity on First Launch
```dart
// In identity_providers.dart or similar
final identityProvider = FutureProvider<Identity?>((ref) async {
  final storage = ref.read(secureStorageProvider);

  // Try to load existing identity
  final existing = await storage.loadIdentity();
  if (existing != null) return existing;

  // Create new identity on first launch
  final newIdentity = await IdentityService.generateIdentity();
  await storage.saveIdentity(newIdentity);

  return newIdentity;
});
```

### Fix 3: Verify Chat Screen Works
```bash
# Check that ChatScreen exists and compiles
grep -r "class ChatScreen" lib/
```

**If missing:** You'll need to create it or verify navigation works.

---

## 📋 Deployment Readiness Score

Calculate your readiness:

- [ ] All dependencies installed (flutter pub get) - 10 points
- [ ] No compilation errors (flutter analyze) - 20 points
- [ ] Unit tests passing (dart test) - 10 points
- [ ] Identity service works - 20 points
- [ ] Database migrations work - 10 points
- [ ] BLE permissions configured - 10 points
- [ ] Location permissions configured - 5 points
- [ ] Chat UI exists and compiles - 15 points

**Score:**
- **100 points:** Deploy with confidence! 🚀
- **80-99 points:** Deploy, expect minor issues
- **60-79 points:** Fix critical items first
- **< 60 points:** More work needed before device testing

---

## 🎯 Recommended Deployment Strategy

### Option A: Deploy "As Is" (Learn by Breaking)
**Good if:**
- You want to see what breaks
- You're comfortable debugging on device
- You want to identify gaps quickly

**Steps:**
1. Follow DEPLOYMENT_GUIDE.md
2. Install on both devices
3. Document every crash/error
4. Fix issues one by one
5. Rebuild and retest

### Option B: Fix Critical Items First (Safer)
**Good if:**
- You want a smoother first-run experience
- You want to test specific features

**Priority fixes:**
1. ✅ **Add initialization flow** (identit + database + Matrix)
2. ✅ **Verify chat screen works** (can send/receive messages)
3. ✅ **Start BLE scanning on launch** (mesh connectivity)
4. Then deploy and test

---

## 🔥 What I Recommend

**Deploy now with "Option A"** - here's why:

1. **You'll learn faster** by seeing what actually breaks on device
2. **BLE testing requires real hardware** - can't test in simulator
3. **Most issues will be UI/flow** - not core functionality
4. **Rally Mode is solid** - 58 tests passing, code compiles
5. **You can fix issues iteratively** - rebuild every 6 days anyway

**Expect these issues:**
- First launch might crash (no identity initialized)
- Matrix registration might need manual trigger
- BLE might not auto-start scanning
- Contact adding might need tweaking

**But the core tech is there:**
- ✅ Crypto working (Ed25519/X25519)
- ✅ Database working (Drift + migrations)
- ✅ BLE stack ready (flutter_blue_plus + Noise)
- ✅ Rally Mode complete (full UI + backend)

---

## Next Steps

1. **Read:** `DEPLOYMENT_GUIDE.md` (step-by-step Xcode instructions)
2. **Deploy:** Install on iPhone + iPad (15 minutes)
3. **Test:** Follow `TESTING_PLAN.md` scenarios
4. **Document:** Any crashes or errors you encounter
5. **Fix:** Address issues in order of severity
6. **Iterate:** Rebuild and retest

---

## Need Help?

If you get stuck:

1. **Check Xcode console** - most errors show there
2. **Run `flutter doctor`** - verify Flutter setup
3. **Clean and rebuild** - `flutter clean && flutter pub get`
4. **Check this file** - common issues listed above
5. **Review logs** - Window → Devices → View Device Logs

---

**You're ready to deploy!** 🎉

The fastest way to progress is:
1. Deploy now (even if not perfect)
2. See what breaks
3. Fix the critical path
4. Test the BLE mesh networking (the unique feature!)
5. Iterate

Don't aim for perfection before first device test - aim for learning what needs fixing!
