import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as flutter_widgets;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';

/// Watches the Riverpod settings state and keeps the easy_localization locale
/// in sync. Also wraps the widget tree with [Directionality] so Arabic (RTL)
/// works without changing individual widgets.
class LocaleBridge extends ConsumerWidget {
  final Widget child;
  const LocaleBridge({required this.child, super.key});

  static const _supportedCodes = {'en', 'fr', 'es', 'ar'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsOperationsProvider);

    settingsAsync.whenData((settings) {
      if (settings == null) return;
      final code = settings.language;
      if (!_supportedCodes.contains(code)) return;
      final target = Locale(code);
      if (context.locale != target) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          await context.setLocale(target);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_locale', code);
        });
      }
    });

    final isRtl = context.locale.languageCode == 'ar';
    return Directionality(
      textDirection: isRtl ? flutter_widgets.TextDirection.rtl : flutter_widgets.TextDirection.ltr,
      child: child,
    );
  }
}
