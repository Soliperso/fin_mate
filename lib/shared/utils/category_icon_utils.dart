import 'package:flutter/cupertino.dart' show CupertinoIcons, IconData;

const _iconKeyMap = <String, IconData>{
  // Finance / Income
  'money_dollar_circle': CupertinoIcons.money_dollar_circle,
  'briefcase': CupertinoIcons.briefcase,
  'chart_bar_alt_fill': CupertinoIcons.chart_bar_alt_fill,
  'arrow_up_circle_fill': CupertinoIcons.arrow_up_circle_fill,
  'gift': CupertinoIcons.gift,
  'percent': CupertinoIcons.percent,
  'building_2_fill': CupertinoIcons.building_2_fill,
  'paintbrush_fill': CupertinoIcons.paintbrush_fill,
  'person_2_fill': CupertinoIcons.person_2_fill,
  'camera_fill': CupertinoIcons.camera_fill,
  'music_note': CupertinoIcons.music_note,
  'globe': CupertinoIcons.globe,
  'doc_text_fill': CupertinoIcons.doc_text_fill,
  'envelope_fill': CupertinoIcons.envelope_fill,
  // Food, Home & Transport
  'cart': CupertinoIcons.cart,
  'bag': CupertinoIcons.bag,
  'drop_fill': CupertinoIcons.drop_fill,
  'house': CupertinoIcons.house,
  'bolt': CupertinoIcons.bolt,
  'flame': CupertinoIcons.flame,
  'hammer_fill': CupertinoIcons.hammer_fill,
  'wrench_fill': CupertinoIcons.wrench_fill,
  'car_detailed': CupertinoIcons.car_detailed,
  'airplane': CupertinoIcons.airplane,
  'tram_fill': CupertinoIcons.tram_fill,
  // Lifestyle & Entertainment
  'scissors': CupertinoIcons.scissors,
  'sparkles': CupertinoIcons.sparkles,
  'bed_double_fill': CupertinoIcons.bed_double_fill,
  'heart': CupertinoIcons.heart,
  'book': CupertinoIcons.book,
  'desktopcomputer': CupertinoIcons.desktopcomputer,
  'film': CupertinoIcons.film,
  'tv_fill': CupertinoIcons.tv_fill,
  'gamecontroller_fill': CupertinoIcons.gamecontroller_fill,
  'headphones': CupertinoIcons.headphones,
  // Communication & Finance
  'phone_fill': CupertinoIcons.phone_fill,
  'wifi': CupertinoIcons.wifi,
  'creditcard': CupertinoIcons.creditcard,
  'person_crop_circle': CupertinoIcons.person_crop_circle,
  'arrow_right_arrow_left': CupertinoIcons.arrow_right_arrow_left,
  'tag': CupertinoIcons.tag,
};

/// Icon options shown when editing an **income** category.
const incomeIconOptions = <(String, IconData, String)>[
  ('money_dollar_circle', CupertinoIcons.money_dollar_circle, 'Income'),
  ('briefcase', CupertinoIcons.briefcase, 'Salary'),
  ('chart_bar_alt_fill', CupertinoIcons.chart_bar_alt_fill, 'Invest'),
  ('arrow_up_circle_fill', CupertinoIcons.arrow_up_circle_fill, 'Savings'),
  ('gift', CupertinoIcons.gift, 'Gift'),
  ('percent', CupertinoIcons.percent, 'Bonus'),
  ('building_2_fill', CupertinoIcons.building_2_fill, 'Business'),
  ('paintbrush_fill', CupertinoIcons.paintbrush_fill, 'Creative'),
  ('person_2_fill', CupertinoIcons.person_2_fill, 'Freelance'),
  ('camera_fill', CupertinoIcons.camera_fill, 'Media'),
  ('music_note', CupertinoIcons.music_note, 'Royalties'),
  ('globe', CupertinoIcons.globe, 'Online'),
  ('doc_text_fill', CupertinoIcons.doc_text_fill, 'Contract'),
  ('house', CupertinoIcons.house, 'Rental'),
  ('car_detailed', CupertinoIcons.car_detailed, 'Vehicle'),
  ('bag', CupertinoIcons.bag, 'Sales'),
  ('envelope_fill', CupertinoIcons.envelope_fill, 'Invoice'),
  ('arrow_right_arrow_left', CupertinoIcons.arrow_right_arrow_left, 'Transfer'),
  ('tag', CupertinoIcons.tag, 'Other'),
];

