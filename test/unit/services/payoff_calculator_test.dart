import 'package:flutter_test/flutter_test.dart';
import 'package:finmate/features/debt_payoff/domain/entities/debt_entity.dart';
import 'package:finmate/features/debt_payoff/domain/services/payoff_calculator.dart';

// Helpers
DebtEntity _debt({
  required String id,
  required String name,
  required double balance,
  required double interestRate,
  required double minimumPayment,
}) {
  final now = DateTime(2026, 3, 1);
  return DebtEntity(
    id: id,
    userId: 'user1',
    name: name,
    debtType: 'credit_card',
    balance: balance,
    interestRate: interestRate,
    minimumPayment: minimumPayment,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // Sarah's three debts used throughout
  final creditCard = _debt(
    id: 'cc',
    name: 'Chase Credit Card',
    balance: 4800,
    interestRate: 22.99,
    minimumPayment: 96,
  );
  final personalLoan = _debt(
    id: 'pl',
    name: 'Personal Loan',
    balance: 8500,
    interestRate: 11.5,
    minimumPayment: 210,
  );
  final autoLoan = _debt(
    id: 'al',
    name: 'Auto Loan',
    balance: 12000,
    interestRate: 6.9,
    minimumPayment: 285,
  );

  final debts = [creditCard, personalLoan, autoLoan];

  // ─────────────────────────────────────────────────────────────────────────
  group('PayoffCalculator — Avalanche (highest rate first)', () {
    late PayoffResult result;

    setUpAll(() {
      result = PayoffCalculator.compute(
        debts: debts,
        strategy: DebtStrategy.avalanche,
      );
    });

    test('produces a non-empty schedule', () {
      expect(result.schedule, isNotEmpty);
    });

    test('month 1 focus debt is Chase Credit Card (22.99% — highest rate)', () {
      expect(result.schedule.first.focusDebtName, 'Chase Credit Card');
    });

    test('total monthly payment in month 1 equals sum of all minimums (\$591)', () {
      final month1 = result.schedule.first;
      expect(month1.totalPaymentThisMonth, closeTo(591, 0.5));
    });

    test('all balances are zero at the end of the schedule', () {
      final last = result.schedule.last;
      final remaining = last.debtBalancesAfter.values.fold(0.0, (s, b) => s + b);
      expect(remaining, closeTo(0, 0.01));
    });

    test('total paid is greater than total original balance (\$25,300) due to interest', () {
      expect(result.totalPaid, greaterThan(25300));
    });

    test('total interest paid is positive', () {
      expect(result.totalInterestPaid, greaterThan(0));
    });

    test('debt-free date is in the future', () {
      expect(result.debtFreeDate.isAfter(DateTime.now()), isTrue);
    });

    test('schedule length matches totalMonths', () {
      expect(result.totalMonths, equals(result.schedule.length));
    });

    test('balances decrease monotonically over the schedule', () {
      double prev = result.schedule.first.totalBalance;
      for (final snap in result.schedule.skip(1)) {
        expect(snap.totalBalance, lessThanOrEqualTo(prev + 0.01));
        prev = snap.totalBalance;
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('PayoffCalculator — Snowball (lowest balance first)', () {
    late PayoffResult result;

    setUpAll(() {
      result = PayoffCalculator.compute(
        debts: debts,
        strategy: DebtStrategy.snowball,
      );
    });

    test('produces a non-empty schedule', () {
      expect(result.schedule, isNotEmpty);
    });

    test('month 1 focus debt is Chase Credit Card (\$4,800 — lowest balance)', () {
      // CC has the lowest balance among the three debts
      expect(result.schedule.first.focusDebtName, 'Chase Credit Card');
    });

    test('total monthly payment in month 1 equals sum of all minimums (\$591)', () {
      final month1 = result.schedule.first;
      expect(month1.totalPaymentThisMonth, closeTo(591, 0.5));
    });

    test('all balances are zero at the end of the schedule', () {
      final last = result.schedule.last;
      final remaining = last.debtBalancesAfter.values.fold(0.0, (s, b) => s + b);
      expect(remaining, closeTo(0, 0.01));
    });

    test('total paid is greater than total original balance (\$25,300)', () {
      expect(result.totalPaid, greaterThan(25300));
    });

    test('balances decrease monotonically', () {
      double prev = result.schedule.first.totalBalance;
      for (final snap in result.schedule.skip(1)) {
        expect(snap.totalBalance, lessThanOrEqualTo(prev + 0.01));
        prev = snap.totalBalance;
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('Avalanche vs Snowball — financial comparison', () {
    late PayoffResult avalanche;
    late PayoffResult snowball;

    setUpAll(() {
      avalanche = PayoffCalculator.compute(
        debts: debts,
        strategy: DebtStrategy.avalanche,
      );
      snowball = PayoffCalculator.compute(
        debts: debts,
        strategy: DebtStrategy.snowball,
      );
    });

    test('Avalanche pays less total interest than Snowball', () {
      // Mathematically optimal — Avalanche always wins on interest
      expect(avalanche.totalInterestPaid, lessThanOrEqualTo(snowball.totalInterestPaid));
    });

    test('Avalanche total paid is <= Snowball total paid', () {
      expect(avalanche.totalPaid, lessThanOrEqualTo(snowball.totalPaid));
    });

    test('both strategies reach debt-free within 50 years', () {
      expect(avalanche.totalMonths, lessThan(600));
      expect(snowball.totalMonths, lessThan(600));
    });

    test('interest savings reported correctly (avalanche - snowball delta)', () {
      final savings = snowball.totalInterestPaid - avalanche.totalInterestPaid;
      // Savings should be non-negative (Avalanche is always at least as good)
      expect(savings, greaterThanOrEqualTo(0));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('Extra payment simulation', () {
    test('extra \$200/month reduces total interest compared to no extra', () {
      final base = PayoffCalculator.compute(
        debts: debts,
        strategy: DebtStrategy.avalanche,
      );
      final withExtra = PayoffCalculator.compute(
        debts: debts,
        strategy: DebtStrategy.avalanche,
        extraMonthlyPayment: 200,
      );
      expect(withExtra.totalInterestPaid, lessThan(base.totalInterestPaid));
      expect(withExtra.totalMonths, lessThan(base.totalMonths));
    });

    test('extra payment shortens payoff timeline', () {
      final base = PayoffCalculator.compute(
        debts: debts,
        strategy: DebtStrategy.avalanche,
      );
      final withExtra = PayoffCalculator.compute(
        debts: debts,
        strategy: DebtStrategy.avalanche,
        extraMonthlyPayment: 500,
      );
      expect(withExtra.debtFreeDate.isBefore(base.debtFreeDate), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('Edge cases', () {
    test('empty debt list returns immediate debt-free result', () {
      final result = PayoffCalculator.compute(
        debts: [],
        strategy: DebtStrategy.avalanche,
      );
      expect(result.schedule, isEmpty);
      expect(result.totalPaid, 0);
      expect(result.totalInterestPaid, 0);
    });

    test('single zero-balance debt produces empty schedule', () {
      final zeroDbt = _debt(
        id: 'z',
        name: 'Zero',
        balance: 0,
        interestRate: 10,
        minimumPayment: 25,
      );
      final result = PayoffCalculator.compute(
        debts: [zeroDbt],
        strategy: DebtStrategy.avalanche,
      );
      expect(result.schedule, isEmpty);
    });

    test('minimum payment > monthly interest pays off debt (no infinite loop)', () {
      final highRate = _debt(
        id: 'hr',
        name: 'High Rate Card',
        balance: 1000,
        interestRate: 99.9, // extreme APR
        minimumPayment: 150, // must exceed monthly interest ($83.25)
      );
      final result = PayoffCalculator.compute(
        debts: [highRate],
        strategy: DebtStrategy.avalanche,
      );
      expect(result.schedule, isNotEmpty);
      expect(result.totalMonths, lessThan(600));
    });

    test('monthsToPayoffAtMinimum returns null when minimum <= monthly interest', () {
      // minimum $10 on $10,000 at 2% APR → monthly interest = $16.67 > $10
      final trapDebt = _debt(
        id: 'trap',
        name: 'Debt Trap',
        balance: 10000,
        interestRate: 2.0,
        minimumPayment: 10,
      );
      // monthly interest = 10000 * 2% / 12 = 16.67 > 10 minimum
      expect(trapDebt.monthsToPayoffAtMinimum, isNull);
    });

    test('monthsToPayoffAtMinimum returns value for zero-interest debt', () {
      final zeroRate = _debt(
        id: 'zr',
        name: 'Interest Free',
        balance: 1200,
        interestRate: 0,
        minimumPayment: 100,
      );
      expect(zeroRate.monthsToPayoffAtMinimum, equals(12));
    });
  });
}
