# Temporary Workarounds & TODOs

This file documents temporary changes and workarounds that need to be properly fixed later.

## 1. Android Background Service Disabled

**Date**: 2026-01-21  
**Files Modified**:
- `apps/mobile/android/app/src/main/AndroidManifest.xml` - commented out service declaration
- `apps/mobile/lib/core/providers/mesh_providers.dart` - wrapped updatePeerCount in try-catch
- `apps/mobile/pubspec.yaml` - commented out flutter_background_service dependency
- `apps/mobile/lib/data/services/mesh_background_service.dart` - replaced with stub

**Issue**: App crashes on Android 14+ (API 34) with:
```
android.app.RemoteServiceException$CannotPostForegroundServiceNotificationException: 
Bad notification for startForeground
```

**Root Cause**: `flutter_background_service` requires a notification channel to be created BEFORE calling `startForeground()` on Android 14+. The current implementation doesn't create the channel early enough.

**Temporary Fix**:
1. Commented out the `<service>` declaration in `AndroidManifest.xml`:
```xml
<!-- TEMPORARILY DISABLED: Causes crash on Android 14+ without proper notification channel
<service
    android:name="id.flutter.flutter_background_service.BackgroundService"
    ...
</service>
-->
```

2. Wrapped `MeshBackgroundService.updatePeerCount()` call in try-catch in `mesh_providers.dart` (line ~183)

**Proper Fix Required**:
1. Create notification channel at app startup (in MainActivity or Application class)
2. OR upgrade `flutter_background_service` to a version that handles Android 14+ properly
3. Uncomment the service declaration in manifest after fix

**Impact of Workaround**: Mesh networking stops when app is backgrounded on Android (iOS unaffected).

---

## How to search for temporary changes

Run this from the project root:
```bash
grep -r "TEMPORARILY DISABLED\|TODO.*temporary\|WORKAROUND" --include="*.dart" --include="*.xml" --include="*.kt" --include="*.java" .
```
