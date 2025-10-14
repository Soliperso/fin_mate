import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/insights_service.dart';

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
