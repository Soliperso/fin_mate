import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const _kRatesKey = 'pref_exchange_rates_json';
  static const _kTimestampKey = 'pref_exchange_rates_ts';
  static const _ttl = Duration(hours: 4);
  static const _apiUrl =
      'https://api.frankfurter.app/latest?from=USD';

  // Approximate fallback used when network and cache are both unavailable.
  static const Map<String, double> _fallbackRates = {
    'EUR': 0.882,
    'GBP': 0.751,
    'JPY': 147.20,
    'CAD': 1.356,
    'AUD': 1.538,
    'CHF': 0.870,
    'CNY': 7.245,
    'INR': 83.40,
    'MXN': 19.23,
    'BRL': 5.56,
    'KRW': 1370.0,
    'SGD': 1.333,
    'HKD': 7.813,
    'SEK': 10.10,
    'NOK': 10.53,
    'DKK': 6.67,
    'NZD': 1.667,
    'ZAR': 18.18,
    'AED': 3.673,
    'SAR': 3.750,
    'TRY': 34.48,
    'PLN': 3.846,
    'THB': 35.71,
    'IDR': 16129.0,
    'MYR': 4.545,
    'PHP': 55.56,
  };

  /// Returns a map of currencyCode → units-per-USD.
  /// e.g. {'EUR': 0.882} means 1 USD = 0.882 EUR.
  Future<Map<String, double>> fetchRates() async {
    final prefs = await SharedPreferences.getInstance();

    // Return cached data if still fresh.
    final cached = await _loadCached(prefs);
    if (cached != null) return cached;

    // Fetch from Frankfurter.
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = body['rates'] as Map<String, dynamic>;
        final rates = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));

        // Persist to cache.
        await prefs.setString(_kRatesKey, jsonEncode(rates));
        await prefs.setInt(
            _kTimestampKey, DateTime.now().millisecondsSinceEpoch);

        return rates;
      }
    } catch (_) {
      // Network error — fall through to stale cache or fallback.
    }

    // Use stale cache if present, else hardcoded fallback.
    final stale = _readRawCache(prefs);
    return stale ?? _fallbackRates;
  }

  Future<Map<String, double>?> _loadCached(SharedPreferences prefs) async {
    final ts = prefs.getInt(_kTimestampKey);
    if (ts == null) return null;
    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (age > _ttl) return null;
    return _readRawCache(prefs);
  }

  Map<String, double>? _readRawCache(SharedPreferences prefs) {
    final json = prefs.getString(_kRatesKey);
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return null;
    }
  }
}
