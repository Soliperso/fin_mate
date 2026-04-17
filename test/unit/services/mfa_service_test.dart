import 'package:finmate/core/services/mfa_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MfaService svc;

  setUp(() {
    svc = MfaService();
  });

  group('MfaService — generateTotpSecret', () {
    late String secret;

    setUpAll(() {
      svc = MfaService();
      secret = svc.generateTotpSecret();
    });

    test('secret is exactly 32 characters', () {
      expect(secret.length, 32);
    });

    test('secret uses only Base32 alphabet [A-Z2-7]', () {
      expect(secret, matches(RegExp(r'^[A-Z2-7]+$')));
    });

    test(
        'generates a different secret on each call (non-deterministic)',
        () {
      final secret1 = svc.generateTotpSecret();
      final secret2 = svc.generateTotpSecret();
      expect(secret1, isNot(equals(secret2)));
    });
  });

  group('MfaService — generateTotpUri', () {
    test('produces otpauth://totp/ prefix', () {
      final uri = svc.generateTotpUri(
        email: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );
      expect(uri, startsWith('otpauth://totp/'));
    });

    test('URI contains the secret parameter', () {
      final uri = svc.generateTotpUri(
        email: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );
      expect(uri, contains('secret=JBSWY3DPEHPK3PXP'));
    });

    test('URI contains the issuer parameter', () {
      final uri = svc.generateTotpUri(
        email: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );
      expect(uri, contains('issuer=Finmate'));
    });

    test('email is percent-encoded in the URI path', () {
      final uri = svc.generateTotpUri(
        email: 'user+tag@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );
      expect(uri, contains('user%2Btag%40example.com'));
    });

    test('custom issuer replaces default Finmate', () {
      final uri = svc.generateTotpUri(
        email: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
        issuer: 'MyApp',
      );
      expect(uri, contains('issuer=MyApp'));
    });

    test('URI contains algorithm=SHA1 and digits=6 and period=30', () {
      final uri = svc.generateTotpUri(
        email: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );
      expect(uri, contains('algorithm=SHA1'));
      expect(uri, contains('digits=6'));
      expect(uri, contains('period=30'));
    });
  });

  group('MfaService — formatOtpCode', () {
    test('formats 6-digit code as "XXX XXX"', () {
      expect(svc.formatOtpCode('123456'), '123 456');
    });

    test('returns code unchanged when not exactly 6 digits', () {
      expect(svc.formatOtpCode('12345'), '12345');
    });

    test('returns code unchanged for 7-digit input', () {
      expect(svc.formatOtpCode('1234567'), '1234567');
    });
  });

  group('MfaService — isValidOtpFormat', () {
    test('returns true for 6-digit numeric string', () {
      expect(svc.isValidOtpFormat('123456'), isTrue);
    });

    test('returns true for code with space "123 456"', () {
      expect(svc.isValidOtpFormat('123 456'), isTrue);
    });

    test('returns false for 5-digit code', () {
      expect(svc.isValidOtpFormat('12345'), isFalse);
    });

    test('returns false for 7-digit code', () {
      expect(svc.isValidOtpFormat('1234567'), isFalse);
    });

    test('returns false for alpha characters', () {
      expect(svc.isValidOtpFormat('abc123'), isFalse);
    });

    test('returns false for empty string', () {
      expect(svc.isValidOtpFormat(''), isFalse);
    });
  });

  group('MfaService — cleanOtpCode', () {
    test('removes spaces from code', () {
      expect(svc.cleanOtpCode('123 456'), '123456');
    });

    test('returns unchanged string with no spaces', () {
      expect(svc.cleanOtpCode('123456'), '123456');
    });

    test('trims leading/trailing whitespace', () {
      expect(svc.cleanOtpCode(' 123456 '), '123456');
    });
  });

  group('MfaService — getRemainingSeconds', () {
    test('returns value between 1 and 30 inclusive', () {
      final result = svc.getRemainingSeconds();
      expect(result, greaterThanOrEqualTo(1));
      expect(result, lessThanOrEqualTo(30));
    });

    test('result equals 30 - (currentSecond % 30)', () {
      final result = svc.getRemainingSeconds();
      final expected = 30 - (DateTime.now().second % 30);
      // Use closeTo tolerance to handle second boundary race condition
      expect(result, closeTo(expected, 1));
    });
  });
}
