import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Service for exporting user data in various formats
class DataExportService {
  /// Generate JSON export of all user data
  String generateJsonExport({
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> accounts,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> budgets,
  }) {
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'export_format_version': '1.0',
      'profile': profile,
      'accounts': accounts,
      'transactions': transactions,
      'budgets': budgets,
      'summary': {
        'total_accounts': accounts.length,
        'total_transactions': transactions.length,
        'total_budgets': budgets.length,
      }
    };

    return jsonEncode(exportData);
  }

  /// Generate CSV export from list of data
  String generateCsvExport(
    List<Map<String, dynamic>> data, {
    required String filename,
  }) {
    if (data.isEmpty) {
      return 'No data to export';
    }

    // Get headers from first item
    final headers = data.first.keys.toList();
    final csvBuffer = StringBuffer();

    // Add headers
    csvBuffer.writeln(headers.join(','));

    // Add rows
    for (final item in data) {
      final row = headers.map((header) {
        final value = item[header];
        // Handle null values and escape commas in strings
        if (value == null) {
          return '';
        }
        final stringValue = value.toString();
        if (stringValue.contains(',') || stringValue.contains('"')) {
          return '"${stringValue.replaceAll('"', '""')}"';
        }
        return stringValue;
      }).toList();
      csvBuffer.writeln(row.join(','));
    }

    return csvBuffer.toString();
  }

  /// Save JSON export to file and return file path
  Future<String> saveJsonExportToFile(String jsonData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'finmate_export_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonData);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save JSON export: $e');
    }
  }

  /// Save CSV export to file and return file path
  Future<String> saveCsvExportToFile(String csvData, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${filename}_export_$timestamp.csv';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csvData);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save CSV export: $e');
    }
  }

  /// Generate transaction CSV — human-readable, round-trippable for import.
  ///
  /// Headers: Date,Type,Amount,Account,Category,Description,Notes,Tags
  ///
  /// [dateFormat] must be one of: 'yyyy-MM-dd' (default), 'MM/dd/yyyy', 'dd/MM/yyyy'
  String generateTransactionsCsv(
    List<Map<String, dynamic>> transactions, {
    String dateFormat = 'yyyy-MM-dd',
  }) {
    if (transactions.isEmpty) {
      return 'No transactions to export';
    }

    final csvBuffer = StringBuffer();
    csvBuffer
        .writeln('Date,Type,Amount,Account,Category,Description,Notes,Tags');

    final fmt = DateFormat(dateFormat);

    for (final tx in transactions) {
      // Date
      final rawDate = tx['date'] ?? tx['created_at'] ?? '';
      String date = rawDate is String && rawDate.isNotEmpty
          ? rawDate.substring(0, 10) // ISO date portion
          : '';
      if (date.isNotEmpty) {
        try {
          date = fmt.format(DateTime.parse(date));
        } catch (_) {}
      }

      // Human-readable account / category names (joined fields preferred)
      final account = tx['account_name'] ?? tx['account_id'] ?? '';
      final category = tx['category_name'] ?? tx['category_id'] ?? '';

      // Tags — pipe-separated
      final rawTags = tx['tags'];
      String tags = '';
      if (rawTags is List) {
        tags = rawTags.join('|');
      } else if (rawTags is String && rawTags.isNotEmpty) {
        tags = rawTags;
      }

      final row = [
        _escapeCsvValue(date),
        _escapeCsvValue((tx['type'] ?? '').toString()),
        _escapeCsvValue((tx['amount'] ?? '').toString()),
        _escapeCsvValue(account.toString()),
        _escapeCsvValue(category.toString()),
        _escapeCsvValue((tx['description'] ?? '').toString()),
        _escapeCsvValue((tx['notes'] ?? '').toString()),
        _escapeCsvValue(tags),
      ];

      csvBuffer.writeln(row.join(','));
    }

    return csvBuffer.toString();
  }

  /// Generate budget CSV with formatted headers
  String generateBudgetsCsv(List<Map<String, dynamic>> budgets) {
    if (budgets.isEmpty) {
      return 'No budgets to export';
    }

    final csvBuffer = StringBuffer();

    // Custom headers
    csvBuffer.writeln(
        'Category,Budget Amount,Current Spending,Remaining,Period,Status');

    // Add rows with formatted data
    for (final budget in budgets) {
      final category = budget['category'] ?? '';
      final amount = budget['amount'] ?? '';
      final spent = budget['spent'] ?? 0;
      final remaining = (double.tryParse(amount.toString()) ?? 0) - spent;
      final period = budget['period'] ?? 'monthly';
      final status = budget['status'] ?? 'active';

      final row = [
        _escapeCsvValue(category),
        _escapeCsvValue(amount.toString()),
        _escapeCsvValue(spent.toString()),
        _escapeCsvValue(remaining.toString()),
        _escapeCsvValue(period),
        _escapeCsvValue(status),
      ];

      csvBuffer.writeln(row.join(','));
    }

    return csvBuffer.toString();
  }

  /// Helper method to escape CSV values
  String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
