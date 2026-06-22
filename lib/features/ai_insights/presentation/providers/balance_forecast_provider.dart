import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/balance_forecast_service.dart';
import '../../domain/entities/balance_forecast.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// Service provider
final balanceForecastServiceProvider = Provider<BalanceForecastService>((ref) {
  ref.watch(userSessionProvider);
  return BalanceForecastService();
});

// Balance forecast provider — autoDispose so navigating to the forecast page
// always recomputes from the latest accounts / transactions / recurring data.
final balanceForecastProvider =
    FutureProvider.autoDispose<BalanceForecast>((ref) async {
  final service = ref.watch(balanceForecastServiceProvider);
  return await service.generate30DayForecast();
});

// Current balance provider (extracted from forecast)
final currentBalanceProvider = Provider.autoDispose<double>((ref) {
  final forecastAsync = ref.watch(balanceForecastProvider);
  return forecastAsync.when(
    data: (forecast) => forecast.currentBalance,
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});

// Safe to spend provider (extracted from forecast)
final safeToSpendProvider = Provider.autoDispose<double>((ref) {
  final forecastAsync = ref.watch(balanceForecastProvider);
  return forecastAsync.when(
    data: (forecast) => forecast.safeToSpend,
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});

// Multi-scenario forecast provider
final multiScenarioForecastProvider =
    FutureProvider.autoDispose<List<ForecastScenario>>((ref) async {
  final service = ref.watch(balanceForecastServiceProvider);
  return await service.generateMultiScenarioForecast();
});

// Currently selected scenario type (UI state)
final selectedForecastScenarioProvider =
    StateProvider<ForecastScenarioType>((ref) => ForecastScenarioType.baseline);

// Derived provider: currently active scenario's BalanceForecast
final activeForecastProvider =
    Provider.autoDispose<AsyncValue<BalanceForecast>>((ref) {
  final scenariosAsync = ref.watch(multiScenarioForecastProvider);
  final selectedType = ref.watch(selectedForecastScenarioProvider);

  return scenariosAsync.whenData(
    (scenarios) => scenarios.firstWhere((s) => s.type == selectedType).forecast,
  );
});
