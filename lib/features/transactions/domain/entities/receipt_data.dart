/// Entity representing extracted receipt data
class ReceiptData {
  final String fullText;
  final double amount;
  final String merchant;
  final DateTime date;
  final List<String> items;

  ReceiptData({
    required this.fullText,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.items,
  });

  /// Create a copy with modified fields
  ReceiptData copyWith({
    String? fullText,
    double? amount,
    String? merchant,
    DateTime? date,
    List<String>? items,
  }) {
    return ReceiptData(
      fullText: fullText ?? this.fullText,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      items: items ?? this.items,
    );
  }

  @override
  String toString() =>
      'ReceiptData(amount: $amount, merchant: $merchant, date: $date, items: ${items.length})';
}
