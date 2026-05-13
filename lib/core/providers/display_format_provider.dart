import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── SharedPreferences keys ──────────────────────────────────────────────────
const _keyCurrency = 'pref_currency';
const _keyHomeCurrency = 'pref_home_currency';
const _keyDateFormat = 'pref_date_format';
const _keyNumberFormat = 'pref_number_format';

// ─── Lookup maps ─────────────────────────────────────────────────────────────
const currencySymbols = {
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
  'CAD': 'CA\$',
  'AUD': 'A\$',
  'CHF': 'Fr',
  'CNY': '¥',
  'INR': '₹',
  'MXN': 'MX\$',
  'BRL': 'R\$',
  'KRW': '₩',
  'SGD': 'S\$',
  'HKD': 'HK\$',
  'SEK': 'kr',
  'NOK': 'kr',
  'DKK': 'kr',
  'NZD': 'NZ\$',
  'ZAR': 'R',
  'AED': 'د.إ',
  'SAR': '﷼',
  'TRY': '₺',
  'PLN': 'zł',
  'THB': '฿',
  'IDR': 'Rp',
  'MYR': 'RM',
  'PHP': '₱',
};

const numberLocales = {
  '1,234.56': 'en_US',
  '1.234,56': 'de_DE',
  '1 234.56': 'fr_FR',
};

const datePatterns = {
  'MM/DD/YYYY': 'MM/dd/yyyy',
  'DD/MM/YYYY': 'dd/MM/yyyy',
  'YYYY-MM-DD': 'yyyy-MM-dd',
};

// ─── State ───────────────────────────────────────────────────────────────────
class DisplayFormatState {
  final String currencyCode;
  /// The currency amounts are stored in (set once on first run, never auto-changed).
  final String homeCurrencyCode;
  final String dateFormat;
  final String numberFormat;

  const DisplayFormatState({
    this.currencyCode = 'USD',
    this.homeCurrencyCode = 'USD',
    this.dateFormat = 'MM/DD/YYYY',
    this.numberFormat = '1,234.56',
  });

  String get currencySymbol => currencySymbols[currencyCode] ?? '\$';
  String get numberLocale => numberLocales[numberFormat] ?? 'en_US';
  String get datePattern => datePatterns[dateFormat] ?? 'MM/dd/yyyy';

  DisplayFormatState copyWith({
    String? currencyCode,
    String? homeCurrencyCode,
    String? dateFormat,
    String? numberFormat,
  }) {
    return DisplayFormatState(
      currencyCode: currencyCode ?? this.currencyCode,
      homeCurrencyCode: homeCurrencyCode ?? this.homeCurrencyCode,
      dateFormat: dateFormat ?? this.dateFormat,
      numberFormat: numberFormat ?? this.numberFormat,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class DisplayFormatNotifier extends StateNotifier<DisplayFormatState> {
  DisplayFormatNotifier(super.initial);

  Future<void> setCurrency(String code) async {
    if (!currencySymbols.containsKey(code)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, code);
    state = state.copyWith(currencyCode: code);
    setCachedDisplayFormat(state);
  }

  Future<void> setDateFormat(String format) async {
    if (!datePatterns.containsKey(format)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDateFormat, format);
    state = state.copyWith(dateFormat: format);
    setCachedDisplayFormat(state);
  }

  Future<void> setNumberFormat(String format) async {
    if (!numberLocales.containsKey(format)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNumberFormat, format);
    state = state.copyWith(numberFormat: format);
    setCachedDisplayFormat(state);
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

/// Injected from main() with values read from SharedPreferences before runApp,
/// so the correct format is applied on the very first frame.
final initialDisplayFormatProvider =
    Provider<DisplayFormatState>((_) => const DisplayFormatState());

final displayFormatProvider =
    StateNotifierProvider<DisplayFormatNotifier, DisplayFormatState>((ref) {
  return DisplayFormatNotifier(ref.watch(initialDisplayFormatProvider));
});

/// Convenience: currency symbol for the current selection.
final currencySymbolProvider = Provider<String>((ref) {
  return ref.watch(displayFormatProvider).currencySymbol;
});

/// Convenience: a ready-to-use NumberFormat for currency with 2 decimal places.
final currencyFormat2Provider = Provider<NumberFormat>((ref) {
  final fmt = ref.watch(displayFormatProvider);
  return NumberFormat.currency(
    symbol: fmt.currencySymbol,
    locale: fmt.numberLocale,
    decimalDigits: 2,
  );
});

/// Convenience: a ready-to-use NumberFormat for currency with 0 decimal places.
final currencyFormat0Provider = Provider<NumberFormat>((ref) {
  final fmt = ref.watch(displayFormatProvider);
  return NumberFormat.currency(
    symbol: fmt.currencySymbol,
    locale: fmt.numberLocale,
    decimalDigits: 0,
  );
});

/// Convenience: compact currency (e.g. $1.2K).
final currencyFormatCompactProvider = Provider<NumberFormat>((ref) {
  final fmt = ref.watch(displayFormatProvider);
  return NumberFormat.compactCurrency(
    symbol: fmt.currencySymbol,
    locale: fmt.numberLocale,
    decimalDigits: 0,
  );
});

/// Convenience: DateFormat built from the user's selected date pattern.
final userDateFormatProvider = Provider<DateFormat>((ref) {
  final pattern = ref.watch(displayFormatProvider).datePattern;
  return DateFormat(pattern);
});

// ─── Singleton for service-layer access ──────────────────────────────────────
DisplayFormatState? _cachedDisplayFormat;

void setCachedDisplayFormat(DisplayFormatState state) {
  _cachedDisplayFormat = state;
}

/// Get the current display format state (for use in service classes that can't access Riverpod).
/// This is initialized in main() before runApp.
DisplayFormatState getCachedDisplayFormat() {
  return _cachedDisplayFormat ?? const DisplayFormatState();
}

/// Helper to load initial display format from SharedPreferences.
/// Call this in main() before runApp, and always call setCachedDisplayFormat with the result.
Future<DisplayFormatState> loadInitialDisplayFormat() async {
  final prefs = await SharedPreferences.getInstance();
  final currencyCode = prefs.getString(_keyCurrency) ?? 'USD';
  // Seed home currency on first run so it is locked in and never changes automatically.
  if (!prefs.containsKey(_keyHomeCurrency)) {
    await prefs.setString(_keyHomeCurrency, currencyCode);
  }
  final homeCurrencyCode = prefs.getString(_keyHomeCurrency) ?? currencyCode;
  final state = DisplayFormatState(
    currencyCode: currencyCode,
    homeCurrencyCode: homeCurrencyCode,
    dateFormat: prefs.getString(_keyDateFormat) ?? 'MM/DD/YYYY',
    numberFormat: prefs.getString(_keyNumberFormat) ?? '1,234.56',
  );
  setCachedDisplayFormat(state);
  return state;
}
