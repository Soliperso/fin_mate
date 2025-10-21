import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/insights_service.dart';
import '../../domain/entities/recurring_expense_pattern.dart';
import '../../domain/entities/spending_anomaly.dart';
import '../../domain/entities/merchant_insight.dart';

// Service provider
final insightsServiceProvider = Provider<InsightsService>((ref) {
  return InsightsService();
});

// Spending patterns provider
final spendingPatternsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.analyzeSpendingPatterns();
});

// Category breakdown provider
final categoryBreakdownProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getCategoryBreakdown(days: days);
});

// Cashflow forecast provider
final cashflowForecastProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, months) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.generateCashflowForecast(months: months);
});

// Spending insights provider
final spendingInsightsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getSpendingInsights();
});

// Default category breakdown (30 days)
final defaultCategoryBreakdownProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getCategoryBreakdown(days: 30);
});

// Default forecast (3 months)
final defaultForecastProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.generateCashflowForecast(months: 3);
});

// Proactive alerts provider
final proactiveAlertsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getProactiveAlerts();
});

// Subscription changes provider
final subscriptionChangesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.detectSubscriptionChanges();
});

// Pattern Recognition Providers (Phase 1)

/// Recurring expenses provider
final recurringExpensesProvider = FutureProvider<List<RecurringExpensePattern>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.detectRecurringExpenses(daysToAnalyze: 180);
});

/// Spending anomalies provider
final spendingAnomaliesProvider = FutureProvider<List<SpendingAnomaly>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.detectSpendingAnomalies(daysToAnalyze: 90);
});

/// Merchant frequency insights provider
final merchantInsightsProvider = FutureProvider<List<MerchantInsight>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.analyzeMerchantFrequency(daysToAnalyze: 90);
});

/// Weekend vs weekday spending provider
final weekendVsWeekdayProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(insightsServiceProvider);
  return await service.getWeekendVsWeekdaySpending(daysToAnalyze: 90);
});
