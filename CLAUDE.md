# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Finmate** is a cross-platform personal finance app built with Flutter. It covers transaction tracking, budgeting, savings goals, dashboard analytics (net worth, cash flow, money health), and AI-powered forecasting. The backend is Supabase (auth, Postgres, storage, realtime). No bank account linking — all data is manually entered or imported via CSV.

---

## Key Commands

```bash
# Run the app (requires .env with Supabase credentials)
flutter run

# Run on specific device
flutter run -d <device_id>

# Get dependencies after pulling changes
flutter pub get

# Analyze code for issues (run before commits)
flutter analyze

# Format code
dart format .

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Regenerate code after modifying @freezed or @JsonSerializable classes
dart run build_runner build --delete-conflicting-outputs
```

### Database Migrations
New migrations go in `supabase/migrations/` with an incrementing numeric prefix (currently at `34_`).
```bash
# Apply via CLI (requires project linking)
supabase db push

# Or manually: paste the SQL into Supabase dashboard → SQL editor → Run
```

---

## Architecture

### Tech Stack
- **Framework**: Flutter 3.37+ with Material 3
- **State Management**: Riverpod (`StateNotifierProvider`, `FutureProvider`, `Provider`)
- **Routing**: GoRouter with auth guard redirect
- **Backend**: Supabase (Auth, Postgres, Storage, Realtime)
- **AI**: OpenAI GPT-4o-mini (via `http` package, key via `EnvConfig.openAiApiKey`)
- **Error Tracking**: Sentry (`sentry_flutter`)
- **Ads**: Google Mobile Ads
- **Secure Storage**: `flutter_secure_storage` via `SecureStorageService`
- **Code Generation**: `freezed` + `json_serializable` via `build_runner`

### Feature-First Clean Architecture

```
lib/
├── core/
│   ├── config/        # app_config.dart, env_config.dart, router.dart, supabase_client.dart
│   ├── constants/     # app_sizes.dart, app_effects.dart
│   ├── error/         # global_error_handler.dart
│   ├── guards/        # admin_guard.dart (isAdminProvider)
│   ├── providers/     # analytics_provider.dart, subscription_provider.dart
│   ├── services/      # biometric, mfa, secure_storage, sentry, ad, analytics, theme, device_security
│   └── theme/         # AppTheme (light + dark, Material 3)
├── features/
│   ├── auth/          # Email/password, OTP verify, MFA (TOTP + email OTP), biometric
│   ├── dashboard/     # Net worth card, cash flow chart, money health score, upcoming bills carousel
│   ├── transactions/  # CRUD with accounts and categories, receipt scanner (ML Kit), CSV import/export
│   ├── budgets/       # Category budgets with progress tracking
│   ├── savings_goals/ # Goals + contributions (accessible via Profile → /goals)
│   ├── recurring_transactions/ # Scheduled income/expenses, auto-generation, mark-as-paid
│   ├── debt_payoff/   # Avalanche/Snowball payoff, payment plans, DTI widget
│   ├── ai_insights/   # OpenAI GPT-4o-mini chat, balance forecast (code complete, route dormant)
│   ├── notifications/ # In-app notifications with real-time updates
│   ├── settings/      # Display, notification settings, data privacy, CSV/JSON export
│   ├── profile/       # Profile edit, security settings, legal, about
│   ├── admin/         # User management, system analytics (active, admin-guarded)
│   └── subscription/  # Paywall page, subscription status card
└── shared/            # Reusable widgets (buttons, containers, offline indicator, ad widgets)
```

### Each Feature Module Structure
```
feature_name/
├── data/
│   ├── datasources/   # Supabase API calls
│   ├── models/        # JSON-serializable models extending domain entities
│   └── repositories/  # Repository implementations
├── domain/
│   ├── entities/      # Pure Dart business objects
│   └── repositories/  # Abstract interfaces
└── presentation/
    ├── pages/
    ├── widgets/
    └── providers/     # Riverpod providers (datasource → repository → UI providers)
```

---

## Core Patterns

### Supabase Client
A global shortcut is available everywhere — prefer this over `Supabase.instance.client`:
```dart
import 'package:finmate/core/config/supabase_client.dart';
final data = await supabase.from('table').select();
```

### Environment Config
Credentials are loaded from `.env` via `flutter_dotenv`. Always access through `EnvConfig`:
```dart
EnvConfig.supabaseUrl
EnvConfig.supabaseAnonKey
```

### Riverpod Provider Pattern
```dart
// Datasource → Repository → FutureProvider (reads) + StateNotifierProvider (mutations)
final repositoryProvider = Provider<Repo>((ref) => RepoImpl(...));

final dataProvider = FutureProvider<List<Item>>((ref) async {
  return ref.watch(repositoryProvider).getData();
});

// After mutations, always invalidate to refresh UI:
ref.invalidate(dataProvider);
```

Auth state flows through `authNotifierProvider` (StateNotifierProvider<AuthNotifier, AuthState>). The router (`routerProvider`) watches this via `_RouterNotifier` and auto-redirects unauthenticated users to `/login`.

### Naming Conventions
- Entities: `FeatureEntity` (e.g., `TransactionEntity`)
- Models: `FeatureModel extends FeatureEntity`
- Providers: `featureProvider`, `featureOperationsProvider`
- Pages: `FeaturePage`

---

## Routing

Router is in `lib/core/config/router.dart`. The main `ShellRoute` renders `MainShell` — a **5-tab `NavigationBar`**: **Dashboard, Transactions, Budgets, Debt, Profile**.

