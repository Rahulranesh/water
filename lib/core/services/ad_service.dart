import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  const AdService();

  bool get nativeAdsAvailable => !kIsWeb;

  Future<void> initializeAfterConsent() async {
    debugPrint('HydroFlow ads initialized after consent.');
  }

  Future<bool> showRewardedAdForAdFreeHour() async {
    if (kIsWeb) {
      debugPrint('Web does not support Mobile Ads SDK.');
      return true;
    }

    final adUnitId = defaultTargetPlatform == TargetPlatform.android
        ? 'ca-app-pub-3940256099942544/5224354917' // Android Test Rewarded Ad ID
        : 'ca-app-pub-3940256099942544/1712485313'; // iOS Test Rewarded Ad ID

    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
          );

          ad.show(
            onUserEarnedReward: (ad, reward) {
              if (!completer.isCompleted) {
                completer.complete(true);
              }
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    return completer.future;
  }
}
