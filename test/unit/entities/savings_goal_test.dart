import 'package:flutter_test/flutter_test.dart';
import 'package:finmate/features/savings_goals/domain/entities/savings_goal_entity.dart';

SavingsGoal _goal({
  required double targetAmount,
  required double currentAmount,
  bool isCompleted = false,
  DateTime? deadline,
}) {
  final now = DateTime(2026, 3, 1);
  return SavingsGoal(
    id: 'g1',
    userId: 'user1',
    name: 'Test Goal',
    targetAmount: targetAmount,
    currentAmount: currentAmount,
    isCompleted: isCompleted,
    deadline: deadline,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('SavingsGoal — progress', () {
    test('returns correct percentage', () {
      final goal = _goal(targetAmount: 1000, currentAmount: 250);
      expect(goal.progress, 25.0);
    });

    test('is capped at 100 when currentAmount exceeds target', () {
      final goal = _goal(targetAmount: 1000, currentAmount: 1500);
      expect(goal.progress, 100.0);
    });

    test('returns 0 when currentAmount is 0', () {
      final goal = _goal(targetAmount: 1000, currentAmount: 0);
      expect(goal.progress, 0.0);
    });

    test('returns 0 when targetAmount is 0', () {
      final goal = _goal(targetAmount: 0, currentAmount: 0);
      expect(goal.progress, 0.0);
    });

    test('returns 100 when goal is fully funded', () {
      final goal = _goal(targetAmount: 500, currentAmount: 500);
      expect(goal.progress, 100.0);
    });
  });

  group('SavingsGoal — remainingAmount', () {
    test('returns correct remaining amount', () {
      final goal = _goal(targetAmount: 1000, currentAmount: 300);
      expect(goal.remainingAmount, 700.0);
    });

    test('returns 0 when fully funded', () {
      final goal = _goal(targetAmount: 500, currentAmount: 500);
      expect(goal.remainingAmount, 0.0);
    });

    test('returns 0 when overfunded (never negative)', () {
      final goal = _goal(targetAmount: 500, currentAmount: 600);
      expect(goal.remainingAmount, 0.0);
    });
  });

  group('SavingsGoal — isOverdue', () {
    test('returns false when no deadline is set', () {
      final goal = _goal(targetAmount: 1000, currentAmount: 0);
      expect(goal.isOverdue, isFalse);
    });

    test('returns false when deadline is in the future', () {
      final goal = _goal(
        targetAmount: 1000,
        currentAmount: 0,
        deadline: DateTime(2099, 12, 31),
      );
      expect(goal.isOverdue, isFalse);
    });

    test('returns true when deadline is in the past and goal is incomplete', () {
      final goal = _goal(
        targetAmount: 1000,
        currentAmount: 0,
        deadline: DateTime(2020, 1, 1),
      );
      expect(goal.isOverdue, isTrue);
    });

    test('returns false when goal is completed regardless of past deadline', () {
      final goal = _goal(
        targetAmount: 1000,
        currentAmount: 1000,
        isCompleted: true,
        deadline: DateTime(2020, 1, 1),
      );
      expect(goal.isOverdue, isFalse);
    });
  });

  group('SavingsGoal — daysRemaining', () {
    test('returns null when no deadline', () {
      final goal = _goal(targetAmount: 1000, currentAmount: 0);
      expect(goal.daysRemaining, isNull);
    });

    test('returns 0 when deadline has passed', () {
      final goal = _goal(
        targetAmount: 1000,
        currentAmount: 0,
        deadline: DateTime(2020, 1, 1),
      );
      expect(goal.daysRemaining, 0);
    });

    test('returns positive days for a future deadline', () {
      final goal = _goal(
        targetAmount: 1000,
        currentAmount: 0,
        deadline: DateTime.now().add(const Duration(days: 30)),
      );
      expect(goal.daysRemaining, greaterThan(0));
    });
  });
}
