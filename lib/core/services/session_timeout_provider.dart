import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_timeout_service.dart';

final sessionTimeoutServiceProvider = Provider<SessionTimeoutService>((ref) {
  final service = SessionTimeoutService();
  ref.onDispose(service.dispose);
  return service;
});
