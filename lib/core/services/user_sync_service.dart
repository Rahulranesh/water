import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fcm_service.dart';
import 'location_service.dart';

/// Syncs the user's FCM push token and location coordinates to Firestore.
/// This enables a backend to run automated weather push notifications.
class UserSyncService {
  factory UserSyncService() => _instance;
  UserSyncService._internal();
  static final UserSyncService _instance = UserSyncService._internal();

  static const _userIdKey = 'hydroflow_device_user_id';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = const LocationService();

  /// Fetches or generates a persistent random device ID.
  Future<String> _getOrGenerateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_userIdKey);
    if (id == null) {
      // Generate a simple, collision-resistant random identifier
      final rand = Random();
      final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final buffer = StringBuffer();
      for (var i = 0; i < 16; i++) {
        buffer.write(chars[rand.nextInt(chars.length)]);
      }
      id = 'dev_${buffer.toString()}';
      await prefs.setString(_userIdKey, id);
    }
    return id;
  }

  /// Syncs the current FCM Token and coordinates to Firestore.
  /// Gracefully fails if Firestore is offline or permissions are missing.
  Future<void> syncUserSession() async {
    debugPrint('UserSyncService: starting syncUserSession...');
    try {
      final deviceId = await _getOrGenerateDeviceId();
      debugPrint('UserSyncService: got device ID: $deviceId');

      final fcmToken = await FcmService().getDeviceToken();
      debugPrint('UserSyncService: got FCM token: ${fcmToken != null ? "exists" : "null"}');

      if (fcmToken == null) {
        debugPrint('UserSyncService: No FCM token, skipping sync');
        return;
      }

      // Read current location if permission is granted
      double? lat;
      double? lon;
      debugPrint('UserSyncService: checking location permission...');
      final perm = await _locationService.checkPermission();
      debugPrint('UserSyncService: location permission: $perm');
      if (_locationService.isGranted(perm)) {
        debugPrint('UserSyncService: fetching current position...');
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          lat = position.latitude;
          lon = position.longitude;
          debugPrint('UserSyncService: position fetched: $lat, $lon');
        }
      }

      debugPrint('UserSyncService: saving to Firestore...');
      // Save user record in Cloud Firestore
      await _firestore.collection('users').doc(deviceId).set({
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'latitude': lat,
        'longitude': lon,
        'lastActive': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      }, SetOptions(merge: true));

      debugPrint('UserSyncService: Synced device ID $deviceId to Firestore successfully');
    } catch (e) {
      debugPrint('UserSyncService: Firestore sync failed: $e');
    }
  }
}
