# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**FinMate** is a cross-platform financial management app built with Flutter, combining personal finance tracking, bill splitting, savings goals, and AI-powered forecasting. The app uses Supabase for backend services and follows clean architecture principles.

## Key Commands

### Development
```bash
# Run the app (requires Supabase credentials in .env)
flutter run

# Run on specific device
flutter run -d <device_id>

# Hot reload: Press 'r' in the terminal
# Hot restart: Press 'R' in the terminal

# Get dependencies after pulling changes
flutter pub get
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code for issues (run before commits)
flutter analyze

# Format code
dart format .

# Check for outdated dependencies
flutter pub outdated
```

### Database Migrations
```bash
# Apply migrations to Supabase (requires project linking)
supabase db push

# If not linked, run migrations manually:
# 1. Go to: https://supabase.com/dashboard/project/{project_id}/sql/new
# 2. Copy content from supabase/migrations/09_create_bill_splitting_and_savings_goals.sql
# 3. Paste and click RUN
```

## Architecture & Design

### Tech Stack (Currently Implemented)
- **Framework**: Flutter 3.37+ with Material 3 design system
- **State Management**: Riverpod (StateNotifier pattern)
- **Routing**: GoRouter with auth guards
- **Backend**: Supabase (Auth, Postgres, Storage, Realtime)
- **Local Storage**: flutter_secure_storage for sensitive data
- **Security**: MFA (TOTP/Email OTP), Biometric auth via local_auth

### Feature-First Architecture

The codebase follows clean architecture with feature-first organization:

```
lib/
├── core/
│   ├── config/          # App configuration, router, Supabase client
│   ├── constants/       # App colors, sizes, effects
│   ├── services/        # Cross-cutting services (biometric, MFA, notifications, secure storage)
│   ├── theme/           # Material 3 theme configuration
│   └── utils/           # Shared utilities
├── features/
│   ├── auth/            # Authentication & onboarding
│   ├── dashboard/       # Net worth, cash flow, money health
│   ├── transactions/    # Transaction CRUD, accounts, categories
│   ├── budgets/         # Budget tracking and alerts
│   ├── bill_splitting/  # Group expenses and settlements
│   ├── profile/         # User profile and settings
│   └── ai_insights/     # AI-powered insights (UI only)
├── shared/              # Shared widgets (buttons, containers, states)
└── main.dart
```

### Each Feature Module Structure
```
feature_name/
├── data/
│   ├── datasources/     # Remote data sources (Supabase API calls)
│   ├── models/          # Data models with JSON serialization
│   └── repositories/    # Repository implementations
├── domain/
│   ├── entities/        # Business entities (pure Dart classes)
│   └── repositories/    # Repository interfaces
└── presentation/
    ├── pages/           # Full screen UI components
    ├── widgets/         # Feature-specific widgets
    └── providers/       # Riverpod state providers
```

### Database Schema (Supabase)

**Core Tables:**
- `user_profiles` - User data and MFA settings
- `accounts` - Financial accounts (cash, checking, savings, etc.)
- `categories` - Transaction categories
- `transactions` - Financial transactions
- `recurring_transactions` - Scheduled transactions
- `budgets` - Budget tracking
- `net_worth_snapshots` - Historical net worth tracking
- `notifications` - In-app notifications

**Bill Splitting Tables:**
- `bill_groups` - Groups for splitting expenses
- `group_members` - Members in each group with roles
- `group_expenses` - Expenses to be split
- `expense_splits` - Individual split amounts
- `settlements` - Payment records between members

**Savings Goals Tables:**
- `savings_goals` - Goal tracking with progress
- `goal_contributions` - Contributions to goals

### State Management Patterns

**Riverpod Providers Used:**
- `FutureProvider` - Async data fetching
- `StateNotifierProvider` - Mutable state management
- `Provider` - Simple dependency injection

**Example Pattern:**
```dart
// Repository provider
final repositoryProvider = Provider<Repository>((ref) {
  return RepositoryImpl(datasource: RemoteDatasource());
});

// Data provider
final dataProvider = FutureProvider<List<Item>>((ref) async {
  final repository = ref.watch(repositoryProvider);
  return await repository.getData();
});

// Operations provider
final operationsProvider = StateNotifierProvider<OperationsNotifier, AsyncValue<void>>((ref) {
  return OperationsNotifier(ref.watch(repositoryProvider));
});
```

