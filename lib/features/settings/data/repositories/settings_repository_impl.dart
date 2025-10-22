import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';
import '../models/settings_model.dart';
import '../../../../core/services/data_export_service.dart';

/// Implementation of SettingsRepository
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remoteDataSource;
  final DataExportService _exportService;

  SettingsRepositoryImpl({
    required SettingsRemoteDataSource remoteDataSource,
    required DataExportService exportService,
  })  : _remoteDataSource = remoteDataSource,
        _exportService = exportService;

  @override
  Future<SettingsEntity?> getSettings(String userId) async {
    try {
      final settings = await _remoteDataSource.getSettings(userId);
      return settings?.toEntity();
    } catch (e) {
      throw Exception('Failed to get settings: $e');
    }
  }

  @override
  Future<SettingsEntity> updateThemeMode(String userId, String themeMode) async {
    try {
      final settings = await _remoteDataSource.updateThemeMode(userId, themeMode);
      return settings.toEntity();
    } catch (e) {
      throw Exception('Failed to update theme mode: $e');
    }
  }

  @override
  Future<SettingsEntity> updateLanguage(String userId, String language) async {
    try {
      final settings = await _remoteDataSource.updateLanguage(userId, language);
      return settings.toEntity();
    } catch (e) {
      throw Exception('Failed to update language: $e');
    }
  }

  @override
  Future<SettingsEntity> updateNotificationPreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    try {
      final prefModel = NotificationPreferencesModel(
        pushEnabled: preferences.pushEnabled,
        emailEnabled: preferences.emailEnabled,
        soundEnabled: preferences.soundEnabled,
        budgetAlerts: preferences.budgetAlerts,
        budgetThreshold: preferences.budgetThreshold,
        billReminders: preferences.billReminders,
        billReminderDays: preferences.billReminderDays,
        transactionAlerts: preferences.transactionAlerts,
        transactionThreshold: preferences.transactionThreshold,
        moneyHealthUpdates: preferences.moneyHealthUpdates,
        goalNotifications: preferences.goalNotifications,
      );

      final settings = await _remoteDataSource.updateNotificationPreferences(
        userId,
        prefModel,
      );
      return settings.toEntity();
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  @override
  Future<void> deleteAccount(String userId) async {
    try {
      await _remoteDataSource.deleteAccount(userId);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  @override
  Future<String> exportDataAsJson(String userId) async {
    try {
      final profile = await _remoteDataSource.exportProfile(userId);
      final accounts = await _remoteDataSource.exportAccounts(userId);
      final transactions = await _remoteDataSource.exportTransactions(userId);
      final budgets = await _remoteDataSource.exportBudgets(userId);

      return _exportService.generateJsonExport(
        profile: profile,
        accounts: accounts,
        transactions: transactions,
        budgets: budgets,
      );
    } catch (e) {
      throw Exception('Failed to export data as JSON: $e');
    }
  }

  @override
  Future<String> exportTransactionsAsCsv(String userId) async {
    try {
      final transactions = await _remoteDataSource.exportTransactions(userId);
      return _exportService.generateCsvExport(transactions, filename: 'transactions');
    } catch (e) {
      throw Exception('Failed to export transactions as CSV: $e');
    }
  }

  @override
  Future<String> exportBudgetsAsCsv(String userId) async {
    try {
      final budgets = await _remoteDataSource.exportBudgets(userId);
      return _exportService.generateCsvExport(budgets, filename: 'budgets');
    } catch (e) {
      throw Exception('Failed to export budgets as CSV: $e');
    }
  }
}
