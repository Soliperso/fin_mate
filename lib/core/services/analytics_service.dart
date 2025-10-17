import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../error/global_error_handler.dart';

/// Service for tracking user analytics events
/// Logs events to Supabase analytics_events table
class AnalyticsService {
  final SupabaseClient _supabase;
  String? _sessionId;
  String? _appVersion;
  String? _platform;

  AnalyticsService(this._supabase);

  /// Initialize analytics service with app info
  Future<void> initialize() async {
    try {
      // Generate session ID
      _sessionId = const Uuid().v4();

      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // Detect platform
      if (kIsWeb) {
        _platform = 'web';
      } else if (Platform.isIOS) {
        _platform = 'ios';
      } else if (Platform.isAndroid) {
        _platform = 'android';
      } else {
        _platform = 'unknown';
      }
    } catch (e, stackTrace) {
      // Don't let analytics initialization break the app
      await GlobalErrorHandler.handleError(
        e,
        stackTrace,
        context: 'Analytics initialization',
        extra: {'fatal': false},
      );
    }
  }

  /// Start a new session (call on app startup or after timeout)
  void startNewSession() {
    _sessionId = const Uuid().v4();
  }

  /// Log a custom event
  Future<void> logEvent({
    required String eventName,
    Map<String, dynamic>? properties,
    String? screenName,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return; // Don't log events for unauthenticated users

      await _supabase.from('analytics_events').insert({
        'user_id': userId,
        'event_name': eventName,
        'event_properties': properties ?? {},
        'screen_name': screenName,
        'session_id': _sessionId,
        'platform': _platform,
        'app_version': _appVersion,
      });
    } catch (e, stackTrace) {
      // Silently fail - don't break user experience for analytics
      await GlobalErrorHandler.handleError(
        e,
        stackTrace,
        context: 'Analytics log event: $eventName',
        extra: {'event_name': eventName, 'properties': properties},
      );
    }
  }

  /// Track screen view
  Future<void> trackScreen(String screenName) async {
    await logEvent(
      eventName: 'screen_view',
      screenName: screenName,
      properties: {'screen_name': screenName},
    );
  }

  /// Track user sign up
  Future<void> trackSignUp({String? method}) async {
    await logEvent(
      eventName: 'user_signed_up',
      properties: {'method': method ?? 'email'},
    );
  }

  /// Track user sign in
  Future<void> trackSignIn({String? method}) async {
    await logEvent(
      eventName: 'user_signed_in',
      properties: {'method': method ?? 'email'},
    );
  }

  /// Track user sign out
  Future<void> trackSignOut() async {
    await logEvent(eventName: 'user_signed_out');
  }

  /// Track transaction events
  Future<void> trackTransactionCreated({
    required String transactionId,
    required double amount,
    required String type,
    String? category,
  }) async {
    await logEvent(
      eventName: 'transaction_created',
      properties: {
        'transaction_id': transactionId,
        'amount': amount,
        'type': type,
        'category': category,
      },
    );
  }

  Future<void> trackTransactionUpdated({
    required String transactionId,
  }) async {
    await logEvent(
      eventName: 'transaction_updated',
      properties: {'transaction_id': transactionId},
    );
  }

  Future<void> trackTransactionDeleted({
    required String transactionId,
  }) async {
    await logEvent(
      eventName: 'transaction_deleted',
      properties: {'transaction_id': transactionId},
    );
  }

  /// Track budget events
  Future<void> trackBudgetCreated({
    required String budgetId,
    required double amount,
    String? category,
  }) async {
    await logEvent(
      eventName: 'budget_created',
      properties: {
        'budget_id': budgetId,
        'amount': amount,
        'category': category,
      },
    );
  }

  Future<void> trackBudgetUpdated({
    required String budgetId,
  }) async {
    await logEvent(
      eventName: 'budget_updated',
      properties: {'budget_id': budgetId},
    );
  }

  Future<void> trackBudgetDeleted({
    required String budgetId,
  }) async {
    await logEvent(
      eventName: 'budget_deleted',
      properties: {'budget_id': budgetId},
    );
  }

  /// Track bill splitting events
  Future<void> trackGroupCreated({
    required String groupId,
    required int memberCount,
  }) async {
    await logEvent(
      eventName: 'group_created',
      properties: {
        'group_id': groupId,
        'member_count': memberCount,
      },
    );
  }

  Future<void> trackExpenseCreated({
    required String expenseId,
    required String groupId,
    required double amount,
  }) async {
    await logEvent(
      eventName: 'expense_created',
      properties: {
        'expense_id': expenseId,
        'group_id': groupId,
        'amount': amount,
      },
    );
  }

  Future<void> trackSettlementRecorded({
    required String settlementId,
    required String groupId,
    required double amount,
  }) async {
    await logEvent(
      eventName: 'settlement_recorded',
      properties: {
        'settlement_id': settlementId,
        'group_id': groupId,
        'amount': amount,
      },
    );
  }

  /// Track savings goal events
  Future<void> trackGoalCreated({
    required String goalId,
    required double targetAmount,
  }) async {
    await logEvent(
      eventName: 'goal_created',
      properties: {
        'goal_id': goalId,
        'target_amount': targetAmount,
      },
    );
  }

  Future<void> trackContributionAdded({
    required String goalId,
    required double amount,
  }) async {
    await logEvent(
      eventName: 'contribution_added',
      properties: {
        'goal_id': goalId,
        'amount': amount,
      },
    );
  }

  /// Track AI insights usage
  Future<void> trackAIQuery({
    required String queryType,
    String? query,
  }) async {
    await logEvent(
      eventName: 'ai_query',
      properties: {
        'query_type': queryType,
        'has_query': query != null,
      },
    );
  }

  /// Track document uploads
  Future<void> trackDocumentUploaded({
    required String documentType,
    int? fileSize,
  }) async {
    await logEvent(
      eventName: 'document_uploaded',
      properties: {
        'document_type': documentType,
        'file_size': fileSize,
      },
    );
  }

  /// Track feature adoption
  Future<void> trackFeatureUsed(String featureName) async {
    await logEvent(
      eventName: 'feature_used',
      properties: {'feature_name': featureName},
    );
  }

  /// Track errors (user-facing)
  Future<void> trackError({
    required String errorType,
    String? errorMessage,
    String? screenName,
  }) async {
    await logEvent(
      eventName: 'user_error',
      screenName: screenName,
      properties: {
        'error_type': errorType,
        'error_message': errorMessage,
      },
    );
  }

  /// Track app lifecycle events
  Future<void> trackAppOpened() async {
    await logEvent(eventName: 'app_opened');
  }

  Future<void> trackAppClosed() async {
    await logEvent(eventName: 'app_closed');
  }

  Future<void> trackAppBackgrounded() async {
    await logEvent(eventName: 'app_backgrounded');
  }

  Future<void> trackAppForegrounded() async {
    await logEvent(eventName: 'app_foregrounded');
  }
}
