/// Application-wide configuration constants
///
/// This file contains app-level settings that don't change
/// across environments (unlike EnvConfig which has environment-specific values)
class AppConfig {
  // App Information
  static const String appName = 'FinMate';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Storage Keys
  static const String localStorageBox = 'finmate_storage';
  static const String secureStoragePrefix = 'finmate_secure_';

  // Storage Keys - Specific
  static const String userSessionKey = '${secureStoragePrefix}user_session';
  static const String biometricEnabledKey = '${secureStoragePrefix}biometric_enabled';
  static const String themePreferenceKey = 'theme_preference';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // Auth Configuration
  static const int sessionTimeoutMinutes = 30;
  static const int mfaCodeLength = 6;
  static const int maxLoginAttempts = 5;

  // Security
  static const int pinLength = 6;
  static const int biometricMaxAttempts = 3;
  static const String encryptionAlgorithm = 'AES-256-GCM';

  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Settings
  static const int cacheExpirationHours = 24;
  static const int imageCacheExpirationDays = 7;

  // Bill Splitting
  static const int maxGroupMembers = 50;
  static const int maxExpensesPerGroup = 1000;
  static const List<String> supportedCurrencies = ['USD', 'EUR', 'GBP', 'CAD'];
  static const String defaultCurrency = 'USD';

  // Budget & Goals
  static const int maxBudgetCategories = 20;
  static const int maxSavingsGoals = 10;
  static const double minGoalAmount = 1.0;
  static const double maxGoalAmount = 1000000.0;

  // AI Insights
  static const int forecastMonths = 6;
  static const int maxInsightHistory = 100;
  static const String aiModel = 'gpt-4';

  // UI/UX
  static const int splashScreenDurationMs = 2000;
  static const int toastDurationMs = 3000;
  static const int animationDurationMs = 300;
  static const double swipeThreshold = 0.4;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;

  // Contact & Support
  static const String supportEmail = 'support@finmate.app';
  static const String privacyPolicyUrl = 'https://finmate.app/privacy';
  static const String termsOfServiceUrl = 'https://finmate.app/terms';

  // Social
  static const String websiteUrl = 'https://finmate.app';
  static const String twitterHandle = '@finmate';

  AppConfig._();
}
