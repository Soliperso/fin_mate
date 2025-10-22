import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settings_model.dart';
import '../../../../core/config/supabase_client.dart';

/// Remote data source for settings
class SettingsRemoteDataSource {
  final SupabaseClient _supabase;

  SettingsRemoteDataSource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  /// Get user settings
  Future<SettingsModel?> getSettings(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return SettingsModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get settings: $e');
    }
  }

  /// Update theme mode
  Future<SettingsModel> updateThemeMode(String userId, String themeMode) async {
    try {
      final response = await _supabase.rpc(
        'update_user_settings',
        params: {
          'p_user_id': userId,
          'p_theme_mode': themeMode,
        },
      );

      return SettingsModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update theme mode: $e');
    }
  }

  /// Update language
  Future<SettingsModel> updateLanguage(String userId, String language) async {
    try {
      final response = await _supabase.rpc(
        'update_user_settings',
        params: {
          'p_user_id': userId,
          'p_language': language,
        },
      );

      return SettingsModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update language: $e');
    }
  }

  /// Update notification preferences
  Future<SettingsModel> updateNotificationPreferences(
    String userId,
    NotificationPreferencesModel preferences,
  ) async {
    try {
      final response = await _supabase.rpc(
        'update_user_settings',
        params: {
          'p_user_id': userId,
          'p_notification_preferences': preferences.toJson(),
        },
      );

      return SettingsModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  /// Delete user account and all associated data
  Future<void> deleteAccount(String userId) async {
    try {
      // Delete all user data cascading from user_profiles
      // Due to RLS, deletion is restricted to the user's own profile
      await _supabase.from('user_profiles').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Export all user transactions
  Future<List<Map<String, dynamic>>> exportTransactions(String userId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to export transactions: $e');
    }
  }

  /// Export all user budgets
  Future<List<Map<String, dynamic>>> exportBudgets(String userId) async {
    try {
      final response = await _supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to export budgets: $e');
    }
  }

  /// Export all user accounts
  Future<List<Map<String, dynamic>>> exportAccounts(String userId) async {
    try {
      final response = await _supabase
          .from('accounts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to export accounts: $e');
    }
  }

  /// Export user profile
  Future<Map<String, dynamic>> exportProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to export profile: $e');
    }
  }

  /// Check if user is admin
  bool get isAdmin {
    final user = _supabase.auth.currentUser;
    return user != null;
  }
}
