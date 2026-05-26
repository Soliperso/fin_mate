import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/payment_config.dart';
import 'subscription_provider.dart';

/// SharedPreferences key for the lifetime per-install AI chat query count.
const _kAiQueryCountKey = 'ai_chat_query_count';

// ============================================================================
// Usage Provider
// ============================================================================

/// Reads the current lifetime AI chat query count from SharedPreferences.
/// Resets only on app reinstall — not monthly.
final aiQueryUsageProvider = FutureProvider<AIQueryUsage>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final count = prefs.getInt(_kAiQueryCountKey) ?? 0;
  return AIQueryUsage(queriesUsed: count);
});

// ============================================================================
// Gate Provider
// ============================================================================

/// Returns true if the user can send another AI chat message.
/// Premium users always return true. Free users are limited to 10 lifetime queries.
final canMakeQueryProvider = FutureProvider<bool>((ref) async {
  final isPremium = await ref.watch(isPremiumProvider.future);
  if (isPremium) return true;

  final usage = await ref.watch(aiQueryUsageProvider.future);
  return !usage.hasReachedLimit;
});

// ============================================================================
// Operations Provider
// ============================================================================

/// Provider for mutating AI query usage.
final aiQueryOperationsProvider =
    Provider<AIQueryOperations>((ref) => AIQueryOperations(ref));

class AIQueryOperations {
  final Ref _ref;
  AIQueryOperations(this._ref);

  /// Increments the per-install query count in SharedPreferences.
  /// No-op for premium users.
  Future<void> incrementQueryCount() async {
    final isPremium = await _ref.read(isPremiumProvider.future);
    if (isPremium) return;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kAiQueryCountKey) ?? 0;
    await prefs.setInt(_kAiQueryCountKey, current + 1);

    // Invalidate so the banner and gate refresh immediately
    _ref.invalidate(aiQueryUsageProvider);
  }

  /// Resets the local query counter. Used after a successful purchase
  /// so the new premium user gets a clean slate on downgrade (if ever).
  Future<void> resetQueryCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAiQueryCountKey);
    _ref.invalidate(aiQueryUsageProvider);
  }
}

// ============================================================================
// Model
// ============================================================================

class AIQueryUsage {
  final int queriesUsed;

  const AIQueryUsage({required this.queriesUsed});

  /// True when the user has hit the 10-query lifetime free limit.
  bool get hasReachedLimit =>
      queriesUsed >= PaymentConfig.freemiumAIQueriesPerMonth;

  /// Queries remaining before the paywall kicks in (min 0).
  int get queriesRemaining {
    final remaining = PaymentConfig.freemiumAIQueriesPerMonth - queriesUsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Progress value for the usage bar, clamped 0.0–1.0.
  double get usagePercentage =>
      (queriesUsed / PaymentConfig.freemiumAIQueriesPerMonth).clamp(0.0, 1.0);
}
