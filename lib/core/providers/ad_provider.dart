import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ad_service.dart';
import 'feature_flag_provider.dart';
import 'subscription_provider.dart';

/// Provider for AdService singleton
final adServiceProvider = Provider<AdService>((ref) {
  return AdService.instance;
});

/// Determines if ads should be shown to the current user.
/// Returns false for premium users or when the ads flag is disabled.
final shouldShowAdsProvider = FutureProvider<bool>((ref) async {
  try {
    final isPremium = await ref.watch(isPremiumProvider.future);
    if (isPremium) return false;
    final flags = await ref.watch(appFeatureFlagsProvider.future);
    return featureEnabled(flags, 'ads');
  } catch (e) {
    return true;
  }
});
