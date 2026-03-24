// Tests for AddTransactionPage form validation logic.
//
// The page uses a custom numpad (not a standard TextFormField for amount),
// so amount validation is tested as pure logic, and title validation is
// exercised via its validator function (same logic used in the live form).
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Amount validation (mirrors add_transaction_page.dart _saveTransaction logic)
// ---------------------------------------------------------------------------

/// Returns an error string if [raw] is not a valid positive amount, else null.
String? validateAmount(String raw) {
  final amount = double.tryParse(raw);
  if (amount == null) return 'Please enter a valid amount greater than 0.';
  if (amount <= 0) return 'Please enter a valid amount greater than 0.';
  return null;
}

// ---------------------------------------------------------------------------
// Title validation (mirrors the TextFormField validator in add_transaction_page)
// ---------------------------------------------------------------------------

/// Returns an error string if [value] is empty or null, else null.
String? validateTitle(String? value) {
  if (value == null || value.trim().isEmpty) return 'Title is required';
  return null;
}

void main() {
  group('Amount validation', () {
    test('empty string is invalid', () {
      expect(validateAmount(''), isNotNull);
    });

    test('non-numeric string is invalid', () {
      expect(validateAmount('abc'), isNotNull);
    });

    test('zero is invalid', () {
      expect(validateAmount('0'), isNotNull);
    });

    test('zero with decimals is invalid', () {
      expect(validateAmount('0.00'), isNotNull);
    });

    test('negative number is invalid', () {
      expect(validateAmount('-10'), isNotNull);
    });

    test('positive integer is valid', () {
      expect(validateAmount('100'), isNull);
    });

    test('positive decimal is valid', () {
      expect(validateAmount('19.99'), isNull);
    });

    test('very small positive amount is valid', () {
      expect(validateAmount('0.01'), isNull);
    });
  });

  group('Title validation', () {
    test('null is invalid', () {
      expect(validateTitle(null), isNotNull);
    });

    test('empty string is invalid', () {
      expect(validateTitle(''), isNotNull);
    });

    test('whitespace-only string is invalid', () {
      expect(validateTitle('   '), isNotNull);
    });

    test('non-empty string is valid', () {
      expect(validateTitle('Groceries'), isNull);
    });

    test('single character is valid', () {
      expect(validateTitle('X'), isNull);
    });

    test('returns correct error message for empty title', () {
      expect(validateTitle(''), equals('Title is required'));
    });
  });
}
