import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data_export_service.dart';

/// Manages automatic periodic backups to Supabase Storage.
class AutoBackupService {
  static const _lastBackupKey = 'auto_backup_last_run';
  static const _bucket = 'backups';

  final _exportService = DataExportService();

  /// Returns the last backup timestamp, or null if never backed up.
  Future<DateTime?> lastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_lastBackupKey);
    return ts != null ? DateTime.tryParse(ts) : null;
  }

  /// Returns true if a backup should run given [schedule] ('daily' or 'weekly').
  Future<bool> shouldRunBackup(String schedule) async {
    if (schedule == 'off') return false;
    final last = await lastBackupDate();
    if (last == null) return true;
    final now = DateTime.now();
    if (schedule == 'daily') {
      return now.difference(last).inHours >= 24;
    }
    // weekly
    return now.difference(last).inDays >= 7;
  }

  /// Collects all user data, serialises to JSON, and uploads to Supabase Storage.
  /// Returns the storage path on success.
  Future<String> runBackup() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;

    // Gather data
    final profile = await _fetchProfile(client, userId);
    final accounts = await _fetchAll(client, 'accounts', userId);
    final transactions = await _fetchAll(client, 'transactions', userId);
    final budgets = await _fetchAll(client, 'budgets', userId);

    final json = _exportService.generateJsonExport(
      profile: profile,
      accounts: accounts,
      transactions: transactions,
      budgets: budgets,
    );

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final path = '$userId/backup_$timestamp.json';

    await client.storage.from(_bucket).uploadBinary(
          path,
          utf8.encode(json),
          fileOptions: const FileOptions(contentType: 'application/json'),
        );

    return path;
  }

  /// Persists the current timestamp as the last successful backup time.
  Future<void> markBackupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
  }

  /// Reads the user's backup schedule from Supabase and runs a backup if due.
  /// Call this once on app startup after auth resolves.
  Future<void> runIfDue() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final row = await client
          .from('user_settings')
          .select('notification_preferences')
          .eq('id', userId)
          .maybeSingle();

      final prefs = (row?['notification_preferences'] as Map?)?.cast<String, dynamic>() ?? {};
      final schedule = prefs['auto_backup_schedule'] as String? ?? 'off';

      if (!await shouldRunBackup(schedule)) return;

      await runBackup();
      await markBackupComplete();
    } catch (_) {
      // Auto backup is non-fatal
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _fetchProfile(
      SupabaseClient client, String userId) async {
    try {
      final data = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAll(
      SupabaseClient client, String table, String userId) async {
    try {
      final data = await client.from(table).select().eq('user_id', userId);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }
}
