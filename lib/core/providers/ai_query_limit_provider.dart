import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../config/payment_config.dart';
import 'subscription_provider.dart';

/// Provider to track AI query usage for the current month
final aiQueryUsageProvider = FutureProvider<AIQueryUsage>((ref) async {
  final user = ref.watch(authNotifierProvider).user;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final supabase = Supabase.instance.client;

  // Get current month's start and end dates
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  try {
    // Query ai_usage_tracking table for current month
    final response = await supabase
        .from('ai_usage_tracking')
        .select('query_count')
        .eq('user_id', user.id)
        .gte('month_start', monthStart.toIso8601String())
        .lte('month_start', monthEnd.toIso8601String())
        .maybeSingle();

    final queryCount = response?['query_count'] as int? ?? 0;

    return AIQueryUsage(
      queriesUsed: queryCount,
      monthStart: monthStart,
      monthEnd: monthEnd,
    );
  } catch (e) {
    // If no record exists yet, return 0 queries used
    return AIQueryUsage(
      queriesUsed: 0,
      monthStart: monthStart,
      monthEnd: monthEnd,
    );
  }
});

/// Provider to check if user can make another AI query
final canMakeQueryProvider = FutureProvider<bool>((ref) async {
  // Check if user is premium
  final isPremium = await ref.watch(isPremiumProvider.future);
  if (isPremium) {
    return true; // Premium users have unlimited queries
  }

  // Check freemium query limit
  final usage = await ref.watch(aiQueryUsageProvider.future);
  return usage.queriesUsed < PaymentConfig.freemiumAIQueriesPerMonth;
});

/// Provider for AI query operations
final aiQueryOperationsProvider =
    Provider<AIQueryOperations>((ref) => AIQueryOperations(ref));

/// Operations for managing AI query usage
class AIQueryOperations {
  final Ref _ref;

  AIQueryOperations(this._ref);

  /// Increment the query count for current month
  Future<void> incrementQueryCount() async {
    final user = _ref.read(authNotifierProvider).user;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Don't count queries for premium users
    final isPremium = await _ref.read(isPremiumProvider.future);
    if (isPremium) {
      return;
    }

    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    try {
      // Try to get existing record for current month
      final existing = await supabase
          .from('ai_usage_tracking')
          .select('id, query_count')
          .eq('user_id', user.id)
          .eq('month_start', monthStart.toIso8601String())
          .maybeSingle();

      if (existing != null) {
        // Update existing record
        final currentCount = existing['query_count'] as int;
        await supabase
            .from('ai_usage_tracking')
            .update({'query_count': currentCount + 1}).eq('id', existing['id']);
      } else {
        // Create new record for this month
        await supabase.from('ai_usage_tracking').insert({
          'user_id': user.id,
          'month_start': monthStart.toIso8601String(),
          'query_count': 1,
        });
      }

      // Invalidate the usage provider to refresh the count
      _ref.invalidate(aiQueryUsageProvider);
    } catch (e) {
      throw Exception('Failed to increment query count: $e');
    }
  }

  /// Get days until query limit resets
  int getDaysUntilReset() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return nextMonth.difference(now).inDays + 1;
  }
}

/// Model for AI query usage data
class AIQueryUsage {
  final int queriesUsed;
  final DateTime monthStart;
  final DateTime monthEnd;

  AIQueryUsage({
    required this.queriesUsed,
    required this.monthStart,
    required this.monthEnd,
  });

  /// Check if user has reached the query limit
  bool get hasReachedLimit =>
      queriesUsed >= PaymentConfig.freemiumAIQueriesPerMonth;

  /// Get remaining queries
  int get queriesRemaining {
    final remaining = PaymentConfig.freemiumAIQueriesPerMonth - queriesUsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Get usage percentage (0.0 to 1.0)
  double get usagePercentage {
    return queriesUsed / PaymentConfig.freemiumAIQueriesPerMonth;
  }
}
