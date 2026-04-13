import 'dart:convert';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

/// Extracts structured data from receipt images using Google ML Kit OCR.
/// AI parsing is attempted first via the Supabase openai-proxy Edge Function;
/// falls back to regex parsing when the user is unauthenticated or the proxy
/// is unavailable.
class ReceiptOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to extract text from receipt: $e');
    }
  }

  Future<Map<String, dynamic>> processReceipt(String imagePath) async {
    try {
      final text = await extractText(imagePath);
      final lines = text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      // Try AI parsing via server-side proxy first.
      // Falls back to regex parsing if the user is unauthenticated or the
      // proxy returns an error.
      final aiResult = await _parseWithAI(text);
      if (aiResult != null) return aiResult;

      // Fall back to regex parsing
      final merchant = _extractMerchant(lines);
      final date = _extractDate(lines);
      final total = _extractTotal(lines);
      final subtotal = _extractSubtotal(lines);
      final tax = _extractTax(lines);
      final tip = _extractTip(lines);
      final items = _extractItems(lines);

      return {
        'text': text,
        'amount': total,
        'subtotal': subtotal,
        'tax': tax,
        'tip': tip,
        'merchant': merchant,
        'date': date,
        'items': items,
        'aiParsed': false,
      };
    } catch (e) {
      throw Exception('Failed to process receipt: $e');
    }
  }

  Future<Map<String, dynamic>?> _parseWithAI(String rawText) async {
    try {
      // Route through the Supabase Edge Function proxy so the OpenAI key
      // never leaves the server.  Falls back to regex parsing if the user
      // is not authenticated or the proxy is unavailable.
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return null;

      final proxyUrl =
          '${EnvConfig.supabaseUrl}/functions/v1/openai-proxy';
      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
          'apikey': EnvConfig.supabaseAnonKey,
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a receipt parser. Extract structured data from receipt OCR text. '
                  'Return ONLY valid JSON — no markdown, no explanation — with exactly these fields:\n'
                  '{\n'
                  '  "merchant": string,\n'
                  '  "date": "YYYY-MM-DD",\n'
                  '  "subtotal": number | null,\n'
                  '  "tax": number | null,\n'
                  '  "tip": number | null,\n'
                  '  "total": number,\n'
                  '  "items": [{"name": string, "price": number}]\n'
                  '}\n'
                  'Use null for fields not found. Items should only include purchasable products/services, '
                  'not summary rows like tax or total.',
            },
            {
              'role': 'user',
              'content': 'Parse this receipt:\n\n$rawText',
            },
          ],
          'max_tokens': 1000,
          'temperature': 0,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return null;

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final content =
          (decoded['choices'] as List).first['message']['content'] as String;

      // Strip markdown fences if model wraps response
      final cleaned = content
          .trim()
          .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*', multiLine: true), '')
          .trim();

      final parsed = json.decode(cleaned) as Map<String, dynamic>;

      DateTime date = DateTime.now();
      if (parsed['date'] != null) {
        try {
          date = DateTime.parse(parsed['date'] as String);
        } catch (_) {}
      }

      final rawItems = (parsed['items'] as List?) ?? [];
      final items = rawItems
          .map((item) {
            final name = (item['name'] as String?)?.trim() ?? '';
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            if (name.isEmpty) return '';
            if (price > 0) return '$name — \$${price.toStringAsFixed(2)}';
            return name;
          })
          .where((s) => s.isNotEmpty)
          .toList();

      return {
        'text': rawText,
        'merchant': (parsed['merchant'] as String?)?.trim() ?? 'Receipt Item',
        'date': date,
        'subtotal': (parsed['subtotal'] as num?)?.toDouble() ?? 0.0,
        'tax': (parsed['tax'] as num?)?.toDouble() ?? 0.0,
        'tip': (parsed['tip'] as num?)?.toDouble() ?? 0.0,
        'amount': (parsed['total'] as num?)?.toDouble() ?? 0.0,
        'items': items,
        'aiParsed': true,
      };
    } catch (_) {
      return null;
    }
  }

  // ── Merchant ────────────────────────────────────────────────

  String _extractMerchant(List<String> lines) {
    for (final line in lines.take(6)) {
      // Skip phone numbers
      if (RegExp(r'\d{3}[-.\s]\d{3}[-.\s]\d{4}').hasMatch(line)) continue;
      // Skip street addresses (start with a number)
      if (RegExp(r'^\d+\s+[A-Za-z]').hasMatch(line)) continue;
      // Skip city/state/zip lines
      if (RegExp(r'\b[A-Z]{2}\s+\d{5}\b').hasMatch(line)) continue;
      // Skip URLs and emails
      final lower = line.toLowerCase();
      if (lower.contains('@') ||
          lower.contains('www.') ||
          lower.contains('.com')) {
        continue;
      }
      // Skip pure numbers or very short strings
      if (line.length < 3) continue;
      if (RegExp(r'^\d+([.,]\d+)?$').hasMatch(line)) continue;
      return line;
    }
    return 'Receipt Item';
  }

  // ── Date ────────────────────────────────────────────────────

  DateTime _extractDate(List<String> lines) {
    const monthNames = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    for (final line in lines) {
      // ISO: 2024-01-15
      final iso = RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})').firstMatch(line);
      if (iso != null) {
        try {
          return DateTime(
            int.parse(iso.group(1)!),
            int.parse(iso.group(2)!),
            int.parse(iso.group(3)!),
          );
        } catch (_) {}
      }

      // Written month: Jan 15, 2024 / January 15 2024
      final written = RegExp(
        r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*[\s.]+(\d{1,2})[,\s]+(\d{4})',
        caseSensitive: false,
      ).firstMatch(line);
      if (written != null) {
        try {
          final month =
              monthNames[written.group(1)!.toLowerCase().substring(0, 3)]!;
          return DateTime(
            int.parse(written.group(3)!),
            month,
            int.parse(written.group(2)!),
          );
        } catch (_) {}
      }

      // Numeric: MM/DD/YYYY or DD/MM/YYYY
      final numeric =
          RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(line);
      if (numeric != null) {
        try {
          final a = int.parse(numeric.group(1)!);
          final b = int.parse(numeric.group(2)!);
          var year = int.parse(numeric.group(3)!);
          if (year < 100) year += 2000;
          if (a <= 12 && b <= 31) return DateTime(year, a, b); // MM/DD
          if (b <= 12 && a <= 31) return DateTime(year, b, a); // DD/MM
        } catch (_) {}
      }
    }
    return DateTime.now();
  }

  // ── Totals ───────────────────────────────────────────────────

  /// Grand total — looks for TOTAL / BALANCE / AMOUNT DUE keywords.
  /// Falls back to the largest monetary amount on the receipt.
  double _extractTotal(List<String> lines) {
    final keywords = RegExp(
      r'\b(grand\s+total|total\s+due|amount\s+due|balance\s+due|total\s+amount|balance|total)\b',
      caseSensitive: false,
    );
    double best = 0.0;
    for (final line in lines) {
      if (keywords.hasMatch(line)) {
        final v = _amountFromLine(line);
        if (v > best) best = v;
      }
    }
    if (best > 0) return best;

    // Fallback: largest amount anywhere
    for (final line in lines) {
      final v = _amountFromLine(line);
      if (v > best) best = v;
    }
    return best;
  }

  double _extractSubtotal(List<String> lines) {
    final keywords = RegExp(
      r'\b(sub[\s-]?total|merchandise|items?\s+total)\b',
      caseSensitive: false,
    );
    for (final line in lines) {
      if (keywords.hasMatch(line)) {
        final v = _amountFromLine(line);
        if (v > 0) return v;
      }
    }
    return 0.0;
  }

  double _extractTax(List<String> lines) {
    final keywords = RegExp(
      r'\b(tax|hst|gst|pst|vat|sales\s+tax|state\s+tax|city\s+tax|local\s+tax)\b',
      caseSensitive: false,
    );
    double total = 0.0;
    for (final line in lines) {
      if (keywords.hasMatch(line)) {
        total += _amountFromLine(line);
      }
    }
    return total;
  }

  double _extractTip(List<String> lines) {
    final keywords = RegExp(
      r'\b(tip|gratuity|service\s+charge|service\s+fee)\b',
      caseSensitive: false,
    );
    for (final line in lines) {
      if (keywords.hasMatch(line)) {
        final v = _amountFromLine(line);
        if (v > 0) return v;
      }
    }
    return 0.0;
  }

  // ── Items ────────────────────────────────────────────────────

  List<String> _extractItems(List<String> lines) {
    final pricePattern = RegExp(r'[\$£€]?\s*(\d{1,6}[.,]\d{2})(?!\s*%)');

    // Always skip these regardless of whether a price is present
    final alwaysSkipUrl = RegExp(r'(www\.|\.com|\.net|\.org|@)');
    final alwaysSkipPhone = RegExp(r'\d{3}[-.\s]\d{3}[-.\s]\d{4}');
    final alwaysSkipNoLetters = RegExp(r'^[^a-zA-Z]+$');

    // Summary rows that already appear in the extracted card — skip even if
    // they carry a price so they don't duplicate information
    final summaryRow = RegExp(
      r'^(total|grand\s+total|subtotal|sub[\s\-]?total|'
      r'tax|hst|gst|pst|vat|sales\s+tax|'
      r'tip|gratuity|service\s+charge|'
      r'cash|change\s+due|balance\s+due|amount\s+due|amount\s+paid)',
      caseSensitive: false,
    );

    // For lines WITHOUT a price, apply stricter filtering to remove store
    // metadata, greetings, date/time, receipt numbers, etc.
    final metadataLine = RegExp(
      r'^(receipt|order|trans|invoice|check|ticket|ref|reg|store|'
      r'cashier|server|clerk|operator|terminal|till|pos|'
      r'table|seat|guest|member|card|auth|approval|'
      r'date|time|open|close|hour|'
      r'tel|fax|phone|address|'
      r'thank|welcome|come\s+again|have\s+a|enjoy|'
      r'visit\s+us|follow\s+us|loyalty|points|reward|earn)',
      caseSensitive: false,
    );
    // Street address pattern: starts with a number followed by a word
    final addressLine = RegExp(r'^\d+\s+[A-Za-z]');
    // Date/time line
    final dateTimeLine = RegExp(
      r'(\d{1,2}[:/]\d{2}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
    );

    final items = <String>[];

    for (final line in lines) {
      if (line.length < 3) continue;
      if (alwaysSkipNoLetters.hasMatch(line)) continue;
      if (alwaysSkipPhone.hasMatch(line)) continue;
      if (alwaysSkipUrl.hasMatch(line)) continue;
      if (summaryRow.hasMatch(line)) continue;

      final priceMatch = pricePattern.firstMatch(line);

      if (priceMatch != null) {
        // Line has a price — very likely a real item, keep it
        final rawName = line
            .substring(0, priceMatch.start)
            .replaceAll(RegExp(r'[\s.·\-]{2,}'), ' ')
            .trim();
        final rawPrice = priceMatch
            .group(0)!
            .replaceAll(RegExp(r'[^\d.,]'), '')
            .replaceAll(',', '.');
        final price = double.tryParse(rawPrice);
        if (rawName.length >= 2 && price != null && price > 0) {
          items.add('$rawName — \$${price.toStringAsFixed(2)}');
        } else {
          items.add(line);
        }
      } else {
        // No price — apply stricter metadata filter before including
        if (metadataLine.hasMatch(line)) continue;
        if (addressLine.hasMatch(line)) continue;
        if (dateTimeLine.hasMatch(line)) continue;
        items.add(line);
      }
    }

    return items;
  }

  // ── Helpers ──────────────────────────────────────────────────

  /// Returns the largest monetary value found in [line].
  /// Excludes numbers followed by % (tax rates, discounts expressed as %).
  double _amountFromLine(String line) {
    final pattern = RegExp(r'[\$£€]?\s*(\d{1,6}[.,]\d{2})(?!\s*%)');
    double best = 0.0;
    for (final m in pattern.allMatches(line)) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0.0;
      if (v > best) best = v;
    }
    return best;
  }

  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
