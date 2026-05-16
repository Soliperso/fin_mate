/// Centralized date format pattern strings.
/// Use these constants with DateFormat(AppDateFormats.X, locale) instead of
/// scattering literal format strings across the codebase.
class AppDateFormats {
  AppDateFormats._();

  /// e.g. "Aug 5"
  static const shortDate = 'MMM d';

  /// e.g. "Aug 5, 2025"
  static const mediumDate = 'MMM d, yyyy';

  /// e.g. "August 5, 2025"
  static const fullDate = 'MMMM d, yyyy';

  /// e.g. "August 5"
  static const fullMonthDay = 'MMMM d';

  /// e.g. "Aug 2025"
  static const monthYear = 'MMM yyyy';

  /// e.g. "August 2025"
  static const fullMonthYear = 'MMMM yyyy';

  /// e.g. "Aug"  (charts x-axis label)
  static const monthOnly = 'MMM';

  /// e.g. "Aug 25"  (short year, charts)
  static const monthShortYear = 'MMM yy';

  /// e.g. "2:30 PM"
  static const timeOnly = 'h:mm a';

  /// e.g. "Aug 5, 2025 · 2:30 PM"
  static const dateTime = "MMM d, yyyy · h:mm a";

  /// ISO-style timestamp for file names and exports — e.g. "20250805_143000"
  static const exportTimestamp = 'yyyyMMdd_HHmmss';
}
