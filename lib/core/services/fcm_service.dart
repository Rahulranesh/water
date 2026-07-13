import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'user_sync_service.dart';

/// Top-level background message handler for FCM.
/// Must be annotated with @pragma('vm:entry-point') so it doesn't get tree-shaken.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class FcmService {
  factory FcmService() => _instance;
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initializes listeners for foreground, background, and app-opened scenarios.
  Future<void> initialize() async {
    if (_initialized) return;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions (safely handles iOS & Android)
    await requestPermission();

    // Foreground listener: shows a local notification when FCM is received
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground FCM message: ${message.notification?.title}');
      _showForegroundLocalNotification(message);
    });

    // App opened via notification listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened via remote notification: ${message.messageId}');
    });

    // Handle initial message if app was terminated and opened via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from terminated state via notification: ${initialMessage.messageId}');
    }

    // Listener for FCM token refreshes
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('FCM Token refreshed: $token');
      UserSyncService().syncUserSession();
    });

    // Run first device sync (non-blocking)
    UserSyncService().syncUserSession();

    _initialized = true;
  }

  /// Request permissions for remote push notifications.
  Future<void> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('User notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('FCM Request Permission error: $e');
    }
  }

  /// Fetches the unique FCM Device Registration Token.
  Future<String?> getDeviceToken() async {
    try {
      if (kIsWeb) return null;
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM Device Token: $e');
      return null;
    }
  }

  /// Triggered when a notification is received in the foreground.
  /// Translates remote FCM message to a local notification alert.
  Future<void> _showForegroundLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'hydroflow_remote_notifications',
            'Remote Alerts',
            channelDescription: 'Used for remote notifications from the cloud.',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
      );
    }
  }
}
