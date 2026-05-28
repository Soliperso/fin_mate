import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/secure_storage_provider.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/services/insights_service.dart';
import '../../domain/entities/recurring_expense_pattern.dart';
import '../../domain/entities/spending_anomaly.dart';
import '../../domain/entities/merchant_insight.dart';
import '../../domain/entities/proactive_alert.dart';
import 'chat_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../savings_goals/presentation/providers/savings_goal_providers.dart';

// Service provider
final insightsServiceProvider = Provider<InsightsService>((ref) {
  ref.watch(userSessionProvider);
  return InsightsService();
});

// Spending patterns provider
final spendingPatternsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.analyzeSpendingPatterns();
});

// Category breakdown provider
final categoryBreakdownProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getCategoryBreakdown(days: days);
});

// Cashflow forecast provider
final cashflowForecastProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, months) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.generateCashflowForecast(months: months);
});

// Spending insights provider
final spendingInsightsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getSpendingInsights();
});

// Default category breakdown (30 days)
final defaultCategoryBreakdownProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getCategoryBreakdown(days: 30);
});

// Default forecast (3 months)
final defaultForecastProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.generateCashflowForecast(months: 3);
});

// Proactive alerts provider
final proactiveAlertsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getProactiveAlerts();
});

// Subscription changes provider
final subscriptionChangesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.detectSubscriptionChanges();
});

// Pattern Recognition Providers (Phase 1)

/// Recurring expenses provider
final recurringExpensesProvider =
    FutureProvider<List<RecurringExpensePattern>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.detectRecurringExpenses(daysToAnalyze: 180);
});

/// Spending anomalies provider
final spendingAnomaliesProvider =
    FutureProvider<List<SpendingAnomaly>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.detectSpendingAnomalies(daysToAnalyze: 90);
});

/// Merchant frequency insights provider
final merchantInsightsProvider =
    FutureProvider<List<MerchantInsight>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.analyzeMerchantFrequency(daysToAnalyze: 90);
});

/// Weekend vs weekday spending provider
final weekendVsWeekdayProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getWeekendVsWeekdaySpending(daysToAnalyze: 90);
});

// Phase 3: Proactive Alerts

/// Typed proactive alerts provider
final typedProactiveAlertsProvider =
    FutureProvider<List<ProactiveAlert>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getTypedProactiveAlerts();
});

// ── Dismissed alerts — persisted across sessions ──────────────────────────────

class DismissedAlertsNotifier extends StateNotifier<Set<String>> {
  final SecureStorageService _storage;
  final String _userId;

  DismissedAlertsNotifier(this._storage, this._userId) : super({}) {
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.getDismissedAlertIds(_userId);
    if (mounted) state = saved;
  }

  void dismiss(String alertId) {
    state = {...state, alertId};
    _storage.saveDismissedAlertIds(_userId, state);
  }
}

final dismissedAlertIdsProvider =
    StateNotifierProvider<DismissedAlertsNotifier, Set<String>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final storage = ref.read(secureStorageServiceProvider);
  return DismissedAlertsNotifier(storage, userId);
});

// ── Savings goal alerts ───────────────────────────────────────────────────────

final goalAlertsProvider = FutureProvider<List<ProactiveAlert>>((ref) async {
  final goals = await ref.watch(savingsGoalsProvider.future);
  final alerts = <ProactiveAlert>[];
  final now = DateTime.now();

  for (final goal in goals) {
    if (goal.isCompleted) continue;

    // Milestone alerts (25 / 50 / 75 %)
    for (final milestone in [25, 50, 75]) {
      if (goal.progress >= milestone) {
        alerts.add(ProactiveAlert(
          id: 'goal_milestone_${goal.id}_$milestone',
          type: AlertType.unknown,
          severity: AlertSeverity.low,
          title: '${goal.name} is $milestone% funded!',
          message:
              'Great progress — you\'ve saved \$${goal.currentAmount.toStringAsFixed(0)} of \$${goal.targetAmount.toStringAsFixed(0)}.',
          createdAt: now,
        ));
      }
    }

    // Behind pace alert
    final needed = goal.monthlySavingsNeeded;
    if (needed != null && needed > 0 && goal.daysRemaining != null && goal.daysRemaining! > 0) {
      final monthsElapsed = now.difference(goal.createdAt).inDays / 30.0;
      if (monthsElapsed > 1) {
        final actualMonthlyRate = goal.currentAmount / monthsElapsed;
        if (actualMonthlyRate < needed * 0.8) {
          alerts.add(ProactiveAlert(
            id: 'goal_behind_${goal.id}',
            type: AlertType.cashFlowWarning,
            severity: AlertSeverity.medium,
            title: '${goal.name} is falling behind',
            message:
                'You need \$${needed.toStringAsFixed(0)}/mo but are averaging \$${actualMonthlyRate.toStringAsFixed(0)}/mo.',
            createdAt: now,
          ));
        }
      }
    }

    // Deadline approaching (≤ 30 days)
    final days = goal.daysRemaining;
    if (days != null && days > 0 && days <= 30) {
      alerts.add(ProactiveAlert(
        id: 'goal_deadline_${goal.id}',
        type: AlertType.cashFlowWarning,
        severity: days <= 7 ? AlertSeverity.high : AlertSeverity.medium,
        title: '${goal.name} deadline in $days days',
        message:
            'You still need \$${goal.remainingAmount.toStringAsFixed(0)} to reach your target.',
        createdAt: now,
      ));
    }
  }

  return alerts;
});

// ── Income alerts ─────────────────────────────────────────────────────────────

final incomeAlertsProvider = FutureProvider<List<ProactiveAlert>>((ref) async {
  final service = ref.read(insightsServiceProvider);
  return service.detectIncomeAlerts();
});

/// Dynamic context-aware suggested prompts
final dynamicPromptsProvider = FutureProvider<List<String>>((ref) async {
  final queryProcessor = ref.watch(queryProcessorProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return queryProcessor.getSuggestedPrompts();
  return await queryProcessor.getDynamicSuggestedPrompts(userId);
});
