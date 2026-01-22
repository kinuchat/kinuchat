# iOS TestFlight Setup Guide

## Prerequisites
- Apple Developer Account ($99/year)
- Xcode installed (for archive & upload)
- Bundle ID: `com.kinuchat.app`

---

## Step 1: App Store Connect Setup

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform**: iOS
   - **Name**: Kinu
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: com.kinuchat.app (register first if needed)
   - **SKU**: kinuchat-ios-001 (any unique string)
   - **User Access**: Full Access

---

## Step 2: Register Bundle ID (if not already done)

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Certificates, Identifiers & Profiles → Identifiers
3. Click "+" to add new identifier
4. Select "App IDs" → Continue
5. Select "App" → Continue
6. Fill in:
   - **Description**: Kinu App
   - **Bundle ID**: Explicit → `com.kinuchat.app`
7. Enable Capabilities:
   - [x] Background Modes (for Bluetooth LE)
   - [x] Push Notifications (if using later)
8. Continue → Register

---

## Step 3: Build & Archive from Xcode

### Option A: Using Xcode GUI

```bash
cd /Users/jayklauminzer/Development/bridgeChat/apps/mobile
open ios/Runner.xcworkspace
```

1. Select "Runner" in project navigator
2. Select your Team under "Signing & Capabilities"
3. Select "Any iOS Device (arm64)" as build target
4. Product → Archive
5. When archive completes, Organizer opens
6. Select archive → Distribute App
7. Choose "App Store Connect" → Next
8. Choose "Upload" → Next
9. Let Xcode manage signing → Next
10. Upload

### Option B: Command Line (after Xcode signing setup)

```bash
cd /Users/jayklauminzer/Development/bridgeChat/apps/mobile

# Clean build
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release

# Create archive
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/ipa \
  -exportOptionsPlist ExportOptions.plist
```

---

## Step 4: TestFlight Setup

1. After upload processes (5-30 min), go to App Store Connect
2. Select Kinu app → TestFlight tab
3. The build should appear under "iOS Builds"
4. Click the build number
5. Add **Export Compliance Information**:
   - Does your app use encryption? → **Yes** (we use E2E encryption)
   - Does your app qualify for exemptions? → **Yes, it qualifies**
   - Select: "Only uses encryption from iOS/macOS"
6. Click "Save"

---

## Step 5: Add Testers

### Internal Testing (up to 100 users)
1. TestFlight → Internal Testing → "App Store Connect Users"
2. Add team members who have App Store Connect access
3. They'll receive TestFlight invite automatically

### External Testing (up to 10,000 users)
1. TestFlight → External Testing → "+" to create group
2. Name: "Beta Testers"
3. Add build to group
4. Submit for TestFlight Review (usually 24-48 hours first time)
5. Once approved, add testers by email
6. Or create public link for easy sharing

---

## Common Issues

### "No signing certificate" error
- Open Xcode → Preferences → Accounts → Add your Apple ID
- Select Runner project → Signing & Capabilities
- Enable "Automatically manage signing"
- Select your Team

### "Provisioning profile" issues
- In Xcode: Runner → Signing → Team dropdown
- Select your development team
- Xcode will auto-create profiles

### Build fails with capability error
Ensure these are enabled in Developer Portal for com.kinuchat.app:
- Background Modes
- Push Notifications (optional)

---

## Version Bumping for Updates

Before each TestFlight update:

```bash
# Edit pubspec.yaml
version: 1.0.0+2  # Increment build number (+2, +3, etc.)
```

Or for new version:
```bash
version: 1.0.1+1  # New version resets build number
```

---

## RevenueCat iOS Setup

After first TestFlight build:

1. Go to RevenueCat dashboard
2. Add iOS App:
   - Platform: iOS
   - App Bundle ID: `com.kinuchat.app`
3. Create App Store Connect API Key:
   - App Store Connect → Users and Access → Integrations → App Store Connect API
   - Generate API Key (Admin role)
   - Download .p8 key file
4. Add key to RevenueCat:
   - Project Settings → Apps → iOS app → App Store Connect API
   - Upload Issuer ID, Key ID, and .p8 file
5. Products will sync automatically from App Store Connect

---

## Checklist

- [ ] Bundle ID registered in Apple Developer Portal
- [ ] App created in App Store Connect
- [ ] Signing configured in Xcode
- [ ] Archive built and uploaded
- [ ] Export compliance answered
- [ ] TestFlight group created
- [ ] First tester invited
- [ ] (Optional) RevenueCat iOS app connected
