import 'package:flutter_test/flutter_test.dart';
import 'package:fin_mate/features/transactions/domain/entities/transaction_entity.dart';

void main() {
  group('TransactionEntity', () {
    final now = DateTime.now();

    test('should create a transaction entity', () {
      final transaction = TransactionEntity(
        id: '1',
        userId: 'user1',
        type: TransactionType.expense,
        amount: 50.0,
        description: 'Coffee',
        notes: 'Morning coffee',
        date: now,
        accountId: 'account1',
        categoryId: 'category1',
        createdAt: now,
        updatedAt: now,
      );

      expect(transaction.id, '1');
      expect(transaction.userId, 'user1');
      expect(transaction.type, TransactionType.expense);
      expect(transaction.amount, 50.0);
      expect(transaction.description, 'Coffee');
    });

    test('should create an income transaction', () {
      final transaction = TransactionEntity(
        id: '2',
        userId: 'user1',
        type: TransactionType.income,
        amount: 3000.0,
        description: 'Salary',
        date: now,
        accountId: 'account1',
        categoryId: 'category1',
        createdAt: now,
        updatedAt: now,
      );

      expect(transaction.type, TransactionType.income);
      expect(transaction.amount, 3000.0);
    });

    test('should support copying with modifications', () {
      final original = TransactionEntity(
        id: '1',
        userId: 'user1',
        type: TransactionType.expense,
        amount: 50.0,
        description: 'Coffee',
        date: now,
        accountId: 'account1',
        categoryId: 'category1',
        createdAt: now,
        updatedAt: now,
      );

      final modified = original.copyWith(amount: 75.0);

      expect(modified.amount, 75.0);
      expect(modified.description, 'Coffee'); // unchanged
      expect(original.amount, 50.0); // original unchanged
    });

    test('should support large transaction amounts', () {
      final transaction = TransactionEntity(
        id: '1',
        userId: 'user1',
        type: TransactionType.expense,
        amount: 999999.99,
        description: 'Large purchase',
        date: now,
        accountId: 'account1',
        categoryId: 'category1',
        createdAt: now,
        updatedAt: now,
      );

      expect(transaction.amount, equals(999999.99));
    });

    test('should support equality comparison', () {
      final transaction1 = TransactionEntity(
        id: '1',
        userId: 'user1',
        type: TransactionType.expense,
        amount: 50.0,
        description: 'Coffee',
        date: now,
        accountId: 'account1',
        categoryId: 'category1',
        createdAt: now,
        updatedAt: now,
      );

      final transaction2 = TransactionEntity(
        id: '1',
        userId: 'user1',
        type: TransactionType.expense,
        amount: 50.0,
        description: 'Coffee',
        date: now,
        accountId: 'account1',
        categoryId: 'category1',
        createdAt: now,
        updatedAt: now,
      );

      expect(transaction1, equals(transaction2));
    });
  });
}
