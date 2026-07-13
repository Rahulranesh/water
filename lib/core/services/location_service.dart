import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Handles location permission checking and coordinate fetching.
class LocationService {
  const LocationService();

  /// Returns true if location services are enabled on this device.
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Returns the current [LocationPermission] status without prompting.
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  /// Requests location permission from the OS and returns the result.
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  /// Returns true if the granted permission is usable (whenInUse or always).
  bool isGranted(LocationPermission permission) =>
      permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;

  /// Opens the device settings so the user can manually change the permission.
  Future<bool> openSettings() => Geolocator.openLocationSettings();

  /// Returns the current device [Position] or null on failure.
  Future<Position?> getCurrentPosition() async {
    try {
      final permission = await checkPermission();
      if (!isGranted(permission)) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.reduced, // city-level is enough
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('LocationService error: $e');
      return null;
    }
  }
}
