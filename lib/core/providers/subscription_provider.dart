import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';

// ============================================================================
// Subscription Tier Provider (Supabase source of truth)
// ============================================================================

/// Fetches the current user's subscription tier from Supabase user_profiles.
/// Falls back to 'freemium' on any error.
final subscriptionTierProvider = FutureProvider<String?>((ref) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await supabase
        .from('user_profiles')
        .select('subscription_tier')
        .eq('id', userId)
        .maybeSingle();

    return response?['subscription_tier'] as String? ?? 'freemium';
  } catch (_) {
    return 'freemium';
  }
});

// ============================================================================
// Premium Status Provider
// ============================================================================

/// Returns true when the user has an active premium subscription.
/// Source of truth: Supabase user_profiles.subscription_tier.
// [MVP: RevenueCat - Commented out; re-enable alongside Purchases.configure() in main.dart]
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final tier = await ref.read(subscriptionTierProvider.future);
  return tier == 'premium';
});

// ============================================================================
// Detailed Subscription Info Provider
// ============================================================================

/// Returns full subscription details from Supabase for display in profile/settings.
final userSubscriptionProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    return await supabase
        .from('user_profiles')
        .select(
            'id, subscription_tier, subscription_status, subscription_end_date, trial_end_date, created_at')
        .eq('id', userId)
        .maybeSingle();
  } catch (_) {
    return null;
  }
});
