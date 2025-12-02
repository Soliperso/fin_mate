/// Environment configuration for FinMate
///
/// This file manages environment-specific settings like API keys,
/// Supabase URLs, and feature flags.
///
/// SECURITY NOTE: Values are injected at build time using --dart-define flags.
/// Never commit actual API keys to version control.
class EnvConfig {
  // Environment type
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );

  // API Endpoints (for future use)
  static const String plaidClientId = String.fromEnvironment(
    'PLAID_CLIENT_ID',
    defaultValue: '',
  );

  static const String plaidSecret = String.fromEnvironment(
    'PLAID_SECRET',
    defaultValue: '',
  );

  static const String plaidEnv = String.fromEnvironment(
    'PLAID_ENV',
    defaultValue: 'sandbox',
  );

  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String stripeMonthlyPriceId = String.fromEnvironment(
    'STRIPE_MONTHLY_PRICE_ID',
    defaultValue: '',
  );

  static const String stripeAnnualPriceId = String.fromEnvironment(
    'STRIPE_ANNUAL_PRICE_ID',
    defaultValue: '',
  );

  static const String paypalClientId = String.fromEnvironment(
    'PAYPAL_CLIENT_ID',
    defaultValue: '',
  );

  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  // Feature Flags
  static const bool enableBiometricAuth = bool.fromEnvironment(
    'ENABLE_BIOMETRIC_AUTH',
    defaultValue: true,
  );

  static const bool enableAiInsights = bool.fromEnvironment(
    'ENABLE_AI_INSIGHTS',
    defaultValue: true,
  );

  static const bool enableBankSync = bool.fromEnvironment(
    'ENABLE_BANK_SYNC',
    defaultValue: false,
  );

  // Analytics (Optional)
  static const String posthogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: '',
  );

  static const String amplitudeApiKey = String.fromEnvironment(
    'AMPLITUDE_API_KEY',
    defaultValue: '',
  );

  // Environment checks
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  // Debug settings
  static bool get enableLogging => isDevelopment || isStaging;
  static bool get enableDebugTools => isDevelopment;

  // Validation helper
  static bool get isConfigured =>
      supabaseUrl != 'https://your-project.supabase.co' &&
      supabaseAnonKey != 'your-anon-key-here';

  EnvConfig._();
}
