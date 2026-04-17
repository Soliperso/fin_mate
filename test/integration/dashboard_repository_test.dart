import 'package:finmate/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

void main() {
  group('DashboardRepositoryImpl', () {
    test('can be instantiated with a mock Supabase client', () {
      final mockSupabase = MockSupabaseClient();
      final repo = DashboardRepositoryImpl(supabaseClient: mockSupabase);
      expect(repo, isNotNull);
    });

    test('getDashboardStats returns empty stats when user is null', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();

      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(null);

      final repo = DashboardRepositoryImpl(supabaseClient: mockSupabase);
      final stats = await repo.getDashboardStats();

      // Should return empty stats rather than throwing
      expect(stats.netWorth, 0.0);
    });

    test('getMonthlyFlowData returns data even when user is null', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();

      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(null);

      final repo = DashboardRepositoryImpl(supabaseClient: mockSupabase);
      final data = await repo.getMonthlyFlowData();

      // Should return a list (possibly empty)
      expect(data, isA<List>());
    });

    test('getNetWorthSnapshots returns empty list when user is null', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();

      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(null);

      final repo = DashboardRepositoryImpl(supabaseClient: mockSupabase);
      final snapshots = await repo.getNetWorthSnapshots();

      expect(snapshots, isEmpty);
    });

    test('createNetWorthSnapshot completes when user is null', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();

      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(null);

      final repo = DashboardRepositoryImpl(supabaseClient: mockSupabase);

      // Should complete without throwing
      expect(repo.createNetWorthSnapshot(), completes);
    });
  });
}
