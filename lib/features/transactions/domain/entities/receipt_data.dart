/// Entity representing extracted receipt data
class ReceiptData {
  final String fullText;
  final double amount; // grand total
  final double subtotal; // pre-tax total (0 if not found)
  final double tax; // total tax (0 if not found)
  final double tip; // tip / gratuity (0 if not found)
  final String merchant;
  final DateTime date;
  final List<String> items; // "Item Name — $price" or plain description

  ReceiptData({
    required this.fullText,
    required this.amount,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.tip = 0.0,
    required this.merchant,
    required this.date,
    required this.items,
  });

  ReceiptData copyWith({
    String? fullText,
    double? amount,
    double? subtotal,
    double? tax,
    double? tip,
    String? merchant,
    DateTime? date,
    List<String>? items,
  }) {
    return ReceiptData(
      fullText: fullText ?? this.fullText,
      amount: amount ?? this.amount,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      tip: tip ?? this.tip,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      items: items ?? this.items,
    );
  }

  @override
  String toString() =>
      'ReceiptData(merchant: $merchant, total: $amount, tax: $tax, items: ${items.length})';
}
