import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoPage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../guards/admin_guard.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/auth_callback_page.dart';
import '../../features/auth/presentation/pages/set_new_password_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/transactions/presentation/pages/scan_receipt_page.dart';
import '../../features/transactions/presentation/pages/transaction_detail_page.dart';
// [AI Insights - Commented out]
// import '../../features/ai_insights/presentation/pages/ai_insights_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/savings_goals/presentation/pages/savings_goals_page.dart';
import '../../features/savings_goals/presentation/pages/goal_detail_page.dart';
import '../../features/debt_payoff/presentation/pages/debt_page.dart';
import '../../features/debt_payoff/presentation/pages/debt_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
// [MVP: Pricing/Subscription - Commented out for initial launch]
// import '../../features/profile/presentation/pages/pricing_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/security_settings_page.dart';
import '../../features/profile/presentation/pages/legal_page.dart';
import '../../features/subscription/presentation/pages/paywall_page.dart';
// [MVP: Subscription Management - Commented out for initial launch]
// import '../../features/subscription/presentation/pages/subscription_page.dart';
// import '../../features/subscription/presentation/pages/payment_methods_page.dart';
// import '../../features/subscription/presentation/pages/billing_history_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/notification_settings_page.dart';
import '../../features/settings/presentation/pages/display_settings_page.dart';
import '../../features/settings/presentation/pages/data_privacy_page.dart';
import '../../features/admin/presentation/pages/user_management_page.dart';
import '../../features/admin/presentation/pages/user_detail_page.dart';
import '../../features/admin/presentation/pages/system_analytics_page_enhanced.dart';
import '../../features/admin/presentation/pages/system_settings_page.dart';
import '../../features/recurring_transactions/presentation/pages/recurring_transactions_page.dart';
import '../../features/recurring_transactions/presentation/pages/add_recurring_transaction_page.dart';
import '../../features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
// RE-ENABLE: import '../services/ad_service.dart';
// RE-ENABLE: import '../providers/ad_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Page used for the 5 bottom-nav tabs — fades in over 150 ms.
/// Only one page lives in the tree at a time so there are no GlobalKey conflicts.
class _FadeTransitionPage extends CustomTransitionPage<void> {
  _FadeTransitionPage({required super.child})
      : super(
          transitionDuration: const Duration(milliseconds: 150),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        );
}

// Helper class for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Router notifier that watches auth state changes and server admin verification
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (previous, next) {
      notifyListeners();
    });
    // Re-evaluate admin redirects once the server RPC resolves.
    _ref.listen(serverAdminVerifiedProvider, (previous, next) {
      notifyListeners();
    });
    // Re-evaluate admin redirects once the local profile loads.
    // Without this, profileProvider resolves after the redirect already ran
    // (returning false while loading) and the router never corrects itself.
    _ref.listen(isAdminProvider, (previous, next) {
      notifyListeners();
    });
  }
}

