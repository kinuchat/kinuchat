import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Current user location stream
///
/// Provides real-time location updates for Rally channel discovery.
/// Returns null if location permission is denied.
///
/// Location settings:
/// - High accuracy (GPS)
/// - Updates every 100m movement
/// - Automatic permission checking
final currentLocationProvider = StreamProvider<Position?>((ref) async* {
  // Check location permission
  final permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    yield null;
    return;
  }

  // Check if location services are enabled
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    yield null;
    return;
  }

  // Stream location updates
  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Update every 100 meters
      timeLimit: Duration(seconds: 30), // Maximum wait time
    ),
  );
});

/// Current location permission status
///
/// Checks the app's location permission state.
/// Used to show permission request UI when needed.
final locationPermissionProvider = FutureProvider<LocationPermission>((ref) async {
  return await Geolocator.checkPermission();
});

/// Location service enabled status
///
/// Checks if the device's location services are enabled.
final locationServiceEnabledProvider = FutureProvider<bool>((ref) async {
  return await Geolocator.isLocationServiceEnabled();
});

/// Request location permission
///
/// Call this to request location permission from the user.
/// Returns the new permission state.
///
/// Example:
/// ```dart
/// final newPermission = await requestLocationPermission();
/// if (newPermission == LocationPermission.whileInUse) {
///   // Permission granted
/// }
/// ```
Future<LocationPermission> requestLocationPermission() async {
  return await Geolocator.requestPermission();
}

/// Get current location once
///
/// Gets a single location update without streaming.
/// Useful for one-time location checks.
///
/// Example:
/// ```dart
/// try {
///   final position = await getCurrentLocation();
///   print('Lat: ${position.latitude}, Lon: ${position.longitude}');
/// } catch (e) {
///   print('Failed to get location: $e');
/// }
/// ```
Future<Position> getCurrentLocation() async {
  // Check permission
  final permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    final newPermission = await Geolocator.requestPermission();
    if (newPermission == LocationPermission.denied ||
        newPermission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }
  }

  // Check if service is enabled
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled');
  }

  // Get current position
  return await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    ),
  );
}

/// Open location settings
///
/// Opens the device's location settings page.
/// Useful when location services are disabled.
Future<bool> openLocationSettings() async {
  return await Geolocator.openLocationSettings();
}

/// Calculate distance between two positions in meters
///
/// Uses the Haversine formula for great-circle distance.
///
/// Example:
/// ```dart
/// final distance = calculateDistance(
///   startLat: 37.7749,
///   startLon: -122.4194,
///   endLat: 37.8044,
///   endLon: -122.2712,
/// );
/// print('Distance: ${distance}m');
/// ```
double calculateDistance({
  required double startLat,
  required double startLon,
  required double endLat,
  required double endLon,
}) {
  return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
}

/// Format distance in human-readable format
///
/// Example:
/// ```dart
/// print(formatDistance(500));    // "500m"
/// print(formatDistance(1500));   // "1.5km"
/// print(formatDistance(15000));  // "15km"
/// ```
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()}m';
  } else {
    final km = meters / 1000;
    if (km < 10) {
      return '${km.toStringAsFixed(1)}km';
    } else {
      return '${km.round()}km';
    }
  }
}
