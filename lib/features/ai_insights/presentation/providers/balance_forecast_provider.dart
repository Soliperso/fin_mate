import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/balance_forecast_service.dart';
import '../../domain/entities/balance_forecast.dart';

// Service provider
final balanceForecastServiceProvider = Provider<BalanceForecastService>((ref) {
  return BalanceForecastService();
});

// Balance forecast provider
final balanceForecastProvider = FutureProvider<BalanceForecast>((ref) async {
  final service = ref.watch(balanceForecastServiceProvider);
  return await service.generate30DayForecast();
});

// Current balance provider (extracted from forecast)
final currentBalanceProvider = Provider<double>((ref) {
  final forecastAsync = ref.watch(balanceForecastProvider);
  return forecastAsync.when(
    data: (forecast) => forecast.currentBalance,
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});

// Safe to spend provider (extracted from forecast)
final safeToSpendProvider = Provider<double>((ref) {
  final forecastAsync = ref.watch(balanceForecastProvider);
  return forecastAsync.when(
    data: (forecast) => forecast.safeToSpend,
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});