Commented-out routes (with their reason tag):
- `[AI Insights - Commented out]` — AI chat/forecast page (code complete, dormant until V1.1)
- `[MVP: Pricing/Subscription - Commented out for initial launch]` — subscription management pages

To activate a dormant route: uncomment its import at the top of `router.dart` and uncomment the corresponding `GoRoute` block.

### Active Routes
| Route | Feature |
|---|---|
| `/dashboard` | Dashboard (net worth, cash flow, health score, upcoming bills carousel) |
| `/transactions`, `/transactions/add` | Transactions + add/edit + CSV import/export |
| `/transactions/scan-receipt` | ML Kit receipt scanner |
| `/budgets` | Budgets |
| `/goals`, `/goals/:id` | Savings Goals (also linked from Profile) |
| `/recurring-transactions`, `/recurring-transactions/add` | Recurring Transactions (also linked from Profile) |
| `/debt`, `/debt/:debtId` | Debt Payoff (Avalanche/Snowball) |
| `/notifications` | In-app notifications |
| `/profile`, `/profile/edit`, `/profile/security`, `/profile/legal` | Profile management |
| `/settings`, `/settings/notifications`, `/settings/display`, `/settings/data-privacy` | Settings |
| `/admin/users`, `/admin/analytics`, `/admin/settings` | Admin panel (admin-guarded) |
| `/paywall` | Subscription paywall |

---

## Services Initialized at Startup (`main.dart`)

| Service | Purpose |
|---|---|
| `SentryService` | Error/crash tracking |
| `AnalyticsService` | Custom event tracking (Supabase-backed) |
| `AdService` | Google Mobile Ads |
| `DeviceSecurityService` | Jailbreak/root detection (logs warning, does not block) |
| `AutoBackupService` | Scheduled local data backup |
| `RecurringTransactionProcessor` | Auto-generates transactions from overdue recurring entries |
| `ReviewService` | In-app review prompt logic |

---

## Database Schema (Supabase)

Migrations live in `supabase/migrations/` (files `00_` through `33_`). All tables use **Row Level Security (RLS)**. New tables must include `user_id = auth.uid()` RLS policies.

Key tables:
- `user_profiles`, `accounts`, `categories`, `transactions`, `recurring_transactions`
- `budgets`, `net_worth_snapshots`, `notifications`
- `savings_goals`, `goal_contributions`
- `documents`, `analytics_events`, `emergency_fund_settings`
- `debts`, `debt_payments` — Debt Payoff feature

Financial amounts stored as `DECIMAL(15,2)`.

---

## AI Integration

The AI Insights feature (`lib/features/ai_insights/`) uses **OpenAI GPT-4o-mini** via direct HTTP calls (`openai_chat_service.dart`). The API key is loaded from `.env` via `EnvConfig.openAiApiKey`. (`AppConfig.aiModel` references `'gpt-4'` but is stale/unused — do not rely on it.)

`BalanceForecastService` (`lib/features/ai_insights/data/services/balance_forecast_service.dart`) generates 30-day balance forecasts from spending history and recurring transactions — this runs locally without any AI API call.

**The entire `ai_insights` feature is currently dormant** (route commented out in `router.dart`). Do not enable it without explicit instruction.

---

## Implementation Status

### Active (routed and working)
- Auth (email/password, MFA TOTP + email OTP, biometric, OTP verify)
- Dashboard (net worth, cash flow, health score, upcoming bills carousel)
- Transactions (CRUD, receipt scanner via ML Kit, CSV import/export)
- Budgets, Emergency Fund
- Debt Payoff (Avalanche/Snowball, payment plans, DTI widget)
- Savings Goals (accessible via Profile → `/goals`)
- Recurring Transactions (create/edit/delete, schedule, auto-generation, accessible via Profile → `/recurring-transactions`)
- Notifications, Profile, Settings
- Admin Panel (user management, system analytics — admin-guarded, accessible via Profile for admins)
- Data export (JSON, CSV) via Settings → Data & Privacy

### Code complete but route dormant
- AI Insights (`[AI Insights - Commented out]`) — full implementation in `lib/features/ai_insights/`; re-enable by uncommenting import + route in `router.dart`
- Subscription / Pricing (`[MVP: Pricing/Subscription - Commented out]`) — paywall page active at `/paywall`; full subscription management pages are dormant

### Planned / Not yet implemented
- Password reset deep-link verification (pending testing)
- CSV export for budgets (partial — transactions CSV export is live)

---

## Security & Data Handling

- Never commit `.env`
- Never log financial amounts or auth tokens in production
- All Supabase queries rely on RLS — never use service role key in client code
- Sensitive local data goes through `SecureStorageService` (wraps `flutter_secure_storage`)
- TOTP secrets encrypted at rest; biometric credentials in platform keychain
- MFA enforced for sensitive actions when enabled by user
- Session timeout: 30 minutes (`AppConfig.sessionTimeoutMinutes`)

---

## UI Rules

- **No styling/color changes** without explicit request
- Use shared widgets from `lib/shared/widgets/`
- All financial amounts display with 2 decimal places
- Loading: `CircularProgressIndicator` or shimmer
- App is locked to portrait orientation

---

## Troubleshooting

**"Table does not exist" errors** — migrations not applied. Run all files from `supabase/migrations/` in order in the Supabase SQL editor.

**RLS policy errors** — verify `Supabase.instance.client.auth.currentUser` is non-null and that RLS policies in the dashboard match expected `auth.uid()` context.

**Hot reload not reflecting provider changes** — use hot restart (`R`) after modifying providers or router config.

**Code gen errors after modifying models** — run `dart run build_runner build --delete-conflicting-outputs`.
