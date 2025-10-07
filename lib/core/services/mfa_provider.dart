import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mfa_service.dart';

/// Provider for MFA service
final mfaServiceProvider = Provider<MfaService>((ref) {
  return MfaService();
});
