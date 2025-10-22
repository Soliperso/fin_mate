import '../entities/settings_entity.dart';

/// Repository interface for settings management
abstract class SettingsRepository {
  /// Get user settings
  Future<SettingsEntity?> getSettings(String userId);

  /// Update theme mode
  Future<SettingsEntity> updateThemeMode(String userId, String themeMode);

  /// Update language
  Future<SettingsEntity> updateLanguage(String userId, String language);

  /// Update notification preferences
  Future<SettingsEntity> updateNotificationPreferences(
    String userId,
    NotificationPreferences preferences,
  );

  /// Delete user account and all associated data
  Future<void> deleteAccount(String userId);

  /// Export user data as JSON
  Future<String> exportDataAsJson(String userId);

  /// Export transactions as CSV
  Future<String> exportTransactionsAsCsv(String userId);

  /// Export budgets as CSV
  Future<String> exportBudgetsAsCsv(String userId);
}
