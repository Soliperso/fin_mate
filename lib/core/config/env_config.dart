/// Environment configuration for FinMate
///
/// This file manages environment-specific settings like API keys,
/// Supabase URLs, and feature flags.
///
/// SECURITY NOTE: Never commit actual API keys to version control.
/// Use environment variables or secure storage instead.
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

  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
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
    defaultValue: false, // Disabled in MVP
  );

  // Environment checks
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  // Debug settings
  static bool get enableLogging => isDevelopment || isStaging;
  static bool get enableDebugTools => isDevelopment;

  EnvConfig._();
}
