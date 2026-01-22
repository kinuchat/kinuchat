# Claude Rules for Kinu Mobile App

## Build Rules

### Auto-increment version on every build
Before running `flutter build apk`, `flutter build ios`, or `flutter install`:
1. Read the current version from `pubspec.yaml`
2. Increment the build number (the `+N` part)
3. Update `pubspec.yaml` with the new version

Example: `1.0.0+2` becomes `1.0.0+3`

The version format is `MAJOR.MINOR.PATCH+BUILD` where:
- MAJOR.MINOR.PATCH = user-visible version (only change when releasing new features)
- BUILD = internal build number (increment every build)
