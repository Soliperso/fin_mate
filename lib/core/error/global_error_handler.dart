import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../services/sentry_service.dart';

/// Global error handler for the application
/// Captures all uncaught errors and sends them to Sentry
class GlobalErrorHandler {
  /// Handle an error with context
  static Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    // Log to console in debug mode
    if (kDebugMode) {
      print('❌ Error ${fatal ? '(FATAL)' : ''}: $error');
      print('Stack trace: $stackTrace');
      if (context != null) {
        print('Context: $context');
      }
    }

    // Determine severity level
    final level = fatal
        ? SentryLevel.fatal
        : error.toString().contains('Warning')
            ? SentryLevel.warning
            : SentryLevel.error;

    // Capture in Sentry
    await SentryService.captureException(
      error,
      stackTrace: stackTrace,
      hint: context,
      level: level,
      extra: {
        'fatal': fatal,
        if (context != null) 'context': context,
        ...?extra,
      },
    );
  }

  /// Handle a warning (non-fatal error)
  static Future<void> handleWarning(
    String message, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    if (kDebugMode) {
      print('⚠️ Warning: $message');
      if (context != null) {
        print('Context: $context');
      }
    }

    await SentryService.captureMessage(
      message,
      level: SentryLevel.warning,
      extra: {
        if (context != null) 'context': context,
        ...?extra,
      },
    );
  }

  /// Handle an info message (for important events)
  static Future<void> handleInfo(
    String message, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    if (kDebugMode) {
      print('ℹ️ Info: $message');
    }

    await SentryService.captureMessage(
      message,
      level: SentryLevel.info,
      extra: {
        if (context != null) 'context': context,
        ...?extra,
      },
    );
  }

  /// Handle network errors
  static Future<void> handleNetworkError(
    Object error,
    StackTrace stackTrace, {
    String? endpoint,
    int? statusCode,
  }) async {
    await handleError(
      error,
      stackTrace,
      context: 'Network Error',
      extra: {
        if (endpoint != null) 'endpoint': endpoint,
        if (statusCode != null) 'status_code': statusCode,
      },
    );
  }

  /// Handle database errors
  static Future<void> handleDatabaseError(
    Object error,
    StackTrace stackTrace, {
    String? query,
    String? table,
  }) async {
    await handleError(
      error,
      stackTrace,
      context: 'Database Error',
      extra: {
        if (query != null) 'query': query,
        if (table != null) 'table': table,
      },
    );
  }

  /// Handle authentication errors
  static Future<void> handleAuthError(
    Object error,
    StackTrace stackTrace, {
    String? action,
  }) async {
    await handleError(
      error,
      stackTrace,
      context: 'Authentication Error',
      extra: {
        if (action != null) 'action': action,
      },
    );
  }
}
