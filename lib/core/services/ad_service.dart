import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      // Initialization failed silently
    }
  }

  /// Get the appropriate banner ad unit ID for the current platform
  /// Using test IDs for development - replace with real IDs for production
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Test ID - Replace with your AdMob unit ID for production
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      // Test ID - Replace with your AdMob unit ID for production
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Get the appropriate interstitial ad unit ID for the current platform
  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Test ID - Replace with your AdMob unit ID for production
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      // Test ID - Replace with your AdMob unit ID for production
      return 'ca-app-pub-3940256099942544/4411468910';
    }
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
            onAdFailedToLoad?.call(interstitialAd!, error);
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
