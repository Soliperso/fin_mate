import 'package:finmate/features/transactions/data/services/csv_import_service.dart';
import 'package:finmate/features/transactions/domain/entities/transaction_entity.dart';
import 'package:finmate/features/transactions/domain/entities/account_entity.dart';
import 'package:finmate/features/transactions/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';

// Builders
AccountEntity _account({
  required String id,
  required String name,
}) {
  return AccountEntity(
    id: id,
    userId: 'user-abc',
    name: name,
    balance: 0,
    type: AccountType.checking,
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 1),
  );
}

CategoryEntity _category({
  required String id,
  required String name,
  TransactionType type = TransactionType.expense,
}) {
  return CategoryEntity(
    id: id,
    name: name,
    color: '#FF000000',
    icon: 'food',
    type: type,
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 1),
  );
}

String _csv(List<Map<String, String>> rows) {
  const header = 'Date,Type,Amount,Account,Category,Description,Notes,Tags\n';
  return header +
      rows
          .map((r) {
            final cells = [
              r['date'] ?? '2025-01-15',
              r['type'] ?? 'expense',
              r['amount'] ?? '50.00',
              r['account'] ?? 'Checking',
              r['category'] ?? 'Food',
              r['description'] ?? '',
              r['notes'] ?? '',
              r['tags'] ?? '',
            ];
            // Quote cells that contain commas
            return cells
                .map((cell) => cell.contains(',') ? '"$cell"' : cell)
                .join(',');
          })
          .join('\n');
}

String _stringOfBytes(int byteCount) => 'A' * byteCount;

