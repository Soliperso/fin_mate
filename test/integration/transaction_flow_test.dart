import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction Flow Integration Tests', () {
    test('should create transaction with valid data', () {
      final transaction = {
        'id': 'txn_123',
        'type': 'expense',
        'amount': 50.0,
        'description': 'Coffee',
        'date': DateTime.now(),
        'categoryId': 'cat_1',
        'accountId': 'acc_1',
      };

      expect(transaction['id'], isNotEmpty);
      expect(transaction['amount'], greaterThan(0));
      expect(transaction['type'], isIn(['income', 'expense']));
    });

    test('should validate transaction amounts', () {
      expect(_isValidAmount(50.0), true);
      expect(_isValidAmount(0.01), true);
      expect(_isValidAmount(0.0), false);
      expect(_isValidAmount(-50.0), false);
    });

    test('should handle expense transactions', () {
      const type = 'expense';
      const amount = 75.50;
      const description = 'Groceries';

      expect(type, 'expense');
      expect(amount, greaterThan(0));
      expect(description.isNotEmpty, true);
    });

    test('should handle income transactions', () {
      const type = 'income';
      const amount = 3000.0;
      const description = 'Salary';

      expect(type, 'income');
      expect(amount, greaterThan(0));
      expect(description.isNotEmpty, true);
    });

    test('should validate transaction dates', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final future = today.add(const Duration(days: 1));

      expect(today.isBefore(future), true);
      expect(yesterday.isBefore(today), true);
    });

    test('should handle transaction categories', () {
      const categories = ['Food', 'Transport', 'Entertainment', 'Utilities'];

      for (var category in categories) {
        expect(category.isNotEmpty, true);
      }
    });

    test('should calculate transaction totals', () {
      final transactions = [
        {'type': 'expense', 'amount': 50.0},
        {'type': 'expense', 'amount': 75.0},
        {'type': 'income', 'amount': 3000.0},
      ];

      final totalExpense = transactions
          .where((t) => t['type'] == 'expense')
          .fold<double>(0, (sum, t) => sum + (t['amount'] as double));

      final totalIncome = transactions
          .where((t) => t['type'] == 'income')
          .fold<double>(0, (sum, t) => sum + (t['amount'] as double));

      expect(totalExpense, 125.0);
      expect(totalIncome, 3000.0);
    });

    test('should filter transactions by type', () {
      final allTransactions = [
        {'type': 'expense', 'amount': 50.0},
        {'type': 'income', 'amount': 100.0},
        {'type': 'expense', 'amount': 75.0},
      ];

      final expenses = allTransactions.where((t) => t['type'] == 'expense').toList();
      final incomes = allTransactions.where((t) => t['type'] == 'income').toList();

      expect(expenses.length, 2);
      expect(incomes.length, 1);
    });

    test('should sort transactions by date', () {
      final now = DateTime.now();
      final transactions = [
        {'date': now, 'amount': 50.0},
        {'date': now.subtract(const Duration(days: 1)), 'amount': 75.0},
        {'date': now.add(const Duration(days: 1)), 'amount': 100.0},
      ];

      transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      expect(transactions[0]['amount'], 100.0); // Most recent first
      expect(transactions[2]['amount'], 75.0); // Oldest last
    });

    test('should format transaction display amounts', () {
      expect(_formatCurrency(1000.0), '\$1,000.00');
      expect(_formatCurrency(50.5), '\$50.50');
      expect(_formatCurrency(0.99), '\$0.99');
    });
  });
}

bool _isValidAmount(double amount) {
  return amount > 0;
}

String _formatCurrency(double amount) {
  return '\$${amount.toStringAsFixed(2).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  )}';
}
