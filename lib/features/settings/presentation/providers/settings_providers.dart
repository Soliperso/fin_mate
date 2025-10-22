import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/services/data_export_service.dart';

/// Provider for settings repository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final datasource = SettingsRemoteDataSource();
  final exportService = DataExportService();
  return SettingsRepositoryImpl(
    remoteDataSource: datasource,
    exportService: exportService,
  );
});

/// Provider for current user settings
final userSettingsProvider = FutureProvider<SettingsEntity?>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;

  if (user == null) {
    return null;
  }

  final repository = ref.watch(settingsRepositoryProvider);
  return await repository.getSettings(user.id);
});

/// State notifier for settings operations
class SettingsNotifier extends StateNotifier<AsyncValue<SettingsEntity?>> {
  final SettingsRepository _repository;
  final String _userId;

  SettingsNotifier(this._repository, this._userId) : super(const AsyncValue.loading());

  /// Initialize settings
  Future<void> initialize() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getSettings(_userId);
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update theme mode
  Future<void> updateThemeMode(String themeMode) async {
    try {
      final settings = await _repository.updateThemeMode(_userId, themeMode);
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update language
  Future<void> updateLanguage(String language) async {
    try {
      final settings = await _repository.updateLanguage(_userId, language);
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      final settings = await _repository.updateNotificationPreferences(
        _userId,
        preferences,
      );
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      await _repository.deleteAccount(_userId);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Export data as JSON
  Future<String> exportDataAsJson() async {
    return await _repository.exportDataAsJson(_userId);
  }

  /// Export transactions as CSV
  Future<String> exportTransactionsAsCsv() async {
    return await _repository.exportTransactionsAsCsv(_userId);
  }

  /// Export budgets as CSV
  Future<String> exportBudgetsAsCsv() async {
    return await _repository.exportBudgetsAsCsv(_userId);
  }
}

/// Provider for settings operations state notifier
final settingsOperationsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsEntity?>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;

  if (user == null) {
    return SettingsNotifier(
      ref.watch(settingsRepositoryProvider),
      '',
    );
  }

  return SettingsNotifier(
    ref.watch(settingsRepositoryProvider),
    user.id,
  );
});
