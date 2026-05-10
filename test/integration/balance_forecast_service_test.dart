import 'package:finmate/features/ai_insights/data/services/balance_forecast_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  group('BalanceForecastService — initialization', () {
    test('can be instantiated with a mock Supabase client', () {
      final mockSupabase = MockSupabaseClient();
      final svc = BalanceForecastService(supabaseClient: mockSupabase);
      expect(svc, isNotNull);
    });

    test('throws when user is not authenticated', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();

      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(null);

      final svc = BalanceForecastService(supabaseClient: mockSupabase);

      expect(
        () => svc.generate30DayForecast(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
