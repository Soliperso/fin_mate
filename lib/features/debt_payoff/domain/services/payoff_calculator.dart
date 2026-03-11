import 'dart:math';
import '../entities/debt_entity.dart';

enum DebtStrategy { avalanche, snowball }

/// Result of a debt payoff simulation.
class PayoffResult {
  final DateTime debtFreeDate;
  final double totalInterestPaid;
  final double totalPaid;
  final List<MonthlySnapshot> schedule;

  const PayoffResult({
    required this.debtFreeDate,
    required this.totalInterestPaid,
    required this.totalPaid,
    required this.schedule,
  });

  int get totalMonths => schedule.length;
}

/// A single month in the payoff schedule.
class MonthlySnapshot {
  final int month; // 1-based
  final DateTime date;
  final double totalBalance;
  final double interestThisMonth;
  final double totalPaymentThisMonth;
  final String focusDebtName;

  const MonthlySnapshot({
    required this.month,
    required this.date,
    required this.totalBalance,
    required this.interestThisMonth,
    required this.totalPaymentThisMonth,
    required this.focusDebtName,
  });
}

/// Pure Dart amortization engine — no I/O, fully synchronous.
class PayoffCalculator {
  static const int _maxMonths = 600; // 50-year safety cap

  /// Compute payoff schedule for the given [debts] using [strategy].
  /// [extraMonthlyPayment] is added to the focus debt each month.
  static PayoffResult compute({
    required List<DebtEntity> debts,
    required DebtStrategy strategy,
    double extraMonthlyPayment = 0,
  }) {
    if (debts.isEmpty) {
      return PayoffResult(
        debtFreeDate: DateTime.now(),
        totalInterestPaid: 0,
        totalPaid: 0,
        schedule: [],
      );
    }

    // Work with mutable state
    final balances = <String, double>{
      for (final d in debts) d.id: max(0.0, d.balance),
    };
    final monthlyRates = <String, double>{
      for (final d in debts) d.id: d.interestRate / 100.0 / 12.0,
    };
    final minimums = <String, double>{
      for (final d in debts) d.id: d.minimumPayment,
    };
    final nameMap = <String, String>{
      for (final d in debts) d.id: d.name,
    };

    double totalInterest = 0;
    double totalPaid = 0;
    final schedule = <MonthlySnapshot>[];

    final now = DateTime.now();

    for (int month = 1; month <= _maxMonths; month++) {
      final activeIds = debts
          .map((d) => d.id)
          .where((id) => balances[id]! > 0.001)
          .toList();

      if (activeIds.isEmpty) break;

      // --- Step 1: Sort by strategy to find focus debt ---
      activeIds.sort((a, b) {
        if (strategy == DebtStrategy.avalanche) {
          // Highest rate first
          final rateA = debts.firstWhere((d) => d.id == a).interestRate;
          final rateB = debts.firstWhere((d) => d.id == b).interestRate;
          return rateB.compareTo(rateA);
        } else {
          // Lowest balance first
          return balances[a]!.compareTo(balances[b]!);
        }
      });

      final focusId = activeIds.first;
      double interestThisMonth = 0;
      double paymentThisMonth = 0;

      // --- Step 2: Accrue interest on all active debts ---
      for (final id in activeIds) {
        final interest = balances[id]! * monthlyRates[id]!;
        balances[id] = balances[id]! + interest;
        interestThisMonth += interest;
        totalInterest += interest;
      }

      // --- Step 3: Pay minimums on non-focus debts ---
      double budgetRemaining = activeIds.fold<double>(
        extraMonthlyPayment,
        (sum, id) => sum + minimums[id]!,
      );

      for (final id in activeIds.skip(1)) {
        final payment = min(minimums[id]!, balances[id]!);
        balances[id] = balances[id]! - payment;
        paymentThisMonth += payment;
        budgetRemaining -= payment;
        totalPaid += payment;
      }

      // --- Step 4: Apply remaining budget to focus debt ---
      final focusPayment = min(budgetRemaining, balances[focusId]!);
      balances[focusId] = balances[focusId]! - focusPayment;
      paymentThisMonth += focusPayment;
      totalPaid += focusPayment;

      // Clamp near-zero balances to prevent floating point drift
      for (final id in activeIds) {
        if (balances[id]! < 0.01) balances[id] = 0.0;
      }

      final totalBalance = balances.values.fold<double>(0, (s, b) => s + b);

      schedule.add(MonthlySnapshot(
        month: month,
        date: DateTime(now.year, now.month + month, 1),
        totalBalance: totalBalance,
        interestThisMonth: interestThisMonth,
        totalPaymentThisMonth: paymentThisMonth,
        focusDebtName: nameMap[focusId]!,
      ));
    }

    final debtFreeDate = schedule.isNotEmpty
        ? schedule.last.date
        : DateTime.now().add(const Duration(days: 1));

    return PayoffResult(
      debtFreeDate: debtFreeDate,
      totalInterestPaid: totalInterest,
      totalPaid: totalPaid,
      schedule: schedule,
    );
  }
}
