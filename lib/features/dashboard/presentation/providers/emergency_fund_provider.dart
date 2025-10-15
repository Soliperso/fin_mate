import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/services/emergency_fund_service.dart';
import '../../domain/entities/emergency_fund_status.dart';

// Emergency Fund Service Provider
final emergencyFundServiceProvider = Provider<EmergencyFundService>((ref) {
  return EmergencyFundService(supabase);
});

// Emergency Fund Status Provider
final emergencyFundStatusProvider = FutureProvider<EmergencyFundStatus>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  final service = ref.watch(emergencyFundServiceProvider);
  return await service.calculateEmergencyFundStatus(userId);
});
