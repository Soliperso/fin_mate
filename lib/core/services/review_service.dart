import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _keyFirstOpen = 'review_first_open';
  static const _keyTxCount = 'review_tx_count';
  static const _keyPrompted = 'review_prompted';
  static const _minDays = 3;
  static const _minTransactions = 5;

  /// Call once at app start to record the first-open timestamp.
  Future<void> recordAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_keyFirstOpen) == null) {
        await prefs.setString(_keyFirstOpen, DateTime.now().toIso8601String());
      }
    } catch (_) {}
  }

  /// Call after a new transaction is successfully saved.
  /// Increments the counter and shows the native review prompt when all
  /// conditions are met (3+ days since install, 5+ transactions, never shown).
  Future<void> maybePromptAfterTransaction() async {
    if (!kReleaseMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.getBool(_keyPrompted) == true) return;

      final count = (prefs.getInt(_keyTxCount) ?? 0) + 1;
      await prefs.setInt(_keyTxCount, count);

      final firstOpenStr = prefs.getString(_keyFirstOpen);
      if (firstOpenStr == null) return;
      final daysSinceInstall =
          DateTime.now().difference(DateTime.parse(firstOpenStr)).inDays;

      if (daysSinceInstall < _minDays || count < _minTransactions) return;

      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setBool(_keyPrompted, true);
      }
    } catch (_) {}
  }
}
