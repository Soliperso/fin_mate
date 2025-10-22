import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('Currency Formatting', () {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    );

    test('should format positive amounts correctly', () {
      expect(currencyFormat.format(1000.0), '\$1,000.00');
      expect(currencyFormat.format(50.5), '\$50.50');
      expect(currencyFormat.format(0.99), '\$0.99');
    });

    test('should format zero correctly', () {
      expect(currencyFormat.format(0.0), '\$0.00');
    });

    test('should format large amounts with commas', () {
      expect(currencyFormat.format(1000000.0), '\$1,000,000.00');
      expect(currencyFormat.format(10000.0), '\$10,000.00');
    });

    test('should handle decimal precision', () {
      final result = currencyFormat.format(99.999);
      expect(result, contains('100.00')); // Rounds to 100.00
    });

    test('should format small decimal amounts', () {
      expect(currencyFormat.format(0.01), '\$0.01');
      expect(currencyFormat.format(0.1), '\$0.10');
    });
  });

  group('Date Formatting', () {
    final dateFormat = DateFormat('MMM dd, yyyy');

    test('should format dates correctly', () {
      final date = DateTime(2024, 1, 15);
      expect(dateFormat.format(date), 'Jan 15, 2024');
    });

    test('should format current date', () {
      final now = DateTime.now();
      final formatted = dateFormat.format(now);
      expect(formatted.isNotEmpty, true);
      expect(formatted.length, greaterThan(10));
    });

    test('should handle different months', () {
      expect(
        dateFormat.format(DateTime(2024, 12, 25)),
        'Dec 25, 2024',
      );
      expect(
        dateFormat.format(DateTime(2024, 6, 30)),
        'Jun 30, 2024',
      );
    });
  });

  group('Percentage Formatting', () {
    test('should format percentages correctly', () {
      final percent = (50 / 100) * 100;
      expect(percent.toStringAsFixed(1), '50.0');
    });

    test('should handle zero percentage', () {
      final percent = (0 / 100) * 100;
      expect(percent.toStringAsFixed(1), '0.0');
    });

    test('should handle decimal percentages', () {
      final percent = (33.33 / 100) * 100;
      expect(percent.toStringAsFixed(2), '33.33');
    });
  });
}
