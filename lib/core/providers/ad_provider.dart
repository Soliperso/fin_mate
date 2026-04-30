import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ad_service.dart';
import 'subscription_provider.dart';

// ============================================================================
// Ad Service Provider
// ============================================================================

/// Provider for AdService singleton
final adServiceProvider = Provider<AdService>((ref) {
  return AdService.instance;
});

// ============================================================================
// Ad Display Logic Provider
// ============================================================================

/// Provider that determines if ads should be shown to the current user
/// Ads are shown ONLY to non-premium (freemium) users
/// Returns false for premium users, true for freemium users
final shouldShowAdsProvider = FutureProvider<bool>((ref) async {
  try {
    final isPremium = await ref.watch(isPremiumProvider.future);

    // Show ads ONLY if user is NOT premium
    return !isPremium;
  } catch (e) {
    // On error, default to showing ads (safer for monetization)
    // Most errors mean user is not authenticated or has default freemium tier
    return true;
  }
});

// ============================================================================
// Native Ad Provider
// ============================================================================

/// Loads and holds the native ad. Returns null if premium or load fails.
final nativeAdProvider =
    StateNotifierProvider<NativeAdNotifier, NativeAd?>((ref) {
  return NativeAdNotifier(ref);
});

class NativeAdNotifier extends StateNotifier<NativeAd?> {
  NativeAdNotifier(this._ref) : super(null) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final shouldShow = await _ref.read(shouldShowAdsProvider.future);
      if (!shouldShow) return;

      if (!AdService.instance.isInitialized) {
        await AdService.instance.initialize();
      }

      final ad = NativeAd(
        adUnitId: AdService.instance.nativeAdUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (mounted) state = ad as NativeAd;
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
        ),
      );
      ad.load();
    } catch (_) {}
  }

  @override
  void dispose() {
    state?.dispose();
    super.dispose();
  }
}
