import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/payment_config.dart';
import '../config/supabase_client.dart';
import 'subscription_provider.dart';

// ============================================================================
// Usage Provider — backed by Supabase user_profiles.free_uses_count
// ============================================================================

/// Reads the current lifetime premium-feature use count from Supabase.
/// Falls back to 0 on any error so the user is never erroneously blocked.
final aiQueryUsageProvider = FutureProvider<AIQueryUsage>((ref) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const AIQueryUsage(queriesUsed: 0);

    final response = await supabase
        .from('user_profiles')
        .select('free_uses_count')
        .eq('id', userId)
        .maybeSingle();

    final count = (response?['free_uses_count'] as int?) ?? 0;
    return AIQueryUsage(queriesUsed: count);
  } catch (_) {
    return const AIQueryUsage(queriesUsed: 0);
  }
});

// ============================================================================
// Gate Provider
// ============================================================================

/// Returns true if the user can use another premium feature.
/// Premium users always return true. Free users are limited to 10 lifetime uses.
final canMakeQueryProvider = FutureProvider<bool>((ref) async {
  final isPremium = await ref.watch(isPremiumProvider.future);
  if (isPremium) return true;

  final usage = await ref.watch(aiQueryUsageProvider.future);
  return !usage.hasReachedLimit;
});

// ============================================================================
// Operations Provider
// ============================================================================

/// Provider for mutating premium feature usage.
final aiQueryOperationsProvider =
    Provider<AIQueryOperations>((ref) => AIQueryOperations(ref));

class AIQueryOperations {
  final Ref _ref;
  AIQueryOperations(this._ref);

  /// Atomically increments the Supabase counter via RPC.
  /// No-op for premium users.
  Future<void> incrementQueryCount() async {
    final isPremium = await _ref.read(isPremiumProvider.future);
    if (isPremium) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.rpc(
        'increment_free_uses',
        params: {'p_user_id': userId},
      );
    } catch (_) {
      // Non-fatal: if the RPC fails the gate will re-read on next open
    }

    _ref.invalidate(aiQueryUsageProvider);
  }

  /// Resets the local provider cache (e.g. after a successful purchase).
  /// The Supabase counter is kept for audit purposes; premium check bypasses it.
  void resetQueryCount() {
    _ref.invalidate(aiQueryUsageProvider);
  }
}

// ============================================================================
// Model
// ============================================================================

class AIQueryUsage {
  final int queriesUsed;

  const AIQueryUsage({required this.queriesUsed});

  bool get hasReachedLimit =>
      queriesUsed >= PaymentConfig.freemiumAIQueriesPerMonth;

  int get queriesRemaining {
    final remaining = PaymentConfig.freemiumAIQueriesPerMonth - queriesUsed;
    return remaining > 0 ? remaining : 0;
  }

  double get usagePercentage =>
      (queriesUsed / PaymentConfig.freemiumAIQueriesPerMonth).clamp(0.0, 1.0);
}
