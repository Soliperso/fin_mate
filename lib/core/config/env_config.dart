import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for FinMate
///
/// This file manages environment-specific settings like API keys,
/// Supabase URLs, and feature flags.
///
/// SECURITY NOTE: Never commit actual API keys to version control.
/// Use .env file for local development (excluded from git).
class EnvConfig {
  // Environment type
  static String get environment =>
      dotenv.get('ENVIRONMENT', fallback: 'development');

  // Supabase Configuration
  static String get supabaseUrl =>
      dotenv.get('SUPABASE_URL', fallback: 'https://your-project.supabase.co');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: 'your-anon-key-here');

  // API Endpoints (for future use)
  static String get plaidClientId =>
      dotenv.get('PLAID_CLIENT_ID', fallback: '');

  static String get plaidSecret =>
      dotenv.get('PLAID_SECRET', fallback: '');

  static String get plaidEnv =>
      dotenv.get('PLAID_ENV', fallback: 'sandbox');

  static String get openAiApiKey =>
      dotenv.get('OPENAI_API_KEY', fallback: '');

  static String get stripePublishableKey =>
      dotenv.get('STRIPE_PUBLISHABLE_KEY', fallback: '');

  static String get paypalClientId =>
      dotenv.get('PAYPAL_CLIENT_ID', fallback: '');

  // Feature Flags
  static bool get enableBiometricAuth =>
      dotenv.get('ENABLE_BIOMETRIC_AUTH', fallback: 'true') == 'true';

  static bool get enableAiInsights =>
      dotenv.get('ENABLE_AI_INSIGHTS', fallback: 'true') == 'true';

  static bool get enableBankSync =>
      dotenv.get('ENABLE_BANK_SYNC', fallback: 'false') == 'true';

  // Analytics (Optional)
  static String get posthogApiKey =>
      dotenv.get('POSTHOG_API_KEY', fallback: '');

  static String get amplitudeApiKey =>
      dotenv.get('AMPLITUDE_API_KEY', fallback: '');

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
