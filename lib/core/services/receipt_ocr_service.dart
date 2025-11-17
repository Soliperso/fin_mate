import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for extracting text from receipt images using Google ML Kit
class ReceiptOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from an image file
  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to extract text from receipt: $e');
    }
  }

  /// Process a receipt image and extract structured data
  /// Returns a map with extracted data
  Future<Map<String, dynamic>> processReceipt(String imagePath) async {
    try {
      final text = await extractText(imagePath);

      // Parse the extracted text to get receipt data
      final lines = text.split('\n');

      // Initialize parsed data
      var amount = 0.0;
      var merchantName = '';
      var date = DateTime.now();
      final items = <String>[];

      // Parse receipt lines
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        // Try to extract amount (look for currency symbols and numbers)
        final amountPattern = RegExp(r'[\$€£]?\s*(\d+[.,]\d{2})');
        final amountMatch = amountPattern.firstMatch(trimmedLine);
        if (amountMatch != null && amount == 0.0) {
          final amountStr = amountMatch.group(1)!.replaceAll(',', '.');
          amount = double.tryParse(amountStr) ?? 0.0;
        }

        // Try to extract merchant name (usually at the top)
        if (merchantName.isEmpty && trimmedLine.length > 5 && !trimmedLine.contains(RegExp(r'^\d'))) {
          merchantName = trimmedLine;
        }

        // Try to extract date (look for date patterns)
        final datePattern = RegExp(
          r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})',
        );
        final dateMatch = datePattern.firstMatch(trimmedLine);
        if (dateMatch != null) {
          try {
            final dateStr = dateMatch.group(0)!;
            // Try to parse date in different formats
            try {
              // Basic date parsing (improve as needed)
              final parts = dateStr.split(RegExp(r'[/-]'));
              if (parts.length == 3) {
                final year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
                final month = int.parse(parts[0]);
                final day = int.parse(parts[1]);
                date = DateTime(year, month, day);
              }
            } catch (_) {
              // Date parsing failed, use current date
            }
          } catch (_) {
            // Date parsing failed, use current date
          }
        }

        // Collect potential item descriptions
        if (trimmedLine.length > 3 &&
            !trimmedLine.contains(RegExp(r'^\d+\.\d{2}$')) &&
            !trimmedLine.contains(merchantName)) {
          items.add(trimmedLine);
        }
      }

      return {
        'text': text,
        'amount': amount,
        'merchant': merchantName.isNotEmpty ? merchantName : 'Receipt Item',
        'date': date,
        'items': items,
      };
    } catch (e) {
      throw Exception('Failed to process receipt: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
