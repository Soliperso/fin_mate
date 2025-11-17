import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';

// ============================================================================
// Subscription Tier Provider
// ============================================================================

/// FutureProvider that fetches the current user's subscription tier
final subscriptionTierProvider = FutureProvider<String?>((ref) async {
  try {
    final auth = Supabase.instance.client.auth;
    final userId = auth.currentUser?.id;

    if (userId == null) {
      return null;
    }

    final response = await supabase
        .from('user_profiles')
        .select('subscription_tier')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return 'freemium'; // Default to freemium
    }

    return response['subscription_tier'] as String? ?? 'freemium';
  } catch (e) {
    // Default to freemium on error
    return 'freemium';
  }
});

// ============================================================================
// Premium Status Provider
// ============================================================================

/// Computed provider that returns true if user has premium subscription
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final tier = await ref.watch(subscriptionTierProvider.future);
  return tier == 'premium';
});

// ============================================================================
// Subscription Check Helper
// ============================================================================

/// Helper provider to get detailed subscription information
final userSubscriptionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final auth = Supabase.instance.client.auth;
    final userId = auth.currentUser?.id;

    if (userId == null) {
      return null;
    }

    final response = await supabase
        .from('user_profiles')
        .select('id, subscription_tier, created_at')
        .eq('id', userId)
        .maybeSingle();

    return response;
  } catch (e) {
    // Error fetching subscription info
    return null;
  }
});
