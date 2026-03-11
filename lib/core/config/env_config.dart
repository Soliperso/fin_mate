import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for FinMate
///
/// Reads values from the .env file loaded at startup via flutter_dotenv.
class EnvConfig {
  // Supabase Configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key-here';

  // Sentry
  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';

  // Stripe
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  static String get stripeMonthlyPriceId =>
      dotenv.env['STRIPE_MONTHLY_PRICE_ID'] ?? '';

  static String get stripeAnnualPriceId =>
      dotenv.env['STRIPE_ANNUAL_PRICE_ID'] ?? '';

  // AI
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // Environment
  static String get environment =>
      dotenv.env['ENVIRONMENT'] ?? 'development';

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  static bool get enableLogging => isDevelopment || isStaging;
  static bool get enableDebugTools => isDevelopment;

  // Validation
  static bool get isConfigured =>
      supabaseUrl != 'https://your-project.supabase.co' &&
      supabaseAnonKey != 'your-anon-key-here';

  EnvConfig._();
}
