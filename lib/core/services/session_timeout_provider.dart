import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'session_timeout_service.dart';

final sessionTimeoutServiceProvider = Provider<SessionTimeoutService>((ref) {
  final service = SessionTimeoutService();
  // Force auth state to unauthenticated on timeout, even when the Supabase
  // network sign-out call fails, so the router always redirects to /login.
  service.onSessionExpired = () {
    ref.read(authNotifierProvider.notifier).signOut();
  };
  ref.onDispose(service.dispose);
  return service;
});
