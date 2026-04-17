import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/global_error_handler.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/datasources/debt_remote_datasource.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/services/payoff_calculator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  ref.watch(userSessionProvider);
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
    _ref.invalidate(debtsProvider);
    _ref.invalidate(debtSummaryProvider);
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
      _invalidateDashboard();
      return true;
    } catch (e, stack) {
      GlobalErrorHandler.handleError(e, stack, context: 'recordDebtPayment');
      return false;
    }
  }

  Future<bool> deletePayment({
    required String paymentId,
    required String debtId,
    required double amount,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deletePayment(
        paymentId: paymentId,
        debtId: debtId,
        amount: amount,
      );
      _analytics.logEvent(
        eventName: 'debt_payment_deleted',
        properties: {'debt_id': debtId, 'amount': amount},
      );
      state = const AsyncValue.data(null);
      _invalidateDashboard();
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final debtNotifierProvider = StateNotifierProvider<DebtNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(debtRepositoryProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return DebtNotifier(repository, analytics, ref);
});

// ── Gamification ─────────────────────────────────────────────────────────────

/// All payments across all debts — used for streak calculation.
final allDebtPaymentsProvider = FutureProvider<List<DebtPaymentEntity>>((ref) async {
  final repository = ref.watch(debtRepositoryProvider);
  return repository.getAllPayments();
});

/// Gamification data: streak + milestones computed from debts + payments.
final debtGamificationProvider = Provider<DebtGamification?>((ref) {
  final debts = ref.watch(debtsProvider).valueOrNull;
  final payments = ref.watch(allDebtPaymentsProvider).valueOrNull;
  if (debts == null || debts.isEmpty) return null;
  return DebtGamification.compute(debts: debts, payments: payments ?? []);
});

// ── Gamification value types ─────────────────────────────────────────────────

class DebtMilestone {
  final String debtName;
  final double progressPercent;
  final bool isComplete;
  final double? originalBalance;
  final double currentBalance;

  const DebtMilestone({
    required this.debtName,
    required this.progressPercent,
    required this.isComplete,
    this.originalBalance,
    required this.currentBalance,
  });

  int get nextMilestone {
    if (progressPercent >= 100) return 100;
    if (progressPercent >= 75) return 100;
    if (progressPercent >= 50) return 75;
    if (progressPercent >= 25) return 50;
    return 25;
  }

  double? get amountToNextMilestone {
    if (isComplete || originalBalance == null || originalBalance! <= 0) return null;
    if (progressPercent <= 0) return null;
    final targetBalance = originalBalance! * (1.0 - nextMilestone / 100.0);
    final delta = currentBalance - targetBalance;
    return delta > 0 ? delta : null;
  }
}

class DebtGamification {
  final int streakMonths;
  final List<DebtMilestone> milestones;
  final double totalPaidAllTime;
  final double? overallProgressPercent;

  const DebtGamification({
    required this.streakMonths,
    required this.milestones,
    required this.totalPaidAllTime,
    this.overallProgressPercent,
  });

  String get badgeTitle {
    if (streakMonths >= 12) return 'Debt Warrior';
    if (streakMonths >= 6) return 'Dedicated';
    if (streakMonths >= 3) return 'Consistent';
    if (streakMonths >= 1) return 'Getting Started';
    return 'Fresh Start';
  }

  String get badgeIcon {
    // Returns icon code to be rendered as icon, not emoji
    if (streakMonths >= 12) return 'trophy';
    if (streakMonths >= 6) return 'bolt';
    if (streakMonths >= 3) return 'flame';
    if (streakMonths >= 1) return 'rocket';
    return 'leaf';
  }

  int? get monthsToNextBadge {
    if (streakMonths >= 12) return null;
    if (streakMonths >= 6) return 12 - streakMonths;
    if (streakMonths >= 3) return 6 - streakMonths;
    if (streakMonths >= 1) return 3 - streakMonths;
    return 1;
  }

  String get nextBadgeIcon {
    if (streakMonths >= 12) return '';
    if (streakMonths >= 6) return 'trophy';
    if (streakMonths >= 3) return 'bolt';
    if (streakMonths >= 1) return 'flame';
    return 'rocket';
  }

  String get nextBadgeTitle {
    if (streakMonths >= 12) return '';
    if (streakMonths >= 6) return 'Debt Warrior';
    if (streakMonths >= 3) return 'Dedicated';
    if (streakMonths >= 1) return 'Consistent';
    return 'Getting Started';
  }

  factory DebtGamification.compute({
    required List<DebtEntity> debts,
    required List<DebtPaymentEntity> payments,
  }) {
    int streakMonths = 0;
    if (payments.isNotEmpty) {
      final monthsWithPayments = payments
          .map((p) => '${p.paymentDate.year}-${p.paymentDate.month}')
          .toSet();
      final now = DateTime.now();
      var checkYear = now.year;
      var checkMonth = now.month;
      for (var i = 0; i < 60; i++) {
        final key = '$checkYear-$checkMonth';
        if (monthsWithPayments.contains(key)) {
          streakMonths++;
        } else if (i > 0) {
          break;
        }
        checkMonth--;
        if (checkMonth == 0) {
          checkMonth = 12;
          checkYear--;
        }
      }
    }

    final milestones = debts.map((debt) {
      final original = debt.originalBalance;
      double progress = 0.0;
      if (original != null && original > 0) {
        progress = ((original - debt.balance) / original * 100).clamp(0.0, 100.0);
      }
      return DebtMilestone(
        debtName: debt.name,
        progressPercent: progress,
        isComplete: debt.balance <= 0,
        originalBalance: debt.originalBalance,
        currentBalance: debt.balance,
      );
    }).toList();

    // Sort milestones: incomplete by progress descending, completed at bottom
    milestones.sort((a, b) {
      if (a.isComplete != b.isComplete) return a.isComplete ? 1 : -1;
      return b.progressPercent.compareTo(a.progressPercent);
    });

    final totalPaid = payments.fold<double>(0, (s, p) => s + p.amount);

    // Calculate overall portfolio progress
    final debtsWithOriginal = debts
        .where((d) => d.originalBalance != null && d.originalBalance! > 0)
        .toList();

    double? overallProgressPercent;
    if (debtsWithOriginal.isNotEmpty) {
      final totalOriginal =
          debtsWithOriginal.fold<double>(0, (s, d) => s + d.originalBalance!);
      final totalPaidDown = debtsWithOriginal.fold<double>(0, (s, d) {
        final paid = (d.originalBalance! - d.balance).clamp(0.0, d.originalBalance!);
        return s + paid;
      });
      overallProgressPercent = (totalPaidDown / totalOriginal * 100).clamp(0.0, 100.0);
    }

    return DebtGamification(
      streakMonths: streakMonths,
      milestones: milestones,
      totalPaidAllTime: totalPaid,
      overallProgressPercent: overallProgressPercent,
    );
  }
}
