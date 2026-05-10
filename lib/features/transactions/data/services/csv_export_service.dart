import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction_entity.dart';

class CsvExportService {
  static const _headers = [
    'Date',
    'Type',
    'Amount',
    'Account',
    'Category',
    'Description',
    'Notes',
    'Tags',
  ];

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  String export(List<TransactionEntity> transactions) {
    final rows = <List<dynamic>>[_headers];

    for (final t in transactions) {
      rows.add([
        _dateFormat.format(t.date),
        t.type.name,
        t.amount.toStringAsFixed(2),
        t.accountName ?? '',
        t.categoryName ?? '',
        t.description ?? '',
        t.notes ?? '',
        t.tags?.join(';') ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}
