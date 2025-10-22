import 'package:flutter_test/flutter_test.dart';
import 'package:fin_mate/features/transactions/domain/entities/account_entity.dart';

void main() {
  group('AccountEntity', () {
    final now = DateTime.now();

    test('should create an account entity', () {
      final account = AccountEntity(
        id: '1',
        userId: 'user1',
        name: 'Checking',
        type: AccountType.checking,
        balance: 1000.0,
        currency: 'USD',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(account.id, '1');
      expect(account.name, 'Checking');
      expect(account.type, AccountType.checking);
      expect(account.balance, 1000.0);
      expect(account.currency, 'USD');
      expect(account.isActive, true);
    });

    test('should support different account types', () {
      final types = [
        AccountType.cash,
        AccountType.checking,
        AccountType.savings,
        AccountType.creditCard,
        AccountType.investment,
      ];

      for (var type in types) {
        final account = AccountEntity(
          id: '1',
          userId: 'user1',
          name: 'Test Account',
          type: type,
          balance: 0,
          currency: 'USD',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(account.type, type);
      }
    });

    test('should support copying with modifications', () {
      final original = AccountEntity(
        id: '1',
        userId: 'user1',
        name: 'Checking',
        type: AccountType.checking,
        balance: 1000.0,
        currency: 'USD',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final modified = original.copyWith(balance: 1500.0, isActive: false);

      expect(modified.balance, 1500.0);
      expect(modified.isActive, false);
      expect(modified.name, 'Checking'); // unchanged
      expect(original.balance, 1000.0); // original unchanged
    });

    test('should support equality comparison', () {
      final account1 = AccountEntity(
        id: '1',
        userId: 'user1',
        name: 'Checking',
        type: AccountType.checking,
        balance: 1000.0,
        currency: 'USD',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final account2 = AccountEntity(
        id: '1',
        userId: 'user1',
        name: 'Checking',
        type: AccountType.checking,
        balance: 1000.0,
        currency: 'USD',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(account1, equals(account2));
    });

    test('should handle inactive accounts', () {
      final account = AccountEntity(
        id: '1',
        userId: 'user1',
        name: 'Old Checking',
        type: AccountType.checking,
        balance: 0,
        currency: 'USD',
        isActive: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(account.isActive, false);
    });
  });
}
