# FinMate - App Structure

This document provides an overview of the scaffolded app structure.

## Project Structure

```
lib/
├── core/                          # Core functionality
│   ├── constants/
│   │   ├── app_colors.dart       # Color palette
│   │   └── app_sizes.dart        # Spacing & sizing
│   ├── theme/
│   │   └── app_theme.dart        # Material 3 themes
│   └── config/
│       └── router.dart           # GoRouter configuration
│
├── features/                      # Feature modules
│   ├── auth/
│   │   └── presentation/
│   │       └── pages/
│   │           ├── onboarding_page.dart
│   │           ├── login_page.dart
│   │           └── signup_page.dart
│   │
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── dashboard_page.dart
│   │       └── widgets/
│   │           ├── net_worth_card.dart
│   │           ├── money_health_score.dart
│   │           ├── cash_flow_card.dart
│   │           ├── upcoming_bills_card.dart
│   │           └── quick_action_button.dart
│   │
│   ├── bill_splitting/
│   │   └── presentation/
│   │       └── pages/
│   │           ├── bills_page.dart
│   │           └── group_detail_page.dart
│   │
│   ├── budgets/
│   │   └── presentation/
│   │       └── pages/
│   │           └── budgets_page.dart
│   │
│   └── ai_insights/
│       └── presentation/
│           └── pages/
│               └── insights_page.dart
│
├── shared/                        # Shared widgets & services
│   └── widgets/
│       ├── custom_button.dart
│       ├── loading_overlay.dart
│       └── empty_state.dart
│
└── main.dart                      # App entry point
```

## Features Implemented

### 1. Authentication Flow
- **Onboarding**: 3-slide introduction with Material 3 design
- **Login**: Email/password with biometric placeholder
- **Signup**: Full registration flow with terms acceptance

### 2. Dashboard
- Net worth display with trend indicator
- Money health score (0-100 scale)
- Monthly cash flow breakdown
- Quick action buttons
- Upcoming bills timeline
- Recent transactions list

### 3. Bill Splitting
- Group management interface
- Balance tracking per group
- Expense recording
- Settlement status indicators

### 4. Budgets
- Category-based budget tracking
- Visual progress indicators
- Over/under budget alerts
- Spending breakdown

### 5. AI Insights
- Personalized spending alerts
- Weekly spending digest
- Category breakdown
- Trend analysis

## Design System

### Colors
- **Primary**: Emerald Green (#2ECC71), Deep Navy (#1A2B4C)
- **Secondary**: Royal Purple (#6C5CE7), Teal Blue (#00CEC9)
- **Status**: Success (#27AE60), Warning (#F39C12), Error (#E74C3C)

### Typography
- **Font**: Inter (via Google Fonts)
- **Scales**: Display, Headline, Title, Body, Label

### Theme
- Light and dark mode support
- Material 3 design system
- Consistent spacing (4dp grid)
- Rounded cards with soft shadows

## Navigation

The app uses GoRouter with the following structure:

```
/onboarding          → Onboarding Page (initial)
/login               → Login Page
/signup              → Signup Page

Main App Shell (with bottom navigation):
/dashboard           → Dashboard Page
/bills               → Bills Page
  /bills/group/:id   → Group Detail Page
/budgets             → Budgets Page
/insights            → AI Insights Page
```

## State Management

- **Provider**: Riverpod 2.6.1
- Currently using mock data
- Ready for integration with backend services

## Next Steps

To continue development:

1. **Backend Integration**
   - Add Supabase SDK
   - Implement authentication with Supabase Auth
   - Create database models
   - Set up API calls

2. **State Management**
   - Create Riverpod providers for each feature
   - Implement state classes
   - Add loading/error states

3. **Local Storage**
   - Add Hive/Isar for offline data
   - Implement encryption

4. **Additional Features**
   - Transaction entry forms
   - Budget creation forms
   - Bill splitting calculations
   - Settlement flows

5. **Testing**
   - Unit tests for business logic
   - Widget tests for UI components
   - Integration tests for critical flows

## Running the App

```bash
# Run in development
flutter run

# Run on specific device
flutter run -d <device_id>

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Dependencies

Core dependencies added:
- `flutter_riverpod`: State management
- `go_router`: Navigation
- `google_fonts`: Typography (Inter font)
- `intl`: Number/date formatting

See `pubspec.yaml` for full dependency list.
