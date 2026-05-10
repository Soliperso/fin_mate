// Tests for the router redirect guard logic.
//
// The redirect function in router.dart follows this contract:
//   - Unauthenticated user on a protected route → '/login'
//   - Authenticated user on an auth route (not '/' or '/verify-email') → '/dashboard'
//   - Otherwise → null (no redirect)
//
// We extract and exercise that contract directly without spinning up
// a full ProviderScope + GoRouter, keeping tests fast and dependency-free.
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Redirect logic extracted from router.dart for unit testing
// ---------------------------------------------------------------------------

const _authRoutes = [
  '/login',
  '/signup',
  '/onboarding',
  '/verify-email',
  '/forgot-password',
  '/auth/callback',
  '/',
];

/// Mirrors the redirect logic in router.dart.
/// Returns a redirect path or null if no redirect is needed.
String? computeRedirect({
  required bool isAuthenticated,
  required String location,
}) {
  final isAuthRoute = _authRoutes.any(
    (r) => location == r || location.startsWith('$r/'),
  );

  if (!isAuthenticated && !isAuthRoute) {
    return '/login';
  }

  if (isAuthenticated &&
      isAuthRoute &&
      location != '/' &&
      !location.startsWith('/verify-email')) {
    return '/dashboard';
  }

  return null;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Unauthenticated user', () {
    test('visiting /dashboard is redirected to /login', () {
      expect(
        computeRedirect(isAuthenticated: false, location: '/dashboard'),
        '/login',
      );
    });

    test('visiting /transactions is redirected to /login', () {
      expect(
        computeRedirect(isAuthenticated: false, location: '/transactions'),
        '/login',
      );
    });

    test('visiting /debt is redirected to /login', () {
      expect(
        computeRedirect(isAuthenticated: false, location: '/debt'),
        '/login',
      );
    });

    test('visiting /budgets is redirected to /login', () {
      expect(
        computeRedirect(isAuthenticated: false, location: '/budgets'),
        '/login',
      );
    });

    test('visiting /login is not redirected', () {
      expect(
        computeRedirect(isAuthenticated: false, location: '/login'),
        isNull,
      );
    });

    test('visiting /signup is not redirected', () {
      expect(
        computeRedirect(isAuthenticated: false, location: '/signup'),
        isNull,
      );
    });

    test('visiting splash / is not redirected', () {
      expect(
        computeRedirect(isAuthenticated: false, location: '/'),
        isNull,
      );
    });
  });

  group('Authenticated user', () {
    test('visiting /dashboard is not redirected', () {
      expect(
        computeRedirect(isAuthenticated: true, location: '/dashboard'),
        isNull,
      );
    });

    test('visiting /transactions is not redirected', () {
      expect(
        computeRedirect(isAuthenticated: true, location: '/transactions'),
        isNull,
      );
    });

    test('visiting /login is redirected to /dashboard', () {
      expect(
        computeRedirect(isAuthenticated: true, location: '/login'),
        '/dashboard',
      );
    });

    test('visiting /signup is redirected to /dashboard', () {
      expect(
        computeRedirect(isAuthenticated: true, location: '/signup'),
        '/dashboard',
      );
    });

    test('visiting /onboarding is redirected to /dashboard', () {
      expect(
        computeRedirect(isAuthenticated: true, location: '/onboarding'),
        '/dashboard',
      );
    });

    test('visiting /verify-email is NOT redirected (email verify stays open)',
        () {
      expect(
        computeRedirect(isAuthenticated: true, location: '/verify-email'),
        isNull,
      );
    });

    test('visiting splash / is not redirected', () {
      expect(
        computeRedirect(isAuthenticated: true, location: '/'),
        isNull,
      );
    });
  });
}