/// Icon options shown when editing an **expense** category.
const expenseIconOptions = <(String, IconData, String)>[
  ('cart', CupertinoIcons.cart, 'Groceries'),
  ('bag', CupertinoIcons.bag, 'Dining'),
  ('drop_fill', CupertinoIcons.drop_fill, 'Drinks'),
  ('house', CupertinoIcons.house, 'Rent'),
  ('bolt', CupertinoIcons.bolt, 'Utilities'),
  ('flame', CupertinoIcons.flame, 'Gas'),
  ('phone_fill', CupertinoIcons.phone_fill, 'Phone'),
  ('wifi', CupertinoIcons.wifi, 'Internet'),
  ('car_detailed', CupertinoIcons.car_detailed, 'Transport'),
  ('airplane', CupertinoIcons.airplane, 'Travel'),
  ('tram_fill', CupertinoIcons.tram_fill, 'Transit'),
  ('scissors', CupertinoIcons.scissors, 'Beauty'),
  ('heart', CupertinoIcons.heart, 'Health'),
  ('sparkles', CupertinoIcons.sparkles, 'Luxury'),
  ('bed_double_fill', CupertinoIcons.bed_double_fill, 'Hotel'),
  ('book', CupertinoIcons.book, 'Education'),
  ('desktopcomputer', CupertinoIcons.desktopcomputer, 'Tech'),
  ('film', CupertinoIcons.film, 'Movies'),
  ('tv_fill', CupertinoIcons.tv_fill, 'Streaming'),
  ('gamecontroller_fill', CupertinoIcons.gamecontroller_fill, 'Gaming'),
  ('music_note', CupertinoIcons.music_note, 'Music'),
  ('headphones', CupertinoIcons.headphones, 'Audio'),
  ('hammer_fill', CupertinoIcons.hammer_fill, 'Repairs'),
  ('wrench_fill', CupertinoIcons.wrench_fill, 'Maintenance'),
  ('creditcard', CupertinoIcons.creditcard, 'Debt'),
  ('doc_text_fill', CupertinoIcons.doc_text_fill, 'Insurance'),
  ('person_crop_circle', CupertinoIcons.person_crop_circle, 'Personal'),
  ('envelope_fill', CupertinoIcons.envelope_fill, 'Postage'),
  ('tag', CupertinoIcons.tag, 'Other'),
];

/// Single source of truth for mapping a category to its display icon.
///
/// Priority: explicit [iconKey] → name-based matching → default tag.
IconData getCategoryIcon(String? categoryName, {String? type, String? iconKey}) {
  if (iconKey != null && _iconKeyMap.containsKey(iconKey)) {
    return _iconKeyMap[iconKey]!;
  }

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
  if (cat.contains('food') || cat.contains('dining') || cat.contains('groceries')) {
    return CupertinoIcons.cart;
  }
  if (cat.contains('restaurant') || cat.contains('cafe') || cat.contains('coffee')) {
    return CupertinoIcons.bag;
  }
  if (cat.contains('transport') || cat.contains('fuel') || cat.contains('gas')) {
    return CupertinoIcons.car_detailed;
  }
  if (cat.contains('travel') || cat.contains('flight')) return CupertinoIcons.airplane;
  if (cat.contains('shopping')) return CupertinoIcons.bag;
  if (cat.contains('entertainment') || cat.contains('movie')) return CupertinoIcons.film;
  if (cat.contains('utilities') || cat.contains('bill') || cat.contains('electric')) {
    return CupertinoIcons.bolt;
  }
  if (cat.contains('health') || cat.contains('medical') || cat.contains('doctor')) {
    return CupertinoIcons.heart;
  }
  if (cat.contains('education') || cat.contains('school') || cat.contains('course')) {
    return CupertinoIcons.book;
  }
  if (cat.contains('housing') || cat.contains('rent') || cat.contains('mortgage')) {
    return CupertinoIcons.house;
  }
  if (cat.contains('subscri') || cat.contains('stream')) return CupertinoIcons.tv_fill;
  if (cat.contains('phone') || cat.contains('mobile')) return CupertinoIcons.phone_fill;
  if (cat.contains('internet') || cat.contains('wifi')) return CupertinoIcons.wifi;

  return CupertinoIcons.tag;
}