// Router provider with auth guard
final routerProvider = Provider<GoRouter>((ref) {
  // Create a notifier that will trigger router refreshes when auth state changes
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState.user != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/onboarding') ||
          state.matchedLocation.startsWith('/verify-email') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/auth/callback') ||
          state.matchedLocation.startsWith('/set-new-password') ||
          state.matchedLocation == '/';
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      // Password recovery takes priority — always redirect to set-new-password.
      if (authState.isPasswordRecovery &&
          state.matchedLocation != '/set-new-password') {
        return '/set-new-password';
      }

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // If authenticated and trying to access auth routes, redirect to dashboard
      if (isAuthenticated && isAuthRoute && state.matchedLocation != '/' && !state.matchedLocation.startsWith('/verify-email')) {
        return '/dashboard';
      }

      if (isAdminRoute) {
        // Layer 1 — local profile check.
        // Read the raw async value so we can differentiate loading from
        // "loaded and not admin". While loading, allow optimistically — the
        // _RouterNotifier listens to isAdminProvider so the router will
        // re-evaluate and kick out non-admins once the profile resolves.
        final profileAsync = ref.read(profileProvider);
        if (!profileAsync.isLoading) {
          final isAdminLocal = profileAsync.valueOrNull?.isAdmin ?? false;
          if (!isAdminLocal) return '/dashboard';
        }

        // Layer 2 — server-side RPC verification (defence-in-depth).
        // Uses cached AsyncValue so the redirect stays synchronous.
        // The _RouterNotifier listens to serverAdminVerifiedProvider so the
        // router re-evaluates this redirect once the RPC result arrives.
        final serverResult = ref.read(serverAdminVerifiedProvider);
        final isAdminServer = serverResult.when(
          data: (verified) => verified,
          // Still loading — optimistically allow (layer 1 passed); the router
          // will re-run and correct this once the RPC resolves.
          loading: () => true,
          // RPC error — deny access to be safe.
          error: (_, __) => false,
        );
        if (!isAdminServer) return '/dashboard';
      }

      return null; // No redirect
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      // Auth Routes
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        pageBuilder: (context, state) =>
            _FadeTransitionPage(child: const PaywallPage()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginPage(
          reason: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.extra as String;
          return VerifyEmailPage(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return ForgotPasswordPage(email: email);
        },
      ),
      GoRoute(
        path: '/auth/callback',
        name: 'auth-callback',
        builder: (context, state) => const AuthCallbackPage(),
      ),
      GoRoute(
        path: '/set-new-password',
        name: 'set-new-password',
        builder: (context, state) => const SetNewPasswordPage(),
      ),

      // Main App Shell with Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => _FadeTransitionPage(child: const DashboardPage()),
            routes: [],
          ),
          GoRoute(
            path: '/budgets',
            name: 'budgets',
            pageBuilder: (context, state) => _FadeTransitionPage(child: const BudgetsPage()),
          ),
          GoRoute(
            path: '/recurring-transactions',
            name: 'recurring-transactions',
            pageBuilder: (context, state) => const CupertinoPage(child: RecurringTransactionsPage()),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-recurring-transaction',
                builder: (context, state) => AddRecurringTransactionPage(
                  transaction: state.extra as RecurringTransactionEntity?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            pageBuilder: (context, state) => _FadeTransitionPage(
              child: TransactionsPage(
                openSearch: state.uri.queryParameters.containsKey('search'),
              ),
            ),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-transaction',
                pageBuilder: (context, state) {
                  final type = state.uri.queryParameters['type'];
                  final id = state.uri.queryParameters['id'];
                  return CupertinoPage(
                    child: AddTransactionPage(
                      transactionType: type,
                      transactionId: id,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'scan-receipt',
                name: 'scan-receipt',
                builder: (context, state) => const ScanReceiptPage(),
              ),
              GoRoute(
                path: ':id',
                name: 'transaction-detail',
                builder: (context, state) => TransactionDetailPage(
                  transactionId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/debt',
            name: 'debt',
            pageBuilder: (context, state) => _FadeTransitionPage(child: const DebtPage()),
            routes: [
              GoRoute(
                path: ':debtId',
                name: 'debt-detail',
                builder: (context, state) => DebtDetailPage(
                  debtId: state.pathParameters['debtId']!,
                ),
              ),
            ],
          ),
          // [AI Insights - Commented out]
          // GoRoute(
          //   path: '/insights',
          //   name: 'insights',
          //   pageBuilder: (context, state) => _FadeTransitionPage(child: const AiInsightsPage()),
          // ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            pageBuilder: (context, state) => const CupertinoPage(child: NotificationsPage()),
          ),
          GoRoute(
            path: '/goals',
            name: 'goals',
            pageBuilder: (context, state) => const CupertinoPage(child: SavingsGoalsPage()),
            routes: [
              GoRoute(
                path: ':goalId',
                name: 'goal-detail',
                builder: (context, state) {
                  final goalId = state.pathParameters['goalId']!;
                  return GoalDetailPage(goalId: goalId);
                },
              ),
            ],
          ),
          // [MVP: Pricing - Commented out for initial launch]
          // GoRoute(
          //   path: '/pricing',
          //   name: 'pricing',
          //   builder: (context, state) => const PricingPage(),
          // ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => _FadeTransitionPage(child: const ProfilePage()),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'profile-edit',
                builder: (context, state) => const EditProfilePage(),
              ),
              GoRoute(
                path: 'security',
                name: 'security-settings',
                builder: (context, state) => const SecuritySettingsPage(),
              ),
              // [MVP: Subscription Management - Commented out for initial launch]
              // GoRoute(
              //   path: 'subscription',
              //   name: 'subscription',
              //   builder: (context, state) => const SubscriptionPage(),
              //   routes: [
              //     GoRoute(
              //       path: 'payment-methods',
              //       name: 'payment-methods',
              //       builder: (context, state) => const PaymentMethodsPage(),
              //     ),
              //     GoRoute(
              //       path: 'billing-history',
              //       name: 'billing-history',
              //       builder: (context, state) => const BillingHistoryPage(),
              //     ),
              //   ],
              // ),
              GoRoute(
                path: 'legal',
                name: 'legal',
                builder: (context, state) => const LegalPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const CupertinoPage(child: SettingsPage()),
            routes: [
              GoRoute(
                path: 'notifications',
                name: 'notification-settings',
                builder: (context, state) => const NotificationSettingsPage(),
              ),
              GoRoute(
                path: 'display',
                name: 'display-settings',
                builder: (context, state) => DisplaySettingsPage(
                  section: state.uri.queryParameters['section'],
                ),
              ),
              GoRoute(
                path: 'data-privacy',
                name: 'data-privacy',
                builder: (context, state) => const DataPrivacyPage(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const UserManagementPage(),
        routes: [
          GoRoute(
            path: ':userId',
            name: 'admin-user-detail',
            builder: (context, state) => UserDetailPage(
              userId: state.pathParameters['userId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/analytics',
        name: 'admin-analytics',
        builder: (context, state) => const SystemAnalyticsPageEnhanced(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        builder: (context, state) => const SystemSettingsPage(),
      ),
    ],
  );
});

/// iOS-style tab bar shell — Apple Wallet / Pay aesthetic
class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({required this.child, super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  String _currentTabRoot = '';
  // RE-ENABLE: bool _interstitialShownThisSession = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    // RE-ENABLE: unawaited(AdService.instance.preloadInterstitial());
  }

  // RE-ENABLE: when DAU > 1,000 and 30-day retention > 20%
  // Future<void> _showInterstitialOnTransactions() async {
  //   if (_interstitialShownThisSession) return;
  //   final shouldShow = await ref.read(shouldShowAdsProvider.future);
  //   if (!shouldShow) return;
  //   await AdService.instance.preloadInterstitial();
  //   await AdService.instance.showInterstitialIfEligible(shouldShow: shouldShow);
  //   _interstitialShownThisSession = true;
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = GoRouterState.of(context).uri.path;
    final tabRoot = _tabRoot(path);
    if (_currentTabRoot.isNotEmpty && _currentTabRoot != tabRoot) {
      _fadeController.value = 0.0;
      _fadeController.forward();
    }
    _currentTabRoot = tabRoot;
  }

  String _tabRoot(String path) {
    if (path.startsWith('/dashboard')) return '/dashboard';
    if (path.startsWith('/transactions')) return '/transactions';
    if (path.startsWith('/budgets')) return '/budgets';
    if (path.startsWith('/debt')) return '/debt';
    if (path.startsWith('/profile')) return '/profile';
    return path;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeController,
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1C1C1E)
              : const Color(0xFFFFFFFF),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF38383A)
                  : const Color(0xFFC6C6C8),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 49,
            child: Row(
              children: [
                _TabItem(
                  icon: CupertinoIcons.square_grid_2x2,
                  activeIcon: CupertinoIcons.square_grid_2x2_fill,
                  label: 'nav.dashboard'.tr(),
                  isSelected: selectedIndex == 0,
                  onTap: () => context.go('/dashboard'),
                ),
                _TabItem(
                  icon: CupertinoIcons.arrow_right_arrow_left,
                  activeIcon: CupertinoIcons.arrow_right_arrow_left,
                  label: 'nav.transactions'.tr(),
                  isSelected: selectedIndex == 1,
                  onTap: () {
                    context.go('/transactions');
                    // RE-ENABLE: when DAU > 1,000 and 30-day retention > 20%
                    // unawaited(_showInterstitialOnTransactions());
                  },
                ),
                _TabItem(
                  icon: CupertinoIcons.chart_pie,
                  activeIcon: CupertinoIcons.chart_pie_fill,
                  label: 'nav.budgets'.tr(),
                  isSelected: selectedIndex == 2,
                  onTap: () => context.go('/budgets'),
                ),
                _TabItem(
                  icon: CupertinoIcons.creditcard,
                  activeIcon: CupertinoIcons.creditcard_fill,
                  label: 'nav.debt'.tr(),
                  isSelected: selectedIndex == 3,
                  onTap: () => context.go('/debt'),
                ),
                _TabItem(
                  icon: CupertinoIcons.person,
                  activeIcon: CupertinoIcons.person_fill,
                  label: 'nav.profile'.tr(),
                  isSelected: selectedIndex == 4,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/debt')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF2D9DA9) : const Color(0xFF20808D);
    final inactive = const Color(0xFF8E8E93);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? accent : inactive,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? accent : inactive,
                letterSpacing: -0.24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
