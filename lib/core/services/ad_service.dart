import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

/// Service for managing Google Mobile Ads
/// Handles initialization, loading, and lifecycle of different ad types
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;

  /// Initialize the Mobile Ads SDK.
  /// On iOS, requests App Tracking Transparency permission first (required by
  /// Apple guideline 5.1.2(i)). Ads load regardless of the user's choice —
  /// Google automatically serves non-personalized ads when permission is denied.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Platform.isIOS) {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }

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
  static const List<String> _testDeviceIds = [
    'cf94d0b94170631b703bfff3b4b78855', // Ed :) iPhone
  ];

  // Google's official test ad unit IDs — safe to use in development.
  // Replace via ADMOB_BANNER_* / ADMOB_INTERSTITIAL_* in .env or --dart-define
  // before submitting to the App Store / Play Store.
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';

  /// Get the appropriate banner ad unit ID for the current platform.
  /// Uses the value from .env / --dart-define when set; falls back to Google's
  /// test IDs so ads are always visible during development.
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      final id = EnvConfig.admobBannerAndroid;
      return id.isNotEmpty ? id : _testBannerAndroid;
    }
    if (Platform.isIOS) {
      final id = EnvConfig.admobBannerIos;
      return id.isNotEmpty ? id : _testBannerIos;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Get the appropriate interstitial ad unit ID for the current platform.
  /// Uses the value from .env / --dart-define when set; falls back to Google's
  /// test IDs so ads are always visible during development.
  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      final id = EnvConfig.admobInterstitialAndroid;
      return id.isNotEmpty ? id : _testInterstitialAndroid;
    }
    if (Platform.isIOS) {
      if (!kReleaseMode) return _testInterstitialIos;
      final id = EnvConfig.admobInterstitialIos;
      return id.isNotEmpty ? id : _testInterstitialIos;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Create and load a banner ad.
  /// Returns the loaded [BannerAd] on success, or null if the ad fails to load.
  /// The future only resolves after the native callback confirms success or failure,
  /// preventing the "Ad with id X is not available" plugin warning caused by
  /// disposing the ad before the failure callback fires.
  Future<BannerAd?> loadBannerAd({AdSize size = AdSize.banner}) async {
    // Self-heal: initialize if the deferred startup init hasn't completed yet.
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return null;

    final completer = Completer<BannerAd?>();

    late BannerAd banner;
    banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );

    try {
      await banner.load();
      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) completer.complete(null);
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

    final completer = Completer<InterstitialAd?>();

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                onAdDismissedFullScreenContent?.call(ad);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
              },
            );
            if (!completer.isCompleted) completer.complete(ad);
          },
          onAdFailedToLoad: (error) {
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) completer.complete(null);
      return null;
    }
  }

  /// Get the appropriate native ad unit ID for the current platform.
  String get nativeAdUnitId {
    if (Platform.isAndroid) {
      final id = EnvConfig.admobNativeAndroid;
      return id.isNotEmpty ? id : _testNativeAndroid;
    }
    if (Platform.isIOS) {
      final id = EnvConfig.admobNativeIos;
      return id.isNotEmpty ? id : _testNativeIos;
    }
    throw UnsupportedError('Unsupported platform');
  }

  InterstitialAd? _preloadedInterstitial;

  /// Preload an interstitial ad silently. No-op if already loaded.
  Future<void> preloadInterstitial() async {
    if (_preloadedInterstitial != null) return;
    // Self-heal: wait for SDK before trying to load
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    _preloadedInterstitial = await loadInterstitialAd(
      onAdDismissedFullScreenContent: (_) {
        _preloadedInterstitial = null;
        preloadInterstitial();
      },
    );
  }

  /// Show the preloaded interstitial on every Nth app session.
  /// Pass [shouldShow] = false for premium users to skip entirely.
  Future<void> showInterstitialIfEligible({bool shouldShow = true}) async {
    if (!shouldShow) return;
    if (_preloadedInterstitial == null) return;
    if (!await _SessionCounter.shouldShowAd()) return;
    await _preloadedInterstitial?.show();
  }

  /// Check if the SDK is initialized
  bool get isInitialized => _isInitialized;
}

// ── Session counter — shows interstitial every 3rd cold launch ────────────────
class _SessionCounter {
  static const _key = 'finmate_session_count';
  static const _interval = 3;

  static Future<bool> shouldShowAd() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_key) ?? 0) + 1;
    await prefs.setInt(_key, next);
    return next % _interval == 0;
  }
}
