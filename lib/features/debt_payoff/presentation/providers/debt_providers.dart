import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/datasources/debt_remote_datasource.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/services/payoff_calculator.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(DebtRemoteDatasource());
});

final debtsProvider = FutureProvider<List<DebtEntity>>((ref) async {
  final repository = ref.watch(debtRepositoryProvider);
  return repository.getDebts();
});

final debtPaymentsProvider = FutureProvider.family<List<DebtPaymentEntity>, String>((ref, debtId) async {
  final repository = ref.watch(debtRepositoryProvider);
  return repository.getPayments(debtId);
});

final debtSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(debtRepositoryProvider);
  return repository.getDebtSummary();
});

// ── Strategy & extra payment state ──────────────────────────────────────────

final selectedStrategyProvider = StateProvider<DebtStrategy>((ref) => DebtStrategy.avalanche);

final extraPaymentProvider = StateProvider<double>((ref) => 0.0);

// ── Payoff calculation providers ────────────────────────────────────────────

/// Payoff result for the currently selected strategy (no extra payment).
final payoffResultProvider = Provider<PayoffResult?>((ref) {
  final debts = ref.watch(debtsProvider).valueOrNull;
  final strategy = ref.watch(selectedStrategyProvider);
  if (debts == null || debts.isEmpty) return null;
  return PayoffCalculator.compute(debts: debts, strategy: strategy);
});

/// Always-computed Avalanche result — used by strategy comparison sheet.
final avalancheResultProvider = Provider<PayoffResult?>((ref) {
  final debts = ref.watch(debtsProvider).valueOrNull;
  if (debts == null || debts.isEmpty) return null;
  return PayoffCalculator.compute(debts: debts, strategy: DebtStrategy.avalanche);
});

/// Always-computed Snowball result — used by strategy comparison sheet.
final snowballResultProvider = Provider<PayoffResult?>((ref) {
  final debts = ref.watch(debtsProvider).valueOrNull;
  if (debts == null || debts.isEmpty) return null;
  return PayoffCalculator.compute(debts: debts, strategy: DebtStrategy.snowball);
});

/// Payoff result with extra monthly payment applied — used by simulator.
final simulatedPayoffProvider = Provider<PayoffResult?>((ref) {
  final debts = ref.watch(debtsProvider).valueOrNull;
  final strategy = ref.watch(selectedStrategyProvider);
  final extra = ref.watch(extraPaymentProvider);
  if (debts == null || debts.isEmpty || extra == 0) return null;
  return PayoffCalculator.compute(
    debts: debts,
    strategy: strategy,
    extraMonthlyPayment: extra,
  );
});

// ── Mutation notifier ────────────────────────────────────────────────────────

class DebtNotifier extends StateNotifier<AsyncValue<void>> {
  final DebtRepository _repository;
  final AnalyticsService _analytics;
  final Ref _ref;

  DebtNotifier(this._repository, this._analytics, this._ref) : super(const AsyncValue.data(null));

  void _invalidateDashboard() {
    _ref.invalidate(dashboardNotifierProvider);
    _ref.invalidate(netWorthSnapshotsProvider);
  }

  Future<DebtEntity?> createDebt({
    required String name,
    required String debtType,
    required double balance,
    required double interestRate,
    required double minimumPayment,
    int? dueDay,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final debt = await _repository.createDebt(
        name: name,
        debtType: debtType,
        balance: balance,
        interestRate: interestRate,
        minimumPayment: minimumPayment,
        dueDay: dueDay,
        notes: notes,
      );
      _analytics.trackDebtCreated(debtId: debt.id, balance: balance);
      state = const AsyncValue.data(null);
      _invalidateDashboard();
      return debt;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> updateDebt(String id, Map<String, dynamic> fields) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateDebt(id, fields);
      state = const AsyncValue.data(null);
      _invalidateDashboard();
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteDebt(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteDebt(id);
      state = const AsyncValue.data(null);
      _invalidateDashboard();
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<DebtPaymentEntity?> logPayment({
    required String debtId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final payment = await _repository.logPayment(
        debtId: debtId,
        amount: amount,
        paymentDate: paymentDate,
        notes: notes,
      );
      _analytics.trackDebtPaymentLogged(debtId: debtId, amount: amount);
      state = const AsyncValue.data(null);
      _invalidateDashboard();
      return payment;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> recordPaymentFromTransaction({
    required String debtId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  }) async {
    try {
      await _repository.recordDebtPayment(
        debtId: debtId,
        amount: amount,
        paymentDate: paymentDate,
        notes: notes,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final debtNotifierProvider = StateNotifierProvider<DebtNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(debtRepositoryProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return DebtNotifier(repository, analytics, ref);
});
