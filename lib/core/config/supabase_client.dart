import 'package:supabase_flutter/supabase_flutter.dart';

/// Global Supabase client instance
///
/// Usage:
/// ```dart
/// final user = supabase.auth.currentUser;
/// final data = await supabase.from('table_name').select();
/// ```
final supabase = Supabase.instance.client;