### Routing & Navigation

GoRouter handles routing with authenticated and unauthenticated routes:
- `/splash` - Initial loading
- `/onboarding` - First-time user experience
- `/login`, `/signup` - Authentication
- `/` - Main app shell with bottom navigation
- `/dashboard`, `/transactions`, `/budgets`, `/bills`, `/insights` - Main features

Auth state changes trigger automatic navigation via redirect logic in `lib/core/config/router.dart`.

## Security & Data Handling

### Critical Security Rules
- **Never commit** `.env` file (contains Supabase credentials)
- **Never log** sensitive data (tokens, passwords, financial amounts in production)
- All Supabase operations use **Row Level Security (RLS)** policies
- Financial amounts are stored as `DECIMAL(15,2)` in database
- User sessions managed via Supabase JWT tokens
- MFA required for sensitive operations when enabled

### Environment Configuration
Required in `.env` file:
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=xxxxx
```

### Data Encryption
- Sensitive data uses `flutter_secure_storage`
- TOTP secrets encrypted at rest
- Biometric credentials stored in platform keychain

## Development Guidelines

### When Adding New Features

1. **Create feature module structure:**
   ```
   lib/features/new_feature/
   ├── data/
   ├── domain/
   └── presentation/
   ```

2. **Database changes require migration:**
   - Create new file: `supabase/migrations/XX_description.sql`
   - Include table creation, indexes, RLS policies, and triggers
   - Test locally before deploying

3. **Follow naming conventions:**
   - Entities: `FeatureNameEntity` (e.g., `BillGroup`)
   - Models: `FeatureNameModel` extends entity
   - Providers: `featureNameProvider`, `featureNameOperationsProvider`
   - Pages: `FeaturePage` (e.g., `BillsPage`)

4. **State management:**
   - UI reads from `FutureProvider` or `StateNotifierProvider`
   - Mutations go through `StateNotifier` classes
   - Always invalidate providers after mutations: `ref.invalidate(provider)`

### UI/UX Standards
- **NO changes to styling/colors** without explicit user request
- Use existing shared widgets from `lib/shared/widgets/`
- Follow Material 3 design (already configured in theme)
- All financial amounts display with 2 decimal places
- Loading states use `CircularProgressIndicator` or shimmer
- Error states show user-friendly messages with retry option

### Testing Requirements
- Widget tests for complex UI components
- Unit tests for business logic (repositories, services)
- Mock Supabase calls in tests
- Test error handling paths

## Current Implementation Status

### ✅ Fully Implemented
- Authentication (email/password, MFA, biometric)
- User profiles with avatar upload
- Transactions with accounts and categories
- Budgets with progress tracking
- Dashboard with net worth and cash flow
- Notifications system
- Bill Splitting (backend + basic UI)

### ⚠️ Partial Implementation
- Bill Splitting (needs expense creation UI, settlement flow)
- Savings Goals (database ready, needs frontend)
- AI Insights (UI mockup only, needs backend integration)

### ❌ Not Implemented
- Bank integration (Plaid/TrueLayer)
- Payment processing (Stripe/PayPal for settlements)
- AI-powered forecasting and recommendations
- Document storage for receipts
- Multi-currency support

## Troubleshooting

### Common Issues

**"Table does not exist" errors:**
- Migrations not applied to Supabase
- Solution: Run migrations from `supabase/migrations/` in SQL editor

**Authentication errors:**
- Check `.env` file has correct Supabase credentials
- Verify Supabase project is not paused

**Hot reload not working:**
- Use hot restart (capital R) after changing providers or route configuration

**RLS policy errors:**
- Check user is authenticated: `Supabase.instance.client.auth.currentUser`
- Verify RLS policies in Supabase dashboard match user context

## Important Context

- **Target SDK**: Dart 3.10.0+, Flutter 3.37+
- **Platforms**: iOS, Android, Web (iOS priority for development)
- **Design System**: Material 3 with custom fintech color palette
- **Backend**: Single Supabase project handles all environments
- **State**: Riverpod for all state management (no Bloc or other libraries)
