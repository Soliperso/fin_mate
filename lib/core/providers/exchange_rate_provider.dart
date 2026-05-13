import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/exchange_rate_service.dart';
import 'display_format_provider.dart';

final exchangeRateServiceProvider =
    Provider<ExchangeRateService>((_) => ExchangeRateService());

/// Rates map: currencyCode → units-per-USD.
/// e.g. {'EUR': 0.882} means 1 USD = 0.882 EUR.
/// Fetches from Frankfurter API, cached for 4 hours, falls back to
/// hardcoded values on network failure.
final exchangeRatesProvider =
    FutureProvider<Map<String, double>>((ref) {
  return ref.read(exchangeRateServiceProvider).fetchRates();
});

/// Returns units-per-USD for [code]. USD itself returns 1.0.
double _rateFromUsd(String code, Map<String, double> rates) {
  if (code == 'USD') return 1.0;
  return rates[code] ?? 1.0;
}

/// Multiplier to convert a stored (home-currency) amount to the display currency.
/// Returns 1.0 when display == home, or while rates are loading.
final conversionFactorProvider = Provider<double>((ref) {
  final fmt = ref.watch(displayFormatProvider);
  final displayCode = fmt.currencyCode;
  final homeCode = fmt.homeCurrencyCode;
  if (displayCode == homeCode) return 1.0;
  return ref.watch(exchangeRatesProvider).maybeWhen(
    data: (rates) {
      final displayRate = _rateFromUsd(displayCode, rates);
      final homeRate = _rateFromUsd(homeCode, rates);
      if (homeRate == 0) return 1.0;
      return displayRate / homeRate;
    },
    orElse: () => 1.0,
  );
});

/// Returns a formatted USD-equivalent string for [amount] (in home currency),
/// e.g. "(≈ $113.64)".
/// Returns null when:
///  - the display currency is already USD
///  - rates are still loading
///  - the home currency code is not in the rates map
final usdEquivalentProvider =
    Provider.family<String?, double>((ref, amount) {
  final fmt = ref.watch(displayFormatProvider);
  if (fmt.currencyCode == 'USD') return null;

  return ref.watch(exchangeRatesProvider).whenOrNull(
    data: (rates) {
      final homeRate = _rateFromUsd(fmt.homeCurrencyCode, rates);
      if (homeRate == 0) return null;
      final usd = amount / homeRate;
      return '(≈ ${_formatUsd(usd)})';
    },
  );
});

String _formatUsd(double usd) {
  final abs = usd.abs();
  final sign = usd < 0 ? '-' : '';
  final formatted = abs >= 1
      ? NumberFormat('#,##0.##', 'en_US').format(abs)
      : NumberFormat('#,##0.####', 'en_US').format(abs);
  return '$sign\$$formatted';
}
