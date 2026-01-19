# Kinu iOS Device Deployment Guide

## Overview
This guide walks you through deploying Kinu to your physical iOS devices (iPhone + iPad) for BLE mesh networking testing.

---

## Prerequisites

- ✅ macOS with Xcode installed
- ✅ 2 iOS devices (iPhone + iPad)
- ✅ Lightning/USB-C cables
- ✅ Apple ID (free account works!)
- ✅ Both devices running iOS 15+ recommended

---

## Quick Start (Free Deployment)

### Step 1: Open Xcode Project

```bash
cd /Users/jayklauminzer/Development/bridgeChat/apps/mobile
open ios/Runner.xcworkspace  # Important: Use .xcworkspace, not .xcodeproj!
```

**Note:** If you get an error, run `pod install` first:
```bash
cd ios
pod install
cd ..
```

### Step 2: Configure Signing (One-Time Setup)

1. **In Xcode**, select the **Runner** target in the left sidebar
2. Select the **Signing & Capabilities** tab
3. **Uncheck** "Automatically manage signing" (temporarily)
4. **Check** "Automatically manage signing" again
5. Select your **Apple ID** from the "Team" dropdown
   - If you don't see your Apple ID:
     - Go to **Xcode → Settings → Accounts**
     - Click **+** → Add Apple ID
     - Sign in with your personal Apple ID

6. **Bundle Identifier** should be: `com.kinuchat.mobile`
   - If there's a conflict, change it to: `com.YOUR_NAME.kinu`

7. Xcode will automatically create a **Provisioning Profile**

### Step 3: Trust Your Developer Certificate (On Each Device)

**First time only - do this on BOTH devices:**

1. Connect device via USB
2. Unlock the device
3. Trust this computer (tap "Trust" on device popup)
4. On the device, go to:
   ```
   Settings → General → VPN & Device Management
   → Developer App → [Your Apple ID]
   → Trust "[Your Apple ID]"
   ```

### Step 4: Build & Install on iPhone

1. **Connect iPhone** via USB
2. In Xcode, select **iPhone** from the device dropdown (top toolbar)
3. Click the **▶ Run** button (or press ⌘R)
4. Wait for build to complete (~2-5 minutes first time)
5. App will launch on iPhone!

### Step 5: Build & Install on iPad

1. **Disconnect iPhone, connect iPad**
2. In Xcode, select **iPad** from device dropdown
3. Click **▶ Run** button again
4. App will launch on iPad!

---

## Important Notes

### ⚠️ 7-Day Expiration (Free Account)

- Apps installed with free Apple ID **expire after 7 days**
- You'll see "Untrusted Developer" error
- **Solution:** Just rebuild and reinstall from Xcode
- **Tip:** Set a calendar reminder for every 6 days

### 🔒 BLE Permissions

The app will request:
- ✅ Bluetooth permissions (for mesh networking)
- ✅ Location permissions (for Rally Mode)
- ✅ Notification permissions (for messages)

**Grant all permissions** for full functionality.

### 📱 Running on Both Devices Simultaneously

To test mesh networking between devices:

1. **Build on Device 1**, let it run
2. **Keep Device 1 connected**, or disconnect and run standalone
3. **Switch to Device 2** in Xcode, build and run
4. Both devices now have the app installed!

---

## Troubleshooting

### Error: "Failed to create provisioning profile"

**Solution:** Change the bundle identifier:
```
In Xcode:
Runner target → General tab → Bundle Identifier
Change to: com.YOURNAME.meshlink
```

### Error: "The application could not be verified"

**Solution:** Trust the developer certificate on device:
```
Settings → General → VPN & Device Management → Trust
```

### Error: "Xcode could not locate device support files"

**Solution:** Update Xcode:
```
App Store → Updates → Update Xcode
```

Or download device support files manually from Apple.

### Error: Pod install fails

**Solution:** Update CocoaPods:
```bash
sudo gem install cocoapods
cd ios
pod repo update
pod install
```

### Error: "Developer Mode Required" (iOS 16+)

**Solution:** Enable Developer Mode on device:
```
Settings → Privacy & Security → Developer Mode → Enable
```
Device will restart. Try again after restart.

---

## Testing Checklist

Once installed on both devices:

### ✅ Phase 1: Cloud Messaging Test
- [ ] Create account on Device 1
- [ ] Create account on Device 2
- [ ] Add Device 1's user ID on Device 2 (start conversation)
- [ ] Send message from Device 2
- [ ] Verify message arrives on Device 1 (encrypted)
- [ ] Reply from Device 1
- [ ] Verify delivery receipts
- [ ] Test with both WiFi and cellular

