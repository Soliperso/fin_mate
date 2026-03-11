import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing automatic session timeout
class SessionTimeoutService {
  static const Duration _inactivityTimeout = Duration(minutes: 15);
  Timer? _inactivityTimer;
  DateTime _lastActivityTime = DateTime.now();

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
      // Logout failed silently
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
