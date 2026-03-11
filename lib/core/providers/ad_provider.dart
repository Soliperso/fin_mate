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
