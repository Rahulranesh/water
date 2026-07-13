import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'core/services/fcm_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase (required by google-services plugin)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialise FCM push notification listeners
  await FcmService().initialize();

  // Initialise Mobile Ads SDK
  await MobileAds.instance.initialize();

  runApp(const ProviderScope(child: HydroFlowApp()));
}
