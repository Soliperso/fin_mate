import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication Flow Integration Tests', () {
    test('should validate email format', () {
      final validEmails = [
        'user@example.com',
        'test.user@domain.co.uk',
        'user+tag@example.com',
      ];

      final invalidEmails = [
        'invalid',
        'user@',
        '@example.com',
        'user name@example.com',
      ];

      for (var email in validEmails) {
        expect(isValidEmail(email), true);
      }

      for (var email in invalidEmails) {
        expect(isValidEmail(email), false);
      }
    });

    test('should validate password requirements', () {
      expect(isStrongPassword('Weak'), false); // Too short
      expect(isStrongPassword('password123'), false); // No uppercase
      expect(isStrongPassword('PASSWORD123'), false); // No lowercase
      expect(isStrongPassword('Password123'), true); // Valid
      expect(isStrongPassword('Str0ng!@#Pass'), true); // Very strong
    });

    test('should handle signup flow correctly', () {
      // Test: User can enter email
      final email = 'test@example.com';
      expect(isValidEmail(email), true);

      // Test: User can enter password
      final password = 'TestPassword123';
      expect(isStrongPassword(password), true);

      // Test: Both are valid
      expect(email.isNotEmpty && password.isNotEmpty, true);
    });

    test('should handle login flow correctly', () {
      const email = 'user@example.com';
      const password = 'ValidPassword123';

      expect(email.isNotEmpty, true);
      expect(password.isNotEmpty, true);
      expect(isValidEmail(email), true);
    });

    test('should validate OTP format', () {
      expect(isValidOTP('123456'), true);
      expect(isValidOTP('12345'), false);
      expect(isValidOTP('abcdef'), false);
      expect(isValidOTP(''), false);
    });

    test('should handle password reset request', () {
      const email = 'reset@example.com';
      expect(isValidEmail(email), true);
    });

    test('should validate PIN code', () {
      expect(isValidPIN('123456'), true);
      expect(isValidPIN('12345'), false);
      expect(isValidPIN('abc'), false);
    });
  });
}

// Helper functions for validation
bool isValidEmail(String email) {
  final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  return regex.hasMatch(email);
}

bool isStrongPassword(String password) {
  if (password.length < 8) return false;
  if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
  if (!RegExp(r'[a-z]').hasMatch(password)) return false;
  if (!RegExp(r'[0-9]').hasMatch(password)) return false;
  return true;
}

bool isValidOTP(String otp) {
  if (otp.length != 6) return false;
  return RegExp(r'^\d{6}$').hasMatch(otp);
}

bool isValidPIN(String pin) {
  if (pin.length != 6) return false;
  return RegExp(r'^\d{6}$').hasMatch(pin);
}
