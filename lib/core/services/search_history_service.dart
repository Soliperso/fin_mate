import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _key = 'search_history_transactions';
  static const _max = 5;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final updated = [q, ...current.where((e) => e != q)].take(_max).toList();
    await prefs.setString(_key, jsonEncode(updated));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
