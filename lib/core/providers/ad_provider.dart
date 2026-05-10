import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ad_service.dart';
import 'subscription_provider.dart';

/// Provider for AdService singleton
final adServiceProvider = Provider<AdService>((ref) {
  return AdService.instance;
});

/// Determines if ads should be shown to the current user.
/// Returns true for freemium users, false for premium users.
final shouldShowAdsProvider = FutureProvider<bool>((ref) async {
  try {
    final isPremium = await ref.watch(isPremiumProvider.future);
    return !isPremium;
  } catch (e) {
    return true;
  }
});
