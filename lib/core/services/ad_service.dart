import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/env_config.dart';

/// Service for managing Google Mobile Ads
/// Handles initialization, loading, and lifecycle of different ad types
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;

  /// Initialize the Mobile Ads SDK
  /// Should be called once at app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register test devices to avoid policy violations during development.
      // Find your device ID in the console log after first run:
      // "To get test ads on this device, set testDeviceIdentifiers = @[ @"XXXX" ]"
      // Then add it to the list below.
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      // Initialization failed silently
    }
  }

  /// Add your physical device IDs here during development.
  /// These IDs are printed in the console on first AdMob init.
  /// Safe to leave empty — only affects dev/test builds.
  static const List<String> _testDeviceIds = [];

  /// Get the appropriate banner ad unit ID for the current platform.
  /// Override via ADMOB_BANNER_ANDROID / ADMOB_BANNER_IOS in .env or --dart-define.
  String get bannerAdUnitId {
    if (Platform.isAndroid) return EnvConfig.admobBannerAndroid;
    if (Platform.isIOS) return EnvConfig.admobBannerIos;
    throw UnsupportedError('Unsupported platform');
  }

  /// Get the appropriate interstitial ad unit ID for the current platform.
  /// Override via ADMOB_INTERSTITIAL_ANDROID / ADMOB_INTERSTITIAL_IOS in .env or --dart-define.
  String get interstitialAdUnitId {
    if (Platform.isAndroid) return EnvConfig.admobInterstitialAndroid;
    if (Platform.isIOS) return EnvConfig.admobInterstitialIos;
    throw UnsupportedError('Unsupported platform');
  }

  /// Create and load a banner ad
  /// Returns null if loading fails
  Future<BannerAd?> loadBannerAd({
    AdSize size = AdSize.banner,
    Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!_isInitialized) {
      return null;
    }

    try {
      final banner = BannerAd(
        adUnitId: bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {},
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            onAdFailedToLoad?.call(ad, error);
          },
          onAdOpened: (ad) {},
          onAdClosed: (ad) {},
        ),
      );

      await banner.load();
      return banner;
    } catch (e) {
      return null;
    }
  }

  /// Create and load an interstitial ad
  /// Returns null if loading fails
  Future<InterstitialAd?> loadInterstitialAd({
    Function(Ad, LoadAdError)? onAdFailedToLoad,
    Function(Ad)? onAdDismissedFullScreenContent,
  }) async {
    if (!_isInitialized) {
      return null;
    }

    InterstitialAd? interstitialAd;

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                onAdDismissedFullScreenContent?.call(ad);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
              },
            );
          },
          onAdFailedToLoad: (error) {
            // interstitialAd is null when load fails — skip the callback
          },
        ),
      );
    } catch (e) {
      return null;
    }

    return interstitialAd;
  }

  /// Check if the SDK is initialized
  bool get isInitialized => _isInitialized;
}
