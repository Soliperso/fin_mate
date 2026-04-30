import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for Finmate
///
/// Values are resolved in priority order:
///   1. Compile-time constants via `--dart-define` (used in production CI/CD builds)
///   2. `.env` asset file via flutter_dotenv (used in local development)
///
/// Production build example:
///   flutter build appbundle \
///     --dart-define=SUPABASE_URL=https://... \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=OPENAI_API_KEY=sk-... \
///     --dart-define=SENTRY_DSN=https://... \
///     --dart-define=ENVIRONMENT=production
class EnvConfig {
  // Compile-time constants (set via --dart-define in production builds)
  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const _stripePublishableKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  static const _stripeMonthlyPriceId =
      String.fromEnvironment('STRIPE_MONTHLY_PRICE_ID');
  static const _stripeAnnualPriceId =
      String.fromEnvironment('STRIPE_ANNUAL_PRICE_ID');
  static const _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _environment = String.fromEnvironment('ENVIRONMENT');

  // AdMob (compile-time constants)
  static const _admobAppIdAndroid =
      String.fromEnvironment('ADMOB_APP_ID_ANDROID');
  static const _admobAppIdIos = String.fromEnvironment('ADMOB_APP_ID_IOS');
  static const _admobBannerAndroid =
      String.fromEnvironment('ADMOB_BANNER_ANDROID');
  static const _admobBannerIos = String.fromEnvironment('ADMOB_BANNER_IOS');
  static const _admobInterstitialAndroid =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID');
  static const _admobInterstitialIos =
      String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');
  static const _admobNativeAndroid =
      String.fromEnvironment('ADMOB_NATIVE_ANDROID');
  static const _admobNativeIos = String.fromEnvironment('ADMOB_NATIVE_IOS');

  // Supabase Configuration
  static String get supabaseUrl =>
      _supabaseUrl.isNotEmpty
          ? _supabaseUrl
          : dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey =>
      _supabaseAnonKey.isNotEmpty
          ? _supabaseAnonKey
          : dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Sentry
  static String get sentryDsn =>
      _sentryDsn.isNotEmpty ? _sentryDsn : dotenv.env['SENTRY_DSN'] ?? '';

  // Stripe
  static String get stripePublishableKey =>
      _stripePublishableKey.isNotEmpty
          ? _stripePublishableKey
          : dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  static String get stripeMonthlyPriceId =>
      _stripeMonthlyPriceId.isNotEmpty
          ? _stripeMonthlyPriceId
          : dotenv.env['STRIPE_MONTHLY_PRICE_ID'] ?? '';

  static String get stripeAnnualPriceId =>
      _stripeAnnualPriceId.isNotEmpty
          ? _stripeAnnualPriceId
          : dotenv.env['STRIPE_ANNUAL_PRICE_ID'] ?? '';

  // AI
  static String get openAiApiKey =>
      _openAiApiKey.isNotEmpty
          ? _openAiApiKey
          : dotenv.env['OPENAI_API_KEY'] ?? '';

  // AdMob
  // PRODUCTION: set all ADMOB_* values via --dart-define or .env (local dev only).
  // No test IDs are kept as fallbacks — missing IDs will simply show no ad.
  static String get admobAppIdAndroid =>
      _admobAppIdAndroid.isNotEmpty
          ? _admobAppIdAndroid
          : dotenv.env['ADMOB_APP_ID_ANDROID'] ?? '';

  static String get admobAppIdIos =>
      _admobAppIdIos.isNotEmpty
          ? _admobAppIdIos
          : dotenv.env['ADMOB_APP_ID_IOS'] ?? '';

  static String get admobBannerAndroid =>
      _admobBannerAndroid.isNotEmpty
          ? _admobBannerAndroid
          : dotenv.env['ADMOB_BANNER_ANDROID'] ?? '';

  static String get admobBannerIos =>
      _admobBannerIos.isNotEmpty
          ? _admobBannerIos
          : dotenv.env['ADMOB_BANNER_IOS'] ?? '';

  static String get admobInterstitialAndroid =>
      _admobInterstitialAndroid.isNotEmpty
          ? _admobInterstitialAndroid
          : dotenv.env['ADMOB_INTERSTITIAL_ANDROID'] ?? '';

  static String get admobInterstitialIos =>
      _admobInterstitialIos.isNotEmpty
          ? _admobInterstitialIos
          : dotenv.env['ADMOB_INTERSTITIAL_IOS'] ?? '';

  static String get admobNativeAndroid =>
      _admobNativeAndroid.isNotEmpty
          ? _admobNativeAndroid
          : dotenv.env['ADMOB_NATIVE_ANDROID'] ?? '';

  static String get admobNativeIos =>
      _admobNativeIos.isNotEmpty
          ? _admobNativeIos
          : dotenv.env['ADMOB_NATIVE_IOS'] ?? '';

  // Environment
  static String get environment =>
      _environment.isNotEmpty
          ? _environment
          : dotenv.env['ENVIRONMENT'] ?? 'development';

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  static bool get enableLogging => isDevelopment || isStaging;
  static bool get enableDebugTools => isDevelopment;

  // Validation
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  EnvConfig._();
}
