import 'package:flutter/cupertino.dart' show CupertinoIcons, IconData;

/// Single source of truth for mapping a category name to its display icon.
///
/// [categoryName] — the category's name string (case-insensitive).
/// [type]         — optional transaction type: 'income', 'expense', 'transfer'.
IconData getCategoryIcon(String? categoryName, {String? type}) {
  final cat = (categoryName ?? '').toLowerCase();

  if (type == 'transfer') return CupertinoIcons.arrow_right_arrow_left;

  // Income
  if (cat.contains('salary')) return CupertinoIcons.briefcase;
  if (cat.contains('freelance')) return CupertinoIcons.desktopcomputer;
  if (cat.contains('investment')) return CupertinoIcons.chart_bar_alt_fill;
  if (cat.contains('gift')) return CupertinoIcons.gift;
  if (cat.contains('saving')) return CupertinoIcons.arrow_up_circle_fill;
  if (type == 'income') return CupertinoIcons.money_dollar_circle;

  // Expense
  if (cat.contains('food') || cat.contains('dining')) return CupertinoIcons.cart;
  if (cat.contains('transport') || cat.contains('gas')) return CupertinoIcons.car_detailed;
  if (cat.contains('shopping')) return CupertinoIcons.bag;
  if (cat.contains('entertainment')) return CupertinoIcons.film;
  if (cat.contains('utilities') || cat.contains('bill')) return CupertinoIcons.bolt;
  if (cat.contains('health') || cat.contains('medical')) return CupertinoIcons.heart;
  if (cat.contains('education') || cat.contains('school')) return CupertinoIcons.book;
  if (cat.contains('housing') || cat.contains('rent') || cat.contains('mortgage')) {
    return CupertinoIcons.house;
  }
  if (cat.contains('personal') && cat.contains('care')) {
    return CupertinoIcons.person_crop_circle;
  }

  return CupertinoIcons.tag;
}