### ✅ Phase 2: Mesh Networking Test
- [ ] Enable Airplane Mode on BOTH devices
- [ ] Enable Bluetooth on BOTH devices
- [ ] Keep devices within ~30 feet of each other
- [ ] Send message from Device 1
- [ ] Verify BLE connection established (check status banner)
- [ ] Verify message delivered to Device 2 via BLE
- [ ] Test reply in opposite direction
- [ ] Test store-and-forward (send while out of range, deliver when back in range)

### ✅ Phase 3: Rally Mode Test
- [ ] Enable location permissions on both devices
- [ ] Go to Rally tab
- [ ] Grant location access
- [ ] Create Rally channel at current location
- [ ] Verify channel appears on Device 2
- [ ] Join channel on Device 2
- [ ] Post messages from both devices
- [ ] Verify real-time updates
- [ ] Test map view toggle
- [ ] Test anonymous identity switching

---

## Next Steps After Successful Testing

### Option A: Continue with Free Account
- **Good for:** Short-term development/testing
- **Action:** Rebuild every 6 days
- **Cost:** Free

### Option B: Upgrade to Apple Developer Program
- **Good for:** Longer testing, TestFlight distribution
- **Action:** Sign up at https://developer.apple.com/programs/
- **Cost:** $99/year
- **Benefits:**
  - 90-day builds (no weekly reinstalls)
  - TestFlight distribution (up to 10,000 testers)
  - Push notifications
  - App Store submission
  - Crash analytics

### Option C: TestFlight Public Beta
Once you have Apple Developer account:
1. Archive build in Xcode
2. Upload to App Store Connect
3. Submit for TestFlight review (~24 hours)
4. Share TestFlight link with testers
5. Testers install via TestFlight app

---

## Performance Tips

### Faster Rebuilds
```bash
# Clean build folder if Xcode acts weird
⌘ + Shift + K (Clean Build Folder)

# Speed up builds - disable Bitcode (already disabled in Flutter)
# Speed up builds - use Debug configuration for testing
```

### Debugging on Device

1. **View logs** while device is connected:
   - Window → Devices and Simulators → Select device → View Device Logs

2. **Debug wireless** (after first USB connection):
   - Window → Devices and Simulators → Select device
   - Check "Connect via network"
   - Disconnect USB, device stays available!

---

## Build Configurations

### Debug (Default for Testing)
- ✅ Faster compilation
- ✅ Better error messages
- ✅ Flutter hot reload works
- ⚠️ Larger app size
- ⚠️ Slower performance

### Release (For Performance Testing)
```bash
flutter build ios --release
# Then install via Xcode
```
- ✅ Optimized performance
- ✅ Smaller app size
- ⚠️ No hot reload
- ⚠️ Harder to debug

**Recommendation:** Use Debug for development, Release for final testing before distribution.

---

## Security Notes

### Code Signing
- Your Apple ID signs the app
- Certificate is stored in macOS Keychain
- Device trusts your certificate after first install

### Provisioning Profiles
- Auto-generated by Xcode
- Stored in `~/Library/MobileDevice/Provisioning Profiles/`
- Expire after 7 days (free) or 1 year (paid)

### App Sandbox
- iOS sandbox limits what the app can access
- BLE, Location, Notifications require user permission
- All permissions already configured in Info.plist

---

## Quick Reference Commands

```bash
# Open project in Xcode
open ios/Runner.xcworkspace

# Clean Flutter build
flutter clean

# Get dependencies
flutter pub get

# Install iOS pods
cd ios && pod install && cd ..

# Build for iOS
flutter build ios

# Run on connected device
flutter run

# Check connected devices
flutter devices

# View Flutter logs
flutter logs
```

---

## Additional Resources

- **Apple Developer:** https://developer.apple.com
- **Xcode Help:** Help → Xcode Help (in Xcode menu)
- **Flutter iOS Setup:** https://docs.flutter.dev/get-started/install/macos/mobile-ios
- **BLE Troubleshooting:** Check Bluetooth is enabled, devices are close (~30 ft max)

---

## Support

If you encounter issues:
1. Check the Troubleshooting section above
2. Clean and rebuild: `flutter clean && flutter pub get`
3. Restart Xcode
4. Restart devices
5. Check Xcode console for error messages

---

**Ready to test!** 🚀

Run through the testing checklist and verify:
- ✅ Cloud messaging works
- ✅ BLE mesh networking connects
- ✅ Rally Mode discovers channels
- ✅ Both devices can communicate

Good luck with testing! The BLE mesh networking is the most critical part to validate on real hardware.
