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
          .update({'role': role}).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Send password reset email to user
  Future<void> resetUserPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.finmate://reset-callback/',
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('rate_limit') || msg.contains('429')) {
        throw Exception(
            'Too many reset emails sent. Please wait a few minutes and try again.');
      }
      throw Exception('Failed to send password reset email. Please try again.');
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
      return data
          .map((json) => NetWorthPercentileModel.fromJson(json))
          .toList();
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
      return data
          .map((json) => SubscriptionCohortModel.fromJson(json))
          .toList();
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
      return data
          .map((json) => SubscriptionTimelineModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch subscription timeline: $e');
    }
  }

  /// Export all transactions system-wide as a CSV string (admin only)
  Future<String> exportAllTransactionsCsv() async {
    final response = await _supabase.rpc('admin_export_all_transactions');
    final rows = List<Map<String, dynamic>>.from(response as List);

    const headers = [
      'Date',
      'Type',
      'Amount',
      'Account',
      'Category',
      'Description',
      'Notes',
      'Tags',
      'User ID',
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

  /// Get all feature flags
  Future<List<Map<String, dynamic>>> getFeatureFlags() async {
    final result = await _supabase.rpc('admin_get_feature_flags');
    if (result == null) return [];
    return List<Map<String, dynamic>>.from(result as List);
  }

  /// Enable or disable a feature flag by key
  Future<void> setFeatureFlag(String key, bool enabled) async {
    await _supabase.rpc('admin_set_feature_flag', params: {
      'p_key': key,
      'p_enabled': enabled,
    });
  }

  /// Set the gradual rollout percentage (0–100) for a feature flag
  Future<void> setRolloutPercentage(String key, int percentage) async {
    await _supabase.rpc('admin_set_rollout_percentage', params: {
      'p_key': key,
      'p_pct': percentage,
    });
  }

  /// Get version settings for all platforms (ios, android)
  Future<List<Map<String, dynamic>>> getAppVersions() async {
    final result = await _supabase
        .from('app_versions')
        .select(
            'platform, min_version, latest_version, release_notes, force_update, updated_at, updated_by')
        .order('platform');
    return List<Map<String, dynamic>>.from(result as List);
  }

  /// Update version settings for a platform (admin only via RPC)
  Future<void> setAppVersion({
    required String platform,
    required String minVersion,
    required String latestVersion,
    required String releaseNotes,
    required bool forceUpdate,
  }) async {
    await _supabase.rpc('admin_set_app_version', params: {
      'p_platform': platform,
      'p_min_version': minVersion,
      'p_latest_version': latestVersion,
      'p_release_notes': releaseNotes.isEmpty ? null : releaseNotes,
      'p_force_update': forceUpdate,
    });
  }

  /// Get data health check results (admin only)
  Future<List<Map<String, dynamic>>> getDataHealth() async {
    final result = await _supabase.rpc('admin_get_data_health');
    if (result == null) return [];
    return List<Map<String, dynamic>>.from(result as List);
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

  /// Get paginated feedback submissions (admin only)
  Future<List<Map<String, dynamic>>> getFeedback({
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await _supabase.rpc('admin_get_feedback', params: {
      'p_category': category,
      'p_limit': limit,
      'p_offset': offset,
    });
    if (result == null) return [];
    return List<Map<String, dynamic>>.from(result as List);
  }

  /// Mark a feedback entry as reviewed or unreviewed
  Future<void> setFeedbackReviewed(String id, {required bool reviewed}) async {
    await _supabase.rpc('admin_set_feedback_reviewed', params: {
      'p_id': id,
      'p_reviewed': reviewed,
    });
  }

  /// Get all announcements (admin view — includes inactive)
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final result = await _supabase
        .from('announcements')
        .select(
            'id, title, message, cta_label, cta_url, active, starts_at, ends_at, created_by, updated_at')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(result as List);
  }

  /// Create a new announcement banner
  Future<void> createAnnouncement({
    required String title,
    required String message,
    String? ctaLabel,
    String? ctaUrl,
    required bool active,
    required DateTime startsAt,
    DateTime? endsAt,
  }) async {
    final email = _supabase.auth.currentUser?.email;
    await _supabase.from('announcements').insert({
      'title': title,
      'message': message,
      'cta_label': ctaLabel?.isEmpty == true ? null : ctaLabel,
      'cta_url': ctaUrl?.isEmpty == true ? null : ctaUrl,
      'active': active,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
      'created_by': email,
    });
  }

  /// Update an existing announcement
  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String message,
    String? ctaLabel,
    String? ctaUrl,
    required bool active,
    required DateTime startsAt,
    DateTime? endsAt,
  }) async {
    await _supabase.from('announcements').update({
      'title': title,
      'message': message,
      'cta_label': ctaLabel?.isEmpty == true ? null : ctaLabel,
      'cta_url': ctaUrl?.isEmpty == true ? null : ctaUrl,
      'active': active,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement(String id) async {
    await _supabase.from('announcements').delete().eq('id', id);
  }

  /// Get all system-wide default categories (is_default = TRUE)
  Future<List<Map<String, dynamic>>> getDefaultCategories() async {
    final result = await _supabase
        .from('categories')
        .select('id, name, type, icon, color, is_default, created_at')
        .eq('is_default', true)
        .order('type')
        .order('name');
    return List<Map<String, dynamic>>.from(result as List);
  }

  /// Add a new default category
  Future<void> addDefaultCategory({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    await _supabase.rpc('admin_add_default_category', params: {
      'p_name': name,
      'p_type': type,
      'p_icon': icon,
      'p_color': color,
    });
  }

  /// Update name, icon, and color of a default category (type is immutable)
  Future<void> updateDefaultCategory({
    required String id,
    required String name,
    required String icon,
    required String color,
  }) async {
    await _supabase.rpc('admin_update_default_category', params: {
      'p_id': id,
      'p_name': name,
      'p_icon': icon,
      'p_color': color,
    });
  }

  /// Delete a default category by ID
  Future<void> deleteDefaultCategory(String id) async {
    await _supabase.rpc('admin_delete_default_category', params: {'p_id': id});
  }

  /// Get all email templates
  Future<List<Map<String, dynamic>>> getEmailTemplates() async {
    final result = await _supabase
        .from('email_templates')
        .select(
            'id, key, name, description, subject, body, is_enabled, variables, updated_at')
        .order('name');
    return List<Map<String, dynamic>>.from(result as List);
  }

  /// Update an email template's subject, body, and enabled status
  Future<void> updateEmailTemplate({
    required String id,
    required String subject,
    required String body,
    required bool isEnabled,
  }) async {
    await _supabase.from('email_templates').update({
      'subject': subject,
      'body': body,
      'is_enabled': isEnabled,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Get system-wide audit log
  Future<List<Map<String, dynamic>>> getSystemAuditLog() async {
    try {
      final response = await _supabase
          .from('analytics_events')
          .select(
              'event_name, created_at, user_id, event_properties, screen_name')
          .order('created_at', ascending: false)
          .limit(100);

      final logs = List<Map<String, dynamic>>.from(response);

      final uniqueIds =
          logs.map((e) => e['user_id'] as String?).whereType<String>().toSet();

      Map<String, String> nameMap = {};
      if (uniqueIds.isNotEmpty) {
        try {
          final profiles = await _supabase
              .from('user_profiles')
              .select('id, full_name')
              .inFilter('id', uniqueIds.toList());
          for (final p in List<Map<String, dynamic>>.from(profiles)) {
            final id = p['id'] as String?;
            final name = p['full_name'] as String?;
            if (id != null && name != null && name.isNotEmpty) {
              nameMap[id] = name;
            }
          }
        } catch (_) {}
      }

      return logs.map((e) {
        final uid = e['user_id'] as String? ?? '';
        return {
          'action': e['event_name'],
          'created_at': e['created_at'],
          'user_id': uid,
          'user_name': nameMap[uid],
          'screen_name': e['screen_name'],
          'properties': e['event_properties'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