void main() {
  late CsvImportService svc;
  late List<AccountEntity> accounts;
  late List<CategoryEntity> categories;
  const userId = 'user-abc';

  setUp(() {
    svc = CsvImportService();
    accounts = [
      _account(id: 'acc-1', name: 'Checking'),
      _account(id: 'acc-2', name: 'Savings'),
    ];
    categories = [
      _category(id: 'cat-1', name: 'Food'),
      _category(id: 'cat-2', name: 'Transport'),
    ];
  });

  group('CsvImportService — file-level guards', () {
    test('accepts content at exactly 5 MB (5*1024*1024 bytes)', () {
      // Build a string exactly 5 MB, with valid header
      const contentSize = 5 * 1024 * 1024;
      final headerAndNewline = 'Date,Type,Amount,Account,Category,Description,Notes,Tags\nA';
      final padding = _stringOfBytes(contentSize - headerAndNewline.length);
      final content = headerAndNewline + padding;

      expect(content.length, contentSize);

      // Should not throw size error (may have other errors, but size is OK)
      final result = svc.parse(content, accounts, categories, userId);
      // Just verify it didn't throw the size guard
      expect(result, isNotNull);
    });

    test('rejects content at 5 MB + 1 byte', () {
      final content = _stringOfBytes((5 * 1024 * 1024) + 1);
      expect(
        () => svc.parse(content, accounts, categories, userId),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('too large'),
          ),
        ),
      );
    });

    test('rejects empty string', () {
      expect(
        () => svc.parse('', accounts, categories, userId),
        throwsA(isA<FormatException>()),
      );
    });

    test('accepts exactly 5000 data rows', () {
      final rows = List.generate(5000, (i) => {'date': '2025-01-15'});
      final content = _csv(rows);

      final result = svc.parse(content, accounts, categories, userId);
      expect(result.transactions.length + result.errors.length, 5000);
    });

    test('rejects 5001 data rows', () {
      final rows = List.generate(5001, (i) => {'date': '2025-01-15'});
      final content = _csv(rows);

      expect(
        () => svc.parse(content, accounts, categories, userId),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects mismatched headers', () {
      const content = 'Foo,Bar,Baz,Qux,Quux,Corge,Grault,Garply\n1,2,3,4,5,6,7,8\n';
      expect(
        () => svc.parse(content, accounts, categories, userId),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Not a valid'),
          ),
        ),
      );
    });

    test('accepts headers with extra trailing columns', () {
      const content =
          'Date,Type,Amount,Account,Category,Description,Notes,Tags,ExtraCol\n2025-01-15,expense,50.00,Checking,Food,lunch,none,\n';

      final result = svc.parse(content, accounts, categories, userId);
      expect(result.transactions, isNotEmpty);
    });
  });

  group('CsvImportService — date parsing', () {
    test('parses ISO date yyyy-MM-dd', () {
      final result = svc.parse(
        _csv([{'date': '2025-01-15'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.date, DateTime(2025, 1, 15));
    });

    test('parses MM/dd/yyyy', () {
      final result = svc.parse(
        _csv([{'date': '01/15/2025'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.date, DateTime(2025, 1, 15));
    });

    test('parses dd/MM/yyyy', () {
      final result = svc.parse(
        _csv([{'date': '15/01/2025'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.date, DateTime(2025, 1, 15));
    });

    test(
        'MM/dd is tried before dd/MM for ambiguous dates (06/07/2025 → June 7, not July 6)',
        () {
      final result = svc.parse(
        _csv([{'date': '06/07/2025'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.date, DateTime(2025, 6, 7));
    });

    test('skips row with unrecognised date format', () {
      final result = svc.parse(
        _csv([{'date': '2025.01.15'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.errors.length, 1);
    });
  });

  group('CsvImportService — amount parsing', () {
    test('strips commas from amounts (1,234.56 → 1234.56)', () {
      final result = svc.parse(
        _csv([{'amount': '1,234.56'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.amount, 1234.56);
    });

    test('rejects amount of zero', () {
      final result = svc.parse(
        _csv([{'amount': '0'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.errors.length, 1);
    });

    test('rejects negative amount', () {
      final result = svc.parse(
        _csv([{'amount': '-50.00'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.errors.length, 1);
    });

    test('rejects non-numeric amount', () {
      final result = svc.parse(
        _csv([{'amount': 'abc'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.errors.length, 1);
    });

    test('accepts positive decimal amount', () {
      final result = svc.parse(
        _csv([{'amount': '99.99'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.amount, 99.99);
    });
  });

  group('CsvImportService — type parsing', () {
    test('parses income (case-insensitive INCOME)', () {
      final result = svc.parse(
        _csv([{'type': 'INCOME'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.type, TransactionType.income);
    });

    test('parses expense', () {
      final result = svc.parse(
        _csv([{'type': 'expense'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.type, TransactionType.expense);
    });

    test('parses transfer', () {
      final result = svc.parse(
        _csv([{'type': 'transfer'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.type, TransactionType.transfer);
    });

    test('skips unknown type', () {
      final result = svc.parse(
        _csv([{'type': 'donation'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.errors.length, 1);
    });
  });

  group('CsvImportService — account matching', () {
    test('matches account case-insensitively', () {
      final result = svc.parse(
        _csv([{'account': 'CHECKING'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.accountId, 'acc-1');
    });

    test('skips row when account not found', () {
      final result = svc.parse(
        _csv([{'account': 'NonExistent'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.errors.length, 1);
    });

    test('skips row when account field is empty', () {
      final result = svc.parse(
        _csv([{'account': ''}]),
        accounts,
        categories,
        userId,
      );
      expect(result.errors.length, 1);
    });
  });

  group('CsvImportService — category matching', () {
    test('matches category case-insensitively', () {
      final result = svc.parse(
        _csv([{'category': 'FOOD'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.categoryId, 'cat-1');
    });

    test('leaves categoryId null when category field is empty', () {
      final result = svc.parse(
        _csv([{'category': ''}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.categoryId, isNull);
    });

    test('leaves categoryId null when category name not found', () {
      final result = svc.parse(
        _csv([{'category': 'NonExistent'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.categoryId, isNull);
    });
  });

  group('CsvImportService — tags parsing', () {
    test('splits tags on pipe character', () {
      final result = svc.parse(
        _csv([{'tags': 'food|dining'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.tags, ['food', 'dining']);
    });

    test('filters trailing/empty segments from pipe split ("food|dining|" → [food, dining])',
        () {
      final result = svc.parse(
        _csv([{'tags': 'food|dining|'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.tags, ['food', 'dining']);
      expect(result.transactions.first.tags!.length, 2);
    });

    test('returns null tags when tags field is empty', () {
      final result = svc.parse(
        _csv([{'tags': ''}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.tags, isNull);
    });

    test('trims whitespace from individual tags', () {
      final result = svc.parse(
        _csv([{'tags': ' food | dining '}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.tags, ['food', 'dining']);
    });
  });

  group('CsvImportService — blank row handling', () {
    test('skips completely blank data rows', () {
      const content = '''Date,Type,Amount,Account,Category,Description,Notes,Tags
2025-01-15,expense,50.00,Checking,Food,lunch,,
,,,,,,
2025-01-16,expense,75.00,Checking,Transport,bus,,''';

      final result = svc.parse(content, accounts, categories, userId);
      // Blank row should be filtered; 2 valid rows
      expect(result.transactions.length, 2);
    });
  });

  group('CsvImportService — result shape', () {
    test('returned transaction has correct userId', () {
      final result = svc.parse(
        _csv([{}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.userId, userId);
    });

    test('returned transaction has a non-empty UUID id', () {
      final result = svc.parse(
        _csv([{}]),
        accounts,
        categories,
        userId,
      );
      final id = result.transactions.first.id;
      expect(id, matches(RegExp(r'^[0-9a-f\-]{36}$')));
    });

    test('returned transaction.accountId matches the matched account entity id', () {
      final result = svc.parse(
        _csv([{'account': 'Checking'}]),
        accounts,
        categories,
        userId,
      );
      expect(result.transactions.first.accountId, 'acc-1');
    });
  });
}
