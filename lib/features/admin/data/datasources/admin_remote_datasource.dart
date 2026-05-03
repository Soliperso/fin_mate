import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/admin_user_model.dart';
import '../models/system_stats_model.dart';
import '../models/user_growth_trend_model.dart';
import '../models/financial_trend_model.dart';
import '../models/feature_adoption_model.dart';
import '../models/category_breakdown_model.dart';
import '../models/engagement_metric_model.dart';
import '../models/net_worth_percentile_model.dart';
import '../models/churn_metric_model.dart';
import '../models/subscription_cohort_model.dart';
import '../models/subscription_timeline_model.dart';

/// Remote datasource for admin operations
class AdminRemoteDataSource {
  final SupabaseClient _supabase;

  AdminRemoteDataSource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  /// Get all users with statistics
  Future<List<AdminUserModel>> getAllUsers({
    int? limit,
    int? offset,
    String? searchQuery,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_all_users_with_stats',
        params: {
          'p_limit': limit ?? 50,
          'p_offset': offset ?? 0,
          'p_search_query': searchQuery,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => AdminUserModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Get system-wide statistics
  Future<SystemStatsModel> getSystemStats() async {
    try {
      final response = await _supabase.rpc('get_system_stats');

      if (response == null || response.isEmpty) {
        throw Exception('No system stats returned');
      }

      final data = response[0] as Map<String, dynamic>;
      return SystemStatsModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch system stats: $e');
    }
  }

  /// Get user details by ID
  Future<AdminUserModel> getUserDetails(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_user_details_admin',
        params: {'p_user_id': userId},
      );

      if (response == null || response.isEmpty) {
        throw Exception('User not found');
      }

      final data = response[0] as Map<String, dynamic>;
      return AdminUserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch user details: $e');
    }
  }

  /// Update user role (admin only)
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({'role': role})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Send password reset email to user
  Future<void> resetUserPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Disable/deactivate user account
  Future<void> disableUserAccount(String userId) async {
    try {
      await _supabase.rpc('admin_set_user_active', params: {
        'p_user_id': userId,
        'p_active': false,
      });
    } catch (e) {
      throw Exception('Failed to disable user account: $e');
    }
  }

  /// Enable/reactivate user account
  Future<void> enableUserAccount(String userId) async {
    try {
      await _supabase.rpc('admin_set_user_active', params: {
        'p_user_id': userId,
        'p_active': true,
      });
    } catch (e) {
      throw Exception('Failed to enable user account: $e');
    }
  }

  /// Get audit log entries for a user
  Future<List<Map<String, dynamic>>> getUserAuditLog(String userId) async {
    try {
      final response = await _supabase
          .from('analytics_events')
          .select('event_name, created_at, event_properties, screen_name')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response).map((e) {
        return {
          'action': e['event_name'],
          'created_at': e['created_at'],
          'screen_name': e['screen_name'],
          'properties': e['event_properties'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Advanced Analytics Methods

  /// Get user growth trends
  Future<List<UserGrowthTrendModel>> getUserGrowthTrends({
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'day',
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_user_growth_trends',
        params: {
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
          'p_granularity': granularity,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => UserGrowthTrendModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user growth trends: $e');
    }
  }

  /// Get financial trends
  Future<List<FinancialTrendModel>> getFinancialTrends({
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'day',
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_financial_trends',
        params: {
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
          'p_granularity': granularity,
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => FinancialTrendModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch financial trends: $e');
    }
  }

  /// Get feature adoption stats
  Future<List<FeatureAdoptionModel>> getFeatureAdoptionStats() async {
    try {
      final response = await _supabase.rpc('get_feature_adoption_stats');

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => FeatureAdoptionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch feature adoption stats: $e');
    }
  }

  /// Get category breakdown
  Future<List<CategoryBreakdownModel>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_category_breakdown',
        params: {
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => CategoryBreakdownModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch category breakdown: $e');
    }
  }

  /// Get user engagement metrics
  Future<List<EngagementMetricModel>> getUserEngagementMetrics({
    int periodDays = 30,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_user_engagement_metrics',
        params: {'p_period_days': periodDays},
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => EngagementMetricModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch engagement metrics: $e');
    }
  }

  /// Get net worth percentiles
  Future<List<NetWorthPercentileModel>> getNetWorthPercentiles() async {
    try {
      final response = await _supabase.rpc('get_net_worth_percentiles');

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => NetWorthPercentileModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch net worth percentiles: $e');
    }
  }

  /// Get churn and subscription KPI metrics
  Future<List<ChurnMetricModel>> getChurnMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_churn_metrics',
        params: {
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ChurnMetricModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch churn metrics: $e');
    }
  }

  /// Get subscription cohorts by signup month
  Future<List<SubscriptionCohortModel>> getSubscriptionCohorts() async {
    try {
      final response = await _supabase.rpc('get_subscription_cohorts');

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => SubscriptionCohortModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch subscription cohorts: $e');
    }
  }

  /// Get day-by-day subscription event timeline
  Future<List<SubscriptionTimelineModel>> getSubscriptionTimeline({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_subscription_timeline',
        params: {
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => SubscriptionTimelineModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch subscription timeline: $e');
    }
  }

  /// Export all transactions system-wide as a CSV string (admin only)
  Future<String> exportAllTransactionsCsv() async {
    final response = await _supabase.rpc('admin_export_all_transactions');
    final rows = List<Map<String, dynamic>>.from(response as List);

    const headers = [
      'Date', 'Type', 'Amount', 'Account', 'Category',
      'Description', 'Notes', 'Tags', 'User ID',
    ];
    final lines = [
      headers.join(','),
      ...rows.map((r) => [
            r['date'],
            r['type'],
            r['amount'],
            _csvCell(r['account']),
            _csvCell(r['category']),
            _csvCell(r['description']),
            _csvCell(r['notes']),
            _csvCell(r['tags']),
            r['user_id'],
          ].join(',')),
    ];
    return lines.join('\n');
  }

  String _csvCell(dynamic value) {
    final s = (value ?? '').toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Delete analytics_events older than 90 days
  Future<void> cleanOldData() async {
    await _supabase.rpc('cleanup_old_analytics');
  }

  /// Broadcast a notification to all users in the system
  Future<void> broadcastNotification(String title, String body) async {
    await _supabase.rpc('admin_broadcast_notification', params: {
      'p_title': title,
      'p_body': body,
    });
  }

  /// Get system-wide audit log
  Future<List<Map<String, dynamic>>> getSystemAuditLog() async {
    try {
      final response = await _supabase
          .from('analytics_events')
          .select('event_name, created_at, user_id, event_properties, screen_name')
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response).map((e) {
        return {
          'action': e['event_name'],
          'created_at': e['created_at'],
          'user_id': e['user_id'],
          'screen_name': e['screen_name'],
          'properties': e['event_properties'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
