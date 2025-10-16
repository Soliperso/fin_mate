import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service for error tracking and monitoring with Sentry
class SentryService {
  static bool _isInitialized = false;

  /// Initialize Sentry with configuration from environment variables
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final dsn = dotenv.get('SENTRY_DSN', fallback: '');

    // Skip initialization if DSN is not configured
    if (dsn.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Sentry DSN not configured. Error tracking disabled.');
      }
      return;
    }

    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;

          // Environment configuration
          options.environment = dotenv.get(
            'SENTRY_ENVIRONMENT',
            fallback: kDebugMode ? 'development' : 'production',
          );

          // Release version
          options.release = dotenv.get('SENTRY_RELEASE', fallback: '1.0.0+1');

          // Performance monitoring
          options.tracesSampleRate = kDebugMode ? 1.0 : 0.2; // 100% in dev, 20% in prod

          // Debug mode
          options.debug = kDebugMode;

          // Attach screenshots on errors (helpful for debugging)
          options.attachScreenshot = true;

          // Attach view hierarchy on errors
          options.attachViewHierarchy = true;

          // Send default PII (Personally Identifiable Information)
          // Set to false to comply with GDPR
          options.sendDefaultPii = false;

          // Maximum breadcrumbs (user actions before error)
          options.maxBreadcrumbs = 50;

          // Before send callback - filter sensitive data
          options.beforeSend = (event, hint) {
            // Filter out sensitive data from breadcrumbs
            if (event.breadcrumbs != null) {
              event = event.copyWith(
                breadcrumbs: event.breadcrumbs?.where((breadcrumb) {
                  final message = breadcrumb.message?.toLowerCase() ?? '';
                  // Filter out any breadcrumbs containing sensitive keywords
                  return !message.contains('password') &&
                      !message.contains('token') &&
                      !message.contains('secret') &&
                      !message.contains('apikey');
                }).toList(),
              );
            }

            // Filter sensitive data from request data
            if (event.request?.data != null) {
              final data = event.request!.data as Map<String, dynamic>?;
              if (data != null) {
                data.removeWhere((key, value) =>
                    key.toLowerCase().contains('password') ||
                    key.toLowerCase().contains('token') ||
                    key.toLowerCase().contains('secret'));
              }
            }

            return event;
          };

          // Before breadcrumb callback - filter navigation
          options.beforeBreadcrumb = (breadcrumb, hint) {
            // Don't log navigation to sensitive screens
            if (breadcrumb?.type == 'navigation') {
              final message = breadcrumb?.message?.toLowerCase() ?? '';
              if (message.contains('password') ||
                  message.contains('security') ||
                  message.contains('mfa')) {
                return null; // Skip this breadcrumb
              }
            }
            return breadcrumb;
          };
        },
      );

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Sentry initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Sentry: $e');
      }
    }
  }

  /// Set user context for error reports
  /// Accepts user ID and email
  static Future<void> setUser({String? id, String? email}) async {
    if (!_isInitialized) return;

    if (id == null || email == null) {
      await Sentry.configureScope((scope) => scope.setUser(null));
      return;
    }

    await Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          id: id,
          email: email,
        ),
      );
    });
  }

  /// Clear user context (on logout)
  static Future<void> clearUser() async {
    if (!_isInitialized) return;
    await Sentry.configureScope((scope) => scope.setUser(null));
  }

  /// Set custom context (e.g., screen name, feature usage)
  static Future<void> setContext(String key, Map<String, dynamic> data) async {
    if (!_isInitialized) return;
    await Sentry.configureScope((scope) => scope.setContexts(key, data));
  }

  /// Add breadcrumb (user action tracking)
  static void addBreadcrumb({
    required String message,
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    if (!_isInitialized) return;

    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Capture an exception with context
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('Sentry not initialized. Error: $exception');
      }
      return;
    }

    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: hint != null ? Hint.withMap({'hint': hint}) : null,
        withScope: (scope) {
          scope.level = level;
          if (extra != null) {
            extra.forEach((key, value) {
              scope.setExtra(key, value);
            });
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to capture exception in Sentry: $e');
      }
    }
  }

  /// Capture a message (non-exception events)
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    if (!_isInitialized) return;

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (extra != null) {
          extra.forEach((key, value) {
            scope.setExtra(key, value);
          });
        }
      },
    );
  }

  /// Start a transaction (for performance monitoring)
  static ISentrySpan? startTransaction(
    String name,
    String operation, {
    Map<String, dynamic>? data,
  }) {
    if (!_isInitialized) return null;

    final transaction = Sentry.startTransaction(
      name,
      operation,
      bindToScope: true,
    );

    if (data != null) {
      data.forEach((key, value) {
        transaction.setData(key, value);
      });
    }

    return transaction;
  }

  /// Track screen view
  static void trackScreen(String screenName) {
    if (!_isInitialized) return;

    addBreadcrumb(
      message: 'Screen: $screenName',
      category: 'navigation',
      level: SentryLevel.info,
    );

    setContext('screen', {'name': screenName});
  }

  /// Track feature usage
  static void trackFeature(String featureName, {Map<String, dynamic>? data}) {
    if (!_isInitialized) return;

    addBreadcrumb(
      message: 'Feature: $featureName',
      category: 'feature',
      level: SentryLevel.info,
      data: data,
    );
  }
}
