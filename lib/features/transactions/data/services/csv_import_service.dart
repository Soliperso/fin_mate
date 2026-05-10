import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/category_entity.dart';

/// Result of a CSV import parse attempt.
class CsvImportResult {
  final List<TransactionEntity> transactions;
  final List<String> errors; // row-level messages for skipped rows

  const CsvImportResult({
    required this.transactions,
    required this.errors,
  });
}

/// Parses a Finmate-exported transactions CSV and converts rows into
/// [TransactionEntity] objects ready for insertion.
class CsvImportService {
  static const _expectedHeaders = [
    'Date',
    'Type',
    'Amount',
    'Account',
    'Category',
    'Description',
    'Notes',
    'Tags',
  ];

  static final _dateParsers = [
    DateFormat('yyyy-MM-dd'),
    DateFormat('MM/dd/yyyy'),
    DateFormat('dd/MM/yyyy'),
  ];

  static final _uuid = Uuid();

  static const _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const _maxDataRows = 5000;

  CsvImportResult parse(
    String csvContent,
    List<AccountEntity> accounts,
    List<CategoryEntity> categories,
    String userId,
  ) {
    // Guard: reject files that are too large before attempting to parse.
    if (csvContent.length > _maxFileSizeBytes) {
      throw const FormatException(
        'File is too large. Maximum allowed size is 5 MB.',
      );
    }

    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);

    if (rows.isEmpty) {
      throw const FormatException('The file is empty.');
    }

    // Guard: reject imports with an unreasonable number of rows.
    if (rows.length - 1 > _maxDataRows) {
      throw FormatException(
        'Too many rows (${rows.length - 1}). Maximum allowed is $_maxDataRows rows per import.',
      );
    }

    // Validate headers (case-insensitive)
    final headers =
        rows.first.map((h) => h.toString().trim().toLowerCase()).toList();
    final expected = _expectedHeaders.map((h) => h.toLowerCase()).toList();
    if (!_headersMatch(headers, expected)) {
      throw const FormatException(
        'Not a valid Finmate CSV.\n'
        'Expected headers: Date, Type, Amount, Account, Category, '
        'Description, Notes, Tags',
      );
    }

    final transactions = <TransactionEntity>[];
    final errors = <String>[];
    final now = DateTime.now();

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty ||
          (row.length == 1 && row.first.toString().trim().isEmpty)) {
        continue; // skip blank trailing rows
      }

      final rowNum = i + 1;

      // Pad missing columns so we can always index 0–7
      final cells = List<String>.generate(
        8,
        (j) => j < row.length ? row[j].toString().trim() : '',
      );

      // ── Date ──────────────────────────────────────────────────────
      final date = _parseDate(cells[0]);
      if (date == null) {
        errors.add('Row $rowNum: unrecognised date "${cells[0]}" — skipped.');
        continue;
      }

      // ── Type ──────────────────────────────────────────────────────
      final type = _parseType(cells[1]);
      if (type == null) {
        errors.add('Row $rowNum: unknown type "${cells[1]}" — skipped.');
        continue;
      }

      // ── Amount ────────────────────────────────────────────────────
      final amount = double.tryParse(cells[2].replaceAll(',', ''));
      if (amount == null || amount == 0) {
        errors.add('Row $rowNum: invalid amount "${cells[2]}" — skipped.');
        continue;
      }
      if (amount < 0) {
        errors.add(
          'Row $rowNum: negative amount "${cells[2]}" — use the Type column '
          '(income/expense/transfer) to indicate direction.',
        );
        continue;
      }

      // ── Account (required) ────────────────────────────────────────
      final account = _matchAccount(cells[3], accounts);
      if (account == null) {
        errors.add('Row $rowNum: account "${cells[3]}" not found — skipped.');
        continue;
      }

      // ── Category (optional — null = uncategorised) ────────────────
      final category = _matchCategory(cells[4], categories);

      // ── Tags ──────────────────────────────────────────────────────
      final tags = cells[7].isEmpty
          ? null
          : cells[7]
              .split('|')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();

      transactions.add(TransactionEntity(
        id: _uuid.v4(),
        userId: userId,
        accountId: account.id,
        categoryId: category?.id,
        type: type,
        amount: amount,
        description: cells[5].isEmpty ? null : cells[5],
        notes: cells[6].isEmpty ? null : cells[6],
        date: date,
        tags: tags,
        createdAt: now,
        updatedAt: now,
        categoryName: category?.name,
        accountName: account.name,
      ));
    }

    return CsvImportResult(transactions: transactions, errors: errors);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _headersMatch(List<String> actual, List<String> expected) {
    if (actual.length < expected.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (actual[i] != expected[i]) return false;
    }
    return true;
  }

  DateTime? _parseDate(String raw) {
    for (final fmt in _dateParsers) {
      try {
        return fmt.parseStrict(raw);
      } catch (_) {}
    }
    return null;
  }

  TransactionType? _parseType(String raw) {
    switch (raw.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return null;
    }
  }

  AccountEntity? _matchAccount(String name, List<AccountEntity> accounts) {
    if (name.isEmpty) return null;
    final lower = name.toLowerCase();
    try {
      return accounts.firstWhere(
        (a) => a.name.toLowerCase() == lower,
      );
    } catch (_) {
      return null;
    }
  }

  CategoryEntity? _matchCategory(String name, List<CategoryEntity> categories) {
    if (name.isEmpty) return null;
    final lower = name.toLowerCase();
    try {
      return categories.firstWhere(
        (c) => c.name.toLowerCase() == lower,
      );
    } catch (_) {
      return null;
    }
  }
}
