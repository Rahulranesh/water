// File generated from google-services.json for project water-a75c6
// DO NOT EDIT — regenerate by running: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS yet. '
          'Add a GoogleService-Info.plist and re-run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDKmjr-vANxYuGQ7-5UUosyINL8JtRWn30',
    appId: '1:135030806020:android:c363a13a76d3b7a971c751',
    messagingSenderId: '135030806020',
    projectId: 'water-a75c6',
    storageBucket: 'water-a75c6.firebasestorage.app',
  );
}
