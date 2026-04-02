import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/config/router.dart';
import 'core/config/env_config.dart';
import 'core/services/sentry_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/device_security_service.dart';
// [MVP: Payment Service - Commented out for initial launch]
// import 'core/services/payment_service.dart';
import 'core/services/theme_provider.dart';
import 'core/providers/display_format_provider.dart';
import 'core/error/global_error_handler.dart';
import 'shared/widgets/offline_indicator.dart';
import 'features/transactions/data/datasources/reminder_remote_datasource.dart';
import 'features/budgets/data/datasources/budget_remote_datasource.dart';
import 'core/services/auto_backup_service.dart';
import 'core/services/recurring_transaction_processor.dart';

void main() async {
  // Run app in error zone to catch all errors
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables from .env file (local dev only).
      // Production builds inject values via --dart-define flags instead.
      try {
        await dotenv.load(fileName: ".env");
      } catch (_) {
        // .env not present — production build using --dart-define
      }

      // Lock app to portrait mode
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Initialize Sentry error tracking
      await SentryService.initialize();

      // Initialize Supabase with deep link handling
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
        debug: EnvConfig.enableLogging,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );

      // Listen for deep link authentication (email confirmation)
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn) {
          // User authenticated via deep link
        }
      });

      // Initialize Analytics
      final analytics = AnalyticsService(Supabase.instance.client);
      await analytics.initialize();

      // Initialize Google Mobile Ads
      await AdService.instance.initialize();

      // Check device security (jailbreak/root detection)
      final deviceSecurity = DeviceSecurityService();
      final securityStatus = await deviceSecurity.getSecurityStatus();
      if (!securityStatus.isSafe) {
        // Log security warning
        await GlobalErrorHandler.handleWarning(
          'App running on compromised device',
          context: 'Device Security',
          extra: {
            'isJailbroken': securityStatus.isJailbroken,
            'isDeveloperMode': securityStatus.isDeveloperMode,
          },
        );
      }

      // [MVP: Payment Service - Commented out for initial launch]
      // All features are free during MVP testing phase
      // Stripe payment integration will be enabled post-beta
      // Uncomment below to enable payments:
      // final paymentService = PaymentService();
      // await paymentService.initialize();

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

      // Read saved theme + display format before first frame to avoid flash
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode') ?? 'dark';
      final initialThemeMode = savedTheme == 'light'
          ? ThemeMode.light
          : savedTheme == 'system'
              ? ThemeMode.system
              : ThemeMode.dark;
      final initialDisplayFormat = await loadInitialDisplayFormat();

      // Run app
      runApp(ProviderScope(
        overrides: [
          initialThemeModeProvider.overrideWithValue(initialThemeMode),
          initialDisplayFormatProvider.overrideWithValue(initialDisplayFormat),
        ],
        child: const FinmateApp(),
      ));
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

class FinmateApp extends ConsumerStatefulWidget {
  const FinmateApp({super.key});

  @override
  ConsumerState<FinmateApp> createState() => _FinmateAppState();
}

class _FinmateAppState extends ConsumerState<FinmateApp> {
  @override
  void initState() {
    super.initState();
    // Initialize theme service and load saved theme mode
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final themeService = ref.read(themeServiceProvider);
      await themeService.initialize();
      await ref.read(themeModeProvider.notifier).initialize();

      // Fire due reminders, apply budget carry-overs, and run auto backup on app open
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        unawaited(ReminderRemoteDatasource().processReminders().catchError((_) {}));
        unawaited(BudgetRemoteDataSource().applyCarryOvers().catchError((_) {}));
        unawaited(AutoBackupService().runIfDue().catchError((_) {}));
        unawaited(RecurringTransactionProcessor().processOverdue().catchError((_) {}));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return OfflineIndicator(
      child: MaterialApp.router(
        title: 'Finmate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
