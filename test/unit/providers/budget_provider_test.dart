import 'package:flutter_test/flutter_test.dart';
import 'package:finmate/features/budgets/domain/entities/budget_entity.dart';

BudgetEntity _budget({
  required double amount,
  double? spent,
  double? remaining,
  bool carryOverEnabled = false,
  double lastCarryOverAmount = 0,
}) {
  final now = DateTime(2026, 3, 1);
  return BudgetEntity(
    id: 'b1',
    userId: 'user1',
    amount: amount,
    period: BudgetPeriod.monthly,
    startDate: now,
    isActive: true,
    createdAt: now,
    updatedAt: now,
    spent: spent,
    remaining: remaining,
    carryOverEnabled: carryOverEnabled,
    lastCarryOverAmount: lastCarryOverAmount,
  );
}

void main() {
  group('BudgetEntity — spentPercentage', () {
    test('returns 0 when spent is null', () {
      final budget = _budget(amount: 500);
      expect(budget.spentPercentage, 0.0);
    });

    test('returns correct percentage', () {
      final budget = _budget(amount: 500, spent: 250);
      expect(budget.spentPercentage, 50.0);
    });

    test('returns > 100 when over budget', () {
      final budget = _budget(amount: 500, spent: 600);
      expect(budget.spentPercentage, greaterThan(100));
    });

    test('returns 0 when effectiveAmount is 0', () {
      final budget = _budget(amount: 0, spent: 50);
      expect(budget.spentPercentage, 0.0);
    });
  });

  group('BudgetEntity — isExceeded', () {
    test('returns false when spent is null', () {
      expect(_budget(amount: 500).isExceeded, isFalse);
    });

    test('returns false when spent is equal to amount', () {
      expect(_budget(amount: 500, spent: 500).isExceeded, isFalse);
    });

    test('returns false when spent is under amount', () {
      expect(_budget(amount: 500, spent: 400).isExceeded, isFalse);
    });

    test('returns true when spent exceeds amount', () {
      expect(_budget(amount: 500, spent: 501).isExceeded, isTrue);
    });
  });

  group('BudgetEntity — isNearLimit', () {
    test('returns false when spent is well under limit', () {
      expect(_budget(amount: 500, spent: 100).isNearLimit, isFalse);
    });

    test('returns true when spent is exactly 80%', () {
      expect(_budget(amount: 500, spent: 400).isNearLimit, isTrue);
    });

    test('returns true when spent is between 80% and 100%', () {
      expect(_budget(amount: 500, spent: 450).isNearLimit, isTrue);
    });

    test('returns false when budget is exceeded (isExceeded takes precedence)', () {
      expect(_budget(amount: 500, spent: 600).isNearLimit, isFalse);
    });
  });

  group('BudgetEntity — effectiveAmount with carry-over', () {
    test('ignores carry-over when disabled', () {
      final budget = _budget(
        amount: 500,
        carryOverEnabled: false,
        lastCarryOverAmount: 100,
      );
      expect(budget.effectiveAmount, 500.0);
    });

    test('adds carry-over surplus when enabled', () {
      final budget = _budget(
        amount: 500,
        carryOverEnabled: true,
        lastCarryOverAmount: 50,
      );
      expect(budget.effectiveAmount, 550.0);
    });

    test('subtracts carry-over deficit when enabled', () {
      final budget = _budget(
        amount: 500,
        carryOverEnabled: true,
        lastCarryOverAmount: -80,
      );
      expect(budget.effectiveAmount, 420.0);
    });
  });
}
