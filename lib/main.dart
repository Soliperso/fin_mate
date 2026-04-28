import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
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
import 'core/services/session_timeout_provider.dart';
import 'core/providers/display_format_provider.dart';
import 'core/error/global_error_handler.dart';
import 'core/l10n/locale_bridge.dart';
import 'shared/widgets/offline_indicator.dart';
import 'features/transactions/data/datasources/reminder_remote_datasource.dart';
import 'features/budgets/data/datasources/budget_remote_datasource.dart';
import 'core/services/auto_backup_service.dart';
import 'core/services/review_service.dart';
import 'core/services/recurring_transaction_processor.dart';
import 'core/services/notification_provider.dart';

void main() async {
  // Run app in error zone to catch all errors
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Phase 1 — parallel: env + orientation lock (no deps between them)
      await Future.wait([
        dotenv.load(fileName: '.env').catchError((_) {}),
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
      ]);

      // Set up Flutter error handling early so init errors are caught
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        GlobalErrorHandler.handleError(
          details.exception,
          details.stack ?? StackTrace.current,
          fatal: true,
          context: 'Flutter Framework Error',
        );
      };

      // Phase 2 — sequential: Sentry then Supabase (Sentry must be up before Supabase errors)
      await SentryService.initialize();
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

      // Phase 3 — parallel: analytics (needs Supabase) + localization + prefs
      // These are all independent of each other
      final analytics = AnalyticsService(Supabase.instance.client);
      late SharedPreferences prefs;
      await Future.wait([
        analytics.initialize(),
        EasyLocalization.ensureInitialized(),
        initializeDateFormatting(),
        SharedPreferences.getInstance().then((p) => prefs = p),
      ]);

      // Read saved theme + display format + locale from already-loaded prefs
      final savedTheme = prefs.getString('theme_mode') ?? 'dark';
      final initialThemeMode = savedTheme == 'light'
          ? ThemeMode.light
          : savedTheme == 'system'
              ? ThemeMode.system
              : ThemeMode.dark;
      final initialDisplayFormat = DisplayFormatState(
        currencyCode: prefs.getString('pref_currency') ?? 'USD',
        dateFormat: prefs.getString('pref_date_format') ?? 'MM/DD/YYYY',
        numberFormat: prefs.getString('pref_number_format') ?? '1,234.56',
      );
      setCachedDisplayFormat(initialDisplayFormat);
      final savedLocaleCode = prefs.getString('saved_locale') ?? 'en';

      // [MVP: Payment Service - Commented out for initial launch]
      // All features are free during MVP testing phase
      // Stripe payment integration will be enabled post-beta
      // Uncomment below to enable payments:
      // final paymentService = PaymentService();
      // await paymentService.initialize();

      await ReviewService.instance.recordAppOpen();

      // Run app
      runApp(
        EasyLocalization(
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('es'),
            Locale('ar'),
          ],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: Locale(savedLocaleCode),
          child: ProviderScope(
            overrides: [
              initialThemeModeProvider.overrideWithValue(initialThemeMode),
              initialDisplayFormatProvider.overrideWithValue(initialDisplayFormat),
            ],
            child: const FinmateApp(),
          ),
        ),
      );
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

      // Start session timeout monitoring
      ref.read(sessionTimeoutServiceProvider).startMonitoring();

      // Deferred: non-critical inits that don't affect the first frame
      unawaited(AdService.instance.initialize().catchError((_) {}));
      unawaited(DeviceSecurityService().getSecurityStatus().then((status) {
        if (!status.isSafe) {
          GlobalErrorHandler.handleWarning(
            'App running on compromised device',
            context: 'Device Security',
            extra: {
              'isJailbroken': status.isJailbroken,
              'isDeveloperMode': status.isDeveloperMode,
            },
          );
        }
      }).catchError((_) {}));

      // Fire due reminders, apply budget carry-overs, check alerts, and run auto backup on app open
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        unawaited(ReminderRemoteDatasource().processReminders().catchError((_) {}));
        unawaited(BudgetRemoteDataSource().applyCarryOvers().catchError((_) {}));
        unawaited(AutoBackupService().runIfDue().catchError((_) {}));
        unawaited(RecurringTransactionProcessor().processOverdue().catchError((_) {}));
        // Create notifications for bill reminders and budget alerts
        final notifier = ref.read(notificationsProvider.notifier);
        unawaited(notifier.createBillReminders().catchError((_) {}));
        unawaited(notifier.checkBudgetAlerts().catchError((_) {}));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return OfflineIndicator(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => ref.read(sessionTimeoutServiceProvider).recordActivity(),
        child: MaterialApp.router(
          title: 'Finmate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeMode,
          routerConfig: router,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          builder: (context, child) => LocaleBridge(child: child ?? const SizedBox()),
        ),
      ),
    );
  }
}
