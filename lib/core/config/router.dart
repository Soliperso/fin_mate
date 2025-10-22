import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../guards/admin_guard.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/auth_callback_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/emergency_fund_page.dart';
import '../../features/bill_splitting/presentation/pages/bills_page.dart';
import '../../features/bill_splitting/presentation/pages/group_detail_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/ai_insights/presentation/pages/ai_insights_page.dart';
// COMMENTED OUT - Savings Goals not in MVP Phase 1
// import '../../features/savings_goals/presentation/pages/savings_goals_page.dart';
// import '../../features/savings_goals/presentation/pages/goal_detail_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/security_settings_page.dart';
import '../../features/profile/presentation/pages/legal_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/notification_settings_page.dart';
import '../../features/settings/presentation/pages/display_settings_page.dart';
import '../../features/settings/presentation/pages/data_privacy_page.dart';
import '../../features/admin/presentation/pages/user_management_page.dart';
import '../../features/admin/presentation/pages/system_analytics_page_enhanced.dart';
import '../../features/admin/presentation/pages/system_settings_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

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

// Router notifier that watches auth state changes
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, _) {
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
          state.matchedLocation == '/';
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // If authenticated and trying to access auth routes, redirect to dashboard
      if (isAuthenticated && isAuthRoute && state.matchedLocation != '/' && !state.matchedLocation.startsWith('/verify-email')) {
        return '/dashboard';
      }

      if (isAdminRoute) {
        final isAdmin = ref.read(isAdminProvider);
        if (!isAdmin) {
          return '/dashboard'; // Redirect non-admins
        }
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
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
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

      // Main App Shell with Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
            routes: [
              GoRoute(
                path: 'emergency-fund',
                name: 'emergency-fund',
                builder: (context, state) => const EmergencyFundPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/bills',
            name: 'bills',
            builder: (context, state) => const BillsPage(),
            routes: [
              GoRoute(
                path: 'group/:groupId',
                name: 'group-detail',
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  return GroupDetailPage(groupId: groupId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/budgets',
            name: 'budgets',
            builder: (context, state) => const BudgetsPage(),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsPage(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-transaction',
                builder: (context, state) {
                  final type = state.uri.queryParameters['type'];
                  final id = state.uri.queryParameters['id'];
                  return AddTransactionPage(
                    transactionType: type,
                    transactionId: id,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/insights',
            name: 'insights',
            builder: (context, state) => const AiInsightsPage(),
          ),
          // COMMENTED OUT - Savings Goals not in MVP Phase 1
          // GoRoute(
          //   path: '/goals',
          //   name: 'goals',
          //   builder: (context, state) => const SavingsGoalsPage(),
          //   routes: [
          //     GoRoute(
          //       path: ':goalId',
          //       name: 'goal-detail',
          //       builder: (context, state) {
          //         final goalId = state.pathParameters['goalId']!;
          //         return GoalDetailPage(goalId: goalId);
          //       },
          //     ),
          //   ],
          // ),
          GoRoute(
            path: '/documents',
            name: 'documents',
            builder: (context, state) => const DocumentsPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
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
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: 'notifications',
                name: 'notification-settings',
                builder: (context, state) => const NotificationSettingsPage(),
              ),
              GoRoute(
                path: 'display',
                name: 'display-settings',
                builder: (context, state) => const DisplaySettingsPage(),
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

      // Admin routes
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const UserManagementPage(),
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

/// Main shell with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary,
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Activities',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Insights',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/budgets')) return 1;
    if (location.startsWith('/bills')) return 2;
    if (location.startsWith('/transactions')) return 3;
    if (location.startsWith('/insights')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/budgets');
        break;
      case 2:
        context.go('/bills');
        break;
      case 3:
        context.go('/transactions');
        break;
      case 4:
        context.go('/insights');
        break;
    }
  }
}
