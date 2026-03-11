# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**FinMate** is a cross-platform personal finance app built with Flutter. It covers transaction tracking, budgeting, savings goals, dashboard analytics (net worth, cash flow, money health), and AI-powered forecasting. The backend is Supabase (auth, Postgres, storage, realtime). No bank account linking — all data is manually entered or imported via CSV.

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
New migrations go in `supabase/migrations/` with an incrementing numeric prefix (currently at `33_`).
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
- **AI**: Google Gemini (`google_generative_ai` package)
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
│   ├── providers/     # analytics_provider.dart
│   ├── services/      # biometric, mfa, secure_storage, sentry, ad, analytics, theme, session, device_security
│   └── theme/         # AppTheme (light + dark, Material 3)
├── features/
│   ├── auth/          # Email/password, OTP verify, MFA (TOTP + email OTP), biometric
│   ├── dashboard/     # Net worth card, cash flow chart, money health score, emergency fund
│   ├── transactions/  # CRUD with accounts and categories, receipt scanner (ML Kit)
│   ├── budgets/       # Category budgets with progress tracking
│   ├── savings_goals/ # Goals + contributions (code complete, route commented out)
│   ├── ai_insights/   # Gemini chat, balance forecast, spending alerts (code complete, route commented out)
│   ├── notifications/ # In-app notifications (active)
│   ├── settings/      # Display, notification settings, data privacy (active)
│   ├── profile/       # Profile edit, security settings, legal (active)
│   ├── bill_splitting/# Groups/expenses/settlements (commented out — being replaced by Debt Payoff)
│   ├── admin/         # User management, system analytics (code complete, route commented out)
│   └── documents/     # Receipt/doc storage (code complete, route commented out)
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

Router is in `lib/core/config/router.dart`. The main `ShellRoute` renders `MainShell` — a 3-tab `NavigationBar`: **Dashboard, Transactions, Budgets**.

Many routes exist in the file but are commented out with their reason:
- `[MVP: AI Insights]` — AI chat/forecast page
- `[MVP: Documents]` — document storage
- `[MVP: Admin Panel]` — admin user management and analytics
- `[MVP: Pricing/Subscription]` — subscription management
- `[V1.1: Bill Splitting]` — group expense splitting (being replaced by Debt Payoff)
- `[V1.1: Recurring Transactions]` — recurring transaction automation
- `COMMENTED OUT - Savings Goals not in MVP Phase 1`

To activate a commented-out route: uncomment its import at the top of `router.dart` and uncomment the corresponding `GoRoute` block.

### Active Routes
| Route | Feature |
|---|---|
| `/dashboard` | Dashboard (net worth, cash flow, health score) |
| `/dashboard/emergency-fund` | Emergency Fund tracker |
| `/transactions`, `/transactions/add` | Transactions + add/edit |
| `/transactions/scan-receipt` | ML Kit receipt scanner |
| `/budgets` | Budgets |
| `/notifications` | In-app notifications |
| `/profile`, `/profile/edit`, `/profile/security` | Profile management |
| `/settings`, `/settings/notifications`, `/settings/display`, `/settings/data-privacy` | Settings |

---

## Services Initialized at Startup (`main.dart`)

| Service | Purpose |
|---|---|
| `SentryService` | Error/crash tracking |
| `AnalyticsService` | Custom event tracking (Supabase-backed) |
| `AdService` | Google Mobile Ads |
| `DeviceSecurityService` | Jailbreak/root detection (logs warning, does not block) |
| Stripe (`PaymentService`) | **Commented out** — not active in MVP |

---

## Database Schema (Supabase)

Migrations live in `supabase/migrations/` (files `00_` through `33_`). All tables use **Row Level Security (RLS)**. New tables must include `user_id = auth.uid()` RLS policies.

Key tables:
- `user_profiles`, `accounts`, `categories`, `transactions`, `recurring_transactions`
- `budgets`, `net_worth_snapshots`, `notifications`
- `savings_goals`, `goal_contributions`
- `documents`, `analytics_events`, `emergency_fund_settings`
- `bill_groups`, `group_members`, `group_expenses`, `expense_splits`, `settlements` — to be replaced by debt payoff tables

Financial amounts stored as `DECIMAL(15,2)`.

---

## AI Integration

The app uses **Google Gemini** via the `google_generative_ai` package — not OpenAI. (`AppConfig.aiModel` references `'gpt-4'` but is stale/unused.)

`BalanceForecastService` (`lib/features/ai_insights/data/services/balance_forecast_service.dart`) generates 30-day balance forecasts from spending history and recurring transactions — this runs locally without any AI API call.

---

## Implementation Status

### Active (routed and working)
- Auth (email/password, MFA TOTP + email OTP, biometric, OTP verify)
- Dashboard, Transactions, Budgets, Emergency Fund
- Notifications, Profile, Settings

### Code complete but commented out of routing
- AI Insights / Gemini Chat (`[MVP: AI Insights]`)
- Savings Goals (`COMMENTED OUT - Savings Goals not in MVP`)
- Documents (`[MVP: Documents]`)
- Admin Panel (`[MVP: Admin Panel]`)
- Subscription / Pricing (`[MVP: Pricing/Subscription]`)
- Recurring Transactions (`[V1.1: Recurring Transactions]`)
- Bill Splitting (`[V1.1: Bill Splitting]`) — being replaced by Debt Payoff feature

### Planned / Not yet implemented
- **Debt Payoff** (new core feature — see PRD section 3.3): debt accounts, Avalanche/Snowball strategies, payment plan calendar, DTI ratio widget, net worth integration, extra payment simulator
- CSV import for transactions

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
