import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Service for managing automatic session timeout
class SessionTimeoutService {
  static final Duration _inactivityTimeout =
      Duration(minutes: AppConfig.sessionTimeoutMinutes);
  Timer? _inactivityTimer;
  DateTime _lastActivityTime = DateTime.now();

  /// Called after a timeout fires, whether or not the Supabase sign-out
  /// network call succeeds.  Wire this in the provider to force-invalidate
  /// local auth state so the router always redirects to /login.
  void Function()? onSessionExpired;

  /// Start monitoring user activity
  void startMonitoring() {
    _resetTimer();
  }

  /// Stop monitoring user activity
  void stopMonitoring() {
    _inactivityTimer?.cancel();
  }

  /// Record user activity (call this on user interactions)
  void recordActivity() {
    _lastActivityTime = DateTime.now();
    _resetTimer();
  }

  /// Reset the inactivity timer
  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, _onTimeout);
  }

  /// Handle timeout event
  Future<void> _onTimeout() async {
    final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime);
    
    // Only logout if truly inactive
    if (timeSinceLastActivity >= _inactivityTimeout) {
      await _handleLogout();
    }
  }

  /// Logout user due to inactivity
  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      // Sign-out network call failed — log so it is visible in debug builds,
      // then fall through so onSessionExpired still fires and the router
      // redirects the user to /login.
      debugPrint('[SessionTimeout] signOut failed: $e');
    }
    // Always notify so the auth notifier can invalidate local state, even
    // when the network sign-out call fails.
    onSessionExpired?.call();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
