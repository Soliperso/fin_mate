import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/config/router.dart';
import 'core/config/env_config.dart';
import 'core/services/sentry_service.dart';
import 'core/services/analytics_service.dart';
import 'core/error/global_error_handler.dart';
import 'shared/widgets/offline_indicator.dart';

void main() async {
  // Run app in error zone to catch all errors
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables
      await dotenv.load(fileName: '.env');

      // Initialize Sentry error tracking
      await SentryService.initialize();

      // Initialize Supabase
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
        debug: EnvConfig.enableLogging,
      );

      // Initialize Analytics
      final analytics = AnalyticsService(Supabase.instance.client);
      await analytics.initialize();

      // Set up Flutter error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        GlobalErrorHandler.handleError(
          details.exception,
          details.stack ?? StackTrace.current,
          fatal: true,
          context: 'Flutter Framework Error',
        );
      };

      // Run app
      runApp(const ProviderScope(child: FinMateApp()));
    },
    (error, stackTrace) {
      // Catch all uncaught async errors
      GlobalErrorHandler.handleError(
        error,
        stackTrace,
        fatal: true,
        context: 'Uncaught Async Error',
      );
    },
  );
}

class FinMateApp extends ConsumerWidget {
  const FinMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return OfflineIndicator(
      child: MaterialApp.router(
        title: 'FinMate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
