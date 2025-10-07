import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'biometric_service.dart';

/// Provider for biometric service
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Provider to check if biometric is available
final isBiometricAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.isBiometricAvailable();
});

/// Provider to get primary biometric type
final primaryBiometricTypeProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.getPrimaryBiometricType();
});
